// Stub for non-web platforms — Telegram Mini App integration
// is only available when running as Flutter web inside Telegram.

import 'dart:convert';
import 'dart:io';

const String telegramImplementation = 'IO';

bool get isTelegramAvailable => false;
String? getTelegramInitData() => null;

String get tgFirstName => '';
String get tgLastName => '';
String get tgUsername => '';
String get tgPhotoUrl => '';

/// Stub — uses dart:io HttpClient on non-web.
Future<Map<String, dynamic>?> postToEdgeFunction({
  required String url,
  required String anonKey,
  required Map<String, dynamic> body,
  Map<String, String>? extraHeaders,
}) async {
  try {
    final client = HttpClient();
    final req = await client.postUrl(Uri.parse(url));
    req.headers.set('Content-Type', 'application/json');
    req.headers.set('apikey', anonKey);
    req.headers.set('Authorization', 'Bearer $anonKey');
    extraHeaders?.forEach(req.headers.set);
    req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close().timeout(const Duration(seconds: 15));
    final text = await res.transform(utf8.decoder).join();
    client.close(force: true);
    if (text.isEmpty) return null;
    return jsonDecode(text) as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
}
