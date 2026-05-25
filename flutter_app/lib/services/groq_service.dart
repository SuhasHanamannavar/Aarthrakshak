import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class GroqService {
  static const String _baseUrl = 'https://aarthrakshak-backend.onrender.com/api';

  static Future<String?> complete({
    required String prompt,
    String? systemPrompt,
    String model = 'mixtral-8x7b-32768',
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/ai/complete');
      final body = {
        'prompt': prompt,
        'systemPrompt': ?systemPrompt,
        'model': model,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'responseFormat': 'text',
      };
      final res = await http
          .post(url, headers: ApiService.authHeaders, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['mock'] == true) return null;
        return data['content'] as String?;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> completeJson({
    required String prompt,
    String? systemPrompt,
    String model = 'mixtral-8x7b-32768',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/ai/complete');
      final body = {
        'prompt': prompt,
        'systemPrompt': ?systemPrompt,
        'model': model,
        'temperature': 0.3,
        'maxTokens': 1024,
        'responseFormat': 'json',
      };
      final res = await http
          .post(url, headers: ApiService.authHeaders, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['mock'] == true) return null;
        return data['content'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
