// lib/widgets/admin_sales_page_widget.dart
import 'package:flutter/material.dart';
import '../services/outgoing_items_service.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final TextEditingController _searchController = TextEditingController();
  
  // Map related variables
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  bool showMap = false;
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(0.5, 101.4), // Default position (Pekanbaru area)
    zoom: 10,
  );

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
          search: null,
          page: currentPage,
        );
      }

      if (response['status'] == 'success') {
        // Handle different response structures
        List<dynamic> items;
        
        if (response['data'] is Map && response['data']['data'] != null) {
          // Paginated response structure (like orders API)
          items = response['data']['data'];
          
          if (mounted) {
            setState(() {
              orderData = items.cast<Map<String, dynamic>>();
              filteredOrderData = orderData;
              
              // Handle pagination from nested structure
              final pagination = response['data'];
              currentPage = pagination['current_page'] ?? 1;
              totalPages = pagination['last_page'] ?? 1;
              
              isLoading = false;
              
              // Show map if search found results with location data
              _updateMapMarkers();
            });
          }
        } else {
          // Simple array response structure
          items = response['data'];
          
          if (mounted) {
            setState(() {
              orderData = items.cast<Map<String, dynamic>>();
              filteredOrderData = orderData;
              
              // Handle pagination for search results
              if (searchQuery.isNotEmpty) {
                currentPage = 1;
                totalPages = 1;
              } else {
                final pagination = response['pagination'];
                currentPage = pagination['current_page'];
                totalPages = pagination['last_page'];
              }
              
              isLoading = false;
              
              // Show map if search found results with location data
              _updateMapMarkers();
            });
          }
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
      if (mounted) {
        setState(() {
          orderData = [];
          filteredOrderData = [];
          currentPage = 1;
          totalPages = 1;
          isLoading = false;
        });
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
    markers.clear();
    
    // Only show map if there's a search query and results with location data
    bool hasLocationData = false;
    
    for (int i = 0; i < filteredOrderData.length; i++) {
      final order = filteredOrderData[i];
      final lat = order['latitude'];
      final lng = order['longitude'];
      
      if (lat != null && lng != null) {
        try {
          final latitude = double.parse(lat.toString());
          final longitude = double.parse(lng.toString());
          hasLocationData = true;
          
          markers.add(
            Marker(
              markerId: MarkerId('order_${order['id']}'),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                title: order['pengecer_name'] ?? 'Pengecer',
                snippet: '${order['shipping_address'] ?? ''}\nOrder: ${order['order_number'] ?? ''}',
              ),
              onTap: () => _showOrderDetail(order),
            ),
          );
        } catch (e) {
          print('Error parsing coordinates for order ${order['id']}: $e');
        }
      }
    }
    
    if (mounted) {
      setState(() {
        showMap = searchQuery.isNotEmpty && hasLocationData && markers.isNotEmpty;
      });
    }
    
    // Update map camera to show all markers
    if (markers.isNotEmpty && mapController != null) {
      _fitMarkersOnMap();
    }
  }

  void _fitMarkersOnMap() {
    if (markers.isEmpty || mapController == null) return;
    
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;
    
    for (Marker marker in markers) {
      minLat = marker.position.latitude < minLat ? marker.position.latitude : minLat;
      maxLat = marker.position.latitude > maxLat ? marker.position.latitude : maxLat;
      minLng = marker.position.longitude < minLng ? marker.position.longitude : minLng;
      maxLng = marker.position.longitude > maxLng ? marker.position.longitude : maxLng;
    }
    
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Detail Pesanan',
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
                _buildDetailItem('Order Number', orderData['order_number']?.toString() ?? '-'),
                _buildDetailItem('Pengecer', orderData['pengecer_name']?.toString() ?? '-'),
                _buildDetailItem('Alamat', orderData['shipping_address']?.toString() ?? '-'),
                _buildDetailItem('Kota', orderData['city']?.toString() ?? '-'),
                _buildDetailItem('Total', 'Rp ${_formatCurrency(orderData['total_amount']?.toString() ?? '0')}'),
                _buildDetailItem('Status', orderData['order_status']?.toString() ?? '-'),
                _buildDetailItem('Lokasi', '${orderData['latitude']}, ${orderData['longitude']}'),
                
                if (orderData['order_items'] != null && orderData['order_items'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Item Pesanan:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ...orderData['order_items'].map<Widget>((item) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['product_name']?.toString() ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${item['quantity']} ${item['unit'] ?? 'pcs'}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )).toList(),
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

  String _formatCurrency(String amount) {
    try {
      final double value = double.parse(amount);
      return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    } catch (e) {
      return amount;
    }
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
            
            // Map View (show when search results have location data)
            if (showMap) _buildMapView(),
            
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
              'Tabel Pesanan',
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
                    hintText: 'Cari nama pengecer, alamat...',
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
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Order Number', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Pengecer', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Alamat', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredOrderData.isEmpty 
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
                    : filteredOrderData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        
                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(
                              Text(
                                item['order_number'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            DataCell(
                              Text(
                                item['pengecer_name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataCell(
                              Text(
                                item['shipping_address'] ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rp ${_formatCurrency(item['total_amount']?.toString() ?? '0')}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(item['order_status']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item['order_status'] ?? '',
                                  style: TextStyle(
                                    color: _getStatusColor(item['order_status']),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                                    onPressed: () => _showOrderDetail(item),
                                    tooltip: 'Lihat Detail',
                                  ),
                                  if (item['latitude'] != null && item['longitude'] != null)
                                    IconButton(
                                      icon: const Icon(Icons.location_on, color: Colors.red, size: 20),
                                      onPressed: () => _showLocationDialog(item),
                                      tooltip: 'Lihat Lokasi',
                                    ),
                                ],
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

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Lokasi Pengecer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${markers.length} lokasi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GoogleMap(
                    initialCameraPosition: _initialPosition,
                    markers: markers,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                      // Fit markers after map is created
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _fitMarkersOnMap();
                      });
                    },
                    mapType: MapType.normal,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Legend/Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tap pada marker untuk melihat detail pesanan pengecer',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showLocationDialog(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Lokasi Pengecer'),
            ],
          ),
          content: Container(
            width: 300,
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  double.parse(orderData['latitude'].toString()),
                  double.parse(orderData['longitude'].toString()),
                ),
                zoom: 16,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('location_${orderData['id']}'),
                  position: LatLng(
                    double.parse(orderData['latitude'].toString()),
                    double.parse(orderData['longitude'].toString()),
                  ),
                  infoWindow: InfoWindow(
                    title: orderData['pengecer_name'] ?? 'Pengecer',
                    snippet: orderData['shipping_address'] ?? '',
                  ),
                ),
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
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
