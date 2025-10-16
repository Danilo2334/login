import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/task_files_service.dart';
import '../../ui/task_pdfs_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _taskId;
  late final TaskFilesService _taskService;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _taskService = TaskFilesService(client);
    _ensureTask();
  }

  Future<void> _ensureTask() async {
    final supabase = Supabase.instance.client;
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      return;
    }

    final existing = await supabase.from('tasks').select('id').eq('user_id', uid).limit(1);

    if (existing.isNotEmpty) {
      setState(() => _taskId = existing.first['id'] as String);
      return;
    }

    final now = DateTime.now().toUtc();
    final today = now.toIso8601String().split('T').first;
    final start = now.toIso8601String();
    final end = now.add(const Duration(hours: 1)).toIso8601String();

    final inserted = await supabase
        .from('tasks')
        .insert({
          'user_id': uid,
          'title': 'Demo Task',
          'description': 'Tarea de ejemplo',
          'date': today,
          'start_time': start,
          'end_time': end,
          'is_completed': false,
        })
        .select('id')
        .single();

    setState(() => _taskId = inserted['id'] as String);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage demo'),
        actions: [
          IconButton(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',
          ),
        ],
      ),
      body: _taskId == null
          ? const Center(child: CircularProgressIndicator())
          : TaskPdfsPage(service: _taskService, taskId: _taskId),
    );
  }
}
