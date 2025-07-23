import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderHistoryApiService {
  static const String baseUrl = 'https://udkeluargasehati.com/api';

  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token'); // Use consistent key
      print('DEBUG: Retrieved auth token: ${token != null ? 'exists' : 'null'}');
      return token;
    } catch (e) {
      print('ERROR: Failed to get auth token: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getOrderHistory({
    int page = 1,
    int perPage = 10,
    String? status,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: queryParams);
      
      print('DEBUG: Requesting order history from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Order history response status: ${response.statusCode}');
      print('DEBUG: Order history response body: ${response.body}');
      print('DEBUG: Response body type: ${response.body.runtimeType}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed data type: ${data.runtimeType}');
        print('DEBUG: Parsed data keys: ${data is Map ? data.keys.toList() : 'Not a Map'}');
        
        // Handle different response structures
        List<dynamic> orders = [];
        Map<String, dynamic> pagination = {};
        
        if (data is Map<String, dynamic>) {
          // Check if data has 'data' field (common API structure)
          if (data.containsKey('data')) {
            final dataField = data['data'];
            if (dataField is List) {
              orders = dataField;
            } else if (dataField is Map && dataField.containsKey('data')) {
              // Nested data structure
              orders = dataField['data'] as List<dynamic>? ?? [];
              pagination = dataField['pagination'] as Map<String, dynamic>? ?? {};
            }
          } else {
            // Direct list in root
            if (data.containsKey('orders')) {
              orders = data['orders'] as List<dynamic>? ?? [];
            } else {
              // Fallback: treat entire response as single order (wrap in list)
              orders = [data];
            }
          }
          
          // Extract pagination if available
          if (data.containsKey('pagination')) {
            pagination = data['pagination'] as Map<String, dynamic>? ?? {};
          } else if (data.containsKey('meta')) {
            pagination = data['meta'] as Map<String, dynamic>? ?? {};
          }
        } else if (data is List) {
          // Direct list response
          orders = data;
        }
        
        // Debug: Print first order status if available
        if (orders.isNotEmpty) {
          final firstOrder = orders[0];
          print('DEBUG: First order data keys: ${firstOrder is Map ? firstOrder.keys.toList() : 'Not a Map'}');
          if (firstOrder is Map) {
            print('DEBUG: Order status field: ${firstOrder['status']}');
            print('DEBUG: Order_status field: ${firstOrder['order_status']}');
            print('DEBUG: Payment status field: ${firstOrder['payment_status']}');
          }
        }
        
        return {
          'success': true,
          'message': data is Map ? (data['message'] ?? 'Data berhasil diambil') : 'Data berhasil diambil',
          'data': orders,
          'pagination': pagination,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch order history',
        };
      }
    } catch (e) {
      print('ERROR: Order history API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final uri = Uri.parse('$baseUrl/orders/$orderId');
      
      print('DEBUG: Requesting order detail from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Order detail response status: ${response.statusCode}');
      print('DEBUG: Order detail response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'success': true,
          'message': data['message'] ?? 'Data berhasil diambil',
          'data': data['data'] ?? {},
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch order detail',
        };
      }
    } catch (e) {
      print('ERROR: Order detail API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orange';
      case 'processing':
        return 'blue';
      case 'shipped':
        return 'purple';
      case 'delivered':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  static String getStatusText(String status) {
    // Return the actual status from API instead of hard-coded mapping
    // The API should provide localized status text
    return status.isNotEmpty ? status : 'Status Tidak Diketahui';
  }
}
