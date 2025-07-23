// lib/services/manager_sales_data_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class ManagerSalesDataService {
  static Map<String, dynamic>? _salesData;

  // Load sales data dari JSON file
  static Future<void> loadSalesData() async {
    if (_salesData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/data/manager_sales_data.json');
      _salesData = json.decode(response);
    } catch (e) {
      print('Error loading sales data: $e');
      _salesData = {};
    }
  }

  // Get weekly sales statistics
  static Future<Map<String, dynamic>> getWeeklySalesStats() async {
    await loadSalesData();
    return _salesData?['weekly_sales_stats'] ?? {};
  }

  // Get weekly sales chart data
  static Future<List<Map<String, dynamic>>> getWeeklySalesChart() async {
    await loadSalesData();
    final List<dynamic> data = _salesData?['weekly_sales_chart'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get weekly sales data
  static Future<List<Map<String, dynamic>>> getWeeklySalesData() async {
    await loadSalesData();
    final List<dynamic> data = _salesData?['weekly_sales_data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get categories
  static Future<List<String>> getCategories() async {
    await loadSalesData();
    final List<dynamic> categories = _salesData?['categories'] ?? [];
    return categories.cast<String>();
  }

  // Delete sales item (simulate)
  static Future<bool> deleteSalesItem(int id) async {
    try {
      await loadSalesData();
      final List<dynamic> data = _salesData?['weekly_sales_data'] ?? [];
      data.removeWhere((item) => item['id'] == id);
      return true;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }

  // Search and filter sales data
  static Future<List<Map<String, dynamic>>> searchSalesData({
    String query = '',
    String category = 'Semua Kategori',
  }) async {
    final allData = await getWeeklySalesData();
    
    List<Map<String, dynamic>> filteredData = allData;

    // Filter by category
    if (category != 'Semua Kategori') {
      filteredData = filteredData.where((item) => 
        item['kategori'] == category
      ).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filteredData = filteredData.where((item) => 
        item['nama_barang'].toString().toLowerCase().contains(query.toLowerCase()) ||
        item['kategori'].toString().toLowerCase().contains(query.toLowerCase()) ||
        item['lokasi_stok'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    return filteredData;
  }
}