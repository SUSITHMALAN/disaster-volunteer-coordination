import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl =
      'https://disaster-volunteer-coordination-api.onrender.com';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dvc_token');
  }

  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await _getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    throw Exception(
      'Request failed (${response.statusCode}): ${response.body}',
    );
  }
}
