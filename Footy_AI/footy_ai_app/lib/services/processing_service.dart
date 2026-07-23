import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ProcessingService {
  static String get _processingBaseUrl => AppConfig.processingApiBaseUrl;
  static String? lastError;

  static Future<String?> submitVideoUrl({
    required String videoUrl,
    int? userId,
  }) async {
    try {
      lastError = null;
      final response = await http
          .post(
            Uri.parse('$_processingBaseUrl/api/processing/submit-url'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'video_url': videoUrl,
              'user_id': userId,
              'source_type': 'auto',
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        lastError = 'Server returned ${response.statusCode}: ${response.body}';
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['job_id'] as String?;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  static Future<String?> submitVideoFile({
    required String filePath,
    int? userId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      lastError = null;
      final request = _ProgressMultipartRequest(
        'POST',
        Uri.parse('$_processingBaseUrl/api/processing/submit-file'),
        onProgress: onProgress,
      );

      if (userId != null) {
        request.fields['user_id'] = userId.toString();
      }
      request.files.add(await http.MultipartFile.fromPath('video', filePath));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        lastError = 'Server returned ${response.statusCode}: ${response.body}';
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['job_id'] as String?;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStatus(String jobId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_processingBaseUrl/api/processing/status/$jobId'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getResult(String jobId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_processingBaseUrl/api/processing/result/$jobId'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }
}

class _ProgressMultipartRequest extends http.MultipartRequest {
  _ProgressMultipartRequest(
    super.method,
    super.url, {
    this.onProgress,
  });

  final void Function(double progress)? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    if (onProgress == null || total <= 0) return byteStream;

    var sent = 0;
    final stream = byteStream.transform<List<int>>(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (List<int> data, EventSink<List<int>> sink) {
          sent += data.length;
          onProgress!(sent / total);
          sink.add(data);
        },
      ),
    );
    return http.ByteStream(stream);
  }
}
