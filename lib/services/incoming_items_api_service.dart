// lib/services/incoming_items_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class IncomingItemsApiService {
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    return prefs.getString('access_token');
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

  // GET /api/incoming-items - List Barang Masuk dengan Filter
  static Future<Map<String, dynamic>> getIncomingItems({
    int perPage = 15,
    String? kategori,
    String? search,
    String? stockFilter,
    String sortBy = 'tanggal_masuk_barang',
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
      if (stockFilter != null && stockFilter.isNotEmpty && stockFilter != 'all') {
        queryParams['stock_filter'] = stockFilter;
      }

      final uri = Uri.parse(ApiConfig.incomingItems).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: _getHeaders(token));

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

  // GET /api/incoming-items/categories - Kategori Barang Masuk
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final uri = Uri.parse(ApiConfig.incomingItemsCategories);

      final response = await http.get(uri, headers: _getHeaders(token));

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
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  // GET /api/incoming-items/category/{kategori} - Filter by Kategori
  static Future<Map<String, dynamic>> getIncomingItemsByCategory(
    String kategori, {
    String? stockFilter,
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

      if (stockFilter != null && stockFilter.isNotEmpty && stockFilter != 'all') {
        queryParams['stock_filter'] = stockFilter;
      }

      final uri = Uri.parse(ApiConfig.incomingItemsByCategory(kategori)).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: _getHeaders(token));

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

  // GET /api/incoming-items/search - Pencarian
  static Future<Map<String, dynamic>> searchIncomingItems({
    required String query,
    String? kategori,
    String? stockFilter,
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
      if (stockFilter != null && stockFilter.isNotEmpty && stockFilter != 'all') {
        queryParams['stock_filter'] = stockFilter;
      }

      final uri = Uri.parse(ApiConfig.incomingItemsSearch).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: _getHeaders(token));

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

  // GET /api/incoming-items/weekly-incoming-stats - Statistik Penerimaan Barang Mingguan
  static Future<Map<String, dynamic>> getWeeklyIncomingStats({
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

      final uri = Uri.parse(ApiConfig.incomingItemsWeeklyStats).replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(uri, headers: _getHeaders(token));

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

  // GET /api/incoming-items/{id} - Detail Barang Masuk
  static Future<Map<String, dynamic>> getIncomingItemDetail(int id) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final uri = Uri.parse(ApiConfig.incomingItemDetail(id));

      final response = await http.get(uri, headers: _getHeaders(token));

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
