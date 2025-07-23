// lib/models/sales_order.dart
class SalesOrder {
  final int id;
  final String orderNumber;
  final String pengecerName;
  final String pengecerPhone;
  final String shippingAddress;
  final String city;
  final double latitude;
  final double longitude;
  final double totalAmount;
  final String status; // confirmed, processing, shipped, delivered, cancelled
  final String? deliveryNotes;
  final DateTime? deliveredAt;
  final String? deliveryPhoto;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? distanceKm;
  final double? warehouseLat;
  final double? warehouseLng;

  SalesOrder({
    required this.id,
    required this.orderNumber,
    required this.pengecerName,
    required this.pengecerPhone,
    required this.shippingAddress,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.totalAmount,
    required this.status,
    this.deliveryNotes,
    this.deliveredAt,
    this.deliveryPhoto,
    required this.createdAt,
    this.updatedAt,
    this.distanceKm,
    this.warehouseLat,
    this.warehouseLng,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: json['id'] ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      pengecerName: json['pengecer_name']?.toString() ?? '',
      pengecerPhone: json['pengecer_phone']?.toString() ?? '',
      shippingAddress: json['shipping_address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      latitude: _parseToDouble(json['latitude']),
      longitude: _parseToDouble(json['longitude']),
      totalAmount: _parseToDouble(json['total_amount']),
      status: json['order_status']?.toString() ?? json['status']?.toString() ?? 'pending',
      deliveryNotes: json['delivery_notes']?.toString(),
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.tryParse(json['delivered_at'].toString()) 
          : null,
      deliveryPhoto: json['delivery_photo']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
      distanceKm: _parseToDouble(json['distance_km']),
      warehouseLat: json['warehouse_info'] != null 
          ? _parseToDouble(json['warehouse_info']['latitude'])
          : _parseToDouble(json['warehouse_lat']),
      warehouseLng: json['warehouse_info'] != null 
          ? _parseToDouble(json['warehouse_info']['longitude'])
          : _parseToDouble(json['warehouse_lng']),
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'pengecer_name': pengecerName,
      'pengecer_phone': pengecerPhone,
      'shipping_address': shippingAddress,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'total_amount': totalAmount,
      'order_status': status,
      'delivery_notes': deliveryNotes,
      'delivered_at': deliveredAt?.toIso8601String(),
      'delivery_photo': deliveryPhoto,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'distance_km': distanceKm,
      'warehouse_lat': warehouseLat,
      'warehouse_lng': warehouseLng,
    };
  }

  // Helper methods
  String get statusText {
    // Return the actual status from API instead of hard-coded mapping
    // The API should provide localized status text
    return status.isNotEmpty ? status : 'Tidak Diketahui';
  }

  String get formattedTotalAmount {
    return 'Rp ${totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String get formattedDistance {
    if (distanceKm == null) return 'N/A';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  String get formattedCreatedAt {
    final date = createdAt;
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDeliveredAt {
    if (deliveredAt == null) return '';
    final date = deliveredAt!;
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
