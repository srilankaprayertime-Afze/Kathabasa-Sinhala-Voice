import 'dart:html' as html;

void downloadBytes(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes], 'audio/wav');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

String? getBlobUrl(List<int> bytes) {
  final blob = html.Blob([bytes], 'audio/wav');
  return html.Url.createObjectUrlFromBlob(blob);
}
