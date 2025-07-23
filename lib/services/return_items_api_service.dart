// lib/services/return_items_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import '../models/returnable_item.dart';
import '../models/return_item.dart';

class ReturnItemsApiService {
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token;
  }

  static Map<String, String> _getHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // GET /api/return-items/returnable-items - Dapatkan list barang yang bisa di-return
  static Future<Map<String, dynamic>> getReturnableItems() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final uri = Uri.parse(ApiConfig.returnableItems);

      print('Returnable Items API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Returnable Items API response status: ${response.statusCode}');
      print('Returnable Items API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> dataList = responseData['data'] ?? [];
          print('DEBUG: getReturnableItems dataList count: ${dataList.length}');
          
          final returnableItems = <ReturnableItem>[];
          for (int i = 0; i < dataList.length; i++) {
            try {
              print('DEBUG: Processing returnable item $i: ${dataList[i]}');
              final item = ReturnableItem.fromJson(dataList[i]);
              returnableItems.add(item);
            } catch (e) {
              print('DEBUG: Error processing returnable item $i: $e');
              rethrow;
            }
          }
          
          return {
            'success': true,
            'data': returnableItems,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'API returned error status'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  // POST /api/return-items - Submit return barang
  static Future<Map<String, dynamic>> submitReturn({
    required int orderItemId,
    required int jumlahBarang,
    required String alasanPengembalian,
    XFile? fotoBukti,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final uri = Uri.parse(ApiConfig.returnItems);


      var request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add form fields
      request.fields['order_item_id'] = orderItemId.toString();
      request.fields['jumlah_barang'] = jumlahBarang.toString();
      request.fields['alasan_pengembalian'] = alasanPengembalian;

      // Add file if provided
      if (fotoBukti != null) {
        if (kIsWeb) {
          // For Web: Use readAsBytes
          final bytes = await fotoBukti.readAsBytes();
          var multipartFile = http.MultipartFile.fromBytes(
            'foto_bukti',
            bytes,
            filename: fotoBukti.name,
          );
          request.files.add(multipartFile);
        } else {
          // For Mobile: Use File stream
          var stream = http.ByteStream(File(fotoBukti.path).openRead());
          var length = await File(fotoBukti.path).length();
          var multipartFile = http.MultipartFile(
            'foto_bukti',
            stream,
            length,
            filename: fotoBukti.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      print('Submit Return request fields: ${request.fields}');
      print('Submit Return request files: ${request.files.length}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Submit Return API response status: ${response.statusCode}');
      print('Submit Return API response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(responseBody);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Return berhasil disubmit',
            'data': ReturnItem.fromJson(responseData['data'] ?? {}),
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'API returned error status'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: $responseBody'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  // GET /api/return-items - List return dengan data order (updated)
  static Future<Map<String, dynamic>> getReturnHistory({
    int perPage = 15,
    int page = 1,
    String? status,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final queryParams = <String, String>{
        'per_page': perPage.toString(),
        'page': page.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse(ApiConfig.returnItems).replace(
        queryParameters: queryParams,
      );

      print('Return History API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Return History API response status: ${response.statusCode}');
      print('Return History API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> dataList = responseData['data'] ?? [];
          print('DEBUG: getReturnHistory dataList count: ${dataList.length}');
          
          final returnItems = <ReturnItem>[];
          for (int i = 0; i < dataList.length; i++) {
            try {
              print('DEBUG: Processing return item $i: ${dataList[i]}');
              final item = ReturnItem.fromJson(dataList[i]);
              returnItems.add(item);
            } catch (e) {
              print('DEBUG: Error processing return item $i: $e');
              rethrow;
            }
          }
          
          return {
            'success': true,
            'data': returnItems,
            'pagination': responseData['pagination'] ?? {},
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'API returned error status'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }
  static Future<Map<String, dynamic>> getReturnItems({
    int perPage = 15,
    String? kategori,
    String? search,
    String? dateFrom,
    String? dateTo,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    int page = 1,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final queryParams = <String, String>{
        'per_page': perPage.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'page': page.toString(),
      };

      if (kategori != null && kategori.isNotEmpty) {
        queryParams['kategori'] = kategori;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['date_from'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['date_to'] = dateTo;
      }

      final uri = Uri.parse(ApiConfig.returnItems).replace(
        queryParameters: queryParams,
      );

      print('Return Items API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Return Items API response status: ${response.statusCode}');
      print('Return Items API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'] ?? [],
            'pagination': responseData['pagination'] ?? {},
            'filters': responseData['filters'] ?? {},
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'API returned error status'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('Exception in getReturnItems: $e');
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  // GET /api/return-items/categories - Kategori Barang Return
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final uri = Uri.parse(ApiConfig.returnItemsCategories);

      print('Return Items Categories API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Categories API response status: ${response.statusCode}');
      print('Categories API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': List<String>.from(responseData['data'] ?? []),
            'total_categories': responseData['total_categories'] ?? 0,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'API returned error status'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('Exception in getCategories: $e');
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  // GET /api/return-items/category/{kategori} - Filter by Kategori
  static Future<Map<String, dynamic>> getReturnItemsByCategory(
    String kategori, {
    String? search,
    int perPage = 15,
    int page = 1,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final queryParams = <String, String>{
        'per_page': perPage.toString(),
        'page': page.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(ApiConfig.returnItemsByCategory(kategori)).replace(
        queryParameters: queryParams,
      );

      print('Category filter API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Category filter API response status: ${response.statusCode}');
      print('Category filter API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'] ?? [],
            'pagination': responseData['pagination'] ?? {},
            'filters': responseData['filters'] ?? {},
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'API returned error status'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('Exception in getReturnItemsByCategory: $e');
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  // GET /api/return-items/search - Pencarian
  static Future<Map<String, dynamic>> searchReturnItems({
    required String query,
    String? kategori,
    String? reasonCategory,
    int perPage = 15,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final queryParams = <String, String>{
        'q': query,
        'per_page': perPage.toString(),
      };

      if (kategori != null && kategori.isNotEmpty) {
        queryParams['kategori'] = kategori;
      }
      if (reasonCategory != null && reasonCategory.isNotEmpty) {
        queryParams['reason_category'] = reasonCategory;
      }

      final uri = Uri.parse(ApiConfig.returnItemsSearch).replace(
        queryParameters: queryParams,
      );

      print('Search API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Search API response status: ${response.statusCode}');
      print('Search API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'] ?? [],
            'pagination': responseData['pagination'] ?? {},
            'filters': responseData['filters'] ?? {},
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'API returned error status'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  // GET /api/return-items/weekly-return-stats - Statistik Return Mingguan
  static Future<Map<String, dynamic>> getWeeklyReturnStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final queryParams = <String, String>{};

      if (startDate != null) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate;
      }

      final uri = Uri.parse(ApiConfig.returnItemsWeeklyStats).replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      print('Weekly return stats API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Weekly return stats API response status: ${response.statusCode}');
      print('Weekly return stats API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'] ?? {},
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'API returned error status'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('Exception in getWeeklyReturnStats: $e');
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  // GET /api/return-items/{id} - Detail Return Item
  static Future<Map<String, dynamic>> getReturnItemDetail(int id) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final uri = Uri.parse(ApiConfig.returnItemDetail(id));

      print('Return item detail API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Return item detail API response status: ${response.statusCode}');
      print('Return item detail API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'] ?? {},
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'API returned error status'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

}
