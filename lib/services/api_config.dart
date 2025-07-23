// lib/services/api_config.dart

class ApiConfig {
  // Production API URL
  static const String _baseUrl = 'https://udkeluargasehati.com/api';
  
  static String get baseUrl => _baseUrl;
  
  // Debug info
  static void printDebugInfo() {
    print('=== API CONFIG DEBUG ===');
    print('Current base URL: $_baseUrl');
    print('========================');
  }
  
  // Method to get working base URL (akan dicoba satu per satu)
  static Future<String> getWorkingBaseUrl() async {
    printDebugInfo();
    return _baseUrl;
  }
  
  // Dashboard endpoints
  static String get dashboardStats => '$_baseUrl/dashboard/stats';
  static String get dashboardLowStock => '$_baseUrl/dashboard/low-stock';
  static String get dashboardWeeklyStats => '$_baseUrl/dashboard/weekly-stats';
  static String get dashboardMonthlyStats => '$_baseUrl/dashboard/monthly-stats';
  static String get dashboardComplete => '$_baseUrl/dashboard/complete';
  
  // Auth endpoints
  static String get login => '$_baseUrl/login';
  static String get register => '$_baseUrl/register';
  static String get logout => '$_baseUrl/logout';
  static String get user => '$_baseUrl/user';
  
  // Outgoing items endpoints
  static String get outgoingItems => '$_baseUrl/outgoing-items';
  static String get outgoingItemsCategories => '$_baseUrl/outgoing-items/categories';
  static String get outgoingItemsSearch => '$_baseUrl/outgoing-items/search';
  static String get outgoingItemsWeeklyStats => '$_baseUrl/outgoing-items/weekly-sales-stats';
  static String outgoingItemsByCategory(String category) => '$_baseUrl/outgoing-items/category/$category';
  static String outgoingItemDetail(int id) => '$_baseUrl/outgoing-items/$id';
  
  // Incoming items endpoints
  static String get incomingItems => '$_baseUrl/incoming-items';
  static String get incomingItemsCategories => '$_baseUrl/incoming-items/categories';
  static String get incomingItemsSearch => '$_baseUrl/incoming-items/search';
  static String get incomingItemsWeeklyStats => '$_baseUrl/incoming-items/weekly-incoming-stats';
  static String incomingItemsByCategory(String category) => '$_baseUrl/incoming-items/category/$category';
  static String incomingItemDetail(int id) => '$_baseUrl/incoming-items/$id';
  
  // Return items endpoints
  static String get returnItems => '$_baseUrl/return-items';
  static String get returnItemsCategories => '$_baseUrl/return-items/categories';
  static String get returnItemsSearch => '$_baseUrl/return-items/search';
  static String get returnItemsWeeklyStats => '$_baseUrl/return-items/weekly-return-stats';
  static String get returnableItems => '$_baseUrl/return-items/returnable-items';
  static String returnItemsByCategory(String category) => '$_baseUrl/return-items/category/$category';
  static String returnItemDetail(int id) => '$_baseUrl/return-items/$id';
  
  // Products endpoints
  static String get products => '$_baseUrl/products';
  static String get productsCategories => '$_baseUrl/products/categories';
  static String get productsSearch => '$_baseUrl/products/search';
  static String productsByCategory(String category) => '$_baseUrl/products/category/$category';
  static String productDetail(int id) => '$_baseUrl/products/$id';
  
  // Orders endpoints
  static String get orders => '$_baseUrl/orders';
  static String get salesOrders => '$_baseUrl/orders/sales';
  static String orderDetail(int id) => '$_baseUrl/orders/$id';
  static String orderShippingStatus(int id) => '$_baseUrl/orders/$id/shipping-status';
  
  // Vouchers endpoints
  static String get vouchers => '$_baseUrl/vouchers';
  static String get vouchersValidate => '$_baseUrl/vouchers/validate';
  
  // Shipping methods endpoints
  static String get shippingMethods => '$_baseUrl/shipping-methods';
}
