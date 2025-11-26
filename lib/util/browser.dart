// Conditional export: re-export the correct implementation depending on
// whether `dart:html` is available (web) or not (mobile/desktop).
export 'browser_stub.dart' if (dart.library.html) 'browser_web.dart';
