// Import for math functions
import 'dart:math' as Math;

class WarehouseConfig {
  // UD Keluarga Sehati Warehouse Configuration
  static const String warehouseName = 'UD Keluarga Sehati';
  static const double latitude = 0.5084228544488281;
  static const double longitude = 101.40900501631607;
  
  // Complete Address Information
  static const String street = 'Jl. Suntai, Labuh Baru Bar.';
  static const String district = 'Kec. Payung Sekaki';
  static const String city = 'Pekanbaru';
  static const String province = 'Riau';
  static const String postalCode = '28292';
  
  // Formatted Address
  static const String fullAddress = '$street, $district, $city, $province $postalCode';
  static const String shortAddress = '$street, $city';
  
  // Google Maps Configuration
  static const double defaultZoom = 12.0;
  static const double detailZoom = 15.0;
  
  /// Get warehouse coordinates as Map
  static Map<String, dynamic> getCoordinates() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': fullAddress,
    };
  }
  
  /// Get warehouse info for API requests
  static Map<String, dynamic> getWarehouseInfo() {
    return {
      'name': warehouseName,
      'latitude': latitude,
      'longitude': longitude,
      'street': street,
      'district': district,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'full_address': fullAddress,
    };
  }
  
  /// Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_degreesToRadians(lat1)) * Math.cos(_degreesToRadians(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    
    return earthRadius * c; // Distance in kilometers
  }
  
  /// Calculate distance from warehouse to customer location
  static double getDistanceFromWarehouse(double customerLat, double customerLon) {
    return calculateDistance(latitude, longitude, customerLat, customerLon);
  }
  
  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (Math.pi / 180);
  }
  
  /// Get estimated delivery time based on distance
  static String getEstimatedDeliveryTime(double customerLat, double customerLon) {
    double distance = getDistanceFromWarehouse(customerLat, customerLon);
    
    if (distance <= 5) {
      return '1-2 hari kerja'; // Same city
    } else if (distance <= 20) {
      return '2-3 hari kerja'; // Nearby areas
    } else if (distance <= 50) {
      return '3-5 hari kerja'; // Same province
    } else {
      return '5-7 hari kerja'; // Other provinces
    }
  }
}
