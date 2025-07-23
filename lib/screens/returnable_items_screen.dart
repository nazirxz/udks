// lib/screens/returnable_items_screen.dart

import 'package:flutter/material.dart';
import '../models/returnable_item.dart';
import '../services/return_items_api_service.dart';
import 'return_form_screen.dart';

class ReturnableItemsScreen extends StatefulWidget {
  const ReturnableItemsScreen({super.key});

  @override
  State<ReturnableItemsScreen> createState() => _ReturnableItemsScreenState();
}

class _ReturnableItemsScreenState extends State<ReturnableItemsScreen> {
  List<ReturnableItem> _returnableItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReturnableItems();
  }

  Future<void> _loadReturnableItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the proper API to get returnable items
      final response = await ReturnItemsApiService.getReturnableItems();

      if (response['success']) {
        final List<ReturnableItem> returnableItems = response['data'] ?? [];

        setState(() {
          _returnableItems = returnableItems;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal memuat data';
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
      appBar: AppBar(
        title: const Text('Pilih Barang Return'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
              onPressed: _loadReturnableItems,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_returnableItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada barang yang bisa di-return',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hanya pesanan yang telah selesai yang bisa di-return',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReturnableItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _returnableItems.length,
        itemBuilder: (context, index) {
          final item = _returnableItems[index];
          return _buildReturnableItemCard(item);
        },
      ),
    );
  }

  Widget _buildReturnableItemCard(ReturnableItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.productCategory,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.canReturn ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.canReturn ? 'Bisa Return' : 'Tidak Bisa Return',
                    style: TextStyle(
                      fontSize: 12,
                      color: item.canReturn ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Order',
                    item.orderNumber,
                    Icons.receipt,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Tanggal',
                    item.formattedDate,
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Harga',
                    item.formattedPrice,
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Tersedia Return',
                    '${item.availableToReturn} dari ${item.quantityOrdered}',
                    Icons.inventory,
                  ),
                ),
              ],
            ),
            if (item.quantityReturned > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, 
                         color: Colors.orange[700], 
                         size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Sudah di-return: ${item.quantityReturned} item',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: item.canReturn && item.availableToReturn > 0
                    ? () => _navigateToReturnForm(item)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  item.canReturn && item.availableToReturn > 0
                      ? 'Return Barang'
                      : 'Tidak Bisa Return',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
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

  void _navigateToReturnForm(ReturnableItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnFormScreen(returnableItem: item),
      ),
    ).then((_) {
      // Refresh data setelah kembali dari form return
      _loadReturnableItems();
    });
  }
}
