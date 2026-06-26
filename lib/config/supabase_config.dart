/// Supabase configuration constants.
///
/// In production, load these from environment variables or a .env file.
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL (e.g. https://xxxxx.supabase.co)
  static const String url = 'https://xnwjbrtbpjaeuqyrkyvg.supabase.co';

  /// Your Supabase anon/public key (from Settings → API → Project API keys)
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhud2picnRicGphZXVxeXJreXZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzNTA1NzQsImV4cCI6MjA5NjkyNjU3NH0.4Xr_L_YiEZftCW9Hb43c2LWflKxDmyMKA6SZ0PmbHIQ';

  /// Admin users (Telegram usernames) who can access the admin panel.
  static const List<String> adminUsernames = ['mehdi_mansournia'];

  /// Set to `true` to allow email-authed (non-Telegram) users to access
  /// the admin panel. Only works in debug builds (`flutter run`).
  static const bool debugMode = true;
}
