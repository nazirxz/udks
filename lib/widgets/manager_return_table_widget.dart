// lib/widgets/manager_return_table_widget.dart
import 'package:flutter/material.dart';

class ManagerReturnTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> returnData;
  final List<String> categories;
  final List<String> returnReasons;
  final List<String> returnStatus;
  final Function(int) onView;
  final Function(String, String, String, String) onSearch;

  const ManagerReturnTableWidget({
    Key? key,
    required this.returnData,
    required this.categories,
    required this.returnReasons,
    required this.returnStatus,
    required this.onView,
    required this.onSearch,
  }) : super(key: key);

  @override
  _ManagerReturnTableWidgetState createState() => _ManagerReturnTableWidgetState();
}

class _ManagerReturnTableWidgetState extends State<ManagerReturnTableWidget> {
  String _selectedCategory = 'Semua Kategori';
  String _selectedReason = 'Semua Alasan';
  String _selectedStatus = 'Semua Status';

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
              'Tabel Return Barang Mingguan',
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
            
            // Return Table - Using Admin Sales Template Style
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 8,
                  horizontalMargin: 8,
                  headingRowHeight: 40,
                  dataRowHeight: 48,
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: SizedBox(width: 30, child: Text('No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                    DataColumn(label: SizedBox(width: 100, child: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                    DataColumn(label: SizedBox(width: 60, child: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                    DataColumn(label: SizedBox(width: 80, child: Text('Tgl Return', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                    DataColumn(label: SizedBox(width: 50, child: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                    DataColumn(label: SizedBox(width: 80, child: Text('Produsen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                    DataColumn(label: SizedBox(width: 75, child: Text('Alasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                    DataColumn(label: SizedBox(width: 50, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                    DataColumn(label: SizedBox(width: 70, child: Text('Nilai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                    DataColumn(label: SizedBox(width: 40, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                  ],
                  rows: widget.returnData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${index + 1}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: Text(
                              item['nama_barang'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 60,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(item['kategori_barang']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['kategori_barang'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _getCategoryColor(item['kategori_barang']),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 80,
                            child: Text(
                              _formatDate(item['tanggal_return'] ?? ''),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${item['jumlah_return']}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 80,
                            child: Text(
                              item['nama_produsen'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 75,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getReasonColor(item['alasan_return']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['alasan_return'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _getReasonColor(item['alasan_return']),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 50,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item['status_return']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['status_return'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _getStatusColor(item['status_return']),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 70,
                            child: Text(
                              'Rp ${_formatCurrency(item['nilai_return'] ?? 0)}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green, fontSize: 9),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 40,
                            child: IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue, size: 16),
                              onPressed: () {
                                widget.onView(item['id']);
                                _handleViewDetail(item['id']);
                              },
                              tooltip: 'Lihat Detail',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
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

  // Return reason color method
  Color _getReasonColor(String? reason) {
    switch (reason?.toLowerCase()) {
      case 'rusak':
        return Colors.red;
      case 'cacat':
        return Colors.orange;
      case 'kadaluarsa':
        return Colors.purple;
      case 'tidak sesuai pesanan':
        return Colors.blue;
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
                _buildDetailItem('Tanggal Return', _formatDate(item['tanggal_return']?.toString() ?? '')),
                _buildDetailItem('Produsen', item['nama_produsen']?.toString() ?? '-'),
                _buildDetailItem('Alasan Return', item['alasan_return']?.toString() ?? '-'),
                _buildDetailItem('Status Return', item['status_return']?.toString() ?? '-'),
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