/// Values from `flutter run --dart-define=SUPABASE_URL=...`
/// or from `run_dev.sh` in the project root.
abstract final class SupabaseDartDefines {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const String legacyAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static String get apiKey =>
      publishableKey.isNotEmpty ? publishableKey : legacyAnonKey;
}
