// lib/services/manager_purchase_data_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class ManagerPurchaseDataService {
  static Map<String, dynamic>? _purchaseData;

  // Load purchase data dari JSON file
  static Future<void> loadPurchaseData() async {
    if (_purchaseData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/data/manager_purchase_data.json');
      _purchaseData = json.decode(response);
    } catch (e) {
      print('Error loading purchase data: $e');
      _purchaseData = {};
    }
  }

  // Get weekly purchase statistics
  static Future<Map<String, dynamic>> getWeeklyPurchaseStats() async {
    await loadPurchaseData();
    return _purchaseData?['weekly_purchase_stats'] ?? {};
  }

  // Get weekly purchase chart data
  static Future<List<Map<String, dynamic>>> getWeeklyPurchaseChart() async {
    await loadPurchaseData();
    final List<dynamic> data = _purchaseData?['weekly_purchase_chart'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get weekly purchase data
  static Future<List<Map<String, dynamic>>> getWeeklyPurchaseData() async {
    await loadPurchaseData();
    final List<dynamic> data = _purchaseData?['weekly_purchase_data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get categories
  static Future<List<String>> getCategories() async {
    await loadPurchaseData();
    final List<dynamic> categories = _purchaseData?['categories'] ?? [];
    return categories.cast<String>();
  }

  // Delete purchase item (simulate)
  static Future<bool> deletePurchaseItem(int id) async {
    try {
      await loadPurchaseData();
      final List<dynamic> data = _purchaseData?['weekly_purchase_data'] ?? [];
      data.removeWhere((item) => item['id'] == id);
      return true;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }

  // Search and filter purchase data
  static Future<List<Map<String, dynamic>>> searchPurchaseData({
    String query = '',
    String category = 'Semua Kategori',
  }) async {
    final allData = await getWeeklyPurchaseData();
    
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
        item['lokasi_stok'].toString().toLowerCase().contains(query.toLowerCase()) ||
        item['supplier'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    return filteredData;
  }
}