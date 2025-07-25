// lib/screens/sales_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart';
import '../models/sales_order.dart';
import '../services/sales_order_api_service.dart';
import '../utils/dashboard_utils.dart';
import '../utils/warehouse_config.dart';

class SalesDashboard extends StatefulWidget {
  final User user;

  const SalesDashboard({Key? key, required this.user}) : super(key: key);

  @override
  _SalesDashboardState createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  String _selectedFilter = 'Semua';
  bool _isLoading = true;
  MapType _mapType = MapType.normal;
  
  // API Integration
  List<SalesOrder> _salesOrders = [];
  String _searchQuery = '';
  String? _selectedCity;
  Map<String, dynamic>? _warehouseInfo;
  Map<String, dynamic>? _orderSummary;
  
  // Warehouse coordinates (UD Keluarga Sehati - Pekanbaru, Riau)
  // Jl. Suntai, Labuh Baru Bar., Kec. Payung Sekaki, Pekanbaru, Riau 28292
  double _warehouseLat = WarehouseConfig.latitude;
  double _warehouseLng = WarehouseConfig.longitude;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadSalesOrders();
  }

  Future<void> _loadSalesOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('DEBUG: Loading sales orders with filter: $_selectedFilter');
      debugPrint('DEBUG: API status filter: ${_selectedFilter == 'Semua' ? 'null' : _getApiStatus(_selectedFilter)}');
      
      final result = await SalesOrderApiService.getSalesOrders(
        status: _selectedFilter == 'Semua' ? null : _getApiStatus(_selectedFilter),
        city: _selectedCity,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        warehouseLat: _warehouseLat,
        warehouseLng: _warehouseLng,
      );

      debugPrint('DEBUG: API result: $result');
      debugPrint('DEBUG: Result success: ${result['success']}');
      
      if (result['success']) {
        final ordersData = result['data'];
        debugPrint('DEBUG: Orders data type in dashboard: ${ordersData.runtimeType}');
        debugPrint('DEBUG: Orders data: $ordersData');
        
        // Update warehouse info from API response
        if (result['warehouse'] != null) {
          _warehouseInfo = result['warehouse'];
          _warehouseLat = double.tryParse(result['warehouse']['latitude'].toString()) ?? _warehouseLat;
          _warehouseLng = double.tryParse(result['warehouse']['longitude'].toString()) ?? _warehouseLng;
          debugPrint('DEBUG: Updated warehouse coordinates: $_warehouseLat, $_warehouseLng');
        }
        
        // Update order summary
        if (result['summary'] != null) {
          _orderSummary = result['summary'];
          debugPrint('DEBUG: Order summary: $_orderSummary');
        }
        
        setState(() {
          if (ordersData is List<SalesOrder>) {
            _salesOrders = ordersData;
          } else if (ordersData is List) {
            _salesOrders = ordersData.cast<SalesOrder>();
          } else {
            _salesOrders = [];
          }
        });
        _setupMarkersFromOrders();
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to load sales orders');
      }
    } catch (e, stackTrace) {
      debugPrint('DEBUG: Exception in _loadSalesOrders: $e');
      debugPrint('DEBUG: Stack trace: $stackTrace');
      _showErrorSnackBar('Error loading sales orders: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getApiStatus(String displayStatus) {
    switch (displayStatus) {
      case 'Pending':
        return 'pending';
      case 'Dikonfirmasi':
        return 'confirmed';
      case 'Diproses':
        return 'processing';
      case 'Dikirim':
        return 'shipped';
      case 'Terkirim':
        return 'delivered';
      case 'Dibatalkan':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  String _getDisplayStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'processing':
        return 'Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Terkirim';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Pending';
    }
  }

  bool _matchesFilter(String orderStatus, String filterStatus) {
    String displayStatus = _getDisplayStatus(orderStatus);
    return displayStatus == filterStatus;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _requestLocationPermission() async {
    final permission = await Permission.location.request();
    if (permission == PermissionStatus.granted) {
      _getCurrentLocation();
    } else {
      _setupMarkersFromOrders();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      _setupMarkersFromOrders();
      
      // Move map to current location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      _setupMarkersFromOrders();
    }
  }

  void _setupMarkersFromOrders() {
    final markers = <Marker>{};
    
    // Add current location marker if available
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Lokasi Saya',
            snippet: 'Posisi saat ini',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add warehouse marker
    markers.add(
      Marker(
        markerId: const MarkerId('warehouse'),
        position: LatLng(_warehouseLat, _warehouseLng),
        infoWindow: const InfoWindow(
          title: 'Gudang Utama',
          snippet: 'Warehouse location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
    );

    // Add sales order markers
    for (final order in _salesOrders) {
      // Check if order matches current filter
      bool shouldShowOrder = _selectedFilter == 'Semua' || _matchesFilter(order.status, _selectedFilter);
      
      if (shouldShowOrder) {
        final markerColor = _getMarkerColor(order.status);
        markers.add(
          Marker(
            markerId: MarkerId('order_${order.id}'),
            position: LatLng(order.latitude, order.longitude),
            infoWindow: InfoWindow(
              title: order.pengecerName,
              snippet: '${order.shippingAddress} - ${_getDisplayStatus(order.status)}',
              onTap: () => _showOrderDetail(order),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });
  }

  double _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BitmapDescriptor.hueRed; // Grey-ish red for pending
      case 'confirmed':
        return BitmapDescriptor.hueOrange;
      case 'processing':
        return BitmapDescriptor.hueYellow;
      case 'shipped':
        return BitmapDescriptor.hueBlue;
      case 'delivered':
        return BitmapDescriptor.hueGreen;
      case 'cancelled':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueRed;
    }
  }
  void _filterMarkers(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    // Reload data from API with new filter
    _loadSalesOrders();
  }

  void _changeMapStyle(MapType mapType) {
    setState(() {
      _mapType = mapType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Sales'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Lokasi Saya',
          ),
          PopupMenuButton<MapType>(
            icon: const Icon(Icons.layers),
            onSelected: _changeMapStyle,
            itemBuilder: (context) => [
              const PopupMenuItem(value: MapType.normal, child: Text('Peta Standar')),
              const PopupMenuItem(value: MapType.satellite, child: Text('Satelit')),
              const PopupMenuItem(value: MapType.terrain, child: Text('Terrain')),
              const PopupMenuItem(value: MapType.hybrid, child: Text('Hybrid')),
            ],
          ),
          DashboardUtils.buildUserInfoBadge(widget.user),
          DashboardUtils.buildPopupMenu(
            context, 
            widget.user, 
            (value) => DashboardUtils.handleMenuSelection(context, value, widget.user),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildMapPage(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "summary",
            onPressed: () => _showDistributionSummary(),
            backgroundColor: Colors.green,
            mini: true,
            child: const Icon(Icons.list, color: Colors.white),
            tooltip: 'Ringkasan',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "route",
            onPressed: () => _showOptimalRoute(),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.route, color: Colors.white),
            tooltip: 'Rute Optimal',
          ),
        ],
      ),
    );
  }

  Widget _buildMapPage() {
    return Column(
      children: [
        // Header dengan search dan filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Column(
            children: [
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari lokasi distribusi...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.directions),
                    onPressed: () => _showOptimalRoute(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _searchOrders,
              ),
              const SizedBox(height: 12),
              // Filter buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua', _selectedFilter == 'Semua'),
                    _buildFilterChip('Pending', _selectedFilter == 'Pending'),
                    _buildFilterChip('Dikonfirmasi', _selectedFilter == 'Dikonfirmasi'),
                    _buildFilterChip('Diproses', _selectedFilter == 'Diproses'),
                    _buildFilterChip('Dikirim', _selectedFilter == 'Dikirim'),
                    _buildFilterChip('Terkirim', _selectedFilter == 'Terkirim'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Google Maps
        Expanded(
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(WarehouseConfig.latitude, WarehouseConfig.longitude), // UD Keluarga Sehati Warehouse - Pekanbaru
              zoom: WarehouseConfig.defaultZoom,
            ),
            mapType: _mapType,
            markers: _markers,
            circles: _currentPosition != null ? {
              Circle(
                circleId: const CircleId('currentLocation'),
                center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                radius: 100,
                fillColor: Colors.blue.withValues(alpha: 0.1),
                strokeColor: Colors.blue.withValues(alpha: 0.3),
                strokeWidth: 2,
              ),
            } : {},
            onTap: (LatLng position) {
              // Handle map tap if needed
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We have custom location button
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: true,
            liteModeEnabled: false,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.green,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          _filterMarkers(label);
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.green,
        checkmarkColor: Colors.white,
        side: BorderSide(color: Colors.green.shade300),
      ),
    );
  }

  void _searchOrders(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadSalesOrders();
  }

  void _showOrderDetail(SalesOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.pengecerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        order.shippingAddress,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Order: ${order.orderNumber}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status dan info tambahan
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Status: ${_getDisplayStatus(order.status)}',
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Jarak: ${order.formattedDistance}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              'Total: ${order.formattedTotalAmount}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            
            if (order.deliveryNotes != null && order.deliveryNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Catatan: ${order.deliveryNotes}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openMapsNavigation(order.latitude, order.longitude, order.pengecerName);
                    },
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Navigasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _makePhoneCall(order.pengecerPhone);
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Telepon'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showUpdateStatusDialog(order);
                },
                icon: const Icon(Icons.update, size: 18),
                label: const Text('Update Status Pengiriman'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'confirmed':
        return Colors.orange;
      case 'processing':
        return Colors.yellow[700]!;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openMapsNavigation(double lat, double lng, String name) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      DashboardUtils.showSnackBar(context, 'Tidak dapat membuka aplikasi maps');
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      DashboardUtils.showSnackBar(context, 'Tidak dapat melakukan panggilan');
    }
  }

  void _showUpdateStatusDialog(SalesOrder order) {
    String selectedStatus = order.status;
    String deliveryNotes = '';
    File? deliveryPhoto;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Status: ${order.pengecerName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Pengiriman:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'confirmed', child: Text('Dikonfirmasi')),
                    DropdownMenuItem(value: 'processing', child: Text('Diproses')),
                    DropdownMenuItem(value: 'shipped', child: Text('Dikirim')),
                    DropdownMenuItem(value: 'delivered', child: Text('Terkirim')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Catatan Pengiriman (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    deliveryNotes = value;
                  },
                ),
                const SizedBox(height: 16),
                if (selectedStatus == 'delivered') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.camera,
                              maxWidth: 1024,
                              maxHeight: 1024,
                              imageQuality: 80,
                            );
                            if (image != null) {
                              setState(() {
                                deliveryPhoto = File(image.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Ambil Foto'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1024,
                              maxHeight: 1024,
                              imageQuality: 80,
                            );
                            if (image != null) {
                              setState(() {
                                deliveryPhoto = File(image.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pilih Foto'),
                        ),
                      ),
                    ],
                  ),
                  if (deliveryPhoto != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          deliveryPhoto!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateOrderStatus(
                  order,
                  selectedStatus,
                  deliveryNotes.isNotEmpty ? deliveryNotes : null,
                  deliveryPhoto,
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(
    SalesOrder order,
    String newStatus,
    String? deliveryNotes,
    File? deliveryPhoto,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      String? deliveredAt;
      if (newStatus == 'delivered') {
        deliveredAt = DateTime.now().toIso8601String();
      }

      final result = await SalesOrderApiService.updateShippingStatus(
        orderId: order.id,
        orderStatus: newStatus,
        deliveryNotes: deliveryNotes,
        deliveredAt: deliveredAt,
        deliveryPhoto: deliveryPhoto,
      );

      // Hide loading
      Navigator.pop(context);

      if (result['success']) {
        DashboardUtils.showSnackBar(
          context,
          'Status pengiriman berhasil diupdate',
        );
        // Reload orders to get updated data
        _loadSalesOrders();
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      // Hide loading
      Navigator.pop(context);
      _showErrorSnackBar('Error updating status: $e');
    }
  }

  void _showOptimalRoute() {
    final activeOrders = _salesOrders.where((order) => 
      order.status.toLowerCase() == 'pending' ||
      order.status.toLowerCase() == 'confirmed' || 
      order.status.toLowerCase() == 'processing' || 
      order.status.toLowerCase() == 'shipped'
    ).toList();
    
    // Sort by distance if available
    activeOrders.sort((a, b) {
      if (a.distanceKm != null && b.distanceKm != null) {
        return a.distanceKm!.compareTo(b.distanceKm!);
      }
      return 0;
    });
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Rute Optimal Hari Ini',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '${activeOrders.length} order yang perlu dikirim',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...activeOrders.take(5).map((order) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(order.status),
                child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
              ),
              title: Text(order.pengecerName, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                '${order.shippingAddress} • ${order.formattedTotalAmount} • ${order.formattedDistance}', 
                style: const TextStyle(fontSize: 12)
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 12),
              onTap: () {
                Navigator.pop(context);
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(order.latitude, order.longitude),
                      zoom: 16.0,
                    ),
                  ),
                );
                _showOrderDetail(order);
              },
            )),
            if (activeOrders.length > 5)
              Text('... dan ${activeOrders.length - 5} order lainnya'),
          ],
        ),
      ),
    );
  }

  void _showDistributionSummary() {
    // Use API summary if available, otherwise calculate from local data
    int pendingCount, confirmedCount, processingCount, shippedCount, deliveredCount, cancelledCount;
    
    if (_orderSummary != null) {
      pendingCount = _orderSummary!['pending'] ?? 0;
      confirmedCount = _orderSummary!['confirmed'] ?? 0;
      processingCount = _orderSummary!['processing'] ?? 0;
      shippedCount = _orderSummary!['shipped'] ?? 0;
      deliveredCount = _orderSummary!['delivered'] ?? 0;
      cancelledCount = _orderSummary!['cancelled'] ?? 0;
    } else {
      // Fallback to local calculation
      pendingCount = _salesOrders.where((order) => order.status.toLowerCase() == 'pending').length;
      confirmedCount = _salesOrders.where((order) => order.status.toLowerCase() == 'confirmed').length;
      processingCount = _salesOrders.where((order) => order.status.toLowerCase() == 'processing').length;
      shippedCount = _salesOrders.where((order) => order.status.toLowerCase() == 'shipped').length;
      deliveredCount = _salesOrders.where((order) => order.status.toLowerCase() == 'delivered').length;
      cancelledCount = _salesOrders.where((order) => order.status.toLowerCase() == 'cancelled').length;
    }
    
    final totalValue = _salesOrders.isNotEmpty
        ? _salesOrders.map((order) => order.totalAmount).reduce((a, b) => a + b)
        : 0.0;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ringkasan Distribusi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSummaryCard('Pending', pendingCount, Colors.grey),
                _buildSummaryCard('Dikonfirmasi', confirmedCount, Colors.orange),
                _buildSummaryCard('Diproses', processingCount, Colors.yellow[700]!),
                _buildSummaryCard('Dikirim', shippedCount, Colors.blue),
                _buildSummaryCard('Terkirim', deliveredCount, Colors.green),
                if (cancelledCount > 0)
                  _buildSummaryCard('Dibatalkan', cancelledCount, Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Nilai Order:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Rp ${_formatCurrency(totalValue.toInt())}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total ${_salesOrders.length} order',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (_warehouseInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Gudang: ${_warehouseInfo!['city']}, ${_warehouseInfo!['province']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
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