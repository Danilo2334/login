import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/task_files_service.dart';

class TaskPdfsPage extends StatefulWidget {
  const TaskPdfsPage({
    super.key,
    required this.service,
    required this.taskId,
  });

  final TaskFilesService service;
  final String? taskId;

  @override
  State<TaskPdfsPage> createState() => _TaskPdfsPageState();
}

class _TaskPdfsPageState extends State<TaskPdfsPage> {
  List<FileObject> _files = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      _refresh();
    }
  }

  @override
  void didUpdateWidget(covariant TaskPdfsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId && widget.taskId != null) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (widget.taskId == null) return;
    setState(() => _loading = true);
    try {
      final list = await widget.service.listPdfs(widget.taskId!);
      if (!mounted) return;
      setState(() => _files = list);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los PDFs: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickAndUpload() async {
    if (widget.taskId == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null) return;

    final file = result.files.single;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontro el contenido del archivo')),
      );
      return;
    }

    try {
      await widget.service.uploadPdf(
        taskId: widget.taskId!,
        fileName: file.name,
        bytes: bytes,
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir PDF: $error')),
      );
    }
  }

  Future<void> _open(String path) async {
    final url = await widget.service.signedUrl(path, seconds: 120);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _delete(String path) async {
    await widget.service.delete(path);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'PDFs adjuntos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _pickAndUpload,
                icon: const Icon(Icons.upload_file),
                label: const Text('Subir PDF'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      final uid = Supabase.instance.client.auth.currentUser!.id;
                      final storagePath = '$uid/${widget.taskId!}/${file.name}';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(file.name),
                          subtitle: Text(storagePath),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                onPressed: () => _open(storagePath),
                                icon: const Icon(Icons.download),
                                tooltip: 'Abrir',
                              ),
                              IconButton(
                                onPressed: () => _delete(storagePath),
                                icon: const Icon(Icons.delete),
                                tooltip: 'Eliminar',
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
