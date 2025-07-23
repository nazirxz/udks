// lib/services/outgoing_items_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class OutgoingItemsService {
  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }


  // Get outgoing items with filters
  static Future<Map<String, dynamic>> getOutgoingItems({
    int perPage = 15,
    String? kategori,
    String? search,
    String sortBy = 'tanggal_keluar_barang',
    String sortOrder = 'desc',
    int page = 1,
  }) async {
    try {
      final headers = await _getHeaders();
      
      Map<String, String> queryParams = {
        'per_page': perPage.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'page': page.toString(),
      };
      
      if (kategori != null && kategori.isNotEmpty && kategori != 'Semua Kategori') {
        queryParams['kategori'] = kategori;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final uri = Uri.parse(ApiConfig.outgoingItems).replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - Server tidak merespons');
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load outgoing items: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching outgoing items: $e');
    }
  }

  // Get categories
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.outgoingItemsCategories),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Categories request timeout - Server tidak merespons');
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load categories: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // Get items by category
  static Future<Map<String, dynamic>> getItemsByCategory(String kategori) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.outgoingItemsByCategory(kategori)),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load items by category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching items by category: $e');
    }
  }

  // Search items
  static Future<Map<String, dynamic>> searchItems({
    required String query,
    String? kategori,
  }) async {
    try {
      final headers = await _getHeaders();
      
      Map<String, String> queryParams = {
        'q': query,
      };
      
      if (kategori != null && kategori.isNotEmpty && kategori != 'Semua Kategori') {
        queryParams['kategori'] = kategori;
      }
      
      final uri = Uri.parse(ApiConfig.outgoingItemsSearch).replace(
        queryParameters: queryParams,
      );
      
      
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Search request timeout - Server tidak merespons');
        },
      );
      
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search items: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error searching items: $e');
    }
  }

  // Get weekly sales stats
  static Future<Map<String, dynamic>> getWeeklySalesStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      
      Map<String, String> queryParams = {};
      
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }
      
      final uri = Uri.parse(ApiConfig.outgoingItemsWeeklyStats).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load sales stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sales stats: $e');
    }
  }

  // Get item detail
  static Future<Map<String, dynamic>> getItemDetail(int id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse(ApiConfig.outgoingItemDetail(id)),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Detail request timeout - Server tidak merespons');
        },
      );
      
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load item detail: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching item detail: $e');
    }
  }
}
