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

    final theme = Theme.of(context);
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final fileCount = _files.length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF101427), Color(0xFF1F2A44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(
                count: fileCount,
                loading: _loading,
                onUpload: _pickAndUpload,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 12),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : fileCount == 0
                              ? _EmptyState(onUpload: _pickAndUpload)
                              : RefreshIndicator(
                                  onRefresh: _refresh,
                                  edgeOffset: 16,
                                  child: ListView.separated(
                                    physics: const BouncingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                                    itemCount: _files.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                                    itemBuilder: (context, index) {
                                      final file = _files[index];
                                      final storagePath = '$uid/${widget.taskId!}/${file.name}';
                                      return _PdfTile(
                                        file: file,
                                        storagePath: storagePath,
                                        theme: theme,
                                        onOpen: () => _open(storagePath),
                                        onDelete: () => _delete(storagePath),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.count,
    required this.loading,
    required this.onUpload,
  });

  final int count;
  final bool loading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x336366F1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDFs adjuntos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    count == 0
                        ? 'Aún no has subido documentos'
                        : '$count documento${count == 1 ? '' : 's'} disponibles',
                    key: ValueKey(count),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          FilledButton.icon(
            onPressed: loading ? null : onUpload,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4C1D95),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(
              loading ? 'Cargando...' : 'Subir PDF',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Text(
              'Tus PDFs vivirán aquí',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sube archivos PDF para adjuntarlos a esta tarea y acceder a ellos cuando los necesites.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onUpload,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Agregar tu primer PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfTile extends StatelessWidget {
  const _PdfTile({
    required this.file,
    required this.storagePath,
    required this.theme,
    required this.onOpen,
    required this.onDelete,
  });

  final FileObject file;
  final String storagePath;
  final ThemeData theme;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final updatedAt = file.updatedAt != null ? DateTime.tryParse(file.updatedAt!) : null;
    final sizeBytes = _extractSize(file.metadata);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF818CF8)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  storagePath,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (updatedAt != null)
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label:
                            'Actualizado ${updatedAt.toLocal().toString().split('.').first}',
                      ),
                    if (sizeBytes != null)
                      _InfoChip(
                        icon: Icons.sd_storage_rounded,
                        label: _formatBytes(sizeBytes),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Column(
            children: [
              IconButton(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                tooltip: 'Abrir PDF',
                color: Colors.white,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Eliminar',
                color: Colors.pinkAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static int? _extractSize(Map<String, dynamic>? metadata) {
    final dynamic value = metadata?['size'];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double value = bytes.toDouble();
    int index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    return '${value.toStringAsFixed(value < 10 && index > 0 ? 1 : 0)} ${units[index]}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}
