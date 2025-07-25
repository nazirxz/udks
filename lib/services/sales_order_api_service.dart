// lib/services/sales_order_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
      debugPrint('DEBUG: Retrieved auth token: ${token != null ? 'exists' : 'null'}');
      return token;
    } catch (e) {
      debugPrint('DEBUG: Error getting auth token: $e');
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

      debugPrint('DEBUG: Getting sales orders from: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      debugPrint('DEBUG: Sales orders response status: ${response.statusCode}');
      debugPrint('DEBUG: Sales orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('DEBUG: Parsed response data type: ${responseData.runtimeType}');
        debugPrint('DEBUG: Response data keys: ${responseData.keys}');
        
        if (responseData['status'] == 'success' || responseData['success'] == true) {
          // Handle new pagination structure - data is inside data.data
          final dataWrapper = responseData['data'];
          final ordersData = dataWrapper['data'] ?? dataWrapper ?? [];
          
          debugPrint('DEBUG: Data wrapper type: ${dataWrapper.runtimeType}');
          debugPrint('DEBUG: Orders data type: ${ordersData.runtimeType}');
          debugPrint('DEBUG: Orders data length: ${ordersData is List ? ordersData.length : 'Not a list'}');
          
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
          
          debugPrint('DEBUG: Parsed ${orders.length} orders successfully');
          
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
      debugPrint('DEBUG: Error getting sales orders: $e');
      debugPrint('DEBUG: Error type: ${e.runtimeType}');
      
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

      debugPrint('DEBUG: Updating shipping status for order $orderId to $orderStatus');

      if (deliveryPhoto != null) {
        // Try direct PUT with multipart first
        try {
          final request = http.MultipartRequest('PUT', uri);
          request.headers.addAll(_getMultipartHeaders(token));

          // Add fields - ensure order_status is always included
          request.fields['order_status'] = orderStatus;
          debugPrint('DEBUG: Adding order_status field: $orderStatus');
          
          if (deliveryNotes != null && deliveryNotes.isNotEmpty) {
            request.fields['delivery_notes'] = deliveryNotes;
            debugPrint('DEBUG: Adding delivery_notes field: $deliveryNotes');
          }
          if (deliveredAt != null && deliveredAt.isNotEmpty) {
            request.fields['delivered_at'] = deliveredAt;
            debugPrint('DEBUG: Adding delivered_at field: $deliveredAt');
          }

          // Debug: Print all fields being sent
          debugPrint('DEBUG: All fields being sent: ${request.fields}');

          // Add photo file
          final photoFile = await http.MultipartFile.fromPath(
            'delivery_photo',
            deliveryPhoto.path,
          );
          request.files.add(photoFile);
          debugPrint('DEBUG: Added photo file: ${photoFile.filename}');

          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          debugPrint('DEBUG: Update shipping status response status: ${response.statusCode}');
          debugPrint('DEBUG: Update shipping status response body: ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
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
          } else if (response.statusCode == 422) {
            // Try POST with _method override if PUT multipart fails with 422
            debugPrint('DEBUG: PUT multipart failed with 422, trying POST with _method override');
            
            final postRequest = http.MultipartRequest('POST', uri);
            postRequest.headers.addAll(_getMultipartHeaders(token));
            
            // Add method override
            postRequest.fields['_method'] = 'PUT';
            postRequest.fields['order_status'] = orderStatus;
            
            if (deliveryNotes != null && deliveryNotes.isNotEmpty) {
              postRequest.fields['delivery_notes'] = deliveryNotes;
            }
            if (deliveredAt != null && deliveredAt.isNotEmpty) {
              postRequest.fields['delivered_at'] = deliveredAt;
            }
            
            // Add photo file again
            final postPhotoFile = await http.MultipartFile.fromPath(
              'delivery_photo',
              deliveryPhoto.path,
            );
            postRequest.files.add(postPhotoFile);
            
            final postStreamedResponse = await postRequest.send();
            final postResponse = await http.Response.fromStream(postStreamedResponse);
            
            debugPrint('DEBUG: POST with override response status: ${postResponse.statusCode}');
            debugPrint('DEBUG: POST with override response body: ${postResponse.body}');
            
            if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
              final responseData = json.decode(postResponse.body);
              if (responseData['status'] == 'success' || responseData['success'] == true) {
                return {
                  'success': true,
                  'data': responseData['data'],
                  'message': responseData['message'] ?? 'Shipping status updated successfully',
                };
              }
            }
            
            // If both attempts fail, return the original error
            final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
            String errorMessage = 'Server error: ${response.statusCode}';
            
            if (errorBody['message'] != null) {
              errorMessage = errorBody['message'];
            }
            
            if (errorBody['errors'] != null) {
              final errors = errorBody['errors'];
              if (errors is Map) {
                final errorDetails = errors.values.map((e) => e.toString()).join(', ');
                errorMessage += ' - $errorDetails';
              }
            }
            
            return {
              'success': false,
              'message': errorMessage,
            };
          } else {
            // Handle other error responses for multipart
            final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
            String errorMessage = 'Server error: ${response.statusCode}';
            
            if (errorBody['message'] != null) {
              errorMessage = errorBody['message'];
            }
            
            if (errorBody['errors'] != null) {
              final errors = errorBody['errors'];
              if (errors is Map) {
                final errorDetails = errors.values.map((e) => e.toString()).join(', ');
                errorMessage += ' - $errorDetails';
              }
            }
            
            return {
              'success': false,
              'message': errorMessage,
            };
          }
        } catch (e) {
          debugPrint('DEBUG: Exception in multipart upload: $e');
          return {
            'success': false,
            'message': 'Error uploading photo: $e',
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

        debugPrint('DEBUG: Update shipping status response status: ${response.statusCode}');
        debugPrint('DEBUG: Update shipping status response body: ${response.body}');

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
      debugPrint('DEBUG: Error updating shipping status: $e');
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

      debugPrint('DEBUG: Getting order detail for ID: $orderId');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      debugPrint('DEBUG: Order detail response status: ${response.statusCode}');
      debugPrint('DEBUG: Order detail response body: ${response.body}');

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
      debugPrint('DEBUG: Error getting order detail: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
