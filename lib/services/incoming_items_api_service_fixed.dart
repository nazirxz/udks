// lib/services/incoming_items_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class IncomingItemsApiService {
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token'); // Uses correct token key
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

      print('Incoming Items API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Incoming Items API response status: ${response.statusCode}');
      print('Incoming Items API response body: ${response.body}');

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
      print('Exception in getIncomingItems: $e');
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

      print('Incoming Items Categories API request: $uri');

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
      print('Exception in getIncomingItemsByCategory: $e');
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
      print('Exception in searchIncomingItems: $e');
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

      print('Weekly incoming stats API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Weekly incoming stats API response status: ${response.statusCode}');
      print('Weekly incoming stats API response body: ${response.body}');

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
      print('Exception in getWeeklyIncomingStats: $e');
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

      print('Incoming item detail API request: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Incoming item detail API response status: ${response.statusCode}');
      print('Incoming item detail API response body: ${response.body}');

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
      print('Exception in getIncomingItemDetail: $e');
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  // Test API connection
  static Future<Map<String, dynamic>> testApiConnection() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final uri = Uri.parse(ApiConfig.incomingItemsCategories);

      print('Testing Incoming Items API connection: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));

      print('Test API response status: ${response.statusCode}');
      print('Test API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['status'] == 'success',
          'message': responseData['status'] == 'success' 
              ? 'Incoming Items API connection successful'
              : responseData['message'] ?? 'API returned error status'
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('Exception in testApiConnection: $e');
      return {'success': false, 'message': 'Exception: $e'};
    }
  }
}
