// Stub for non-web platforms — Telegram Mini App integration
// is only available when running as Flutter web inside Telegram.

const String telegramImplementation = 'IO';

bool get isTelegramAvailable => false;
String? getTelegramInitData() => null;

String get tgFirstName => '';
String get tgLastName => '';
String get tgUsername => '';
String get tgPhotoUrl => '';

/// Stub — not available on this platform.
Future<Map<String, dynamic>?> postToEdgeFunction({
  required String url,
  required String anonKey,
  required Map<String, dynamic> body,
}) async {
  return null;
}
