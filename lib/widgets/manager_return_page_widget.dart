// lib/widgets/manager_return_page_widget.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/return_items_api_service.dart';
import '../models/return_item.dart';
import 'manager_return_table_widget.dart';
import 'manager_return_chart_widget.dart';

class ManagerReturnPageWidget extends StatefulWidget {
  const ManagerReturnPageWidget({Key? key}) : super(key: key);

  @override
  _ManagerReturnPageWidgetState createState() => _ManagerReturnPageWidgetState();
}

class _ManagerReturnPageWidgetState extends State<ManagerReturnPageWidget> {
  List<dynamic> returnItems = [];
  List<dynamic> filteredReturnItems = [];
  Map<String, dynamic> weeklyStats = {};
  List<String> categories = ['Semua Kategori'];
  List<String> returnReasons = ['Semua Alasan'];
  List<String> returnStatus = ['Semua Status'];
  
  bool isLoading = true;
  String errorMessage = '';
  String selectedCategory = 'Semua Kategori';
  String selectedReason = 'Semua Alasan';
  String selectedStatus = 'Semua Status';
  String searchQuery = '';
  
  // Pagination
  int currentPage = 1;
  int totalPages = 1;
  int itemsPerPage = 15;
  
  // Timer for auto-refresh
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh data every 2 minutes for realtime updates
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted && !isLoading) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    await _loadReturnItems();
  }

  Future<void> _loadReturnItems() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Load return data using the same method as admin (more realtime)
      final returnItemsResult = await ReturnItemsApiService.getReturnHistory(perPage: itemsPerPage);
      
      // Load weekly stats
      Map<String, dynamic> statsResult;
      try {
        statsResult = await ReturnItemsApiService.getWeeklyReturnStats();
      } catch (e) {
        statsResult = {'success': false, 'message': 'Weekly stats not available'};
      }
      
      // Load categories
      Map<String, dynamic> categoriesResult;
      try {
        categoriesResult = await ReturnItemsApiService.getCategories();
      } catch (e) {
        categoriesResult = {'success': false, 'message': 'Categories not available'};
      }

      if (!returnItemsResult['success']) {
        throw Exception(returnItemsResult['message'] ?? 'Failed to fetch return items');
      }

      // Process return items data (same as admin)
      List<dynamic> processedData = [];
      final returnItemsData = returnItemsResult['data'] as List;
      
      print('DEBUG MANAGER: Return items raw data length: ${returnItemsData.length}');
      
      for (final item in returnItemsData) {
        // Handle both ReturnItem objects and Map objects
        if (item is Map<String, dynamic>) {
          print('DEBUG MANAGER: Processing Map item: $item');
          final processedItem = {
            'id': item['id'] ?? 0,
            'nama_barang': item['product_name'] ?? item['nama_barang'] ?? '',
            'kategori_barang': item['category'] ?? item['kategori_barang'] ?? '',
            'jumlah_barang': item['quantity'] ?? item['jumlah_barang'] ?? 0,
            'nama_produsen': item['producer_name'] ?? item['nama_produsen'] ?? '',
            'alasan_pengembalian': item['reason'] ?? item['alasan_pengembalian'] ?? '',
            'tanggal_pengembalian': item['return_date'] ?? item['tanggal_pengembalian'] ?? '',
            'waktu_pengembalian': item['return_time'] ?? item['waktu_pengembalian'] ?? '',
            'status_pengembalian': item['status'] ?? item['status_pengembalian'] ?? '',
            'reason_category': item['reason_category'] ?? '',
          };
          print('DEBUG MANAGER: Processed item quantity: ${processedItem['jumlah_barang']}');
          processedData.add(processedItem);
        } else {
          // Handle ReturnItem objects
          final returnItem = item as dynamic;
          processedData.add({
            'id': returnItem.id ?? 0,
            'nama_barang': returnItem.namaBarang ?? '',
            'kategori_barang': returnItem.kategoriBarang ?? '',
            'jumlah_barang': returnItem.jumlahBarang ?? 0,
            'nama_produsen': returnItem.namaProdusen ?? '',
            'alasan_pengembalian': returnItem.alasanPengembalian ?? '',
            'tanggal_pengembalian': returnItem.formattedDate ?? '',
            'waktu_pengembalian': returnItem.formattedDate ?? '',
            'status_pengembalian': returnItem.statusText ?? '',
            'reason_category': '',
          });
        }
      }

      setState(() {
        returnItems = processedData;
        filteredReturnItems = List.from(returnItems);
        
        // Handle categories
        if (categoriesResult['success']) {
          final apiCategories = List<String>.from(categoriesResult['data'] ?? []);
          categories = ['Semua Kategori', ...apiCategories];
          
          // Extract unique return reasons from the data
          Set<String> reasonSet = returnItems
              .map((item) => item['alasan_pengembalian']?.toString() ?? '')
              .where((reason) => reason.isNotEmpty)
              .toSet();
          returnReasons = ['Semua Alasan', ...reasonSet.toList()];
          
          // Extract unique status from the data
          Set<String> statusSet = returnItems
              .map((item) => item['status_pengembalian']?.toString() ?? '')
              .where((status) => status.isNotEmpty)
              .toSet();
          returnStatus = ['Semua Status', ...statusSet.toList()];
        }

        // Handle weekly stats
        if (statsResult['success']) {
          weeklyStats = statsResult['data'] ?? {};
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
      print('Error in manager _loadReturnItems: $e');
    }
  }

  Future<void> _handleSearch(String query, String category, String reason, String status) async {
    setState(() {
      searchQuery = query;
      selectedCategory = category;
      selectedReason = reason;
      selectedStatus = status;
    });

    try {
      if (query.isEmpty && category == 'Semua Kategori' && reason == 'Semua Alasan' && status == 'Semua Status') {
        // No filters - show all data
        setState(() {
          filteredReturnItems = List.from(returnItems);
        });
        return;
      }

      // Use API search if there's a search query (same as admin)
      if (query.isNotEmpty) {
        final searchResult = await ReturnItemsApiService.searchReturnItems(
          query: query,
          kategori: category != 'Semua Kategori' ? category : null,
          reasonCategory: reason != 'Semua Alasan' ? reason : null,
        );

        if (searchResult['success']) {
          List<dynamic> processedSearchData = [];
          final searchData = searchResult['data'] as List;
          
          for (final item in searchData) {
            // Handle both ReturnItem objects and Map objects
            if (item is Map<String, dynamic>) {
              processedSearchData.add({
                'id': item['id'] ?? 0,
                'nama_barang': item['product_name'] ?? item['nama_barang'] ?? '',
                'kategori_barang': item['category'] ?? item['kategori_barang'] ?? '',
                'jumlah_barang': item['quantity'] ?? item['jumlah_barang'] ?? 0,
                'nama_produsen': item['producer_name'] ?? item['nama_produsen'] ?? '',
                'alasan_pengembalian': item['reason'] ?? item['alasan_pengembalian'] ?? '',
                'tanggal_pengembalian': item['return_date'] ?? item['tanggal_pengembalian'] ?? '',
                'waktu_pengembalian': item['return_time'] ?? item['waktu_pengembalian'] ?? '',
                'status_pengembalian': item['status'] ?? item['status_pengembalian'] ?? '',
                'reason_category': item['reason_category'] ?? '',
              });
            } else {
              // Handle ReturnItem objects
              final returnItem = item as dynamic;
              processedSearchData.add({
                'id': returnItem.id ?? 0,
                'nama_barang': returnItem.namaBarang ?? '',
                'kategori_barang': returnItem.kategoriBarang ?? '',
                'jumlah_barang': returnItem.jumlahBarang ?? 0,
                'nama_produsen': returnItem.namaProdusen ?? '',
                'alasan_pengembalian': returnItem.alasanPengembalian ?? '',
                'tanggal_pengembalian': returnItem.formattedDate ?? '',
                'waktu_pengembalian': returnItem.formattedDate ?? '',
                'status_pengembalian': returnItem.statusText ?? '',
                'reason_category': '',
              });
            }
          }

          setState(() {
            filteredReturnItems = processedSearchData;
          });
          return;
        }
      }

      // Local filtering if API search not applicable
      List<dynamic> filtered = List.from(returnItems);

      if (category != 'Semua Kategori') {
        filtered = filtered.where((item) => item['kategori_barang'] == category).toList();
      }

      if (reason != 'Semua Alasan') {
        filtered = filtered.where((item) => item['alasan_pengembalian'] == reason).toList();
      }

      if (status != 'Semua Status') {
        filtered = filtered.where((item) => item['status_pengembalian'] == status).toList();
      }

      setState(() {
        filteredReturnItems = filtered;
      });

    } catch (e) {
      setState(() {
        errorMessage = 'Error searching data: $e';
      });
      print('Error in manager _handleSearch: $e');
    }
  }

  Future<void> _handleView(int id) async {
    // For now, this is just a placeholder - the actual view functionality is handled in the widget itself
    // This callback is called from the ManagerReturnTableWidget when the view button is pressed
    // The actual view dialog is shown in the ManagerReturnTableWidget's _handleViewDetail method
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detail return sedang dimuat...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Helper method to convert weekly stats to chart data format
  List<Map<String, dynamic>> _convertStatsToChartData(Map<String, dynamic> stats) {
    if (stats.isEmpty) return [];
    
    List<Map<String, dynamic>> chartData = [];
    
    // Handle API response format with chart_data
    if (stats.containsKey('chart_data')) {
      final chartDataMap = stats['chart_data'];
      if (chartDataMap is Map<String, dynamic>) {
        final labels = chartDataMap['labels'];
        final returnQuantity = chartDataMap['return_quantity'];
        
        if (labels is List && returnQuantity is List && labels.length == returnQuantity.length) {
          for (int i = 0; i < labels.length; i++) {
            chartData.add({
              'day': labels[i],
              'day_short': _getDayShort(labels[i]),
              'total_items': returnQuantity[i] ?? 0,
            });
          }
        }
      }
    }
    // Fallback: if stats structure is different, create a simple chart data
    else if (stats.containsKey('weekly_data')) {
      final weeklyData = stats['weekly_data'];
      if (weeklyData is List) {
        for (var item in weeklyData) {
          if (item is Map<String, dynamic>) {
            chartData.add(item);
          }
        }
      }
    } else {
      // Create simple chart from direct stats
      stats.forEach((key, value) {
        if (value is num) {
          chartData.add({
            'name': key,
            'value': value,
          });
        }
      });
    }
    
    return chartData;
  }

  // Helper method to get short day names
  String _getDayShort(String fullDay) {
    switch (fullDay.toLowerCase()) {
      case 'senin':
        return 'Sen';
      case 'selasa':
        return 'Sel';
      case 'rabu':
        return 'Rab';
      case 'kamis':
        return 'Kam';
      case 'jumat':
        return 'Jum';
      case 'sabtu':
        return 'Sab';
      case 'minggu':
        return 'Min';
      default:
        return fullDay.length > 3 ? fullDay.substring(0, 3) : fullDay;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat data return...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.orange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_return,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Data Return',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Kelola dan pantau data return barang mingguan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Return Table
            ManagerReturnTableWidget(
              returnData: filteredReturnItems.cast<Map<String, dynamic>>(),
              categories: categories,
              returnReasons: returnReasons,
              returnStatus: returnStatus,
              onView: _handleView,
              onSearch: _handleSearch,
              onRefresh: _loadData, // Added refresh callback for realtime updates
            ),
            
            const SizedBox(height: 20),
            
            // Return Chart - Convert weeklyStats to list format for chart
            ManagerReturnChartWidget(
              chartData: _convertStatsToChartData(weeklyStats),
            ),
            
            // Bottom spacing for better UX
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}