import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MediaService {
  static const _baseUrl = 'https://codingaja.com/api/media';
  static const _bearerToken =
      '28b67437f869aca82743cd84682018cdfed0b9237bb22aed0217aa018de9a2f5';

  final _client = http.Client();

  Future<UploadResult> upload(File file) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
      request.headers['Authorization'] = 'Bearer $_bearerToken';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await _client.send(request);
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (data['success'] == true) {
        var url = (data['data']['url'] ?? '').toString();
        url = url.replaceFirst('http://localhost:8000', 'https://codingaja.com');
        return UploadResult(
          success: true,
          url: url,
          filename: data['data']['filename'] ?? '',
          path: data['data']['path'] ?? '',
        );
      }
      return UploadResult(success: false, error: 'Upload failed');
    } catch (e) {
      return UploadResult(success: false, error: e.toString());
    }
  }

  Future<bool> delete(String path) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delete'),
        headers: {
          'Authorization': 'Bearer $_bearerToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'path': path}),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

class UploadResult {
  final bool success;
  final String url;
  final String filename;
  final String path;
  final String? error;

  UploadResult({
    required this.success,
    this.url = '',
    this.filename = '',
    this.path = '',
    this.error,
  });
}
