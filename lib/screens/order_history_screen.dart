import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_history_api_service.dart';
import '../utils/status_utils.dart';
import '../screens/login_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> _orders = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _selectedStatus;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  
  // Get status filters from StatusUtils
  List<Map<String, String>> get _statusFilters => StatusUtils.getStatusFilters();

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreOrders();
      }
    }
  }

  Future<void> _loadOrderHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _orders.clear();
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await OrderHistoryApiService.getOrderHistory(
        page: _currentPage,
        status: _selectedStatus?.isEmpty == true ? null : _selectedStatus,
      );

      if (result['success']) {
        final ordersData = result['data'];
        List<Order> orders = [];
        
        // Safely parse orders data
        if (ordersData is List) {
          for (int i = 0; i < ordersData.length; i++) {
            try {
              final orderJson = ordersData[i];
              if (orderJson != null && orderJson is Map<String, dynamic>) {
                print('DEBUG: Parsing order $i with keys: ${orderJson.keys}');
                final order = Order.fromJson(orderJson);
                orders.add(order);
              } else {
                print('WARNING: Invalid order data at index $i: $orderJson');
              }
            } catch (e) {
              print('ERROR: Failed to parse order $i: $e');
              print('DEBUG: Order JSON: ${ordersData[i]}');
              // Continue parsing other orders
            }
          }
        } else {
          print('WARNING: Expected List but got ${ordersData.runtimeType}: $ordersData');
        }

        setState(() {
          if (refresh || _currentPage == 1) {
            _orders = orders;
          } else {
            _orders.addAll(orders);
          }
          
          // Check if there's more data
          final pagination = result['pagination'] as Map<String, dynamic>?;
          if (pagination != null) {
            final currentPage = int.tryParse(pagination['current_page'].toString()) ?? 1;
            final lastPage = int.tryParse(pagination['last_page'].toString()) ?? 1;
            _hasMoreData = currentPage < lastPage;
          } else {
            _hasMoreData = orders.length >= 10; // Default assumption
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        
        // Handle authentication error
        if (result['message']?.toLowerCase().contains('authentication') == true ||
            result['message']?.toLowerCase().contains('login') == true) {
          _showAuthenticationError();
        } else {
          _showErrorSnackBar(result['message'] ?? 'Gagal memuat riwayat pesanan');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await OrderHistoryApiService.getOrderHistory(
        page: _currentPage + 1,
        status: _selectedStatus?.isEmpty == true ? null : _selectedStatus,
      );

      if (result['success']) {
        final ordersData = result['data'];
        List<Order> orders = [];
        
        // Safely parse orders data
        if (ordersData is List) {
          for (int i = 0; i < ordersData.length; i++) {
            try {
              final orderJson = ordersData[i];
              if (orderJson != null && orderJson is Map<String, dynamic>) {
                final order = Order.fromJson(orderJson);
                orders.add(order);
              }
            } catch (e) {
              print('ERROR: Failed to parse more order $i: $e');
              // Continue parsing other orders
            }
          }
        }

        setState(() {
          _orders.addAll(orders);
          _currentPage++;
          
          // Check if there's more data
          final pagination = result['pagination'] as Map<String, dynamic>?;
          if (pagination != null) {
            final currentPage = int.tryParse(pagination['current_page'].toString()) ?? 1;
            final lastPage = int.tryParse(pagination['last_page'].toString()) ?? 1;
            _hasMoreData = currentPage < lastPage;
          } else {
            _hasMoreData = orders.length >= 10;
          }
          
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _showAuthenticationError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Sesi Login Berakhir'),
          ],
        ),
        content: const Text(
          'Sesi login Anda telah berakhir. Silakan login kembali untuk melihat riwayat pesanan.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadOrderHistory(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          _buildStatusFilter(),
          
          // Orders List
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Status:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = _selectedStatus == filter['value'] ||
                    (_selectedStatus == null && filter['value'] == '');
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? filter['value'] : null;
                        if (_selectedStatus?.isEmpty == true) {
                          _selectedStatus = null;
                        }
                      });
                      _loadOrderHistory(refresh: true);
                    },
                    selectedColor: Colors.orange.shade100,
                    checkmarkColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.orange.shade700 : Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading && _orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Memuat riwayat pesanan...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Pesanan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum pernah melakukan pemesanan.\nMulai berbelanja sekarang!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Mulai Belanja'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.orange,
      onRefresh: () => _loadOrderHistory(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            );
          }
          
          return _buildOrderCard(_orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber ?? 'No Order Number',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: StatusUtils.getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      StatusUtils.getStatusDisplayText(order.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Order Items Summary
              Text(
                order.totalItemsText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // First few items preview
              if (order.orderItems.isNotEmpty) ...[
                ...order.orderItems.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${item.productName} (${item.quantity}x)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                if (order.orderItems.length > 2)
                  Text(
                    '• dan ${order.orderItems.length - 2} item lainnya',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
              
              const SizedBox(height: 12),
              
              // Total and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Rp ${order.formatCurrency(order.totalAmount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _showOrderDetail(order),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Detail',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetail(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _buildOrderDetailSheet(order, scrollController),
      ),
    );
  }

  Widget _buildOrderDetailSheet(Order order, ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Pesanan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.orderNumber ?? 'No Order Number',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: StatusUtils.getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  StatusUtils.getStatusDisplayText(order.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Info
                  _buildDetailSection(
                    'Informasi Pesanan',
                    [
                      _buildDetailRow('Tanggal Pesanan', order.formattedDate),
                      _buildDetailRow('Metode Pengiriman', order.shippingMethod),
                      _buildDetailRow('Metode Pembayaran', order.paymentMethod),
                      if (order.voucherCode?.isNotEmpty == true)
                        _buildDetailRow('Kode Voucher', order.voucherCode!),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Shipping Info
                  _buildDetailSection(
                    'Informasi Pengiriman',
                    [
                      _buildDetailRow('Nama Penerima', order.pengecerName),
                      _buildDetailRow('Nomor Telepon', order.pengecerPhone),
                      _buildDetailRow('Email', order.pengecerEmail),
                      _buildDetailRow('Alamat', '${order.shippingAddress}, ${order.city} ${order.postalCode}'),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Items
                  _buildDetailSection(
                    'Items Pesanan',
                    order.orderItems.map((item) => _buildItemRow(item)).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Price Breakdown
                  _buildDetailSection(
                    'Rincian Harga',
                    [
                      _buildDetailRow('Subtotal', 'Rp ${order.formatCurrency(order.subtotal)}'),
                      _buildDetailRow('Ongkos Kirim', 'Rp ${order.formatCurrency(order.shippingCost)}'),
                      if (order.discountAmount > 0)
                        _buildDetailRow('Diskon', '- Rp ${order.formatCurrency(order.discountAmount)}', 
                                       isDiscount: true),
                      const Divider(height: 20),
                      _buildDetailRow('Total', 'Rp ${order.formatCurrency(order.totalAmount)}', 
                                     isTotal: true),
                    ],
                  ),
                  
                  if (order.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 20),
                    _buildDetailSection(
                      'Catatan',
                      [
                        Text(
                          order.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 40), // Extra space at bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 14 : 12,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 14 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal 
                    ? Colors.orange 
                    : isDiscount 
                        ? Colors.green 
                        : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.productImage?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://udkeluargasehati.com/storage/${item.productImage}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fastfood,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.fastfood,
                    color: Colors.grey,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.quantity} ${item.unit} × Rp ${_formatCurrency(item.unitPrice.toInt())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rp ${_formatCurrency(item.totalPrice.toInt())}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
