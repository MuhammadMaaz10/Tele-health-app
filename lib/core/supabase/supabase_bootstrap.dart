import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads `.env` and initializes the Supabase client. Call before [runApp].
Future<void> initializeSupabase() async {
  debugPrint('[SupabaseInit] loading env config');

  // Prefer compile-time values when provided:
  // flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  const defineUrl = String.fromEnvironment('SUPABASE_URL');
  const defineAnon = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (defineUrl.isNotEmpty && defineAnon.isNotEmpty) {
    debugPrint('[SupabaseInit] using --dart-define values');
    await Supabase.initialize(
      url: defineUrl,
      anonKey: defineAnon,
    );
    debugPrint('[SupabaseInit] Supabase.initialize completed');
    return;
  }

  // Release web hosting can fail to serve hidden dot-files (like `.env`),
  // so use a non-hidden bundled asset first.
  try {
    await dotenv.load(fileName: 'assets/env/config.env');
    debugPrint('[SupabaseInit] loaded assets/env/config.env');
  } catch (_) {
    await dotenv.load(fileName: '.env');
    debugPrint('[SupabaseInit] loaded .env');
  }

  final url = dotenv.env['SUPABASE_URL']?.trim();
  final anon = dotenv.env['SUPABASE_ANON_KEY']?.trim();
  if (url == null || url.isEmpty || anon == null || anon.isEmpty) {
    debugPrint('[SupabaseInit] ERROR: missing SUPABASE_URL or SUPABASE_ANON_KEY');
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY in env config.',
    );
  }
  debugPrint('[SupabaseInit] SUPABASE_URL=$url (anon key length=${anon.length})');
  await Supabase.initialize(
    url: url,
    anonKey: anon,
  );
  debugPrint('[SupabaseInit] Supabase.initialize completed');
}
