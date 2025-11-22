// Utilities for uploading/downloading documents to Supabase storage
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads raw [bytes] to Supabase Storage under [bucket] at [path].
/// If [makePublic] is true (default) returns the public URL via getPublicUrl.
/// If [makePublic] is false, a signed URL is returned (valid for [expiresIn] seconds, default 3600).
/// Throws on error with a descriptive message.
Future<String> uploadDocumentToSupabase(
  Uint8List bytes,
  String path, {
  String bucket = 'Reportes',
  bool makePublic = true,
  int expiresIn = 3600,
}) async {
  final client = Supabase.instance.client;
  try {
    // Ensure bytes not empty
    if (bytes.isEmpty) throw Exception('El archivo está vacío');

    // Upload binary
    await client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    if (makePublic) {
      final url = client.storage.from(bucket).getPublicUrl(path);
      return url;
    }

    // Create signed URL
    final signed = await client.storage.from(bucket).createSignedUrl(path, expiresIn);
    return signed.toString();
  } catch (e) {
    rethrow;
  }
}

/// Deletes a file at [path] from [bucket]. Returns true on success.
Future<bool> deleteDocumentFromSupabase(String path, {String bucket = 'Reportes'}) async {
  final client = Supabase.instance.client;
  try {
  await client.storage.from(bucket).remove([path]);
  // The API returns a response map; if no exception thrown assume success
  return true;
  } catch (_) {
    return false;
  }
}
