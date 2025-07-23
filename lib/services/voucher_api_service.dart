// lib/services/voucher_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class VoucherApiService {
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

  // Get active vouchers - GET /api/vouchers
  static Future<Map<String, dynamic>> getActiveVouchers() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found'
        };
      }

      final response = await http.get(
        Uri.parse(ApiConfig.vouchers),
        headers: _getHeaders(token),
      );

      print('DEBUG: Vouchers response status: ${response.statusCode}');
      print('DEBUG: Vouchers response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'] ?? [],
            'total_vouchers': responseData['total_vouchers'] ?? 0,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to get vouchers',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Exception in getActiveVouchers: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Validate voucher code - POST /api/vouchers/validate
  static Future<Map<String, dynamic>> validateVoucher({
    required String voucherCode,
    required double orderAmount,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found'
        };
      }

      final requestData = {
        'voucher_code': voucherCode,
        'order_amount': orderAmount,
      };

      print('DEBUG: Validating voucher with data: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse(ApiConfig.vouchersValidate),
        headers: _getHeaders(token),
        body: json.encode(requestData),
      );

      print('DEBUG: Voucher validation response status: ${response.statusCode}');
      print('DEBUG: Voucher validation response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ?? 'Voucher is valid',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Voucher validation failed',
          };
        }
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'message': errorBody['message'] ?? 'Voucher not valid',
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Exception in validateVoucher: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
