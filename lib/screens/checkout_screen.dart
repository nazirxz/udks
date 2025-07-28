// lib/screens/checkout_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/user.dart';
import '../services/cart_service.dart';
import '../services/order_api_service.dart';
import '../services/voucher_api_service.dart';
import '../services/shipping_api_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/user_api_service.dart';
import '../utils/warehouse_config.dart';
import 'login_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _voucherController = TextEditingController();
  
  // Customer information form controllers  
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  String _selectedShipping = 'Standard Delivery';
  String _selectedPayment = 'Cash on Delivery';
  bool _isVoucherApplied = false;
  int _discountAmount = 0;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  
  // User data (auto-filled from logged in user)
  User? _currentUser;
  bool _isLoadingUser = false;
  
  // Location data
  double? _latitude;
  double? _longitude;
  String? _locationAddress;
  double? _locationAccuracy;
  
  // Dynamic shipping methods from API
  List<Map<String, dynamic>> _shippingOptions = [];
  
  // Payment methods (usually fixed)
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'title': 'Cash on Delivery',
      'subtitle': 'Pay when you receive',
      'icon': Icons.money,
    },
    {
      'title': 'Bank Transfer',
      'subtitle': 'BCA - 1234567890 (A.N: UD Keluarga Sehati)',
      'icon': Icons.account_balance,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadShippingMethods();
    _loadUserData();
    // Otomatis ambil lokasi saat checkout screen dibuka
    _getCurrentLocationAutomatically();
  }

  // Fungsi untuk otomatis mengambil lokasi tanpa loading indicator yang mengganggu
  Future<void> _getCurrentLocationAutomatically() async {
    try {
      final position = await LocationService.getCurrentPosition();
      
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationAccuracy = position.accuracy;
          _locationAddress = LocationService.formatLocationAddress(
            position, 
            'Lokasi saat ini'
          );
        });
        
        print('DEBUG: Auto-location detected: Lat=${_latitude}, Lng=${_longitude}, Accuracy=${_locationAccuracy}m');
        
        // Optional: Show subtle notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Lokasi otomatis terdeteksi'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('DEBUG: Could not get automatic location');
      }
    } catch (e) {
      print('DEBUG: Error getting automatic location: $e');
      // Don't show error to user for automatic location, just log it
    }
  }

  // Load user data from API
  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      final result = await UserApiService.getUserProfile();
      
      if (result['success'] && result['data'] != null) {
        setState(() {
          _currentUser = result['data'] as User;
          _isLoadingUser = false;
        });
        
        print('DEBUG: User data loaded - Name: ${_currentUser!.fullName}, Email: ${_currentUser!.email}');
      } else {
        setState(() {
          _isLoadingUser = false;
        });
        
        print('DEBUG: Failed to load user data: ${result['message']}');
        
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal mengambil data user'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
      
      print('DEBUG: Exception loading user data: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if user is authenticated
  Future<bool> _checkAuthentication() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _voucherController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadShippingMethods() async {
    try {
      final result = await ShippingApiService.getShippingMethods();
      
      if (result['success'] && mounted) {
        final methods = result['data'] as List<dynamic>;
        setState(() {
          _shippingOptions = methods.map((method) => {
            'title': method['name'] ?? '',
            'subtitle': method['description'] ?? '',
            'price': _parsePrice(method['price']),
            'icon': _getIconFromString(method['icon'] ?? 'local_shipping'),
          }).toList();
        });
        
        // Set default selection to first shipping method if available
        if (_shippingOptions.isNotEmpty) {
          setState(() {
            _selectedShipping = _shippingOptions.first['title'];
          });
        }
      } else {
        // Use default shipping methods if API fails
        setState(() {
          _shippingOptions = ShippingApiService.getDefaultShippingMethods()
              .map((method) => {
                'title': method['name'] ?? '',
                'subtitle': method['description'] ?? '',
                'price': _parsePrice(method['price']),
                'icon': _getIconFromString(method['icon'] ?? 'local_shipping'),
              }).toList();
        });
      }
    } catch (e) {
      print('Error loading shipping methods: $e');
      // Use default shipping methods as fallback
      if (mounted) {
        setState(() {
          _shippingOptions = ShippingApiService.getDefaultShippingMethods()
              .map((method) => {
                'title': method['name'] ?? '',
                'subtitle': method['description'] ?? '',
                'price': _parsePrice(method['price']),
                'icon': _getIconFromString(method['icon'] ?? 'local_shipping'),
              }).toList();
        });
      }
    }
  }
  
  int _parsePrice(dynamic price) {
    if (price == null) return 0;
    if (price is int) return price;
    if (price is double) return price.round();
    if (price is String) {
      final parsed = double.tryParse(price);
      return parsed?.round() ?? 0;
    }
    return 0;
  }
  
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'local_shipping':
        return Icons.local_shipping;
      case 'speed':
        return Icons.speed;
      case 'card_giftcard':
        return Icons.card_giftcard;
      default:
        return Icons.local_shipping;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Summary Section
                        _buildOrderSummary(cartService),
                        const SizedBox(height: 16),
                        
                        // Customer Information Section
                        _buildCustomerInformationForm(),
                        const SizedBox(height: 16),
                        
                        // Shipping Options Section
                        _buildShippingOptions(),
                        const SizedBox(height: 16),
                        
                        // Payment Method Section
                        _buildPaymentMethods(),
                        const SizedBox(height: 16),
                        
                        // Voucher Section
                        _buildVoucherSection(cartService),
                        const SizedBox(height: 16),
                        
                        // Price Breakdown Section
                        _buildPriceBreakdown(cartService),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom Section with Total and Place Order Button
              _buildBottomSection(cartService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Keranjang Kosong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan produk ke keranjang\nuntuk melakukan pemesanan',
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

  Widget _buildCustomerInformationForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Informasi Pengiriman',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // User info section (read-only)
            if (_isLoadingUser) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (_currentUser != null) ...[
              // Name field (read-only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama Lengkap',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser!.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Email field (read-only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser!.email,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nama dan email diambil dari akun yang sedang login',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Error state
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gagal memuat data user',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Silakan refresh halaman atau login ulang',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _loadUserData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Phone field
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon *',
                hintText: 'Contoh: 081234567890',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor telepon wajib diisi';
                }
                if (value.length < 10) {
                  return 'Nomor telepon minimal 10 digit';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Address field
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alamat Lengkap *',
                hintText: 'Jl. Nama Jalan No. XX, Kelurahan, Kecamatan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat lengkap wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // City and Postal Code row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Kota *',
                      hintText: 'Jakarta',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kota wajib diisi';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _postalCodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kode Pos *',
                      hintText: '12345',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kode pos wajib diisi';
                      }
                      if (value.length != 5) {
                        return 'Kode pos harus 5 digit';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Notes field (optional)
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Tambahkan catatan khusus untuk pesanan ini...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 16),
            
            // Location Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _latitude != null && _longitude != null 
                    ? Colors.green.shade50 
                    : Colors.orange.shade50,
                border: Border.all(
                  color: _latitude != null && _longitude != null 
                      ? Colors.green.shade300 
                      : Colors.orange.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _latitude != null && _longitude != null 
                            ? Icons.location_on 
                            : Icons.location_off,
                        color: _latitude != null && _longitude != null 
                            ? Colors.green 
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _latitude != null && _longitude != null 
                              ? 'Lokasi Terdeteksi' 
                              : 'Lokasi Otomatis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _latitude != null && _longitude != null 
                                ? Colors.green.shade700 
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                      if (_isLocationLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_latitude != null && _longitude != null) ...[
                    Text(
                      _locationAddress ?? 'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (_locationAccuracy != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Akurasi: ${_locationAccuracy!.toStringAsFixed(0)}m',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      _isLocationLoading 
                          ? 'Sedang mengambil lokasi perangkat...' 
                          : 'Lokasi akan diambil otomatis saat checkout',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Manual Location Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _getCurrentLocation,
                      icon: _isLocationLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_isLocationLoading 
                          ? 'Mengambil Lokasi...' 
                          : 'Perbarui Lokasi Saat Ini'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Warehouse & Delivery Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warehouse, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        WarehouseConfig.warehouseName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    WarehouseConfig.fullAddress,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (_latitude != null && _longitude != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.local_shipping, size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Estimasi: ${WarehouseConfig.getEstimatedDeliveryTime(_latitude!, _longitude!)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.route, size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Jarak: ${WarehouseConfig.getDistanceFromWarehouse(_latitude!, _longitude!).toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLocationLoading = true;
      });
      
      final position = await LocationService.getCurrentPosition();
      
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationAccuracy = position.accuracy;
          _locationAddress = LocationService.formatLocationAddress(
            position, 
            _addressController.text.trim().isEmpty 
                ? 'Lokasi saat ini' 
                : _addressController.text.trim()
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Lokasi berhasil diperbarui'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal mengambil lokasi. Pastikan GPS aktif.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }
  
  Widget _buildOrderSummary(CartService cartService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Items Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${cartService.totalItems} item${cartService.totalItems > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(cartService.items.map((item) => _buildOrderItem(item, cartService)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItem item, CartService cartService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Product Image/Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: item.backgroundColor ?? Colors.grey.shade100,
            ),
            child: item.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        item.icon ?? Icons.fastfood,
                        color: item.iconColor ?? Colors.grey,
                        size: 24,
                      ),
                    ),
                  )
                : Icon(
                    item.icon ?? Icons.fastfood,
                    color: item.iconColor ?? Colors.grey,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 12),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} ${item.unit} × Rp ${_formatCurrency(item.price)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onPressed: () => cartService.decreaseQuantity(item.productId),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onPressed: () => cartService.increaseQuantity(item.productId),
              ),
            ],
          ),
          
          const SizedBox(width: 8),
          
          // Total Price
          Text(
            'Rp ${_formatCurrency(item.totalPrice)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildShippingOptions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Pilihan Pengiriman',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_shippingOptions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ..._shippingOptions.map((option) => _buildShippingOption(option)),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingOption(Map<String, dynamic> option) {
    final isSelected = _selectedShipping == option['title'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedShipping = option['title']),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.orange.shade50 : null,
          ),
          child: Row(
            children: [
              Icon(
                option['icon'],
                color: isSelected ? Colors.orange : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.orange : Colors.black87,
                      ),
                    ),
                    Text(
                      option['subtitle'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                option['price'] == 0 
                    ? 'Gratis' 
                    : 'Rp ${_formatCurrency(option['price'])}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.orange : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Radio<String>(
                value: option['title'],
                groupValue: _selectedShipping,
                onChanged: (value) => setState(() => _selectedShipping = value!),
                activeColor: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._paymentMethods.map((method) => _buildPaymentMethod(method)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(Map<String, dynamic> method) {
    final isSelected = _selectedPayment == method['title'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedPayment = method['title']),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.orange.shade50 : null,
          ),
          child: Row(
            children: [
              Icon(
                method['icon'],
                color: isSelected ? Colors.orange : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.orange : Colors.black87,
                      ),
                    ),
                    Text(
                      method['subtitle'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: method['title'],
                groupValue: _selectedPayment,
                onChanged: (value) => setState(() => _selectedPayment = value!),
                activeColor: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherSection(CartService cartService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_offer, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Masukkan Voucher',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _voucherController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kode voucher',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.orange),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _applyVoucher(cartService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Terapkan'),
                ),
              ],
            ),
            if (_isVoucherApplied) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Voucher berhasil diterapkan!',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '- Rp ${_formatCurrency(_discountAmount)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(CartService cartService) {
    final subtotal = cartService.totalPrice;
    final shippingCost = _getSelectedShippingCost();
    final tax = 0; // Tax removed for pengecer role
    final discount = _discountAmount;
    final total = subtotal + shippingCost + tax - discount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rincian Harga',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Subtotal', subtotal),
            _buildPriceRow('Ongkos Kirim', shippingCost),
            if (discount > 0) _buildPriceRow('Diskon', -discount, isDiscount: true),
            const Divider(height: 20),
            _buildPriceRow('Total', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}Rp ${_formatCurrency(amount.abs())}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal 
                  ? Colors.orange 
                  : isDiscount 
                      ? Colors.green 
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(CartService cartService) {
    final total = _calculateFinalTotal(cartService);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Rp ${_formatCurrency(total)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _placeOrder(cartService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                child: _isLoading 
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Memproses...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyVoucher(CartService cartService) async {
    final voucherCode = _voucherController.text.trim();
    
    if (voucherCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan kode voucher terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await VoucherApiService.validateVoucher(
        voucherCode: voucherCode,
        orderAmount: cartService.totalPrice.toDouble(),
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        final voucherData = result['data'];
        setState(() {
          _isVoucherApplied = true;
          // Apply discount based on voucher type
          if (voucherData['discount_type'] == 'percentage') {
            final percentage = (voucherData['discount_value'] ?? 0).toDouble();
            _discountAmount = (cartService.totalPrice * (percentage / 100)).round();
          } else if (voucherData['discount_type'] == 'fixed') {
            _discountAmount = (voucherData['discount_value'] ?? 0).toInt();
          } else if (voucherData['discount_type'] == 'free_shipping') {
            _discountAmount = _getSelectedShippingCost();
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Voucher berhasil diterapkan!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Kode voucher tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _getSelectedShippingCost() {
    if (_shippingOptions.isEmpty) return 0;
    
    final selectedOption = _shippingOptions.firstWhere(
      (option) => option['title'] == _selectedShipping,
      orElse: () => _shippingOptions.first,
    );
    return selectedOption['price'] ?? 0;
  }

  int _calculateFinalTotal(CartService cartService) {
    final subtotal = cartService.totalPrice;
    final shippingCost = _getSelectedShippingCost();
    final tax = 0; // Tax removed for pengecer role
    final discount = _discountAmount;
    return subtotal + shippingCost + tax - discount;
  }

  void _placeOrder(CartService cartService) {
    // Show order confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pesanan'),
        content: Text(
          'Yakin ingin memesan ${cartService.totalItems} item dengan total Rp ${_formatCurrency(_calculateFinalTotal(cartService))}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processOrder(cartService);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Pesan'),
          ),
        ],
      ),
    );
  }

  void _processOrder(CartService cartService) async {
    // Check authentication first
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Login Diperlukan'),
            ],
          ),
          content: const Text(
            'Anda harus login terlebih dahulu untuk melakukan pemesanan.'
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
      return;
    }
    
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua data yang diperlukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Debug cart contents first
      print('DEBUG: Cart contents before creating order:');
      for (int i = 0; i < cartService.items.length; i++) {
        final item = cartService.items[i];
        print('  Item $i: ID=${item.productId}, Name="${item.name}", Category="${item.category}", Qty=${item.quantity}');
      }
      
      // Prepare order items
      final orderItems = cartService.items.map((cartItem) => {
        'product_id': cartItem.productId,
        'incoming_item_id': cartItem.productId, // Use same ID as product_id to match backend validation
        'quantity': cartItem.quantity,
        'unit': cartItem.unit,
        'notes': 'Order dari ${cartItem.name}',
      }).toList();
      
      print('DEBUG: Prepared order items:');
      for (int i = 0; i < orderItems.length; i++) {
        final orderItem = orderItems[i];
        print('  Order Item $i: product_id=${orderItem['product_id']}, incoming_item_id=${orderItem['incoming_item_id']}, notes="${orderItem['notes']}"');
        print('  Full JSON: ${json.encode(orderItem)}');
      }
      
      // Validate user data is loaded
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data user belum dimuat. Mohon tunggu atau refresh halaman.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Update location address if empty
      if (_locationAddress?.isEmpty ?? true) {
        _locationAddress = '${_addressController.text}, ${_cityController.text}';
      }
      
      // IMPORTANT: Update koordinat real-time sebelum membuat order
      try {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationAccuracy = position.accuracy;
          _locationAddress = LocationService.formatLocationAddress(
            position, 
            _addressController.text.trim().isEmpty 
                ? '${_addressController.text}, ${_cityController.text}' 
                : _addressController.text.trim()
          );
          print('DEBUG: Real-time location updated before order: Lat=${_latitude}, Lng=${_longitude}, Accuracy=${_locationAccuracy}m');
        } else {
          print('DEBUG: Could not update location before order, using existing coordinates');
        }
      } catch (e) {
        print('DEBUG: Error updating location before order: $e');
        // Continue with existing coordinates if location update fails
      }
      
      // Ensure we have valid coordinates before creating order
      final double finalLatitude = _latitude ?? WarehouseConfig.latitude; // Default UD Keluarga Sehati Warehouse - Pekanbaru if null
      final double finalLongitude = _longitude ?? WarehouseConfig.longitude; // Default UD Keluarga Sehati Warehouse - Pekanbaru if null
      final String finalLocationAddress = _locationAddress ?? '${_addressController.text}, ${_cityController.text}';
      final double finalLocationAccuracy = _locationAccuracy ?? 5.0;
      
      // Create order through API
      final result = await OrderApiService.createOrder(
        pengecerName: _currentUser!.fullName,
        pengecerPhone: _phoneController.text.trim(),
        pengecerEmail: _currentUser!.email,
        shippingAddress: _addressController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        latitude: finalLatitude,
        longitude: finalLongitude,
        locationAddress: finalLocationAddress,
        locationAccuracy: finalLocationAccuracy,
        items: orderItems,
        shippingMethod: _selectedShipping,
        paymentMethod: _selectedPayment,
        voucherCode: _isVoucherApplied ? _voucherController.text.trim() : null,
        notes: _notesController.text.trim(),
      );
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        final orderData = result['data'];
        final orderNumber = orderData['order_number'];
        
        // Check for product mismatch (backend bug detection)
        bool hasProductMismatch = false;
        final orderItems = orderData['order_items'] as List<dynamic>? ?? [];
        for (int i = 0; i < orderItems.length && i < cartService.items.length; i++) {
          final orderItem = orderItems[i];
          final cartItem = cartService.items[i];
          final apiProductName = orderItem['product_name'] ?? '';
          final cartProductName = cartItem.name;
          
          if (apiProductName != cartProductName) {
            hasProductMismatch = true;
            print('PRODUCT MISMATCH DETECTED!');
            print('  Expected: $cartProductName (ID: ${cartItem.productId})');
            print('  Got from API: $apiProductName (ID: ${orderItem['product_id']})');
          }
        }
        
        // Clear cart on successful order
        cartService.clearCart();
        
        // Show success message
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: hasProductMismatch ? Colors.orange : Colors.green),
                  const SizedBox(width: 8),
                  Text(hasProductMismatch ? 'Pesanan Berhasil (Peringatan)' : 'Pesanan Berhasil!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nomor Pesanan: $orderNumber'),
                  const SizedBox(height: 8),
                  Text('Total: Rp ${_formatCurrency(_parsePrice(orderData['total_amount']))}'),
                  const SizedBox(height: 8),
                  if (hasProductMismatch) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange.shade600, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Peringatan: Ketidakcocokan Produk',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ada ketidakcocokan produk dalam pesanan. Silakan hubungi customer service untuk konfirmasi.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text('Pesanan Anda sedang diproses dan akan segera dikirim.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to dashboard
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // Show error message with special handling for authentication errors
        final errorMessage = result['message'] ?? 'Gagal membuat pesanan';
        
        if (mounted) {
          if (errorMessage.toLowerCase().contains('authentication') || 
              errorMessage.toLowerCase().contains('login') ||
              errorMessage.toLowerCase().contains('token')) {
            // Show authentication error dialog
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
                  'Sesi login Anda telah berakhir. Silakan login kembali untuk melanjutkan.'
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
          } else {
            // Show regular error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}