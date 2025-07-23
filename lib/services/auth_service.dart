// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_config.dart';

class AuthService {

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {
        'Accept': 'application/json',
      },
      body: {
        'full_name': fullName,
        'username': username,
        'email': email,
        'password': password,
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Debug info
    print('=== LOGIN DEBUG ===');
    ApiConfig.printDebugInfo();
    
    final loginUrl = ApiConfig.login;
    print('Attempting to connect to: $loginUrl');

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 10)); // Timeout 10 detik

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body.containsKey('access_token')) {
          await saveToken(body['access_token']);
          print('SUCCESS: Login successful!');
          return {'success': true, 'token': body['access_token']};
        } else {
          return {'success': false, 'message': 'Token tidak ditemukan dalam respons'};
        }
      } else {
        final body = json.decode(response.body);
        final errorMessage = body['message'] ?? 'Login gagal dengan status code ${response.statusCode}';
        print('FAILED: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('FATAL ERROR during login: $e');
      return {'success': false, 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      await http.post(
        Uri.parse(ApiConfig.logout),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      await prefs.remove('access_token');
    }
  }

  Future<User?> getUserFromApi() async {
    String? token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(ApiConfig.user),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = json.decode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': body};
    } else {
      return {'success': false, 'message': body['message'] ?? 'An error occurred'};
    }
  }
}