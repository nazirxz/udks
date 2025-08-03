// lib/widgets/admin_return_page_widget.dart
import 'package:flutter/material.dart';
import '../services/return_items_api_service.dart';

class AdminReturnPageWidget extends StatefulWidget {
  const AdminReturnPageWidget({super.key});

  @override
  State<AdminReturnPageWidget> createState() => _AdminReturnPageWidgetState();
}

class _AdminReturnPageWidgetState extends State<AdminReturnPageWidget> {
  List<Map<String, dynamic>> returnData = [];
  List<Map<String, dynamic>> filteredReturnData = [];
  List<Map<String, dynamic>> chartData = [];
  List<String> categories = [];
  List<String> returnReasons = [];
  List<String> returnStatus = [];
  bool isLoading = true;
  final Set<int> _expandedItems = <int>{};

  @override
  void initState() {
    super.initState();
    _loadReturnData();
  }

  Future<void> _loadReturnData() async {
    setState(() {
      isLoading = true;
    });

    try {
      
      // Load return data  
      final returnItemsResult = await ReturnItemsApiService.getReturnHistory(perPage: 20);
      
      // Load weekly stats (if available)
      Map<String, dynamic> statsResult;
      try {
        statsResult = await ReturnItemsApiService.getWeeklyReturnStats();
      } catch (e) {
        statsResult = {'success': false, 'message': 'Weekly stats not available'};
      }
      
      // Load categories (if available)
      Map<String, dynamic> categoriesResult;
      try {
        categoriesResult = await ReturnItemsApiService.getCategories();
      } catch (e) {
        categoriesResult = {'success': false, 'message': 'Categories not available'};
      }

      if (!returnItemsResult['success']) {
        throw Exception(returnItemsResult['message'] ?? 'Failed to fetch return items');
      }

      // Process return items data
      List<Map<String, dynamic>> processedData = [];
      final returnItemsData = returnItemsResult['data'] as List;
      
      print('DEBUG: Return items raw data length: ${returnItemsData.length}');
      
      for (final item in returnItemsData) {
        // Handle both ReturnItem objects and Map objects
        if (item is Map<String, dynamic>) {
          print('DEBUG: Processing Map item: $item');
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
          print('DEBUG: Processed item quantity: ${processedItem['jumlah_barang']}');
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

      // Process chart data
      List<Map<String, dynamic>> processedChartData = [];
      
      if (statsResult['success']) {
        final weeklyData = statsResult['data'];
        
        if (weeklyData != null && weeklyData['chart_data'] != null) {
          final chartData = weeklyData['chart_data'];
          final labels = chartData['labels'] as List? ?? [];
          // Try different possible field names for return quantity
          final returnQuantity = chartData['return_quantity'] as List? ?? 
                               chartData['incoming_quantity'] as List? ?? 
                               chartData['quantities'] as List? ?? [];
          
          // Ensure both lists have the same length, but limit to 7 days max
          final minLength = [labels.length, returnQuantity.length, 7].reduce((a, b) => a < b ? a : b);
          
          for (int i = 0; i < minLength; i++) {
            final dayShort = _getDayShort(labels[i].toString());
            final totalItems = (returnQuantity[i] ?? 0).toInt();
            processedChartData.add({
              'day_short': dayShort,
              'total_items': totalItems,
            });
          }
        }
      }
      
      // If no weekly data, create empty chart
      if (processedChartData.isEmpty) {
        processedChartData = [
          {'day_short': 'Sen', 'total_items': 0},
          {'day_short': 'Sel', 'total_items': 0},
          {'day_short': 'Rab', 'total_items': 0},
          {'day_short': 'Kam', 'total_items': 0},
          {'day_short': 'Jum', 'total_items': 0},
          {'day_short': 'Sab', 'total_items': 0},
          {'day_short': 'Min', 'total_items': 0}
        ];
      }

      // Process categories
      List<String> processedCategories = ['Semua Kategori'];
      if (categoriesResult['success']) {
        try {
          final categoryData = categoriesResult['data'] as List;
          for (final category in categoryData) {
            processedCategories.add(category.toString());
          }
        } catch (e) {
          // Use fallback categories if API categories fail
          processedCategories.addAll(['Elektronik', 'Peralatan', 'Makanan', 'Minuman']);
        }
      } else {
        // Use fallback categories if API call failed
        processedCategories.addAll(['Elektronik', 'Peralatan', 'Makanan', 'Minuman']);
      }

      setState(() {
        returnData = processedData;
        filteredReturnData = processedData;
        chartData = processedChartData;
        categories = processedCategories;
        returnReasons = ['Semua Alasan', 'Kemasan Rusak', 'Kualitas Tidak Sesuai', 'Salah Kirim', 'Expired', 'Cacat Produk'];
        returnStatus = ['Semua Status', 'Recent', 'Processed', 'Approved', 'Rejected', 'Completed'];
        isLoading = false;
      });

    } catch (e) {
      
      setState(() {
        isLoading = false;
        returnData = [];
        filteredReturnData = [];
        chartData = [
          {'day_short': 'Sen', 'total_items': 0},
          {'day_short': 'Sel', 'total_items': 0},
          {'day_short': 'Rab', 'total_items': 0},
          {'day_short': 'Kam', 'total_items': 0},
          {'day_short': 'Jum', 'total_items': 0},
          {'day_short': 'Sab', 'total_items': 0},
          {'day_short': 'Min', 'total_items': 0}
        ];
        categories = ['Semua Kategori'];
        returnReasons = ['Semua Alasan'];
        returnStatus = ['Semua Status'];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data return: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _loadReturnData,
            ),
          ),
        );
      }
    }
  }

  String _getDayShort(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
      case 'senin': 
        return 'Sen';
      case 'tuesday':
      case 'selasa': 
        return 'Sel';
      case 'wednesday':
      case 'rabu': 
        return 'Rab';
      case 'thursday':
      case 'kamis': 
        return 'Kam';
      case 'friday':
      case 'jumat':
      case 'jum\'at': 
        return 'Jum';
      case 'saturday':
      case 'sabtu': 
        return 'Sab';
      case 'sunday':
      case 'minggu': 
        return 'Min';
      default: 
        return day.length >= 3 ? day.substring(0, 3) : day;
    }
  }

  Future<void> _handleSearch(String query, String category, String reason, String status) async {
    try {
      if (query.isEmpty && category == 'Semua Kategori' && reason == 'Semua Alasan' && status == 'Semua Status') {
        // No filters - show all data
        setState(() {
          filteredReturnData = List.from(returnData);
        });
        return;
      }

      // Use API search if there's a search query
      if (query.isNotEmpty) {
        final searchResult = await ReturnItemsApiService.searchReturnItems(
          query: query,
          kategori: category != 'Semua Kategori' ? category : null,
          reasonCategory: reason != 'Semua Alasan' ? reason : null,
        );

        if (searchResult['success']) {
          List<Map<String, dynamic>> processedSearchData = [];
          final searchData = searchResult['data'] as List;
          
          for (final item in searchData) {
            // Handle both ReturnItem objects and Map objects
            if (item is Map<String, dynamic>) {
              processedSearchData.add({
                'id': item['id'] ?? 0,
                'nama_barang': item['nama_barang'] ?? '',
                'kategori_barang': item['kategori_barang'] ?? '',
                'jumlah_barang': item['jumlah_barang'] ?? 0,
                'nama_produsen': item['nama_produsen'] ?? '',
                'alasan_pengembalian': item['alasan_pengembalian'] ?? '',
                'tanggal_pengembalian': item['tanggal_pengembalian'] ?? '',
                'waktu_pengembalian': item['waktu_pengembalian'] ?? '',
                'status_pengembalian': item['status_pengembalian'] ?? '',
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
            filteredReturnData = processedSearchData;
          });
          return;
        }
      }

      // Local filtering if API search not applicable
      List<Map<String, dynamic>> filtered = List.from(returnData);

      if (category != 'Semua Kategori') {
        filtered = filtered.where((item) => item['kategori_barang'] == category).toList();
      }

      if (reason != 'Semua Alasan') {
        filtered = filtered.where((item) => item['alasan_pengembalian'] == reason).toList();
      }

      if (status != 'Semua Status') {
        filtered = filtered.where((item) => item['status_pengembalian'] == status).toList();
      }

      if (query.isNotEmpty) {
        filtered = filtered.where((item) => 
          item['nama_barang'].toString().toLowerCase().contains(query.toLowerCase()) ||
          item['kategori_barang'].toString().toLowerCase().contains(query.toLowerCase()) ||
          item['nama_produsen'].toString().toLowerCase().contains(query.toLowerCase()) ||
          item['alasan_pengembalian'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
      
      setState(() {
        filteredReturnData = filtered;
      });
    } catch (e) {
      // Fallback to local filtering
      List<Map<String, dynamic>> filtered = List.from(returnData);

      if (category != 'Semua Kategori') {
        filtered = filtered.where((item) => item['kategori_barang'] == category).toList();
      }

      if (reason != 'Semua Alasan') {
        filtered = filtered.where((item) => item['alasan_pengembalian'] == reason).toList();
      }

      if (status != 'Semua Status') {
        filtered = filtered.where((item) => item['status_pengembalian'] == status).toList();
      }

      if (query.isNotEmpty) {
        filtered = filtered.where((item) => 
          item['nama_barang'].toString().toLowerCase().contains(query.toLowerCase()) ||
          item['kategori_barang'].toString().toLowerCase().contains(query.toLowerCase()) ||
          item['nama_produsen'].toString().toLowerCase().contains(query.toLowerCase()) ||
          item['alasan_pengembalian'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
      
      setState(() {
        filteredReturnData = filtered;
      });
    }
  }
  
  Widget _buildReturnItemCard(Map<String, dynamic> item, int index) {
    final isExpanded = _expandedItems.contains(item['id']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(item['id']);
                } else {
                  _expandedItems.add(item['id']);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Index number
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nama_barang'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(item['kategori_barang']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['kategori_barang'] ?? '',
                                style: TextStyle(
                                  color: _getCategoryColor(item['kategori_barang']),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              '${item['jumlah_barang']?.toString() ?? '0'} pcs',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item['status_pengembalian']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['status_pengembalian'] ?? '',
                                style: TextStyle(
                                  color: _getStatusColor(item['status_pengembalian']),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Date and arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(item['tanggal_pengembalian']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  
                  // Detailed information
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Produsen',
                          item['nama_produsen'] ?? '-',
                          Icons.business_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Alasan',
                          item['alasan_pengembalian'] ?? '-',
                          Icons.info_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Tanggal Return',
                          _formatDate(item['tanggal_pengembalian']),
                          Icons.calendar_today_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Waktu Return',
                          _formatDateTime(item['waktu_pengembalian']),
                          Icons.access_time_outlined,
                        ),
                      ),
                    ],
                  ),
                  
                  // Action button
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleViewDetail(item['id']),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Lihat Detail'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'elektronik':
        return Colors.blue;
      case 'peralatan':
        return Colors.orange;
      case 'makanan':
        return Colors.green;
      case 'minuman':
        return Colors.purple; 
      default:
        return Colors.grey;
    }
  }

  void _handleViewDetail(int id) {
    // Find the item by id
    final item = filteredReturnData.firstWhere(
      (element) => element['id'] == id,
      orElse: () => {},
    );
    
    if (item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.assignment_return, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Detail Return Barang',
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
                _buildDetailItem('Kategori Barang', item['kategori_barang']?.toString() ?? '-'),
                _buildDetailItem('Jumlah Barang', '${item['jumlah_barang']?.toString() ?? '0'} pcs'),
                _buildDetailItem('Nama Produsen', item['nama_produsen']?.toString() ?? '-'),
                _buildDetailItem('Alasan Pengembalian', item['alasan_pengembalian']?.toString() ?? '-'),
                _buildDetailItem('Tanggal Pengembalian', _formatDate(item['tanggal_pengembalian'])),
                _buildDetailItem('Waktu Pengembalian', _formatDateTime(item['waktu_pengembalian'])),
                _buildDetailItem('Status Pengembalian', item['status_pengembalian']?.toString() ?? '-'),
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
      onRefresh: _loadReturnData,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
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
                  const SizedBox(height: 8),
                  const Text(
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
            _buildReturnTable(),
            
            const SizedBox(height: 20),
            
            // Return Chart
            _buildReturnChart(),
            
            // Bottom spacing for better UX
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnTable() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tabel Return Barang Mingguan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama barang, kategori, produsen, atau alasan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                _handleSearch(value, 'Semua Kategori', 'Semua Alasan', 'Semua Status');
              },
            ),
            
            const SizedBox(height: 16),
            
            // Expandable Return Cards
            if (filteredReturnData.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_return_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Data return kosong',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredReturnData.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildReturnItemCard(item, index + 1);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Return Mingguan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Total barang return per hari',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (chartData.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Find max value for scaling
    double maxValue = chartData.map((data) => (data['total_items'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) maxValue = 1; // Avoid division by zero
    final scaledMaxValue = maxValue * 1.1; // Add 10% padding

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: chartData.map((data) {
          final totalItems = (data['total_items'] ?? 0).toDouble();
          final dayShort = data['day_short'] ?? '';
          final barHeight = scaledMaxValue > 0 ? (totalItems / scaledMaxValue) * 180 : 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Value label on top of bar
                  if (totalItems > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${totalItems.toInt()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                  
                  // Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    width: double.infinity,
                    height: barHeight.clamp(0, 180),
                    constraints: const BoxConstraints(maxWidth: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: totalItems > 0
                            ? [
                                Colors.red.shade300,
                                Colors.red.shade600,
                              ]
                            : [
                                Colors.grey.shade200,
                                Colors.grey.shade300,
                              ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      boxShadow: totalItems > 0
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Day label
                  Text(
                    dayShort,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'recent':
        return Colors.blue;
      case 'processed':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

}