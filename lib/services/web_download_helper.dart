import 'web_download_helper_stub.dart'
    if (dart.library.html) 'web_download_helper_web.dart';

void downloadBytesWeb(List<int> bytes, String fileName) {
  downloadBytes(bytes, fileName);
}

String? getBlobUrlWeb(List<int> bytes) {
  return getBlobUrl(bytes);
}
