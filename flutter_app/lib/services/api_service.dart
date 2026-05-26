import 'dart:convert';
import 'package:http/http.dart' as http;

// Preserved your actual backend deployment URL instead of the generic 'financeapp' placeholder!
const String baseUrl = 'https://aarthrakshak-2.onrender.com/api/v1';

class ApiService {
  static String _jwtToken = '';

  static void setToken(String token) {
    _jwtToken = token;
  }

  static Map<String, String> get authHeaders => {
        if (_jwtToken.isNotEmpty) 'Authorization': 'Bearer $_jwtToken',
        'Content-Type': 'application/json',
      };

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: authHeaders);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(url, headers: authHeaders, body: jsonEncode(body));
  }

  static Future<http.StreamedResponse> uploadPdf(String endpoint, String filePath, String fieldName) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);
    if (_jwtToken.isNotEmpty) request.headers['Authorization'] = 'Bearer $_jwtToken';
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    return await request.send();
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.patch(url, headers: authHeaders, body: jsonEncode(body));
  }
}
