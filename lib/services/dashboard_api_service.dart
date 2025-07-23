// lib/services/dashboard_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class DashboardApiService {
  // Get authentication token
  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print('Retrieved token: ${token != null ? 'Token exists (${token.substring(0, 10)}...)' : 'No token found'}');
    return token;
  }

  // Common headers with authorization
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    print('Request headers: ${headers.keys.toList()}');
    return headers;
  }

  // Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    try {
      final body = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': body['data'],
          'status': body['status'],
          'message': body['message'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'An error occurred',
          'errors': body['errors'],
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('JSON decode error: $e');
      return {
        'success': false,
        'message': 'Failed to parse response: $e',
        'raw_response': response.body,
        'status_code': response.statusCode,
      };
    }
  }

  // GET /api/dashboard/stats - Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      print('Making request to: ${ApiConfig.dashboardStats}');
      print('Headers: $headers');
      
      final response = await http.get(
        Uri.parse(ApiConfig.dashboardStats),
        headers: headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('Network error in getDashboardStats: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // GET /api/dashboard/low-stock - Get low stock warning items
  static Future<Map<String, dynamic>> getLowStockWarning({int? threshold}) async {
    try {
      final headers = await _getHeaders();
      var url = ApiConfig.dashboardLowStock;
      if (threshold != null) {
        url += '?threshold=$threshold';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // GET /api/dashboard/weekly-stats - Get weekly incoming/outgoing statistics
  static Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.dashboardWeeklyStats),
        headers: headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // GET /api/dashboard/monthly-stats - Get monthly statistics
  static Future<Map<String, dynamic>> getMonthlyStats({int? year, int? month}) async {
    try {
      final headers = await _getHeaders();
      var url = ApiConfig.dashboardMonthlyStats;
      
      List<String> params = [];
      if (year != null) params.add('year=$year');
      if (month != null) params.add('month=$month');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // GET /api/dashboard/complete - Get complete dashboard data in one request
  static Future<Map<String, dynamic>> getCompleteDashboard() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.dashboardComplete),
        headers: headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Test method to debug API connectivity
  static Future<Map<String, dynamic>> testApiConnection() async {
    try {
      print('Testing API connection...');
      final headers = await _getHeaders();
      print('Test request to: ${ApiConfig.dashboardStats}');
      
      final response = await http.get(
        Uri.parse(ApiConfig.dashboardStats),
        headers: headers,
      );
      
      print('Test response received');
      return _handleResponse(response);
    } catch (e) {
      print('Test connection failed: $e');
      return {
        'success': false,
        'message': 'Test connection failed: $e',
      };
    }
  }
}
