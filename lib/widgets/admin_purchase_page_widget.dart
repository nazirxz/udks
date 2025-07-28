// lib/widgets/admin_purchase_page_widget.dart
import 'package:flutter/material.dart';
import '../services/incoming_items_api_service.dart';
import 'admin_purchase_table_widget.dart';
import 'admin_purchase_chart_widget.dart';

class AdminPurchasePageWidget extends StatefulWidget {
  const AdminPurchasePageWidget({Key? key}) : super(key: key);

  @override
  _AdminPurchasePageWidgetState createState() => _AdminPurchasePageWidgetState();
}

class _AdminPurchasePageWidgetState extends State<AdminPurchasePageWidget> {
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
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

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

      if (mounted) {
        setState(() {
          if (itemsResult['success']) {
            incomingItems = itemsResult['data'] ?? [];
            filteredIncomingItems = List.from(incomingItems);
            
            final pagination = itemsResult['pagination'] ?? {};
            currentPage = int.tryParse(pagination['current_page'].toString()) ?? 1;
            totalPages = int.tryParse(pagination['last_page'].toString()) ?? 1;
          } else {
            errorMessage = itemsResult['message'];
          }
          if (categoriesResult['success']) {
            final apiCategories = List<String>.from(categoriesResult['data']);
            categories = ['Semua Kategori', ...apiCategories];
          }

          if (statsResult['success']) {
            weeklyStats = statsResult['data'] ?? {};
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading data: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSearch(String query, String category) async {
    if (mounted) {
      setState(() {
        searchQuery = query;
        selectedCategory = category;
        isLoading = true;
      });
    }

    try {
      if (query.isEmpty && category == 'Semua Kategori') {
        // Reset to original data
        await _loadIncomingItems();
      } else {
        // Search with API - handle both query and category filtering
        Map<String, dynamic> result;
        
        if (query.isNotEmpty) {
          // Use search API when there's a query
          result = await IncomingItemsApiService.searchIncomingItems(
            query: query,
            kategori: category == 'Semua Kategori' ? null : category,
            stockFilter: selectedStockFilter == 'Semua Stok' ? null : selectedStockFilter,
          );
        } else if (category != 'Semua Kategori') {
          // Use category filter API when only category is selected
          result = await IncomingItemsApiService.getIncomingItemsByCategory(
            category,
            stockFilter: selectedStockFilter == 'Semua Stok' ? null : selectedStockFilter,
            perPage: itemsPerPage,
            page: currentPage,
          );
        } else {
          // Fallback to general API with filters
          result = await IncomingItemsApiService.getIncomingItems(
            page: currentPage,
            perPage: itemsPerPage,
            kategori: category == 'Semua Kategori' ? null : category,
            search: query.isNotEmpty ? query : null,
            stockFilter: selectedStockFilter == 'Semua Stok' ? null : selectedStockFilter,
          );
        }

        if (mounted) {
          setState(() {
            if (result['success']) {
              filteredIncomingItems = result['data'] ?? [];
              // Update pagination if available
              final pagination = result['pagination'] ?? {};
              currentPage = int.tryParse(pagination['current_page'].toString()) ?? currentPage;
              totalPages = int.tryParse(pagination['last_page'].toString()) ?? totalPages;
            } else {
              errorMessage = result['message'] ?? 'Pencarian gagal';
              filteredIncomingItems = [];
            }
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error searching: $e';
          filteredIncomingItems = [];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleViewDetail(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await IncomingItemsApiService.getIncomingItemDetail(id);
      
      if (mounted) Navigator.of(context).pop();
      
      if (result['success']) {
        final item = result['data'];
        _showItemDetailDialog(item);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat detail: ${result['message']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showItemDetailDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Detail Barang Masuk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item['foto_barang'] != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(item['foto_barang']),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) => const Icon(Icons.error),
                    ),
                  ),
                ),
              _buildDetailRow('Nama Barang', item['nama_barang']?.toString() ?? 'N/A'),
              _buildDetailRow('Kategori', item['kategori_barang']?.toString() ?? 'N/A'),
              _buildDetailRow('Producer', item['producer_name']?.toString() ?? 'N/A'),
              _buildDetailRow('Jumlah', '${item['jumlah_barang']?.toString() ?? '0'} unit'),
              _buildDetailRow('Harga Jual', 'Rp ${_formatCurrency(item['harga_jual'] ?? 0)}'),
              _buildDetailRow('Tanggal Masuk', item['tanggal_masuk_barang']?.toString() ?? 'N/A'),
              _buildDetailRow('Lokasi Rak', item['lokasi_rak_barang']?.toString() ?? 'N/A'),
              _buildDetailRow('Metode Bayar', item['metode_bayar']?.toString() ?? 'N/A'),
              _buildDetailRow('Status Stok', item['stock_status']?.toString() ?? 'N/A'),
              _buildDetailRow('Estimated Value', 'Rp ${_formatCurrency(item['estimated_value'] ?? 0)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final value = amount is String ? double.tryParse(amount) ?? 0.0 : amount.toDouble();
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  List<Map<String, dynamic>> _convertWeeklyStatsToChartData() {
    if (weeklyStats.isEmpty || weeklyStats['chart_data'] == null) {
      return [];
    }

    final chartData = weeklyStats['chart_data'];
    final labels = List<String>.from(chartData['labels'] ?? []);
    final quantities = List<int>.from(chartData['incoming_quantity'] ?? []);

    final dayShortMap = {
      'Senin': 'Sen',
      'Selasa': 'Sel',
      'Rabu': 'Rab',
      'Kamis': 'Kam',
      'Jumat': 'Jum',
      'Sabtu': 'Sab',
      'Minggu': 'Min',
    };

    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < labels.length && i < quantities.length; i++) {
      result.add({
        'day_short': dayShortMap[labels[i]] ?? labels[i],
        'total_items': quantities[i],
      });
    }

    return result;
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat data pembelian...',
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
      color: Colors.red,
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
                  colors: [Colors.red.shade400, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
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
            
            // Error State
            if (errorMessage.isNotEmpty && !isLoading)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // Purchase Table
            AdminPurchaseTableWidget(
              purchaseData: filteredIncomingItems.map((item) => Map<String, dynamic>.from(item)).toList(),
              categories: categories,
              onView: _handleViewDetail,
              onSearch: _handleSearch,
            ),
            
            const SizedBox(height: 20),
            
            // Purchase Chart (using weekly stats)
            AdminPurchaseChartWidget(chartData: _convertWeeklyStatsToChartData()),
            
            // Bottom spacing for better UX
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}