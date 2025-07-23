// lib/services/admin_return_data_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class AdminReturnDataService {
  static Map<String, dynamic>? _returnData;

  // Load return data dari JSON file
  static Future<void> loadReturnData() async {
    if (_returnData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/data/admin_return_data.json');
      _returnData = json.decode(response);
    } catch (e) {
      print('Error loading admin return data: $e');
      _returnData = {
        'weekly_return_data': [
          {
            'id': 1,
            'nama_barang': 'Minyak Goreng Tropical 2L',
            'kategori': 'Minyak Goreng',
            'tanggal_return': '2024-12-25',
            'jumlah': 5,
            'customer': 'Toko Berkah',
            'alasan_return': 'Kemasan Rusak',
            'status': 'Approved',
            'nilai_return': 125000
          },
          {
            'id': 2,
            'nama_barang': 'Beras Premium 5kg',
            'kategori': 'Beras',
            'tanggal_return': '2024-12-24',
            'jumlah': 3,
            'customer': 'Warung Ibu Sari',
            'alasan_return': 'Kualitas Tidak Sesuai',
            'status': 'Pending',
            'nilai_return': 180000
          },
          {
            'id': 3,
            'nama_barang': 'Gula Pasir 1kg',
            'kategori': 'Gula',
            'tanggal_return': '2024-12-23',
            'jumlah': 8,
            'customer': 'PT. Maju Jaya',
            'alasan_return': 'Salah Kirim',
            'status': 'Approved',
            'nilai_return': 120000
          },
          {
            'id': 4,
            'nama_barang': 'Tepung Terigu 1kg',
            'kategori': 'Tepung',
            'tanggal_return': '2024-12-22',
            'jumlah': 12,
            'customer': 'Minimarket ABC',
            'alasan_return': 'Expired',
            'status': 'Rejected',
            'nilai_return': 180000
          },
          {
            'id': 5,
            'nama_barang': 'Mie Instan Kemasan',
            'kategori': 'Mie Instan',
            'tanggal_return': '2024-12-21',
            'jumlah': 20,
            'customer': 'CV. Sumber Rejeki',
            'alasan_return': 'Kemasan Rusak',
            'status': 'Approved',
            'nilai_return': 80000
          }
        ],
        'weekly_return_chart': [
          {'day_short': 'Sen', 'total_items': 8},
          {'day_short': 'Sel', 'total_items': 12},
          {'day_short': 'Rab', 'total_items': 6},
          {'day_short': 'Kam', 'total_items': 15},
          {'day_short': 'Jum', 'total_items': 18},
          {'day_short': 'Sab', 'total_items': 10},
          {'day_short': 'Min', 'total_items': 7}
        ],
        'categories': ['Semua Kategori', 'Minyak Goreng', 'Beras', 'Gula', 'Tepung', 'Mie Instan'],
        'return_reasons': ['Semua Alasan', 'Kemasan Rusak', 'Kualitas Tidak Sesuai', 'Salah Kirim', 'Expired', 'Cacat Produk'],
        'return_status': ['Semua Status', 'Pending', 'Approved', 'Rejected']
      };
    }
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