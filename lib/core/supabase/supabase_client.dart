import 'package:supabase_flutter/supabase_flutter.dart';

/// Raccourci global vers le client Supabase
SupabaseClient get supabase => Supabase.instance.client;
