// lib/screens/return_history_screen.dart

import 'package:flutter/material.dart';
import '../models/return_item.dart';
import '../services/return_items_api_service.dart';

class ReturnHistoryScreen extends StatefulWidget {
  const ReturnHistoryScreen({super.key});

  @override
  State<ReturnHistoryScreen> createState() => _ReturnHistoryScreenState();
}

class _ReturnHistoryScreenState extends State<ReturnHistoryScreen> {
  List<ReturnItem> _returnItems = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedStatus;
  int _currentPage = 1;
  bool _hasMoreData = true;
  Set<int> _expandedItems = <int>{};

  final List<Map<String, String>> _statusOptions = [
    {'value': '', 'label': 'Semua Status'},
    {'value': 'pending', 'label': 'Menunggu Review'},
    {'value': 'approved', 'label': 'Disetujui'},
    {'value': 'rejected', 'label': 'Ditolak'},
    {'value': 'processing', 'label': 'Sedang Diproses'},
    {'value': 'completed', 'label': 'Selesai'},
  ];

  @override
  void initState() {
    super.initState();
    _loadReturnHistory();
  }

  Future<void> _loadReturnHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _returnItems.clear();
      _hasMoreData = true;
    }

    setState(() {
      if (refresh) {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final response = await ReturnItemsApiService.getReturnHistory(
        page: _currentPage,
        status: _selectedStatus,
      );

      if (response['success'] == true) {
        final List<ReturnItem> newItems = List<ReturnItem>.from(response['data'] ?? []);
        final pagination = response['pagination'] ?? {};
        
        setState(() {
          if (refresh) {
            _returnItems = newItems;
          } else {
            _returnItems.addAll(newItems);
          }
          _hasMoreData = _currentPage < (int.tryParse(pagination['last_page'].toString()) ?? 1);
          _currentPage++;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Terjadi kesalahan';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Simple filter button di pojok kanan atas
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Filter Status',
                    onSelected: (value) {
                      setState(() {
                        _selectedStatus = value.isEmpty ? null : value;
                      });
                      _loadReturnHistory(refresh: true);
                    },
                    itemBuilder: (context) {
                      return _statusOptions.map((option) {
                        return PopupMenuItem<String>(
                          value: option['value']!,
                          child: Text(option['label']!),
                        );
                      }).toList();
                    },
                  ),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _returnItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _returnItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadReturnHistory(refresh: true),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_returnItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_return_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada history return',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Return barang akan muncul di sini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadReturnHistory(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _returnItems.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _returnItems.length) {
            // Load more indicator
            if (_hasMoreData) {
              _loadReturnHistory();
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final returnItem = _returnItems[index];
          return _buildReturnItemCard(returnItem);
        },
      ),
    );
  }

  Widget _buildReturnItemCard(ReturnItem returnItem) {
    final isExpanded = _expandedItems.contains(returnItem.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(returnItem.id);
                } else {
                  _expandedItems.add(returnItem.id!);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          returnItem.namaBarang,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          returnItem.kategoriBarang,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${returnItem.jumlahBarang} item',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(returnItem.status ?? 'pending'),
                  const SizedBox(width: 8),
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
                  _buildInfoItem(
                    'Order Number',
                    returnItem.orderNumber,
                    Icons.receipt_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    'Alasan Pengembalian',
                    returnItem.alasanPengembalian,
                    Icons.comment_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    'Tanggal Return',
                    returnItem.formattedDate,
                    Icons.calendar_today_outlined,
                  ),
                  
                  if (returnItem.namaProdusen != null && returnItem.namaProdusen!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      'Produsen',
                      returnItem.namaProdusen!,
                      Icons.business_outlined,
                    ),
                  ],
                  
                  // Photo section
                  if (returnItem.fotoUrl != null) ...[
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
                                'Foto Bukti',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _showImageDialog(returnItem.fotoUrl!),
                                child: Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      returnItem.fotoUrl!,
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      'Foto Bukti',
                      'Tidak ada foto',
                      Icons.photo_outlined,
                    ),
                  ],
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

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'approved':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case 'processing':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ReturnItem.fromJson({'status': status}).statusText,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
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

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Foto Bukti'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gagal memuat gambar',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
