import 'dart:typed_data';
import 'dart:html' as html;

Future<void> openInNewTab(String url) async {
  html.window.open(url, '_blank');
}

Future<void> downloadFromBytes(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes]);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: objectUrl)
    ..download = filename
    ..target = '_blank';
  // Append to DOM to ensure click works in some browsers
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(objectUrl);
}
