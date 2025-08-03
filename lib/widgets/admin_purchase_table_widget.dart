// lib/widgets/admin_purchase_table_widget.dart
import 'package:flutter/material.dart';
import 'dart:async';

class AdminPurchaseTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> purchaseData;
  final List<String> categories;
  final Function(int) onView;
  final Function(String, String) onSearch;

  const AdminPurchaseTableWidget({
    super.key,
    required this.purchaseData,
    required this.categories,
    required this.onView,
    required this.onSearch,
  });

  @override
  State<AdminPurchaseTableWidget> createState() => _AdminPurchaseTableWidgetState();
}

class _AdminPurchaseTableWidgetState extends State<AdminPurchaseTableWidget> {
  String _selectedCategory = 'Semua Kategori';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  Set<int> _expandedItems = <int>{};

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      widget.onSearch(value, _selectedCategory);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Using Admin Sales Template Style
            const Text(
              'Tabel Barang Masuk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Search and Filter Section - Using Admin Sales Template Style
            Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama barang, kategori, supplier, atau lokasi...',
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
                  value: _selectedCategory,
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
                  items: widget.categories.map((category) {
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
                      setState(() {
                        _selectedCategory = value;
                      });
                      // Use current search query instead of empty string
                      widget.onSearch(_searchController.text, value);
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Expandable Purchase Cards
            if (widget.purchaseData.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Data barang masuk kosong',
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
              ...widget.purchaseData.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildPurchaseItemCard(item, index + 1);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseItemCard(Map<String, dynamic> item, int index) {
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
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          color: Colors.purple.shade600,
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
                              '${item['jumlah_barang']} pcs',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Price and arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp ${_formatCurrency(item['estimated_value'] ?? 0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
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
                          'Tanggal Masuk',
                          _formatDate(item['tanggal_masuk_barang'] ?? ''),
                          Icons.calendar_today_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Harga Satuan',
                          'Rp ${_formatCurrency(item['harga_jual'] ?? 0)}',
                          Icons.attach_money,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Supplier',
                          item['producer_name'] ?? '-',
                          Icons.business_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Lokasi Rak',
                          item['lokasi_rak_barang'] ?? '-',
                          Icons.location_on_outlined,
                        ),
                      ),
                    ],
                  ),
                  
                  // Photo section if available
                  if (item['foto_barang'] != null && item['foto_barang'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.photo_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Foto Barang',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['foto_barang'].toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey[400],
                                          size: 32,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Action button
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleViewDetail(item['id']),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Lihat Detail'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Category color method from admin sales template
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

  // Format date method from admin sales template
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

  // Format currency method 
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // View detail handler from admin sales template
  void _handleViewDetail(int id) {
    final item = widget.purchaseData.firstWhere((item) => item['id'] == id, orElse: () => {});
    
    if (item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data tidak ditemukan')),
      );
      return;
    }

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
                  'Detail Barang Masuk',
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
                _buildDetailItem('Tanggal Masuk', _formatDate(item['tanggal_masuk_barang']?.toString() ?? '')),
                _buildDetailItem('Supplier', item['producer_name']?.toString() ?? '-'),
                _buildDetailItem('Harga Satuan', 'Rp ${_formatCurrency(item['harga_jual'] ?? 0)}'),
                _buildDetailItem('Total Harga', 'Rp ${_formatCurrency(item['estimated_value'] ?? 0)}'),
                _buildDetailItem('Lokasi Rak', item['lokasi_rak_barang']?.toString() ?? '-'),
                
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

  // Detail item builder from admin sales template
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
}