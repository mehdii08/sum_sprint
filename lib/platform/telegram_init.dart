// Conditionally exports the Telegram Mini App interop.
//
// On web → reads Telegram data from the DOM bridge element.
// On all other platforms → returns null/false.

export 'telegram_init_io.dart'
    if (dart.library.html) 'telegram_init_web.dart';
