// lib/services/order_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class OrderApiService {
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

  // Create new order - POST /api/orders
  static Future<Map<String, dynamic>> createOrder({
    required String pengecerName,
    required String pengecerPhone,
    required String pengecerEmail,
    required String shippingAddress,
    required String city,
    required String postalCode,
    required double latitude,
    required double longitude,
    required String locationAddress,
    required double locationAccuracy,
    required List<Map<String, dynamic>> items,
    required String shippingMethod,
    required String paymentMethod,
    String? voucherCode,
    String? notes,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.'
        };
      }

      final orderData = {
        'pengecer_name': pengecerName,
        'pengecer_phone': pengecerPhone,
        'pengecer_email': pengecerEmail,
        'shipping_address': shippingAddress,
        'city': city,
        'postal_code': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'location_address': locationAddress,
        'location_accuracy': locationAccuracy,
        'items': items,
        'shipping_method': shippingMethod,
        'payment_method': paymentMethod,
        'notes': notes ?? '',
      };

      if (voucherCode != null && voucherCode.isNotEmpty) {
        orderData['voucher_code'] = voucherCode;
      }

      print('DEBUG: Creating order with data: ${json.encode(orderData)}');

      final response = await http.post(
        Uri.parse(ApiConfig.orders),
        headers: _getHeaders(token),
        body: json.encode(orderData),
      );

      print('DEBUG: Order creation response status: ${response.statusCode}');
      print('DEBUG: Order creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ?? 'Order created successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to create order',
          };
        }
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorBody['message'] ?? 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Exception in createOrder: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get order detail - GET /api/orders/{id}
  static Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found'
        };
      }

      final response = await http.get(
        Uri.parse(ApiConfig.orderDetail(orderId)),
        headers: _getHeaders(token),
      );

      print('DEBUG: Order detail response status: ${response.statusCode}');
      print('DEBUG: Order detail response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to get order detail',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Exception in getOrderDetail: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
