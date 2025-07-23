// lib/models/order.dart
class Order {
  final int? id;
  final int? userId;
  final String? orderNumber;
  final String pengecerName;
  final String pengecerPhone;
  final String pengecerEmail;
  final String shippingAddress;
  final String city;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String locationAddress;
  final double locationAccuracy;
  final double subtotal;
  final double shippingCost;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String shippingMethod;
  final String paymentMethod;
  final String? voucherCode;
  final double voucherDiscount;
  final String status;
  final String? notes;
  final List<OrderItem> orderItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order({
    this.id,
    this.userId,
    this.orderNumber,
    required this.pengecerName,
    required this.pengecerPhone,
    required this.pengecerEmail,
    required this.shippingAddress,
    required this.city,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.locationAddress,
    required this.locationAccuracy,
    required this.subtotal,
    required this.shippingCost,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.shippingMethod,
    required this.paymentMethod,
    this.voucherCode,
    required this.voucherDiscount,
    this.status = 'pending',
    this.notes,
    required this.orderItems,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Debug: Print status fields
    print('DEBUG Order.fromJson: order_status = ${json['order_status']}');
    print('DEBUG Order.fromJson: status = ${json['status']}');
    print('DEBUG Order.fromJson: payment_status = ${json['payment_status']}');
    
    final finalStatus = json['order_status']?.toString() ?? json['status']?.toString() ?? 'pending';
    print('DEBUG Order.fromJson: final status = $finalStatus');
    
    return Order(
      id: _parseToInt(json['id']),
      userId: _parseToInt(json['user_id']),
      orderNumber: json['order_number']?.toString() ?? '',
      pengecerName: json['pengecer_name']?.toString() ?? '',
      pengecerPhone: json['pengecer_phone']?.toString() ?? '',
      pengecerEmail: json['pengecer_email']?.toString() ?? '',
      shippingAddress: json['shipping_address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      latitude: _parseToDouble(json['latitude']),
      longitude: _parseToDouble(json['longitude']),
      locationAddress: json['location_address']?.toString() ?? '',
      locationAccuracy: _parseToDouble(json['location_accuracy']),
      subtotal: _parseToDouble(json['subtotal']),
      shippingCost: _parseToDouble(json['shipping_cost']),
      taxAmount: _parseToDouble(json['tax_amount']),
      discountAmount: _parseToDouble(json['discount_amount']),
      totalAmount: _parseToDouble(json['total_amount']),
      shippingMethod: json['shipping_method']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      voucherCode: json['voucher_code']?.toString(),
      voucherDiscount: _parseToDouble(json['voucher_discount']),
      status: finalStatus,
      notes: json['notes']?.toString(),
      orderItems: (json['order_items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
      'user_id': userId,
      'order_number': orderNumber,
      'pengecer_name': pengecerName,
      'pengecer_phone': pengecerPhone,
      'pengecer_email': pengecerEmail,
      'shipping_address': shippingAddress,
      'city': city,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'location_accuracy': locationAccuracy,
      'subtotal': subtotal,
      'shipping_cost': shippingCost,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'shipping_method': shippingMethod,
      'payment_method': paymentMethod,
      'voucher_code': voucherCode,
      'voucher_discount': voucherDiscount,
      'status': status,
      'notes': notes,
      'order_items': orderItems.map((item) => item.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods for display
  String get formattedDate {
    if (createdAt == null) return '';
    final date = createdAt!;
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get statusText {
    // Return the actual status from API instead of hard-coded mapping
    // The API should provide localized status text
    return status.isNotEmpty ? status : 'Unknown Status';
  }

  String get totalItemsText {
    final totalItems = orderItems.fold(0, (sum, item) => sum + item.quantity);
    return '$totalItems item${totalItems > 1 ? 's' : ''}';
  }

  String formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final int? incomingItemId;
  final String productName;
  final String? productImage;
  final String? productCategory;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    this.incomingItemId,
    required this.productName,
    this.productImage,
    this.productCategory,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: _parseToInt(json['id']),
      orderId: _parseToInt(json['order_id']) ?? 0,
      productId: _parseToInt(json['product_id']) ?? 0,
      incomingItemId: _parseToInt(json['incoming_item_id']),
      productName: json['product_name']?.toString() ?? '',
      productImage: json['product_image']?.toString(),
      productCategory: json['product_category']?.toString(),
      quantity: _parseToInt(json['quantity']) ?? 0,
      unit: json['unit']?.toString() ?? 'pcs',
      unitPrice: _parseToDouble(json['unit_price']),
      totalPrice: _parseToDouble(json['total_price']),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
      'order_id': orderId,
      'product_id': productId,
      'incoming_item_id': incomingItemId,
      'product_name': productName,
      'product_image': productImage,
      'product_category': productCategory,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
