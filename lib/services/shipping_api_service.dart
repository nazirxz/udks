// lib/services/shipping_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ShippingApiService {
  // Get auth token
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
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

  // Get shipping methods - GET /api/shipping-methods
  static Future<Map<String, dynamic>> getShippingMethods() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found'
        };
      }

      final response = await http.get(
        Uri.parse(ApiConfig.shippingMethods),
        headers: _getHeaders(token),
      );

      print('DEBUG: Shipping methods response status: ${response.statusCode}');
      print('DEBUG: Shipping methods response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'] ?? [],
            'total_methods': responseData['total_methods'] ?? 0,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to get shipping methods',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Exception in getShippingMethods: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get default shipping methods (fallback when API fails)
  static List<Map<String, dynamic>> getDefaultShippingMethods() {
    return [
      {
        'id': 1,
        'name': 'Standard Delivery',
        'description': '2-3 business days',
        'price': 15000,
        'icon': 'local_shipping',
        'is_active': true,
      },
      {
        'id': 2,
        'name': 'Express Delivery',
        'description': 'Same day delivery',
        'price': 25000,
        'icon': 'speed',
        'is_active': true,
      },
      {
        'id': 3,
        'name': 'Free Delivery',
        'description': '5-7 business days',
        'price': 0,
        'icon': 'card_giftcard',
        'is_active': true,
      },
    ];
  }
}
