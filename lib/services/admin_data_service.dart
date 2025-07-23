// lib/services/admin_data_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class AdminDataService {
  static Map<String, dynamic>? _adminData;

  // Load admin data dari JSON file
  static Future<void> loadAdminData() async {
    if (_adminData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/data/admin_data.json');
      _adminData = json.decode(response);
    } catch (e) {
      print('Error loading admin data: $e');
      _adminData = {
        'dashboard_stats': {
          'total_user': 25,
          'transaksi_hari_ini': 12,
          'pendapatan_hari_ini': 5750000,
          'pesanan_pending': 8
        },
        'weekly_chart_data': [
          {'day_short': 'Sen', 'penjualan': 15, 'pembelian': 8},
          {'day_short': 'Sel', 'penjualan': 22, 'pembelian': 12},
          {'day_short': 'Rab', 'penjualan': 18, 'pembelian': 10},
          {'day_short': 'Kam', 'penjualan': 25, 'pembelian': 15},
          {'day_short': 'Jum', 'penjualan': 30, 'pembelian': 18},
          {'day_short': 'Sab', 'penjualan': 28, 'pembelian': 16},
          {'day_short': 'Min', 'penjualan': 20, 'pembelian': 11}
        ],
        'recent_transactions': [
          {
            'type': 'penjualan',
            'customer': 'PT. Maju Jaya',
            'items': 15,
            'amount': 2500000
          },
          {
            'type': 'pembelian',
            'supplier': 'CV. Sumber Rejeki',
            'items': 8,
            'amount': 1200000
          },
          {
            'type': 'penjualan',
            'customer': 'Toko Berkah',
            'items': 22,
            'amount': 3200000
          }
        ],
        'inventory_alerts': [
          {
            'product_name': 'Minyak Goreng Tropical 2L',
            'current_stock': 5,
            'minimum_stock': 20,
            'status': 'critical'
          },
          {
            'product_name': 'Beras Premium 5kg',
            'current_stock': 15,
            'minimum_stock': 30,
            'status': 'low'
          }
        ]
      };
    }
  }

  // Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    await loadAdminData();
    return _adminData?['dashboard_stats'] ?? {};
  }

  // Get weekly chart data
  static Future<List<Map<String, dynamic>>> getWeeklyChartData() async {
    await loadAdminData();
    final List<dynamic> data = _adminData?['weekly_chart_data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get recent transactions
  static Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    await loadAdminData();
    final List<dynamic> data = _adminData?['recent_transactions'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get inventory alerts
  static Future<List<Map<String, dynamic>>> getInventoryAlerts() async {
    await loadAdminData();
    final List<dynamic> data = _adminData?['inventory_alerts'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}