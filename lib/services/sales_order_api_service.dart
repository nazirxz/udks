// lib/services/sales_order_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import '../models/sales_order.dart';

class SalesOrderApiService {
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

  // Get headers for multipart form data
  static Map<String, String> _getMultipartHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 📍 1. Get Sales Orders - GET /api/orders/sales
  /// Filter parameters: status, city, date_from, date_to, search, warehouse_lat, warehouse_lng
  static Future<Map<String, dynamic>> getSalesOrders({
    String? status,
    String? city,
    String? dateFrom,
    String? dateTo,
    String? search,
    double? warehouseLat,
    double? warehouseLng,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.'
        };
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
      if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (warehouseLat != null) queryParams['warehouse_lat'] = warehouseLat.toString();
      if (warehouseLng != null) queryParams['warehouse_lng'] = warehouseLng.toString();

      final uri = Uri.parse(ApiConfig.salesOrders).replace(queryParameters: queryParams);

      print('DEBUG: Getting sales orders from: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('DEBUG: Sales orders response status: ${response.statusCode}');
      print('DEBUG: Sales orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('DEBUG: Parsed response data type: ${responseData.runtimeType}');
        print('DEBUG: Response data keys: ${responseData.keys}');
        
        if (responseData['status'] == 'success' || responseData['success'] == true) {
          // Handle new pagination structure - data is inside data.data
          final dataWrapper = responseData['data'];
          final ordersData = dataWrapper['data'] ?? dataWrapper ?? [];
          
          print('DEBUG: Data wrapper type: ${dataWrapper.runtimeType}');
          print('DEBUG: Orders data type: ${ordersData.runtimeType}');
          print('DEBUG: Orders data length: ${ordersData is List ? ordersData.length : 'Not a list'}');
          
          // Handle both List and Map responses
          List<SalesOrder> orders = [];
          if (ordersData is List) {
            orders = ordersData
                .map((orderJson) => SalesOrder.fromJson(orderJson))
                .toList();
          } else if (ordersData is Map<String, dynamic>) {
            // If it's a single order wrapped in a map
            orders = [SalesOrder.fromJson(ordersData)];
          }
          
          print('DEBUG: Parsed ${orders.length} orders successfully');
          
          return {
            'success': true,
            'data': orders,
            'message': responseData['message'] ?? 'Sales orders retrieved successfully',
            'pagination': dataWrapper, // Include pagination info
            'warehouse': responseData['warehouse'], // Include warehouse info
            'summary': responseData['summary'], // Include summary
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to get sales orders',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('DEBUG: Error getting sales orders: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      
      if (e.toString().contains('type') && e.toString().contains('cast')) {
        return {
          'success': false,
          'message': 'Data format error: Unable to parse server response. Please contact support.',
        };
      }
      
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// ✅ 2. Update Shipping Status - PUT /api/orders/{id}/shipping-status
  /// Required: order_status, delivered_at (if status is delivered)
  /// Optional: delivery_notes, delivery_photo
  static Future<Map<String, dynamic>> updateShippingStatus({
    required int orderId,
    required String orderStatus,
    String? deliveryNotes,
    String? deliveredAt,
    File? deliveryPhoto,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.'
        };
      }

      final uri = Uri.parse(ApiConfig.orderShippingStatus(orderId));

      print('DEBUG: Updating shipping status for order $orderId to $orderStatus');

      if (deliveryPhoto != null) {
        // Use multipart request for photo upload
        final request = http.MultipartRequest('PUT', uri);
        request.headers.addAll(_getMultipartHeaders(token));

        // Add fields
        request.fields['order_status'] = orderStatus;
        if (deliveryNotes != null && deliveryNotes.isNotEmpty) {
          request.fields['delivery_notes'] = deliveryNotes;
        }
        if (deliveredAt != null && deliveredAt.isNotEmpty) {
          request.fields['delivered_at'] = deliveredAt;
        }

        // Add photo file
        final photoFile = await http.MultipartFile.fromPath(
          'delivery_photo',
          deliveryPhoto.path,
        );
        request.files.add(photoFile);

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('DEBUG: Update shipping status response status: ${response.statusCode}');
        print('DEBUG: Update shipping status response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['status'] == 'success' || responseData['success'] == true) {
            return {
              'success': true,
              'data': responseData['data'],
              'message': responseData['message'] ?? 'Shipping status updated successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to update shipping status',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      } else {
        // Use regular JSON request without photo
        final requestData = {
          'order_status': orderStatus,
        };
        
        if (deliveryNotes != null && deliveryNotes.isNotEmpty) {
          requestData['delivery_notes'] = deliveryNotes;
        }
        
        if (deliveredAt != null && deliveredAt.isNotEmpty) {
          requestData['delivered_at'] = deliveredAt;
        }

        final response = await http.put(
          uri,
          headers: _getHeaders(token),
          body: json.encode(requestData),
        );

        print('DEBUG: Update shipping status response status: ${response.statusCode}');
        print('DEBUG: Update shipping status response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['status'] == 'success' || responseData['success'] == true) {
            return {
              'success': true,
              'data': responseData['data'],
              'message': responseData['message'] ?? 'Shipping status updated successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to update shipping status',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('DEBUG: Error updating shipping status: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get order detail
  static Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.'
        };
      }

      final uri = Uri.parse(ApiConfig.orderDetail(orderId));

      print('DEBUG: Getting order detail for ID: $orderId');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('DEBUG: Order detail response status: ${response.statusCode}');
      print('DEBUG: Order detail response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' || responseData['success'] == true) {
          final orderData = responseData['data'] ?? responseData['order'];
          final order = SalesOrder.fromJson(orderData);
          
          return {
            'success': true,
            'data': order,
            'message': responseData['message'] ?? 'Order detail retrieved successfully',
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
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('DEBUG: Error getting order detail: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
