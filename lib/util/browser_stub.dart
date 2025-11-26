import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

// Stub implementation for non-web platforms. Uses `url_launcher` to open URLs
// in the external browser. The web implementation (dart:html) lives in
// `browser_web.dart` and is selected via conditional imports.

Future<void> openInNewTab(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) throw ArgumentError('Invalid URL: $url');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> downloadFromBytes(Uint8List bytes, String filename) async {
  // Not implemented on non-web: callers should open the resource URL instead.
  throw UnsupportedError('downloadFromBytes is only supported on web.');
}
