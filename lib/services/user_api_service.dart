// lib/services/user_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import '../models/user.dart';

class UserApiService {
  // Get auth token
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      print('DEBUG: Retrieved auth token: ${token != null ? 'exists' : 'null'}');
      return token;
    } catch (e) {
      print('DEBUG: Error getting auth token: $e');
      return null;
    }
  }

  // Get headers with authentication
  static Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get current user profile - GET /api/user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.'
        };
      }

      print('DEBUG: Getting current user profile...');
      final response = await http.get(
        Uri.parse(ApiConfig.user),
        headers: _getHeaders(token),
      );

      print('DEBUG: User profile response status: ${response.statusCode}');
      print('DEBUG: User profile response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Different API structures handling
        User? user;
        if (responseData.containsKey('data')) {
          // If response has 'data' wrapper
          user = User.fromJson(responseData['data']);
        } else if (responseData.containsKey('user')) {
          // If response has 'user' wrapper
          user = User.fromJson(responseData['user']);
        } else if (responseData.containsKey('id')) {
          // If response is direct user object
          user = User.fromJson(responseData);
        } else {
          return {
            'success': false,
            'message': 'Invalid user data structure in response',
          };
        }

        return {
          'success': true,
          'data': user,
          'message': 'User profile retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Exception in getCurrentUser: $e');
      return {
        'success': false,
        'message': 'Error getting user profile: $e',
      };
    }
  }

  // Cache user profile locally
  static Future<void> cacheUserProfile(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_profile', json.encode(user.toJson()));
      print('DEBUG: User profile cached successfully');
    } catch (e) {
      print('DEBUG: Error caching user profile: $e');
    }
  }

  // Get cached user profile
  static Future<User?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_user_profile');
      if (cachedData != null) {
        final userData = json.decode(cachedData);
        print('DEBUG: Retrieved cached user profile');
        return User.fromJson(userData);
      }
    } catch (e) {
      print('DEBUG: Error getting cached user profile: $e');
    }
    return null;
  }

  // Get user profile with caching fallback
  static Future<Map<String, dynamic>> getUserProfile({bool forceRefresh = false}) async {
    try {
      // Try to get from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedUser = await getCachedUserProfile();
        if (cachedUser != null) {
          print('DEBUG: Using cached user profile');
          return {
            'success': true,
            'data': cachedUser,
            'message': 'User profile retrieved from cache',
          };
        }
      }

      // Get from API
      print('DEBUG: Fetching user profile from API...');
      final result = await getCurrentUser();
      
      // Cache the result if successful
      if (result['success'] && result['data'] != null) {
        await cacheUserProfile(result['data'] as User);
      }

      return result;
    } catch (e) {
      print('Exception in getUserProfile: $e');
      return {
        'success': false,
        'message': 'Error getting user profile: $e',
      };
    }
  }

  // Clear cached user profile
  static Future<void> clearCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_profile');
      print('DEBUG: Cached user profile cleared');
    } catch (e) {
      print('DEBUG: Error clearing cached profile: $e');
    }
  }
}
