import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://62.217.178.166:3000';
  
  static String? _token;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _initialized = true;
    }
  }

  static Future<void> setToken(String? token) async {
    _token = token;
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
  }

  static Future<String?> getToken() async {
    if (!_initialized) {
      await initialize();
    }
    return _token;
  }

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
      await setToken(null);
    }
    return response;
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic>? body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
      await setToken(null);
    }
    return response;
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic>? body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await getHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
      await setToken(null);
    }
    return response;
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await getHeaders();
    final response = await http.delete(url, headers: headers);
    if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
      await setToken(null);
    }
    return response;
  }

  static Future<http.StreamedResponse> uploadFile(
    String endpoint,
    String fileName,
    List<int> fileBytes,
    String fieldName,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final token = await getToken();
    final request = http.MultipartRequest('POST', url);
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: fileName,
      ),
    );
    
    return request.send();
  }
}

