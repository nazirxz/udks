// lib/services/admin_sales_data_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class AdminSalesDataService {
  static Map<String, dynamic>? _salesData;

  // Load sales data dari JSON file
  static Future<void> loadSalesData() async {
    if (_salesData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/data/admin_sales_data.json');
      _salesData = json.decode(response);
    } catch (e) {
      print('Error loading admin sales data: $e');
      _salesData = {
        'order_data': [
          {
            'id': 1,
            'order_number': 'ORD001',
            'customer': 'PT. Maju Jaya',
            'product': 'Minyak Goreng Tropical 2L',
            'quantity': 50,
            'total_price': 1250000,
            'order_date': '2024-12-25',
            'status': 'Diproses'
          },
          {
            'id': 2,
            'order_number': 'ORD002',
            'customer': 'Toko Berkah',
            'product': 'Beras Premium 5kg',
            'quantity': 30,
            'total_price': 1800000,
            'order_date': '2024-12-25',
            'status': 'Pending'
          },
          {
            'id': 3,
            'order_number': 'ORD003',
            'customer': 'CV. Sumber Rejeki',
            'product': 'Gula Pasir 1kg',
            'quantity': 100,
            'total_price': 1500000,
            'order_date': '2024-12-24',
            'status': 'Selesai'
          },
          {
            'id': 4,
            'order_number': 'ORD004',
            'customer': 'Warung Ibu Sari',
            'product': 'Tepung Terigu 1kg',
            'quantity': 25,
            'total_price': 375000,
            'order_date': '2024-12-24',
            'status': 'Dikirim'
          },
          {
            'id': 5,
            'order_number': 'ORD005',
            'customer': 'Minimarket ABC',
            'product': 'Mie Instan Kemasan',
            'quantity': 200,
            'total_price': 800000,
            'order_date': '2024-12-23',
            'status': 'Dibatalkan'
          }
        ],
        'vehicle_data': [
          {
            'id': 1,
            'type': 'Truk',
            'plate_number': 'B 1234 ABC',
            'sales': 'Ahmad Rizki',
            'route': 'Jakarta - Tangerang',
            'description': 'Truk box 4 ton untuk distribusi area barat'
          },
          {
            'id': 2,
            'type': 'Pick Up',
            'plate_number': 'B 5678 DEF',
            'sales': 'Siti Nurhaliza',
            'route': 'Jakarta - Bekasi',
            'description': 'Pick up untuk distribusi area timur'
          },
          {
            'id': 3,
            'type': 'Motor Box',
            'plate_number': 'B 9012 GHI',
            'sales': 'Budi Santoso',
            'route': 'Jakarta Pusat',
            'description': 'Motor box untuk distribusi dalam kota'
          },
          {
            'id': 4,
            'type': 'Van',
            'plate_number': 'B 3456 JKL',
            'sales': 'Rina Marlina',
            'route': 'Jakarta - Depok',
            'description': 'Van untuk distribusi area selatan'
          },
          {
            'id': 5,
            'type': 'Truk',
            'plate_number': 'B 7890 MNO',
            'sales': 'Joko Widodo',
            'route': 'Jakarta - Bogor',
            'description': 'Truk besar 8 ton untuk distribusi luar kota'
          }
        ],
        'categories': ['Semua Kategori', 'Minyak Goreng', 'Beras', 'Gula', 'Tepung', 'Mie Instan']
      };
    }
  }

  // Get order data
  static Future<List<Map<String, dynamic>>> getOrderData() async {
    await loadSalesData();
    final List<dynamic> data = _salesData?['order_data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get vehicle data
  static Future<List<Map<String, dynamic>>> getVehicleData() async {
    await loadSalesData();
    final List<dynamic> data = _salesData?['vehicle_data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get categories
  static Future<List<String>> getCategories() async {
    await loadSalesData();
    final List<dynamic> categories = _salesData?['categories'] ?? [];
    return categories.cast<String>();
  }

  // Delete order item (simulate)
  static Future<bool> deleteOrderItem(int id) async {
    try {
      await loadSalesData();
      final List<dynamic> data = _salesData?['order_data'] ?? [];
      data.removeWhere((item) => item['id'] == id);
      return true;
    } catch (e) {
      print('Error deleting order: $e');
      return false;
    }
  }

  // Delete vehicle item (simulate)
  static Future<bool> deleteVehicleItem(int id) async {
    try {
      await loadSalesData();
      final List<dynamic> data = _salesData?['vehicle_data'] ?? [];
      data.removeWhere((item) => item['id'] == id);
      return true;
    } catch (e) {
      print('Error deleting vehicle: $e');
      return false;
    }
  }

  // Search and filter order data
  static Future<List<Map<String, dynamic>>> searchOrderData({
    String query = '',
    String status = 'Semua Status',
  }) async {
    final allData = await getOrderData();
    
    List<Map<String, dynamic>> filteredData = allData;

    // Filter by status
    if (status != 'Semua Status') {
      filteredData = filteredData.where((item) => 
        item['status'] == status
      ).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filteredData = filteredData.where((item) => 
        item['customer'].toString().toLowerCase().contains(query.toLowerCase()) ||
        item['order_number'].toString().toLowerCase().contains(query.toLowerCase()) ||
        item['product'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    return filteredData;
  }

  // Search and filter vehicle data
  static Future<List<Map<String, dynamic>>> searchVehicleData({
    String query = '',
    String type = 'Semua Type',
  }) async {
    final allData = await getVehicleData();
    
    List<Map<String, dynamic>> filteredData = allData;

    // Filter by type
    if (type != 'Semua Type') {
      filteredData = filteredData.where((item) => 
        item['type'] == type
      ).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filteredData = filteredData.where((item) => 
        item['plate_number'].toString().toLowerCase().contains(query.toLowerCase()) ||
        item['sales'].toString().toLowerCase().contains(query.toLowerCase()) ||
        item['route'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    return filteredData;
  }
}