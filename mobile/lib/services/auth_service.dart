import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/user.dart';

class AuthService {
  static Future<AppUser> login(String email, String password) async {
    final response = await ApiClient.post(
      '/api/Auth/login',
      {'email': email, 'password': password},
      withAuth: false,
    );
    return _persist(response);
  }

  static Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    List<String> skills = const [],
  }) async {
    final response = await ApiClient.post(
      '/api/Auth/register',
      {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
        'skills': skills,
      },
      withAuth: false,
    );
    return _persist(response);
  }

  static Future<AppUser> _persist(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dvc_token', response['token']);
    final user = AppUser.fromJson(response);
    await prefs.setString('dvc_user', user.toJson().toString());
    return user;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dvc_token');
    await prefs.remove('dvc_user');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dvc_token') != null;
  }
}