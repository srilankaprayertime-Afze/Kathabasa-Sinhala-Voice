import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final urls = [
    'https://digitek.lk/woodmart_slide/mobile-banner-1/',
    'https://digitek.lk/woodmart_slide/mobile-banner-2/',
    'https://digitek.lk/woodmart_slide/mobile-banner-3/',
    'https://digitek.lk/woodmart_slide/mobile-banner-4/'
  ];

  for (final u in urls) {
    final response = await http.get(Uri.parse(u));
    final html = response.body;
    final ogRegExp = RegExp('<meta property=\"og:image\" content=\"([^\"]+)\"');
    final ogMatch = ogRegExp.firstMatch(html);
    if (ogMatch != null) {
      print('URL $u -> Found og:image: ${ogMatch.group(1)}');
    } else {
      print('URL $u -> No og:image found.');
    }
  }
}
