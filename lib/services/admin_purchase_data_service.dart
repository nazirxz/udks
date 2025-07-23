// lib/services/admin_purchase_data_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class AdminPurchaseDataService {
  static Map<String, dynamic>? _purchaseData;

  // Load purchase data dari JSON file
  static Future<void> loadPurchaseData() async {
    if (_purchaseData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/data/admin_purchase_data.json');
      _purchaseData = json.decode(response);
    } catch (e) {
      print('Error loading admin purchase data: $e');
      _purchaseData = {
        'weekly_purchase_data': [
          {
            'id': 1,
            'nama_barang': 'Minyak Goreng Tropical 2L',
            'kategori': 'Minyak Goreng',
            'tanggal_masuk': '2024-12-25',
            'jumlah': 100,
            'supplier': 'PT. Tropical Indonesia',
            'harga_satuan': 25000,
            'total_harga': 2500000,
            'lokasi_stok': 'Gudang A-1'
          },
          {
            'id': 2,
            'nama_barang': 'Beras Premium 5kg',
            'kategori': 'Beras',
            'tanggal_masuk': '2024-12-24',
            'jumlah': 80,
            'supplier': 'CV. Pangan Makmur',
            'harga_satuan': 60000,
            'total_harga': 4800000,
            'lokasi_stok': 'Gudang B-2'
          },
          {
            'id': 3,
            'nama_barang': 'Gula Pasir 1kg',
            'kategori': 'Gula',
            'tanggal_masuk': '2024-12-23',
            'jumlah': 150,
            'supplier': 'PT. Gula Nusantara',
            'harga_satuan': 15000,
            'total_harga': 2250000,
            'lokasi_stok': 'Gudang A-3'
          },
          {
            'id': 4,
            'nama_barang': 'Tepung Terigu 1kg',
            'kategori': 'Tepung',
            'tanggal_masuk': '2024-12-22',
            'jumlah': 120,
            'supplier': 'PT. Bogasari',
            'harga_satuan': 15000,
            'total_harga': 1800000,
            'lokasi_stok': 'Gudang C-1'
          },
          {
            'id': 5,
            'nama_barang': 'Mie Instan Kemasan',
            'kategori': 'Mie Instan',
            'tanggal_masuk': '2024-12-21',
            'jumlah': 300,
            'supplier': 'PT. Indofood Sukses',
            'harga_satuan': 4000,
            'total_harga': 1200000,
            'lokasi_stok': 'Gudang D-2'
          }
        ],
        'weekly_purchase_chart': [
          {'day_short': 'Sen', 'total_items': 45},
          {'day_short': 'Sel', 'total_items': 62},
          {'day_short': 'Rab', 'total_items': 38},
          {'day_short': 'Kam', 'total_items': 75},
          {'day_short': 'Jum', 'total_items': 89},
          {'day_short': 'Sab', 'total_items': 56},
          {'day_short': 'Min', 'total_items': 42}
        ],
        'categories': ['Semua Kategori', 'Minyak Goreng', 'Beras', 'Gula', 'Tepung', 'Mie Instan']
      };
    }
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