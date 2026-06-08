import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Storage + [profiles] / [user_roles] updates for Supabase (replaces Heroku multipart APIs).
class SupabaseProfileService {
  SupabaseProfileService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// DD-MM-YYYY (and variants) → `DateTime` for Postgres `date`, or null.
  static DateTime? parseDobDayFirst(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final parts = s.split(RegExp(r'[-/]'));
    if (parts.length != 3) return null;
    final a = int.tryParse(parts[0].trim());
    final b = int.tryParse(parts[1].trim());
    final c = int.tryParse(parts[2].trim());
    if (a == null || b == null || c == null) return null;
    if (c > 1000) {
      // DD-MM-YYYY
      return DateTime(c, b, a);
    }
    return DateTime(a, b, c);
  }

  static Future<String?> _upload({
    required String bucket,
    required String objectPath,
    required List<int> bytes,
    String? contentType,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          objectPath,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
    if (bucket == 'avatars') {
      return _client.storage.from(bucket).getPublicUrl(objectPath);
    }
    return objectPath;
  }

  static Future<String?> uploadBytesForUser({
    required String uid,
    required String bucket,
    required List<int> bytes,
    required String filename,
  }) async {
    final ext = _fileExt(filename);
    final safeName = 'file_${DateTime.now().millisecondsSinceEpoch}$ext';
    final objectPath = '$uid/$safeName';
    final mime = _mimeForExt(ext);
    return _upload(
      bucket: bucket,
      objectPath: objectPath,
      bytes: bytes,
      contentType: mime,
    );
  }

  static String _fileExt(String filename) {
    final i = filename.lastIndexOf('.');
    if (i < 0) return '';
    return filename.substring(i).toLowerCase();
  }

  static String? _mimeForExt(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<int> roleIdByName(String nameUppercase) async {
    final row = await _client
        .from('roles')
        .select('id')
        .eq('name', nameUppercase)
        .single();
    return (row['id'] as num).toInt();
  }

  static Future<void> upsertUserRole({
    required String userId,
    required String roleName,
  }) async {
    final rid = await roleIdByName(roleName);
    await _client.from('user_roles').upsert(
      {
        'user_id': userId,
        'role_id': rid,
      },
      onConflict: 'user_id,role_id',
    );
  }

  /// Updates [profiles] for the signed-in user.
  static Future<void> updateProfileRow({
    required String userId,
    required Map<String, dynamic> fields,
  }) async {
    await _client.from('profiles').update(fields).eq('id', userId);
  }

  /// Inserts or updates [profiles] (used after OTP when no prior profile row exists).
  static Future<void> upsertProfileRow({
    required String userId,
    required Map<String, dynamic> fields,
  }) async {
    await _client.from('profiles').upsert(
      {'id': userId, ...fields},
      onConflict: 'id',
    );
  }
}
