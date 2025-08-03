// lib/widgets/admin_return_table_widget.dart
import 'package:flutter/material.dart';

class AdminReturnTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> returnData;
  final List<String> categories;
  final List<String> returnReasons;
  final List<String> returnStatus;
  final Function(int) onViewDetail;
  final Function(String, String, String, String) onSearch;

  const AdminReturnTableWidget({
    Key? key,
    required this.returnData,
    required this.categories,
    required this.returnReasons,
    required this.returnStatus,
    required this.onViewDetail,
    required this.onSearch,
  }) : super(key: key);

  @override
  _AdminReturnTableWidgetState createState() => _AdminReturnTableWidgetState();
}

class _AdminReturnTableWidgetState extends State<AdminReturnTableWidget> {
  String _selectedCategory = 'Semua Kategori';
  String _selectedReason = 'Semua Alasan';
  String _selectedStatus = 'Semua Status';
  Set<int> _expandedItems = <int>{};

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
            // Header - Using Admin Style
            const Text(
              'Daftar Return Barang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Search and Filter Section - Using Admin Style
            Column(
              children: [
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama barang, kategori, produsen...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) async {
                    widget.onSearch(value, _selectedCategory, _selectedReason, _selectedStatus);
                  },
                ),
                const SizedBox(height: 12),
                // Filter dropdowns row
                Row(
                  children: [
                    // Category dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        ),
                        items: widget.categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                            widget.onSearch('', _selectedCategory, _selectedReason, _selectedStatus);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Reason dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedReason,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Alasan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        ),
                        items: widget.returnReasons.map((reason) {
                          return DropdownMenuItem(
                            value: reason,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                reason,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              _selectedReason = value;
                            });
                            widget.onSearch('', _selectedCategory, _selectedReason, _selectedStatus);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status dropdown
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  ),
                  items: widget.returnStatus.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          status,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      widget.onSearch('', _selectedCategory, _selectedReason, _selectedStatus);
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Return Table - Using Admin Style
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.returnData.isEmpty
                ? Container(
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
                : Column(
                    children: widget.returnData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildReturnItemCard(item, index + 1);
                    }).toList(),
                  ),
            ),
          ],
        ),
      ),
    );
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
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          color: Colors.orange.shade600,
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item['status_pengembalian']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['status_pengembalian'] ?? '-',
                                style: TextStyle(
                                  color: _getStatusColor(item['status_pengembalian']),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              '${item['jumlah_return']} pcs',
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
                  
                  // Date and arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(item['tanggal_pengembalian'] ?? ''),
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
                          'Alasan Pengembalian',
                          item['alasan_pengembalian'] ?? '-',
                          Icons.comment_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Tanggal Return',
                          _formatDate(item['tanggal_pengembalian']),
                          Icons.calendar_today_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    'Waktu Pengembalian',
                    _formatDateTime(item['waktu_pengembalian']),
                    Icons.access_time_outlined,
                  ),
                  const SizedBox(height: 8),
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
                          'Nilai Return',
                          'Rp ${_formatCurrency(item['nilai_return'] ?? 0)}',
                          Icons.attach_money,
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
                  ] else ...[
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      'Foto Barang',
                      'Tidak ada foto',
                      Icons.photo_outlined,
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
                        backgroundColor: Colors.orange,
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

  // Category color method from admin template
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

  // Status color method
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'selesai':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Format date method from admin template
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

  // Format date time method from admin template
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  // View detail handler from admin template
  void _handleViewDetail(int id) {
    final item = widget.returnData.firstWhere((item) => item['id'] == id, orElse: () => {});
    
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
                _buildDetailItem('Kategori', item['kategori_barang']?.toString() ?? '-'),
                _buildDetailItem('Jumlah Return', '${item['jumlah_return']?.toString() ?? '0'} pcs'),
                _buildDetailItem('Tanggal Return', _formatDate(item['tanggal_pengembalian']?.toString() ?? '')),
                _buildDetailItem('Waktu Pengembalian', _formatDateTime(item['waktu_pengembalian']?.toString())),
                _buildDetailItem('Produsen', item['nama_produsen']?.toString() ?? '-'),
                _buildDetailItem('Alasan Pengembalian', item['alasan_pengembalian']?.toString() ?? '-'),
                _buildDetailItem('Status Pengembalian', item['status_pengembalian']?.toString() ?? '-'),
                _buildDetailItem('Nilai Return', 'Rp ${_formatCurrency(item['nilai_return'] ?? 0)}'),
                
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

  // Detail item builder from admin template
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