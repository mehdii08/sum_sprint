import 'dart:html' as html;

Future<void> clearCacheAndReloadImpl() async {
  try {
    // 1. Unregister all service workers
    final registrations =
        await html.window.navigator.serviceWorker?.getRegistrations();
    if (registrations != null) {
      for (final reg in registrations) {
        await reg.unregister();
        // ignore: avoid_print
        print('[CacheClear] Unregistered service worker: ${reg.scope}');
      }
    }

    // 2. Clear all Cache Storage buckets
    final cacheNames = await html.window.caches?.keys();
    if (cacheNames != null) {
      for (final name in cacheNames) {
        await html.window.caches?.delete(name);
        // ignore: avoid_print
        print('[CacheClear] Deleted cache: $name');
      }
    }

    // 3. Clear IndexedDB (Flutter's local storage)
    try {
      final databases = await html.window.indexedDB?.open('databases');
      if (databases != null) {
        // This will clear the Flutter engine's internal DB too
        html.window.indexedDB?.deleteDatabase('flutter');
      }
    } catch (_) {
      // ignore: avoid_print
      print('[CacheClear] IndexedDB clear failed (may be expected)');
    }

    // 4. Clear localStorage
    try {
      html.window.localStorage.clear();
    } catch (_) {
      // ignore: avoid_print
      print('[CacheClear] localStorage clear failed');
    }

    // 5. Hard reload — bypass browser cache
    html.window.location.reload();
  } catch (e) {
    // ignore: avoid_print
    print('[CacheClear] Error: $e');
    // Fallback: just reload
    html.window.location.reload();
  }
}
