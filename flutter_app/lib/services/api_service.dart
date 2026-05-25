import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://10.0.2.2:8080/api';

class ApiService {
  static String _jwtToken = '';

  static void setToken(String token) {
    _jwtToken = token;
  }

  static Map<String, String> get authHeaders => {
        if (_jwtToken.isNotEmpty)
          'Authorization': 'Bearer $_jwtToken',
        'Content-Type': 'application/json',
      };

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: authHeaders);
  }

  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(url, headers: authHeaders, body: jsonEncode(body));
  }
}
