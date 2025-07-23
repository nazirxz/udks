// lib/widgets/manager_purchase_page_widget.dart
import 'package:flutter/material.dart';
import '../services/incoming_items_api_service.dart';
import 'manager_purchase_table_widget.dart';
import 'manager_purchase_chart_widget.dart';

class ManagerPurchasePageWidget extends StatefulWidget {
  const ManagerPurchasePageWidget({Key? key}) : super(key: key);

  @override
  _ManagerPurchasePageWidgetState createState() => _ManagerPurchasePageWidgetState();
}

class _ManagerPurchasePageWidgetState extends State<ManagerPurchasePageWidget> {
  List<dynamic> incomingItems = [];
  List<dynamic> filteredIncomingItems = [];
  Map<String, dynamic> weeklyStats = {};
  List<String> categories = ['Semua Kategori'];
  List<String> stockFilters = ['Semua Stok', 'available', 'empty', 'low_stock'];
  
  bool isLoading = true;
  String errorMessage = '';
  String selectedCategory = 'Semua Kategori';
  String selectedStockFilter = 'Semua Stok';
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

  Future<void> _loadData() async {
    await _loadIncomingItems();
  }

  Future<void> _loadIncomingItems() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Load incoming items
      final itemsResult = await IncomingItemsApiService.getIncomingItems(
        page: currentPage,
        perPage: itemsPerPage,
      );
      
      // Load categories
      final categoriesResult = await IncomingItemsApiService.getCategories();
      
      // Load weekly stats
      final statsResult = await IncomingItemsApiService.getWeeklyIncomingStats();

      setState(() {
        if (itemsResult['success']) {
          incomingItems = itemsResult['data'] ?? [];
          filteredIncomingItems = List.from(incomingItems);
          
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
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleSearch(String query, String category) async {
    setState(() {
      isLoading = true;
      searchQuery = query;
      selectedCategory = category;
    });

    try {
      final result = await IncomingItemsApiService.getIncomingItems(
        page: currentPage,
        perPage: itemsPerPage,
        search: query.isNotEmpty ? query : null,
        kategori: category != 'Semua Kategori' ? category : null,
        stockFilter: selectedStockFilter != 'Semua Stok' ? selectedStockFilter : null,
      );

      if (result['success']) {
        setState(() {
          incomingItems = result['data'] ?? [];
          filteredIncomingItems = List.from(incomingItems);
          
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
      setState(() {
        errorMessage = 'Error searching data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleView(int id) async {
    // View functionality is handled directly by the table widget
    // This callback is required by the interface but not used
    // The table widget shows the detail dialog directly
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
        final incomingQuantity = chartDataMap['incoming_quantity'];
        
        if (labels is List && incomingQuantity is List && labels.length == incomingQuantity.length) {
          for (int i = 0; i < labels.length; i++) {
            chartData.add({
              'day': labels[i],
              'day_short': _getDayShort(labels[i]),
              'total_items': incomingQuantity[i] ?? 0,
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat data pembelian dari server...',
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

    // Show error state if there's an error message
    if (errorMessage.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat data',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.blue,
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
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
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
                        Icons.shopping_bag,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Data Pembelian',
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
                    'Kelola dan pantau data pembelian mingguan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Purchase Table
            ManagerPurchaseTableWidget(
              purchaseData: filteredIncomingItems.cast<Map<String, dynamic>>(),
              categories: categories,
              onView: _handleView,
              onSearch: _handleSearch,
            ),
            
            const SizedBox(height: 20),
            
            // Purchase Chart - Convert weeklyStats to list format for chart
            ManagerPurchaseChartWidget(
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