import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}

