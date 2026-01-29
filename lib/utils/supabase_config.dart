import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://jxhyryktmhzfrtroggbf.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4aHlyeWt0bWh6ZnJ0cm9nZ2JmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxMDA1MTEsImV4cCI6MjA4MDY3NjUxMX0.4f3Myd6yDGY7-gL81QTmL_qnU8asE72XImITASrFi4M';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // Session persistence and auto-refresh are enabled by default in Supabase Flutter
    );
  }
}

