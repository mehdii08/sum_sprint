import 'web_cache_stub.dart'
    if (dart.library.html) 'web_cache_web.dart';

/// Clears all browser caches (service worker, cache storage, local storage)
/// and hard-reloads the app. Only works on web.
Future<void> clearAppCacheAndReload() => clearCacheAndReloadImpl();
