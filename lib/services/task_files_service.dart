import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class TaskFilesService {
  TaskFilesService(
    SupabaseClient client, {
    this.bucketName = 'docs',
  }) : _client = client;

  final SupabaseClient _client;
  final String bucketName;

  StorageFileApi get _storage => _client.storage.from(bucketName);

  Future<List<FileObject>> listPdfs(String taskId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }
    final prefix = '$userId/$taskId';
    final result = await _storage.list(path: prefix);
    return result;
  }

  Future<void> uploadPdf({
    required String taskId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('Usuario no autenticado');
    }
    final path = '$userId/$taskId/$fileName';
    await _storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: true,
      ),
    );
  }

  Future<String> signedUrl(String path, {int seconds = 120}) {
    return _storage.createSignedUrl(path, seconds);
  }

  Future<void> delete(String path) async {
    await _storage.remove([path]);
  }
}
