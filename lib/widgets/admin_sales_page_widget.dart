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
  List<Map<String, dynamic>> salesData = [];
  List<Map<String, dynamic>> filteredSalesData = [];
  List<String> categories = ['Semua Kategori'];
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;
  String selectedCategory = 'Semua Kategori';
  String searchQuery = '';
  Timer? _searchTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSalesData();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    
    // If query is empty, search immediately
    if (value.isEmpty) {
      _handleOrderSearch(value, selectedCategory);
      return;
    }
    
    // Otherwise, debounce for 800ms
    _searchTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _handleOrderSearch(value, selectedCategory);
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      // Get categories from API
      final categoriesResponse = await OutgoingItemsService.getCategories();
      if (mounted) {
        final List<dynamic> categoriesData = categoriesResponse['data'] ?? [];
        setState(() {
          categories = ['Semua Kategori'] + categoriesData.cast<String>();
        });
      }
    } catch (e) {
      // Empty fallback categories
      if (mounted) {
        setState(() {
          categories = ['Semua Kategori'];
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
      // Get outgoing items data using the same service as manager
      final response = await OutgoingItemsService.getOutgoingItems(
        page: currentPage,
        kategori: selectedCategory != 'Semua Kategori' ? selectedCategory : null,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (response['data'] != null) {
        // Use the same simple format as manager
        final List<Map<String, dynamic>> salesMaps = List<Map<String, dynamic>>.from(response['data'] ?? []);
        
        if (mounted) {
          setState(() {
            salesData = salesMaps;
            filteredSalesData = salesMaps;
            totalPages = int.tryParse(response['total_pages'].toString()) ?? 1;
            isLoading = false;
          });
          
          // Update map markers with actual data
          _updateMapMarkers();
        }
      } else {
        throw Exception('Failed to load data - no data field in response');
      }
    } catch (e) {
      print('Error loading sales data: $e');
      if (mounted) {
        setState(() {
          salesData = [];
          filteredSalesData = [];
          currentPage = 1;
          totalPages = 1;
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleOrderSearch(String query, String category) async {
    // Update state immediately for UI responsiveness
    if (mounted) {
      setState(() {
        searchQuery = query;
        selectedCategory = category;
        currentPage = 1; // Reset to first page when searching
      });
    }
    
    // Load data directly without additional debouncing since _onSearchChanged already handles it
    await _loadSalesData();
  }

  void _updateMapMarkers() {
    // Remove map functionality for admin sales data
    // Admin sales focuses on sold items data, not location tracking
  }

  void _showItemDetail(Map<String, dynamic> item) {
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
                  'Detail Barang Terjual',
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
                _buildDetailItem('ID', item['id']?.toString() ?? '-'),
                _buildDetailItem('Nama Barang', item['nama_barang']?.toString() ?? '-'),
                _buildDetailItem('Kategori', item['kategori_barang']?.toString() ?? '-'),
                _buildDetailItem('Jumlah', '${item['jumlah_barang']?.toString() ?? '0'} pcs'),
                _buildDetailItem('Tanggal Keluar', _formatDate(item['tanggal_keluar_barang']?.toString() ?? '')),
                _buildDetailItem('Tujuan Distribusi', item['tujuan_distribusi']?.toString() ?? '-'),
                
                // Show photo if available
                if (item['foto_barang'] != null && item['foto_barang'].toString().isNotEmpty)
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
                            item['foto_barang'].toString(),
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
                    color: Colors.red.withValues(alpha: 0.3),
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
            
            // Map View removed - not needed for admin sales data
            
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
              'Tabel Barang Terjual',
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
                  controller: _searchController,
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
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                // Category dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Filter Kategori',
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
                      await _handleOrderSearch(_searchController.text, value);
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
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tanggal Keluar', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tujuan Distribusi', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredSalesData.isEmpty 
                    ? [
                        const DataRow(
                          cells: [
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(
                              Center(
                                child: Text(
                                  'Data kosong',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                          ],
                        )
                      ]
                    : filteredSalesData.asMap().entries.map((entry) {
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
                                  color: _getCategoryColor(item['kategori_barang']).withValues(alpha: 0.1),
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
                            DataCell(
                              Text(
                                _formatDate(item['tanggal_keluar_barang'] ?? ''),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${item['jumlah_barang']} pcs',
                                style: const TextStyle(fontWeight: FontWeight.w600),
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
                                onPressed: () => _showItemDetail(item),
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