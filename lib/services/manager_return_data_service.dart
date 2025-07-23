// lib/services/manager_return_data_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class ManagerReturnDataService {
  static Map<String, dynamic>? _returnData;

  // Load return data dari JSON file
  static Future<void> loadReturnData() async {
    if (_returnData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/data/manager_return_data.json');
      _returnData = json.decode(response);
    } catch (e) {
      print('Error loading return data: $e');
      _returnData = {};
    }
  }

  // Get weekly return statistics
  static Future<Map<String, dynamic>> getWeeklyReturnStats() async {
    await loadReturnData();
    return _returnData?['weekly_return_stats'] ?? {};
  }

  // Get weekly return chart data
  static Future<List<Map<String, dynamic>>> getWeeklyReturnChart() async {
    await loadReturnData();
    final List<dynamic> data = _returnData?['weekly_return_chart'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get weekly return data
  static Future<List<Map<String, dynamic>>> getWeeklyReturnData() async {
    await loadReturnData();
    final List<dynamic> data = _returnData?['weekly_return_data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get categories
  static Future<List<String>> getCategories() async {
    await loadReturnData();
    final List<dynamic> categories = _returnData?['categories'] ?? [];
    return categories.cast<String>();
  }

  // Get return reasons
  static Future<List<String>> getReturnReasons() async {
    await loadReturnData();
    final List<dynamic> reasons = _returnData?['return_reasons'] ?? [];
    return reasons.cast<String>();
  }

  // Get return status
  static Future<List<String>> getReturnStatus() async {
    await loadReturnData();
    final List<dynamic> status = _returnData?['return_status'] ?? [];
    return status.cast<String>();
  }

  // Delete return item (simulate)
  static Future<bool> deleteReturnItem(int id) async {
    try {
      await loadReturnData();
      final List<dynamic> data = _returnData?['weekly_return_data'] ?? [];
      data.removeWhere((item) => item['id'] == id);
      return true;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }

  // Search and filter return data
  static Future<List<Map<String, dynamic>>> searchReturnData({
    String query = '',
    String category = 'Semua Kategori',
    String reason = 'Semua Alasan',
    String status = 'Semua Status',
  }) async {
    final allData = await getWeeklyReturnData();
    
    List<Map<String, dynamic>> filteredData = allData;

    // Filter by category
    if (category != 'Semua Kategori') {
      filteredData = filteredData.where((item) => 
        item['kategori'] == category
      ).toList();
    }

    // Filter by reason
    if (reason != 'Semua Alasan') {
      filteredData = filteredData.where((item) => 
        item['alasan_return'] == reason
      ).toList();
    }

    // Filter by status
    if (status != 'Semua Status') {
      filteredData = filteredData.where((item) => 
        item['status'] == status
      ).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filteredData = filteredData.where((item) => 
        item['nama_barang'].toString().toLowerCase().contains(query.toLowerCase()) ||
        item['kategori'].toString().toLowerCase().contains(query.toLowerCase()) ||
        item['customer'].toString().toLowerCase().contains(query.toLowerCase()) ||
        item['alasan_return'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    return filteredData;
  }
}