// lib/services/manager_data_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class ManagerDataService {
  static Map<String, dynamic>? _managerData;

  // Load manager data dari JSON file
  static Future<void> loadManagerData() async {
    if (_managerData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/data/manager_data.json');
      _managerData = json.decode(response);
    } catch (e) {
      print('Error loading manager data: $e');
      _managerData = {};
    }
  }

  // Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    await loadManagerData();
    return _managerData?['dashboard_stats'] ?? {};
  }

  // Get weekly chart data
  static Future<List<Map<String, dynamic>>> getWeeklyChartData() async {
    await loadManagerData();
    final List<dynamic> data = _managerData?['weekly_chart_data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get recent transactions
  static Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    await loadManagerData();
    final List<dynamic> data = _managerData?['recent_transactions'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get inventory alerts
  static Future<List<Map<String, dynamic>>> getInventoryAlerts() async {
    await loadManagerData();
    final List<dynamic> data = _managerData?['inventory_alerts'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}