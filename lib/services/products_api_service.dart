// lib/services/products_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ProductsApiService {
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print('DEBUG: Retrieved token: ${token != null ? 'EXISTS (${token.substring(0, 10)}...)' : 'NULL'}');
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

  // Helper method to get authenticated image URL
  static String getAuthenticatedImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // If it's already a full URL, convert localhost addresses to working IP
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      String convertedUrl = imagePath;
      
      // Convert various localhost formats to the working IP address
      if (imagePath.contains('127.0.0.1:8000') || 
          imagePath.contains('localhost:8000') ||
          imagePath.contains('10.0.2.2:8000')) {
        convertedUrl = imagePath.replaceAll(RegExp(r'(127\.0\.0\.1|localhost|10\.0\.2\.2):8000'), '192.168.1.21:8000');
        print('DEBUG: Converted image URL: $imagePath -> $convertedUrl');
      }
      
      return convertedUrl;
    }
    
    // If it's a relative path, prepend the working base URL
    const workingBaseUrl = 'http://192.168.1.21:8000';
    final fullUrl = '$workingBaseUrl/$imagePath'.replaceAll('//', '/').replaceAll('http:/', 'http://').replaceAll('https:/', 'https://');
    print('DEBUG: Generated image URL: $fullUrl');
    return fullUrl;
  }

  // GET /api/products - List Products
  static Future<Map<String, dynamic>> getProducts({
    int perPage = 50,
    String? kategori,
    String? search,
    String sortBy = 'nama_barang',
    String sortOrder = 'asc',
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

      final uri = Uri.parse(ApiConfig.products).replace(queryParameters: queryParams);
      print('DEBUG: Requesting products from: $uri');

      final response = await http.get(uri, headers: _getHeaders(token));
      
      print('DEBUG: Products response status: ${response.statusCode}');
      print('DEBUG: Products response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'] ?? [],
            'total_products': responseData['total_products'] ?? 0,
            'pagination': responseData['pagination'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch products',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Exception in getProducts: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // GET /api/products/categories - Get Categories
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse(ApiConfig.productsCategories),
        headers: _getHeaders(token),
      );

      print('DEBUG: Categories response status: ${response.statusCode}');
      print('DEBUG: Categories response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': responseData['data'] ?? [],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch categories',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Exception in getCategories: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // GET /api/products/{id} - Get Product Detail
  static Future<Map<String, dynamic>> getProductDetail(int id) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse(ApiConfig.productDetail(id)),
        headers: _getHeaders(token),
      );

      print('DEBUG: Product detail response status: ${response.statusCode}');
      print('DEBUG: Product detail response: ${response.body}');

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
            'message': responseData['message'] ?? 'Failed to fetch product detail',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Exception in getProductDetail: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Debug method to test API connectivity
  static Future<Map<String, dynamic>> testApiConnection() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse(ApiConfig.products),
        headers: _getHeaders(token),
      );

      return {
        'success': response.statusCode == 200,
        'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        'data': response.statusCode == 200 ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection failed: $e',
      };
    }
  }

  // Debug method to check authentication
  static Future<Map<String, dynamic>> debugAuth() async {
    final token = await _getAuthToken();
    return {
      'token_exists': token != null,
      'token_preview': token != null ? '${token.substring(0, 10)}...' : null,
    };
  }
}
