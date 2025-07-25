// lib/widgets/admin_sales_page_widget.dart
import 'package:flutter/material.dart';
import '../services/outgoing_items_service.dart';
import 'dart:async';

class AdminSalesPageWidget extends StatefulWidget {
  const AdminSalesPageWidget({super.key});

  @override
  State<AdminSalesPageWidget> createState() => _AdminSalesPageWidgetState();
}

class _AdminSalesPageWidgetState extends State<AdminSalesPageWidget> {
  List<Map<String, dynamic>> orderData = [];
  List<Map<String, dynamic>> filteredOrderData = [];
  List<String> categories = ['Semua Kategori'];
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;
  String selectedCategory = 'Semua Kategori';
  String searchQuery = '';
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await OutgoingItemsService.getCategories();
      
      if (response['status'] == 'success') {
        final List<dynamic> categoryList = response['data'];
        if (mounted) {
          setState(() {
            categories = ['Semua Kategori', ...categoryList.cast<String>()];
          });
        }
      }
    } catch (e) {
      // Fallback categories for demo/testing
      if (mounted) {
        setState(() {
          categories = ['Semua Kategori', 'Elektronik', 'Peralatan', 'Makanan', 'Minuman'];
        });
      }
    }
  }

  Future<void> _loadSalesData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }


    try {
      Map<String, dynamic> response;
      
      // Use search API if there's a search query, otherwise use regular get items
      if (searchQuery.isNotEmpty) {
        response = await OutgoingItemsService.searchItems(
          query: searchQuery,
          kategori: selectedCategory != 'Semua Kategori' ? selectedCategory : null,
        );
      } else {
        response = await OutgoingItemsService.getOutgoingItems(
          perPage: 15,
          kategori: selectedCategory,
          search: null, // Don't use search parameter in regular API
          page: currentPage,
        );
      }

      if (response['status'] == 'success') {
        final List<dynamic> items = response['data'];
        
        if (mounted) {
          setState(() {
            orderData = items.cast<Map<String, dynamic>>();
            filteredOrderData = orderData;
            
            // Handle pagination - search API might not have pagination
            if (searchQuery.isNotEmpty) {
              // For search results, no pagination
              currentPage = 1;
              totalPages = 1;
            } else {
              // For regular API, use pagination data
              final pagination = response['pagination'];
              currentPage = pagination['current_page'];
              totalPages = pagination['last_page'];
            }
            
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load data');
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Fallback demo data for testing
      const fallbackItems = [
        {
          'id': 1,
          'nama_barang': 'Laptop ASUS ROG',
          'kategori_barang': 'Elektronik',
          'jumlah_barang': 2,
          'tanggal_keluar_barang': '2025-07-20',
          'tujuan_distribusi': 'Toko Komputer ABC',
        },
        {
          'id': 2,
          'nama_barang': 'Mouse Gaming Logitech',
          'kategori_barang': 'Elektronik',
          'jumlah_barang': 5,
          'tanggal_keluar_barang': '2025-07-19',
          'tujuan_distribusi': 'Gaming Store XYZ',
        },
        {
          'id': 3,
          'nama_barang': 'Mie Instan Indomie',
          'kategori_barang': 'Makanan',
          'jumlah_barang': 100,
          'tanggal_keluar_barang': '2025-07-18',
          'tujuan_distribusi': 'Toko Kelontong Berkah',
        },
      ];
      
      // Filter fallback data based on search query and category
      List<Map<String, dynamic>> filteredFallback = fallbackItems;
      
      if (searchQuery.isNotEmpty) {
        filteredFallback = fallbackItems.where((item) {
          final nama = item['nama_barang'].toString().toLowerCase();
          final tujuan = item['tujuan_distribusi'].toString().toLowerCase();
          final query = searchQuery.toLowerCase();
          return nama.contains(query) || tujuan.contains(query);
        }).toList();
      }
      
      if (selectedCategory != 'Semua Kategori') {
        filteredFallback = filteredFallback.where((item) {
          return item['kategori_barang'] == selectedCategory;
        }).toList();
      }
      
      if (mounted) {
        setState(() {
          orderData = filteredFallback;
          filteredOrderData = filteredFallback;
          currentPage = 1;
          totalPages = 1;
          isLoading = false;
        });
      }
      
      if (mounted) {
        String message = searchQuery.isNotEmpty 
            ? 'Menggunakan data demo untuk pencarian: "$searchQuery"'
            : 'Menggunakan data demo: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleOrderSearch(String query, String category) async {
    // Cancel previous search timer
    _searchTimer?.cancel();
    
    if (mounted) {
      setState(() {
        selectedCategory = category;
        currentPage = 1; // Reset to first page when searching
      });
    }
    
    // If query is empty, load immediately
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          searchQuery = query;
        });
      }
      await _loadSalesData();
      return;
    }
    
    // Debounce search for 500ms
    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      if (mounted) {
        setState(() {
          searchQuery = query;
        });
        await _loadSalesData();
      }
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
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
      final response = await OutgoingItemsService.getItemDetail(id);
      
      if (mounted) Navigator.of(context).pop();
      
      if (response['status'] == 'success' && response['data'] != null) {
        final itemData = response['data'];
        _showDetailDialog(itemData);
      } else {
        throw Exception('Data tidak ditemukan');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      
      // Show fallback detail dialog with current data
      final currentItem = orderData.firstWhere(
        (item) => item['id'] == id,
        orElse: () => {},
      );
      
      if (currentItem.isNotEmpty) {
        _showDetailDialog(currentItem);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat detail: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showDetailDialog(Map<String, dynamic> itemData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Detail Barang Keluar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('ID', itemData['id']?.toString() ?? '-'),
                _buildDetailItem('Nama Barang', itemData['nama_barang']?.toString() ?? '-'),
                _buildDetailItem('Kategori', itemData['kategori_barang']?.toString() ?? '-'),
                _buildDetailItem('Jumlah', '${itemData['jumlah_barang']?.toString() ?? '0'} pcs'),
                _buildDetailItem('Tanggal Keluar', _formatDate(itemData['tanggal_keluar_barang']?.toString() ?? '')),
                _buildDetailItem('Tujuan Distribusi', itemData['tujuan_distribusi']?.toString() ?? '-'),
                
                // Show photo if available
                if (itemData['foto_barang'] != null && itemData['foto_barang'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Foto Barang:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            itemData['foto_barang'].toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, 
                                           color: Colors.grey, size: 48),
                                      Text('Gagal memuat gambar'),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
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
                    'Kelola pesanan barang keluar dan distribusi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Order Table
            _buildOrderTable(),
            
            // Bottom spacing for better UX
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTable() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tabel Barang Keluar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Search Bar untuk Order
            Column(
              children: [
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama barang, tujuan distribusi...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) async {
                    await _handleOrderSearch(value, selectedCategory);
                  },
                ),
                const SizedBox(height: 12),
                // Category dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Pilih Kategori',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      await _handleOrderSearch(searchQuery, value);
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Order Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tanggal Keluar', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tujuan Distribusi', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredOrderData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(
                          Text(
                            item['nama_barang'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(item['kategori_barang']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item['kategori_barang'] ?? '',
                              style: TextStyle(
                                color: _getCategoryColor(item['kategori_barang']),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text('${item['jumlah_barang']} pcs')),
                        DataCell(
                          Text(
                            _formatDate(item['tanggal_keluar_barang'] ?? ''),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            item['tujuan_distribusi'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                            onPressed: () => _handleViewDetail(item['id']),
                            tooltip: 'Lihat Detail',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // Pagination Controls for Orders
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: currentPage > 1 ? () async {
                        if (mounted) {
                          setState(() {
                            currentPage--;
                          });
                          await _loadSalesData();
                        }
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
                        if (mounted) {
                          setState(() {
                            currentPage++;
                          });
                          await _loadSalesData();
                        }
                      } : null,
                      icon: const Icon(Icons.arrow_forward_ios),
                      tooltip: 'Halaman Selanjutnya',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'elektronik':
        return Colors.blue;
      case 'peralatan':
        return Colors.green;
      case 'makanan':
        return Colors.orange;
      case 'minuman':
        return Colors.purple;
      case 'pakaian':
        return Colors.pink;
      case 'obat-obatan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return '-';
      
      final DateTime date = DateTime.parse(dateString);
      const List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}