// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

const String telegramImplementation = 'WEB';

// ── DOM bridge ──────────────────────────────────────────────────

String? _bridgeJson() {
  try {
    final el = html.document.getElementById('telegram-bridge');
    return el?.text;
  } catch (_) { return null; }
}

Map<String, dynamic>? _data() {
  try {
    final raw = _bridgeJson();
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>?;
  } catch (_) { return null; }
}

bool get isTelegramAvailable => _data()?['available'] == true;

String? getTelegramInitData() {
  final d = _data();
  if (d == null || d['available'] != true) return null;
  final s = d['initData'] as String?;
  return (s != null && s.isNotEmpty) ? s : null;
}

String get tgFirstName => _data()?['user']?['firstName'] as String? ?? '';
String get tgLastName => _data()?['user']?['lastName'] as String? ?? '';
String get tgUsername => _data()?['user']?['username'] as String? ?? '';
String get tgPhotoUrl => _data()?['user']?['photoUrl'] as String? ?? '';

// ── HTTP POST to Supabase Edge Function ──────────────────────────

Future<Map<String, dynamic>?> postToEdgeFunction({
  required String url,
  required String anonKey,
  required Map<String, dynamic> body,
  Map<String, String>? extraHeaders,
}) {
  final c = Completer<Map<String, dynamic>?>();
  final xhr = html.HttpRequest();

  xhr.open('POST', url);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.setRequestHeader('apikey', anonKey);
  xhr.setRequestHeader('Authorization', 'Bearer $anonKey');
  extraHeaders?.forEach(xhr.setRequestHeader);

  xhr.onReadyStateChange.listen((_) {
    if (xhr.readyState == html.HttpRequest.DONE) {
      final st = xhr.status ?? 0;
      if (st >= 200 && st < 300) {
        final text = xhr.responseText ?? '';
        try {
          c.complete(jsonDecode(text) as Map<String, dynamic>?);
        } catch (_) {
          c.complete(null);
        }
      } else {
        try {
          c.complete(jsonDecode(xhr.responseText ?? '') as Map<String, dynamic>?);
        } catch (_) {
          c.complete(null);
        }
      }
    }
  });

  xhr.onError.listen((_) => c.complete(null));

  Timer(const Duration(seconds: 10), () {
    if (!c.isCompleted) c.complete(null);
  });

  xhr.send(jsonEncode(body));
  return c.future;
}
