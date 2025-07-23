// lib/widgets/manager_return_page_widget.dart
import 'package:flutter/material.dart';
import '../services/return_items_api_service.dart';
import 'manager_return_table_widget.dart';
import 'manager_return_chart_widget.dart';

class ManagerReturnPageWidget extends StatefulWidget {
  const ManagerReturnPageWidget({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations or timers here if needed
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadReturnItems();
  }

  Future<void> _loadReturnItems() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Load return items
      final itemsResult = await ReturnItemsApiService.getReturnItems(
        page: currentPage,
        perPage: itemsPerPage,
      );
      
      // Load categories
      final categoriesResult = await ReturnItemsApiService.getCategories();
      
      // Load weekly stats
      final statsResult = await ReturnItemsApiService.getWeeklyReturnStats();

      if (!mounted) return;

      setState(() {
        if (itemsResult['success']) {
          returnItems = itemsResult['data'] ?? [];
          filteredReturnItems = List.from(returnItems);
          
          final pagination = itemsResult['pagination'] ?? {};
          currentPage = pagination['current_page'] ?? 1;
          totalPages = pagination['last_page'] ?? 1;
          
        } else {
          errorMessage = itemsResult['message'];
        }

        if (categoriesResult['success']) {
          final apiCategories = List<String>.from(categoriesResult['data']);
          categories = ['Semua Kategori', ...apiCategories];
        }

        if (statsResult['success']) {
          weeklyStats = statsResult['data'] ?? {};
        } else {
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleSearch(String query, String category, String reason, String status) async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      searchQuery = query;
      selectedCategory = category;
      selectedReason = reason;
      selectedStatus = status;
    });

    try {
      final result = await ReturnItemsApiService.getReturnItems(
        page: currentPage,
        perPage: itemsPerPage,
        search: query.isNotEmpty ? query : null,
        kategori: category != 'Semua Kategori' ? category : null,
        // Note: API might not support reason and status filters, adjust as needed
      );

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          returnItems = result['data'] ?? [];
          filteredReturnItems = List.from(returnItems);
          
          final pagination = result['pagination'] ?? {};
          currentPage = pagination['current_page'] ?? 1;
          totalPages = pagination['last_page'] ?? 1;
        });
      } else {
        setState(() {
          errorMessage = result['message'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        errorMessage = 'Error searching data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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