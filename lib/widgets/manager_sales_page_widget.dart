// lib/widgets/manager_sales_page_widget.dart
import 'package:flutter/material.dart';
import '../services/outgoing_items_service.dart';
import 'manager_sales_table_widget.dart';
import 'manager_sales_chart_widget.dart';

class ManagerSalesPageWidget extends StatefulWidget {
  const ManagerSalesPageWidget({Key? key}) : super(key: key);

  @override
  _ManagerSalesPageWidgetState createState() => _ManagerSalesPageWidgetState();
}

class _ManagerSalesPageWidgetState extends State<ManagerSalesPageWidget> {
  List<Map<String, dynamic>> salesData = [];
  List<Map<String, dynamic>> filteredSalesData = [];
  List<Map<String, dynamic>> chartData = [];
  List<String> categories = [];
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;
  String selectedCategory = 'Semua Kategori';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get outgoing items data
      final response = await OutgoingItemsService.getOutgoingItems(
        page: currentPage,
        kategori: selectedCategory != 'Semua Kategori' ? selectedCategory : null,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );

      // Get categories
      final categoriesResponse = await OutgoingItemsService.getCategories();
      
      // Get weekly stats for chart data
      final stats = await OutgoingItemsService.getWeeklySalesStats();
      print('=== WEEKLY STATS API CALL ===');
      print('Called endpoint: outgoingItemsWeeklyStats');
      print('Raw response: $stats');

      setState(() {
        salesData = List<Map<String, dynamic>>.from(response['data'] ?? []);
        filteredSalesData = salesData;
        
        // Extract categories from response
        final List<dynamic> categoriesData = categoriesResponse['data'] ?? [];
        categories = ['Semua Kategori'] + categoriesData.cast<String>();
        
        totalPages = int.tryParse(response['total_pages'].toString()) ?? 1;
        
        // Convert stats to chart data format
        chartData = _convertStatsToChartData(stats);
        
        isLoading = false;
      });
    } catch (e) {
      print('Error loading sales data: $e');
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Convert weekly stats to chart data format
  List<Map<String, dynamic>> _convertStatsToChartData(Map<String, dynamic> stats) {
    try {
      print('Converting stats to chart data: $stats');
      
      if (stats['data'] != null && stats['data'] is Map) {
        final Map<String, dynamic> apiData = stats['data'];
        
        // Get chart_data from API response (new format)
        final Map<String, dynamic> chartDataFromApi = apiData['chart_data'] ?? {};
        final List<dynamic> labels = chartDataFromApi['labels'] ?? [];
        final List<dynamic> salesQuantity = chartDataFromApi['sales_quantity'] ?? [];
        
        print('Labels: $labels');
        print('Sales quantity: $salesQuantity');
        
        List<Map<String, dynamic>> chartData = [];
        
        // Convert arrays to chart format expected by ManagerSalesChartWidget
        for (int i = 0; i < labels.length && i < salesQuantity.length; i++) {
          final day = labels[i].toString();
          final quantityValue = salesQuantity[i];
          
          // Convert string numbers to int
          int quantityInt = 0;
          if (quantityValue != null) {
            if (quantityValue is String) {
              quantityInt = int.tryParse(quantityValue) ?? 0;
            } else if (quantityValue is num) {
              quantityInt = quantityValue.toInt();
            }
          }
          
          // Create day_short abbreviation
          String dayShort = day;
          switch (day.toLowerCase()) {
            case 'senin':
              dayShort = 'Sen';
              break;
            case 'selasa':
              dayShort = 'Sel';
              break;
            case 'rabu':
              dayShort = 'Rab';
              break;
            case 'kamis':
              dayShort = 'Kam';
              break;
            case 'jumat':
              dayShort = 'Jum';
              break;
            case 'sabtu':
              dayShort = 'Sab';
              break;
            case 'minggu':
              dayShort = 'Min';
              break;
          }
          
          chartData.add({
            'day': day,
            'day_short': dayShort,
            'total_items': quantityInt,
          });
          
          print('Day $i: {day: $day, day_short: $dayShort, total_items: $quantityInt}');
        }
        
        print('Final chart data: $chartData');
        print('Chart data length: ${chartData.length}');
        return chartData;
      }
    } catch (e) {
      print('Error converting stats to chart data: $e');
    }
    
    // Return empty data if conversion fails
    print('Returning empty chart data');
    return [];
  }

  Future<void> _handleSearch(String query, String category) async {
    try {
      setState(() {
        searchQuery = query;
        selectedCategory = category;
        currentPage = 1; // Reset to first page on search
      });
      
      await _loadSalesData();
    } catch (e) {
      print('Error searching data: $e');
    }
  }

  Future<void> _handleDelete(int id) async {
    // For manager role, delete functionality is not available
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitur hapus tidak tersedia untuk manager'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat data penjualan...',
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
      onRefresh: _loadSalesData,
      color: Colors.purple,
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
                  colors: [Colors.purple.shade400, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
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
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Data Penjualan',
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
                    'Kelola dan pantau data penjualan mingguan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Sales Table
            ManagerSalesTableWidget(
              salesData: filteredSalesData,
              categories: categories,
              onDelete: _handleDelete,
              onSearch: _handleSearch,
            ),
            
            // Pagination Controls
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: currentPage > 1 ? () async {
                        setState(() {
                          currentPage--;
                        });
                        await _loadSalesData();
                      } : null,
                      icon: const Icon(Icons.arrow_back_ios),
                      tooltip: 'Halaman Sebelumnya',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Halaman $currentPage dari $totalPages',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      onPressed: currentPage < totalPages ? () async {
                        setState(() {
                          currentPage++;
                        });
                        await _loadSalesData();
                      } : null,
                      icon: const Icon(Icons.arrow_forward_ios),
                      tooltip: 'Halaman Selanjutnya',
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Sales Chart
            ManagerSalesChartWidget(chartData: chartData),
            
            // Bottom spacing for better UX
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}