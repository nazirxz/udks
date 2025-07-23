import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/dashboard_utils.dart';
import '../services/cart_service.dart';
import '../services/products_api_service.dart';
import '../widgets/cart_badge_widget.dart';
import '../screens/checkout_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/returnable_items_screen.dart';
import '../screens/return_history_screen.dart';

class PengecerDashboard extends StatefulWidget {
  final User user;

  const PengecerDashboard({super.key, required this.user});

  @override
  State<PengecerDashboard> createState() => _PengecerDashboardState();
}

class _PengecerDashboardState extends State<PengecerDashboard> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<String> _categories = ['Semua'];
  String _selectedCategory = 'Semua';
  int _selectedIndex = 0; // Untuk bottom navigation
  int _returnTabIndex = 0; // 0: Form Retur, 1: Riwayat Retur
  
  // Loading states
  bool _isLoadingProducts = true;
  String _errorMessage = '';
  
  // Form controllers untuk halaman return - akan dihapus karena menggunakan API baru
  final _namaController = TextEditingController();
  final _namaDistributorController = TextEditingController();
  final _emailController = TextEditingController();
  final _nomorTeleponController = TextEditingController();
  final _kodePoController = TextEditingController();
  final _ruasController = TextEditingController();
  final _keteranganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _namaController.dispose();
    _namaDistributorController.dispose();
    _emailController.dispose();
    _nomorTeleponController.dispose();
    _kodePoController.dispose();
    _ruasController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _initializeProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _errorMessage = '';
    });

    try {
      print('DEBUG: Starting to load products...');
      
      // Test API connection first
      final testResult = await ProductsApiService.testApiConnection();
      print('DEBUG: API test result: $testResult');
      
      if (!testResult['success']) {
        setState(() {
          _errorMessage = 'API connection failed: ${testResult['message']}';
          _isLoadingProducts = false;
        });
        return;
      }

      // Load products and categories
      final productsResult = await ProductsApiService.getProducts(perPage: 100);
      final categoriesResult = await ProductsApiService.getCategories();

      setState(() {
        if (productsResult['success']) {
          final List<dynamic> apiProducts = productsResult['data'] ?? [];
          _allProducts = apiProducts.map((product) {
            // Debug image URL
            final rawImageUrl = product['foto_barang'];
            final authenticatedImageUrl = ProductsApiService.getAuthenticatedImageUrl(rawImageUrl);
            print('DEBUG: Product ${product['nama_barang']}:');
            print('  Raw image URL: $rawImageUrl');
            print('  Authenticated image URL: $authenticatedImageUrl');
            
            return {
              'id': product['id'],
              'name': product['nama_barang'],
              'category': product['kategori_barang'],
              'price': product['harga_jual'] ?? 0,
              'image': authenticatedImageUrl,
              'stock': product['jumlah_barang'],
              'unit': 'pcs',
              // Keep icon and colors for UI consistency
              'icon': _getIconForCategory(product['kategori_barang']),
              'iconColor': _getColorForCategory(product['kategori_barang']),
              'backgroundColor': _getBackgroundColorForCategory(product['kategori_barang']),
            };
          }).cast<Map<String, dynamic>>().toList();

          _filteredProducts = List.from(_allProducts);
          print('DEBUG: Products loaded: ${_allProducts.length} items');
        } else {
          _errorMessage = productsResult['message'];
          print('DEBUG: Failed to load products: ${productsResult['message']}');
        }

        if (categoriesResult['success']) {
          final apiCategories = List<String>.from(categoriesResult['data']);
          _categories = ['Semua', ...apiCategories];
          print('DEBUG: Categories loaded: $_categories');
        }

        _isLoadingProducts = false;
      });
    } catch (e) {
      print('DEBUG: Exception in _initializeProducts: $e');
      setState(() {
        _errorMessage = 'Error loading products: $e';
        _isLoadingProducts = false;
      });
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'makanan ringan':
        return Icons.fastfood;
      case 'minuman ringan':
        return Icons.local_drink;
      case 'minyak goreng':
        return Icons.water_drop;
      case 'beras':
        return Icons.grain;
      case 'gula':
        return Icons.apps;
      case 'tepung':
        return Icons.bakery_dining;
      default:
        return Icons.inventory;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'makanan ringan':
        return Colors.orange;
      case 'minuman ringan':
        return Colors.blue;
      case 'minyak goreng':
        return Colors.amber;
      case 'beras':
        return Colors.brown;
      case 'gula':
        return Colors.grey.shade700;
      case 'tepung':
        return Colors.deepOrange;
      default:
        return Colors.teal;
    }
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrl = product['image'];
    
    // If no image URL or empty, show icon directly
    if (imageUrl == null || imageUrl.toString().isEmpty) {
      return Center(
        child: Icon(
          product['icon'] ?? Icons.inventory,
          size: 40,
          color: product['iconColor'] ?? Colors.grey,
        ),
      );
    }

    return FutureBuilder<String?>(
      future: _getAuthToken(),
      builder: (context, snapshot) {
        final token = snapshot.data;
        final headers = <String, String>{
          'User-Agent': 'UDKeluargaSehati Mobile App',
          'Accept': 'image/*,*/*;q=0.8',
        };
        
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }

        return Image.network(
          imageUrl.toString(),
          fit: BoxFit.cover,
          headers: headers,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                color: product['iconColor'] ?? Colors.orange,
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('DEBUG: Failed to load image $imageUrl - Error: $error');
            
            // Check if it's a forbidden error
            if (error.toString().contains('403') || error.toString().contains('Forbidden')) {
              print('DEBUG: Image forbidden - URL may require authentication: $imageUrl');
            }
            
            return Container(
              color: product['backgroundColor'] ?? Colors.grey.shade100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    product['icon'] ?? Icons.inventory,
                    size: 40,
                    color: product['iconColor'] ?? Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No Image',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Color _getBackgroundColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'makanan ringan':
        return Colors.orange.shade50;
      case 'minuman ringan':
        return Colors.blue.shade50;
      case 'minyak goreng':
        return Colors.amber.shade50;
      case 'beras':
        return Colors.brown.shade50;
      case 'gula':
        return Colors.grey.shade50;
      case 'tepung':
        return Colors.deepOrange.shade50;
      default:
        return Colors.teal.shade50;
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts.where((product) {
          final categoryMatch = _selectedCategory == 'Semua' || product['category'] == _selectedCategory;
          return categoryMatch;
        }).toList();
      } else {
        _filteredProducts = _allProducts.where((product) {
          final nameMatch = (product['name'] ?? '').toLowerCase().contains(query.toLowerCase());
          final categoryMatch = _selectedCategory == 'Semua' || product['category'] == _selectedCategory;
          return nameMatch && categoryMatch;
        }).toList();
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts(_searchController.text);
  }

  List<String> _getCategories() {
    // Use categories loaded from API if available, otherwise return default
    return _categories.isNotEmpty ? _categories : ['Semua'];
  }

  void _goToCheckout() {
    final cartService = Provider.of<CartService>(context, listen: false);
    if (cartService.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang masih kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Dashboard Pengecer' : 'Data Retur Barang'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          DashboardUtils.buildUserInfoBadge(widget.user),
          if (_selectedIndex == 0) // Show in penjualan page
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                );
              },
              tooltip: 'Riwayat Pesanan',
            ),
          if (_selectedIndex == 0) // Only show cart in penjualan page
            Consumer<CartService>(
              builder: (context, cartService, child) {
                return AppBarCartBadge(
                  itemCount: cartService.totalItems,
                  onPressed: _goToCheckout,
                  iconColor: Colors.white,
                  badgeColor: Colors.red,
                );
              },
            ),
          DashboardUtils.buildPopupMenu(
            context, 
            widget.user, 
            (value) => DashboardUtils.handleMenuSelection(context, value, widget.user),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildPenjualanPage() : _buildReturnPage(),
      bottomNavigationBar: _selectedIndex == 1 ? _buildReturnTabBar() : _buildMainBottomNavBar(),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: _goToCheckout,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_cart),
        label: Consumer<CartService>(
          builder: (context, cartService, child) {
            return Text('Checkout (${cartService.totalItems})');
          },
        ),
              ) : null,
    );
  }

  Widget _buildMainBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
          if (index == 1) {
            _returnTabIndex = 0; // Reset ke tab form saat masuk ke halaman return
          } else if (index == 2) {
            // Navigate to Order History Screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
            );
          }
        });
      },
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Penjualan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_return),
          label: 'Return',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Riwayat',
        ),
      ],
    );
  }

  Widget _buildReturnTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
            icon: const Icon(Icons.arrow_back),
            color: Colors.grey.shade600,
          ),
          // Tab buttons
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _returnTabIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _returnTabIndex == 0 ? Colors.orange : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Form Retur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _returnTabIndex == 0 ? Colors.orange : Colors.grey.shade600,
                          fontWeight: _returnTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _returnTabIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _returnTabIndex == 1 ? Colors.orange : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Riwayat Retur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _returnTabIndex == 1 ? Colors.orange : Colors.grey.shade600,
                          fontWeight: _returnTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenjualanPage() {
    return Column(
      children: [
        // Compact Header Card
        Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Selamat datang, ${widget.user.fullName}!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih produk untuk dijual kepada pelanggan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Search and Filter Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _filterProducts,
              ),
              const SizedBox(height: 12),
              
              // Category Filter
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _getCategories().length,
                  itemBuilder: (context, index) {
                    final category = _getCategories()[index];
                    final isSelected = _selectedCategory == category;
                    
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => _filterByCategory(category),
                        selectedColor: Colors.orange.shade100,
                        checkmarkColor: Colors.orange,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.orange : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Products Grid
        Expanded(
          child: _isLoadingProducts
            ? _buildLoadingState()
            : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _filteredProducts.isEmpty 
                ? _buildEmptyState() 
                : _buildProductsGrid(),
        ),
      ],
    );
  }

  Widget _buildReturnPage() {
    return _returnTabIndex == 0 ? _buildReturnHome() : const ReturnHistoryScreen();
  }

  Widget _buildReturnHome() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Return Barang',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola pengembalian barang pesanan Anda',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          // Card untuk Return Baru
          Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReturnableItemsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.assignment_return,
                        size: 32,
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Return Barang Baru',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pilih barang yang ingin di-return dari pesanan selesai',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Card untuk History Return
          Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                setState(() {
                  _returnTabIndex = 1;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.history,
                        size: 32,
                        color: Colors.green[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'History Return',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lihat riwayat dan status return barang',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Penting',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Hanya pesanan dengan status "completed" yang bisa di-return\n• Return harus dilakukan dengan foto bukti\n• Proses review return maksimal 3 hari kerja',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: product['backgroundColor'] ?? Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildProductImage(product),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Product Info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Produk',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${product['price']?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Stok: ${product['stock']} ${product['unit'] ?? 'pcs'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Produk tidak ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci pencarian\natau pilih kategori lain',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          Text(
            'Loading products...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _initializeProducts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(Map<String, dynamic> product) {
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: product['backgroundColor'] ?? Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['image'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            product['icon'] ?? Icons.fastfood,
                            size: 40,
                            color: product['iconColor'] ?? Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Produk',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${product['price']?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stok: ${product['stock']} ${product['unit'] ?? 'pcs'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Provider.of<CartService>(context, listen: false).addProductToCart(product);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product['name']} ditambahkan ke keranjang'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tambah'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}