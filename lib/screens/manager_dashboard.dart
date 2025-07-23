// lib/screens/manager_dashboard.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/dashboard_api_service.dart';
import '../utils/dashboard_utils.dart';
import '../widgets/manager_sales_page_widget.dart';
import '../widgets/manager_purchase_page_widget.dart';
import '../widgets/manager_return_page_widget.dart';

class ManagerDashboard extends StatefulWidget {
  final User user;

  const ManagerDashboard({Key? key, required this.user}) : super(key: key);

  @override
  _ManagerDashboardState createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic> dashboardStats = {};
  List<Map<String, dynamic>> weeklyData = [];
  List<Map<String, dynamic>> lowStockItems = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('Loading dashboard data...');
      // Use the complete dashboard endpoint for efficiency
      final result = await DashboardApiService.getCompleteDashboard();
      
      print('Complete dashboard result: $result');
      
      if (result['success']) {
        final data = result['data'];
        print('Complete dashboard data: $data');
        setState(() {
          // Handle the actual API response structure
          dashboardStats = data['statistics'] ?? {};
          print('Dashboard stats from complete API: $dashboardStats');
          // For weekly data, we need to use individual API since complete doesn't have it
          weeklyData = []; // Will be loaded separately
          // Handle low stock items from the nested structure
          final lowStockData = data['low_stock_warning'];
          if (lowStockData != null && lowStockData['items'] != null) {
            lowStockItems = List<Map<String, dynamic>>.from(lowStockData['items']);
          } else {
            lowStockItems = [];
          }
          isLoading = false;
        });
        
        // Load additional stats that are missing from complete endpoint
        _loadAdditionalStats();
        // Load weekly stats separately since it's not in complete endpoint
        _loadWeeklyStatsOnly();
      } else {
        print('Complete dashboard failed, trying individual APIs...');
        // Fallback to individual API calls if complete endpoint fails
        await _loadIndividualData();
      }
    } catch (e) {
      print('Error loading complete dashboard: $e');
      // Fallback to individual API calls
      await _loadIndividualData();
    }
  }

  Future<void> _loadIndividualData() async {
    try {
      print('Loading individual dashboard data...');
      
      // First test API connection
      final testResult = await DashboardApiService.testApiConnection();
      print('Test API result: $testResult');
      
      // Load dashboard stats
      final statsResult = await DashboardApiService.getDashboardStats();
      print('Stats result: $statsResult');
      
      // Load weekly stats
      final weeklyResult = await DashboardApiService.getWeeklyStats();
      print('Weekly result: $weeklyResult');
      
      // Load low stock items
      final lowStockResult = await DashboardApiService.getLowStockWarning();
      print('Low stock result: $lowStockResult');

      setState(() {
        if (statsResult['success']) {
          dashboardStats = statsResult['data'] ?? {};
          print('Dashboard stats set: $dashboardStats');
        } else {
          print('Stats API failed: ${statsResult['message']}');
        }
        
        if (weeklyResult['success']) {
          weeklyData = _transformWeeklyData(weeklyResult['data']);
          print('Weekly data set: $weeklyData');
        } else {
          print('Weekly API failed: ${weeklyResult['message']}');
        }
        
        if (lowStockResult['success']) {
          lowStockItems = List<Map<String, dynamic>>.from(lowStockResult['data'] ?? []);
          print('Low stock items set: $lowStockItems');
        } else {
          print('Low stock API failed: ${lowStockResult['message']}');
        }
        
        isLoading = false;
      });
    } catch (e) {
      print('Exception in _loadIndividualData: $e');
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadWeeklyStatsOnly() async {
    try {
      print('Loading weekly stats only...');
      final weeklyResult = await DashboardApiService.getWeeklyStats();
      print('Weekly stats result: $weeklyResult');
      
      if (weeklyResult['success']) {
        final rawData = weeklyResult['data'];
        print('Raw weekly data from API: $rawData');
        
        setState(() {
          weeklyData = _transformWeeklyData(rawData);
          print('Transformed weekly data: $weeklyData');
        });
      } else {
        print('Weekly stats API failed: ${weeklyResult['message']}');
      }
    } catch (e) {
      print('Error loading weekly stats: $e');
    }
  }

  Future<void> _loadAdditionalStats() async {
    try {
      print('Loading additional stats from individual endpoint...');
      final statsResult = await DashboardApiService.getDashboardStats();
      print('Individual stats result: $statsResult');
      
      if (statsResult['success']) {
        final additionalStats = statsResult['data'] ?? {};
        print('Additional stats data: $additionalStats');
        
        setState(() {
          // Merge additional stats with existing ones
          dashboardStats.addAll(additionalStats);
          print('Merged dashboard stats: $dashboardStats');
        });
      }
    } catch (e) {
      print('Error loading additional stats: $e');
    }
  }

  // Helper function to safely convert to double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  List<Map<String, dynamic>> _transformWeeklyData(Map<String, dynamic>? weeklyStats) {
    print('Transforming weekly data: $weeklyStats');
    
    if (weeklyStats == null) {
      print('Weekly stats is null, returning empty list');
      return [];
    }
    
    final labels = weeklyStats['labels'] as List<dynamic>? ?? [];
    final dataSection = weeklyStats['data'] as Map<String, dynamic>?;
    final barangMasuk = dataSection?['barang_masuk'] as List<dynamic>? ?? [];
    final barangKeluar = dataSection?['barang_keluar'] as List<dynamic>? ?? [];
    
    print('Labels: $labels');
    print('Barang masuk: $barangMasuk'); 
    print('Barang keluar: $barangKeluar');
    
    List<Map<String, dynamic>> transformedData = [];
    
    for (int i = 0; i < labels.length; i++) {
      final incomingValue = i < barangMasuk.length ? _safeToDouble(barangMasuk[i]) : 0.0;
      final outgoingValue = i < barangKeluar.length ? _safeToDouble(barangKeluar[i]) : 0.0;
      
      final dayData = {
        'day': labels[i],
        'incoming': incomingValue,
        'outgoing': outgoingValue,
      };
      transformedData.add(dayData);
      print('Day $i: $dayData');
    }
    
    print('Final transformed data: $transformedData');
    return transformedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Manager'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          DashboardUtils.buildUserInfoBadge(widget.user),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => DashboardUtils.showSnackBar(context, 'Notifikasi'),
          ),
          DashboardUtils.buildPopupMenu(
            context, 
            widget.user, 
            (value) => DashboardUtils.handleMenuSelection(context, value, widget.user),
          ),
        ],
      ),
      body: isLoading ? _buildLoadingWidget() : _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildLoadingWidget() {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.purple,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Penjualan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Pembelian',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_return),
          label: 'Return',
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildBerandaPage();
      case 1:
        return const ManagerSalesPageWidget();
      case 2:
        return const ManagerPurchasePageWidget();
      case 3:
        return const ManagerReturnPageWidget();
      default:
        return _buildBerandaPage();
    }
  }

  Widget _buildBerandaPage() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            
            // Statistics Cards
            _buildStatisticsCards(),
            const SizedBox(height: 20),
            
            // Weekly Chart
            _buildWeeklyChart(),
            const SizedBox(height: 20),
            
            // Recent Transactions
            _buildRecentTransactions(),
            const SizedBox(height: 20),
            
            // Inventory Alerts
            _buildInventoryAlerts(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Text(
                widget.user.fullName[0],
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang, ${widget.user.fullName}!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Role: ${widget.user.role.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Hari Ini',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Barang Masuk',
                '${dashboardStats['barang_masuk_hari_ini'] ?? 0}',
                Icons.arrow_downward,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Barang Keluar',
                '${dashboardStats['barang_keluar_hari_ini'] ?? 0}',
                Icons.arrow_upward,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Transaksi Penjualan',
                '${dashboardStats['transaksi_penjualan_hari_ini'] ?? 0}',
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Transaksi Pembelian',
                '${dashboardStats['transaksi_pembelian_hari_ini'] ?? 0}',
                Icons.shopping_bag,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Barang Masuk/Keluar Mingguan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: _buildSimpleBarChart(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Barang Masuk', Colors.green),
                const SizedBox(width: 20),
                _buildLegendItem('Barang Keluar', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBarChart() {
    if (weeklyData.isEmpty) {
      return const Center(child: Text('Tidak ada data mingguan'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final itemCount = weeklyData.length;
        final itemWidth = (availableWidth - 32) / itemCount; // 32 for padding
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: weeklyData.map((data) {
            final masuk = _safeToDouble(data['incoming']);
            final keluar = _safeToDouble(data['outgoing']);
            final maxValue = 160.0;

            return SizedBox(
              width: itemWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Value labels at the top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (masuk > 0) ...[
                        Text(
                          '${masuk.toInt()}',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (keluar > 0)
                        Text(
                          '${keluar.toInt()}',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Bars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: (itemWidth * 0.3).clamp(8.0, 20.0),
                        height: (masuk / maxValue * 140).clamp(5.0, 140.0),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Container(
                        width: (itemWidth * 0.3).clamp(8.0, 20.0),
                        height: (keluar / maxValue * 140).clamp(5.0, 140.0),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Day label
                  Text(
                    '${data['day'] ?? ''}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    // Use recent activities from the API if available, otherwise use mock data
    List<Map<String, dynamic>> transactions = [];
    
    // This would be populated from the complete API response if we store it
    // For now, create some sample transactions based on API structure
    transactions = [
      {
        'type': 'barang_masuk',
        'nama_barang': 'Aqua', 
        'jumlah': 100,
        'tanggal': '2025-07-20'
      },
      {
        'type': 'barang_masuk',
        'nama_barang': 'Chitato',
        'jumlah': 50, 
        'tanggal': '2025-07-19'
      }
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () => DashboardUtils.showSnackBar(context, 'Lihat Semua Transaksi'),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              const Text(
                'Tidak ada aktivitas terbaru',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              )
            else
              ...transactions.take(3).map((transaction) {
                return _buildTransactionItem(transaction);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isMasuk = transaction['type'] == 'barang_masuk';
    final color = isMasuk ? Colors.green : Colors.orange;
    final icon = isMasuk ? Icons.arrow_downward : Icons.arrow_upward;
    final namaBarang = transaction['nama_barang'] ?? '';
    final jumlah = transaction['jumlah'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaBarang,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$jumlah unit • ${isMasuk ? 'Barang Masuk' : 'Barang Keluar'}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rp ${_formatCurrency(transaction['amount'] ?? 0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryAlerts() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Peringatan Stok',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lowStockItems.isEmpty)
              const Text(
                'Tidak ada item dengan stok rendah',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              )
            else
              ...lowStockItems.map((alert) {
                return _buildAlertItem(alert);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    // For the complete endpoint response, items don't have status_warning field
    // We'll determine criticality based on stock amount (less than 15 = critical)
    final stockAmount = alert['jumlah_barang'] ?? 0;
    final isCritical = stockAmount < 15;
    final color = isCritical ? Colors.red : Colors.orange;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.error : Icons.warning,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['nama_barang'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${alert['kategori_barang'] ?? ''} - Stok: ${alert['jumlah_barang'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCritical ? 'KRITIS' : 'RENDAH',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
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