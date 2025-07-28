# Dokumentasi Views (Screens) - Aplikasi UD Keluarga Sehati

## Overview
Dokumentasi ini menjelaskan semua views/screens yang ada di folder `/lib/screens` beserta fungsi, API yang digunakan, dan fitur-fitur utamanya.

---

## 1. Authentication Screens

### 1.1 LoginScreen (`login_screen.dart`)
**Lokasi:** `lib/screens/login_screen.dart:6`

**Fungsi:** 
Halaman login utama aplikasi dengan auto-login dan role-based navigation

**API yang digunakan:**
- `AuthService.login()` - Login user dengan email/password
- `AuthService.getUserFromApi()` - Mendapatkan data user setelah login

**Fitur Utama:**
- ✅ Auto-login jika user sudah login sebelumnya
- ✅ Validasi form email dan password
- ✅ Navigasi berdasarkan role user (admin, sales, pengecer, manager)
- ✅ Link ke halaman register dan forgot password
- ✅ Verifikasi OTP jika email belum diverifikasi
- ✅ Responsive design dengan gradient background

**Code Example:**
```dart
// Auto-login check
final user = await _authService.getUserFromApi();
if (user != null && mounted) {
  _navigateToUserDashboard(user);
}

// Role-based navigation
switch (user.role.toLowerCase()) {
  case 'admin': destination = AdminDashboard(user: user); break;
  case 'sales': destination = SalesDashboard(user: user); break;
  case 'pengecer': destination = PengecerDashboard(user: user); break;
  case 'manager': destination = ManagerDashboard(user: user); break;
}
```

---

### 1.2 RegisterScreen (`register_screen.dart`)
**Lokasi:** `lib/screens/register_screen.dart:5`

**Fungsi:** 
Halaman registrasi user baru dengan validasi form

**API yang digunakan:**
- `AuthService.register()` - Registrasi user baru

**Fitur Utama:**
- ✅ Form registrasi lengkap (nama lengkap, username, email, password)
- ✅ Konfirmasi password dengan validasi
- ✅ Navigasi ke OTP verification setelah registrasi berhasil
- ✅ Password visibility toggle

---

### 1.3 OTPVerificationScreen (`otp_verification_screen.dart`)
**Lokasi:** `lib/screens/otp_verification_screen.dart:11`

**Fungsi:** 
Verifikasi email dengan kode OTP 6 digit

**API yang digunakan:**
- `AuthService.verifyOtp()` - Verifikasi kode OTP
- `AuthService.resendOtp()` - Kirim ulang kode OTP

**Fitur Utama:**
- ✅ Input 6 digit kode OTP dengan number keyboard
- ✅ Countdown timer untuk resend OTP (60 detik)
- ✅ Auto-login setelah verifikasi berhasil
- ✅ Error handling dan user feedback

**Code Example:**
```dart
// Countdown timer implementation
Timer.periodic(const Duration(seconds: 1), (timer) {
  setState(() {
    if (_resendCountdown > 0) {
      _resendCountdown--;
    } else {
      timer.cancel();
    }
  });
});
```

---

### 1.4 ForgotPasswordScreen (`forgot_password_screen.dart`)
**Lokasi:** `lib/screens/forgot_password_screen.dart:4`

**Fungsi:** 
Reset password melalui email

**API yang digunakan:**
- `AuthService.forgotPassword()` - Kirim link reset password ke email

**Fitur Utama:**
- ✅ Input email untuk reset password
- ✅ Validasi email format
- ✅ User feedback setelah email terkirim

---

### 1.5 SplashScreen (`splash_screen.dart`)
**Lokasi:** `lib/screens/splash_screen.dart:11`

**Fungsi:** 
Loading screen awal dengan animasi dan auto-login check

**API yang digunakan:**
- `StorageService.isLoggedIn()` - Cek status login
- `StorageService.getRememberMe()` - Cek remember me setting
- `StorageService.getSavedUserData()` - Ambil data user tersimpan

**Fitur Utama:**
- ✅ Animasi loading dengan progress bar
- ✅ Auto-login jika user sudah login
- ✅ Navigasi berdasarkan role user
- ✅ Complex animations (slide, fade, scale, progress)

**Code Example:**
```dart
// Animation setup
_slideAnimationTop = Tween<Offset>(
  begin: const Offset(0, -0.8),
  end: Offset.zero,
).animate(CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
));
```

---

## 2. Dashboard Screens

### 2.1 AdminDashboard (`admin_dashboard.dart`)
**Lokasi:** `lib/screens/admin_dashboard.dart:10`

**Fungsi:** 
Dashboard untuk role Admin dengan overview lengkap sistem

**API yang digunakan:**
- `DashboardApiService.getCompleteDashboard()` - Data dashboard lengkap
- `DashboardApiService.getDashboardStats()` - Statistik harian
- `DashboardApiService.getWeeklyStats()` - Statistik mingguan
- `DashboardApiService.getLowStockWarning()` - Peringatan stok rendah

**Fitur Utama:**
- ✅ Statistik barang masuk/keluar hari ini
- ✅ Chart statistik mingguan dengan custom bar chart
- ✅ Peringatan stok rendah dengan status kritikal
- ✅ Tab navigasi: Beranda, Penjualan, Pembelian, Return
- ✅ Refresh to reload data
- ✅ Error handling dengan retry mechanism

**Code Example:**
```dart
// Custom bar chart implementation
Widget _buildSimpleBarChart() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: weeklyData.map((data) {
      final masuk = _safeToDouble(data['incoming']);
      final keluar = _safeToDouble(data['outgoing']);
      return SizedBox(
        width: itemWidth,
        child: Column(
          children: [
            // Value labels and bars
          ],
        ),
      );
    }).toList(),
  );
}
```

---

### 2.2 ManagerDashboard (`manager_dashboard.dart`)
**Lokasi:** `lib/screens/manager_dashboard.dart:10`

**Fungsi:** 
Dashboard untuk role Manager (mirip Admin dengan warna berbeda)

**API yang digunakan:** 
- Sama dengan AdminDashboard

**Fitur Utama:**
- ✅ Dashboard overview dengan tema warna ungu
- ✅ Statistik dan analytics yang sama dengan admin
- ✅ Same functionality sebagai admin dashboard

---

### 2.3 SalesDashboard (`sales_dashboard.dart`)
**Lokasi:** `lib/screens/sales_dashboard.dart:15`

**Fungsi:** 
Dashboard untuk Sales dengan Google Maps untuk tracking pengiriman

**API yang digunakan:**
- `SalesOrderApiService.getSalesOrders()` - Data orders untuk sales
- `SalesOrderApiService.updateShippingStatus()` - Update status pengiriman

**Dependencies:**
- `google_maps_flutter` - Google Maps integration
- `geolocator` - GPS location services
- `permission_handler` - Location permissions
- `url_launcher` - Navigation dan phone calls
- `image_picker` - Photo capture untuk delivery proof

**Fitur Utama:**
- ✅ Google Maps dengan marker lokasi pengiriman
- ✅ Filter orders berdasarkan status (pending, shipped, delivered, dll)
- ✅ Navigasi GPS ke lokasi customer
- ✅ Update status pengiriman dengan foto bukti
- ✅ Search dan filter orders
- ✅ Phone call integration
- ✅ Optimal route suggestions
- ✅ Distribution summary dengan statistik

**Code Example:**
```dart
// Google Maps integration
GoogleMap(
  onMapCreated: (GoogleMapController controller) {
    _mapController = controller;
  },
  initialCameraPosition: CameraPosition(
    target: LatLng(WarehouseConfig.latitude, WarehouseConfig.longitude),
    zoom: WarehouseConfig.defaultZoom,
  ),
  markers: _markers,
  onTap: (LatLng position) {},
  myLocationEnabled: true,
)

// Update order status with photo
final result = await SalesOrderApiService.updateShippingStatus(
  orderId: order.id,
  orderStatus: newStatus,
  deliveryNotes: deliveryNotes,
  deliveredAt: deliveredAt,
  deliveryPhoto: deliveryPhoto,
);
```

---

### 2.4 PengecerDashboard (`pengecer_dashboard.dart`)
**Lokasi:** `lib/screens/pengecer_dashboard.dart:14`

**Fungsi:** 
Dashboard untuk Pengecer/Customer dengan katalog produk dan return

**API yang digunakan:**
- `ProductsApiService.getProducts()` - Daftar produk tersedia
- `ProductsApiService.getCategories()` - Kategori produk
- `ProductsApiService.testApiConnection()` - Test koneksi API

**Dependencies:**
- `provider` - State management untuk CartService
- `shared_preferences` - Auth token storage

**Fitur Utama:**
- ✅ Katalog produk dengan search dan filter kategori
- ✅ Keranjang belanja dengan CartService (Provider)
- ✅ Tab Return untuk mengelola pengembalian barang
- ✅ Riwayat pesanan
- ✅ Product image loading dengan authentication headers
- ✅ Category-based filtering
- ✅ Real-time cart updates

**Code Example:**
```dart
// Product loading with authentication
Image.network(
  imageUrl.toString(),
  headers: {
    'User-Agent': 'UDKeluargaSehati Mobile App',
    'Accept': 'image/*,*/*;q=0.8',
    'Authorization': 'Bearer $token',
  },
  errorBuilder: (context, error, stackTrace) {
    return Icon(product['icon'] ?? Icons.inventory);
  },
)

// Cart integration
Provider.of<CartService>(context, listen: false).addProductToCart(product);
```

---

## 3. Feature Screens

### 3.1 CheckoutScreen (`checkout_screen.dart`)
**Lokasi:** `lib/screens/checkout_screen.dart:17`

**Fungsi:** 
Halaman checkout untuk proses pemesanan dengan location tracking

**API yang digunakan:**
- `UserApiService.getUserProfile()` - Data profile user
- `OrderApiService.createOrder()` - Buat pesanan baru
- `VoucherApiService.validateVoucher()` - Validasi kode voucher
- `ShippingApiService.getShippingMethods()` - Metode pengiriman
- `LocationService.getCurrentPosition()` - Lokasi real-time

**Dependencies:**
- `provider` - CartService integration
- `geolocator` - GPS location

**Fitur Utama:**
- ✅ Form informasi pengiriman (auto-fill dari profile)
- ✅ Pilihan metode pengiriman dan pembayaran
- ✅ Sistem voucher discount (percentage, fixed, free shipping)
- ✅ Deteksi lokasi otomatis dengan GPS
- ✅ Kalkulasi jarak dari warehouse
- ✅ Rincian harga dengan pajak (10%) dan ongkir
- ✅ Authentication check before order
- ✅ Order validation dan error handling

**Code Example:**
```dart
// Location tracking
final position = await LocationService.getCurrentPosition();
if (position != null) {
  setState(() {
    _latitude = position.latitude;
    _longitude = position.longitude;
    _locationAccuracy = position.accuracy;
  });
}

// Voucher validation
final result = await VoucherApiService.validateVoucher(
  voucherCode: voucherCode,
  orderAmount: cartService.totalPrice.toDouble(),
);

// Order creation
final result = await OrderApiService.createOrder(
  pengecerName: _currentUser!.fullName,
  pengecerPhone: _phoneController.text.trim(),
  latitude: finalLatitude,
  longitude: finalLongitude,
  items: orderItems,
  shippingMethod: _selectedShipping,
  paymentMethod: _selectedPayment,
);
```

---

### 3.2 HomePage (`home_page.dart`)
**Lokasi:** `lib/screens/home_page.dart:3`

**Fungsi:** 
Halaman beranda sederhana

**API yang digunakan:** 
Tidak ada

**Fitur Utama:**
- ✅ Welcome message UD Keluarga Sehati
- ✅ Simple Material Design layout

---

## 4. Services Architecture

### 4.1 Authentication Services
```dart
class AuthService {
  Future<Map<String, dynamic>> login({required String email, required String password});
  Future<Map<String, dynamic>> register({required String fullName, required String username, required String email, required String password});
  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp});
  Future<Map<String, dynamic>> resendOtp({required String email});
  Future<Map<String, dynamic>> forgotPassword({required String email});
  Future<User?> getUserFromApi();
}
```

### 4.2 Data Management Services
```dart
class DashboardApiService {
  static Future<Map<String, dynamic>> getCompleteDashboard();
  static Future<Map<String, dynamic>> getDashboardStats();
  static Future<Map<String, dynamic>> getWeeklyStats();
  static Future<Map<String, dynamic>> getLowStockWarning();
}

class ProductsApiService {
  static Future<Map<String, dynamic>> getProducts({int perPage = 20});
  static Future<Map<String, dynamic>> getCategories();
  static String getAuthenticatedImageUrl(String? rawUrl);
}

class OrderApiService {
  static Future<Map<String, dynamic>> createOrder({...});
}
```

### 4.3 Utility Services
```dart
class LocationService {
  static Future<Position?> getCurrentPosition();
  static String formatLocationAddress(Position position, String address);
}

class CartService extends ChangeNotifier {
  void addProductToCart(Map<String, dynamic> product);
  void removeFromCart(String productId);
  void clearCart();
  int get totalItems;
  int get totalPrice;
}
```

---

## 5. Key Features Summary

### 5.1 Authentication Flow
1. **SplashScreen** → Auto-login check → Role-based dashboard
2. **LoginScreen** → OTP verification (if needed) → Dashboard
3. **RegisterScreen** → OTP verification → Login

### 5.2 Role-Based Access
- **Admin**: Full system overview, all statistics
- **Manager**: Same as admin with different theming
- **Sales**: Google Maps tracking, order management
- **Pengecer**: Product catalog, shopping, returns

### 5.3 Core Technologies
- **Flutter Material Design** - Consistent UI/UX
- **Provider State Management** - Cart and user state
- **Google Maps Integration** - Location tracking
- **GPS Services** - Real-time location
- **RESTful API Integration** - All data operations
- **Image Loading with Auth** - Authenticated image requests
- **Local Storage** - Auto-login, preferences

### 5.4 Security Features
- **JWT Authentication** - Secure API access
- **OTP Email Verification** - Account verification
- **Location Permissions** - Proper permission handling
- **Input Validation** - Form validation throughout
- **Error Handling** - Comprehensive error management

---

## 6. File Structure
```
lib/screens/
├── admin_dashboard.dart          # Admin overview dashboard
├── checkout_screen.dart          # Shopping checkout process
├── forgot_password_screen.dart   # Password reset
├── home_page.dart                # Simple home page
├── login_screen.dart             # Main login screen
├── manager_dashboard.dart        # Manager dashboard
├── order_history_screen.dart     # Order history
├── otp_verification_screen.dart  # Email verification
├── pengecer_dashboard.dart       # Customer dashboard
├── register_screen.dart          # User registration
├── reset_password_screen.dart    # Password reset form
├── return_form_screen.dart       # Return request form
├── return_history_screen.dart    # Return history
├── returnable_items_screen.dart  # Available returns
├── sales_dashboard.dart          # Sales maps dashboard
└── splash_screen.dart            # App loading screen
```

---

## 7. Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5              # State management
  google_maps_flutter: ^2.2.8   # Maps integration
  geolocator: ^9.0.2           # GPS location
  permission_handler: ^10.4.3   # Permissions
  url_launcher: ^6.1.12        # External URLs
  image_picker: ^1.0.4         # Photo capture
  shared_preferences: ^2.2.0    # Local storage
```

---

**Dokumentasi ini dibuat otomatis berdasarkan analisis kode pada:** `2025-07-27`  
**Total Screens Analyzed:** 15  
**Total API Endpoints:** 20+  
**Architecture Pattern:** MVVM dengan Provider State Management