import 'dart:io';

void main() async {
  final url = Uri.parse('https://digitek.lk/?cms_block=mobile-banner');
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  
  String html = '';
  await for (var content in response.transform(SystemEncoding().decoder)) {
    html += content;
  }
  
  final regex = RegExp(r'<img[^>]+src=["\']([^"\']+)["\']', caseSensitive: false);
  final matches = regex.allMatches(html);
  
  for (var match in matches) {
    print(match.group(1));
  }
}
class SystemEncoding {
  get decoder => const SystemEncodingDecoder();
}
class SystemEncodingDecoder extends Converter<List<int>, String> {
  const SystemEncodingDecoder();
  String convert(List<int> input) => String.fromCharCodes(input);
  ByteConversionSink startChunkedConversion(Sink<String> sink) {
    return _SystemEncodingSink(sink);
  }
}
class _SystemEncodingSink extends ByteConversionSinkBase {
  final Sink<String> _sink;
  _SystemEncodingSink(this._sink);
  void add(List<int> chunk) => _sink.add(String.fromCharCodes(chunk));
  void close() => _sink.close();
}
