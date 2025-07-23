// lib/models/returnable_item.dart

class ReturnableItem {
  final int orderItemId;
  final int orderId;
  final String orderNumber;
  final String orderDate;
  final String productName;
  final String productCategory;
  final int quantityOrdered;
  final int quantityReturned;
  final int availableToReturn;
  final double unitPrice;
  final bool canReturn;

  ReturnableItem({
    required this.orderItemId,
    required this.orderId,
    required this.orderNumber,
    required this.orderDate,
    required this.productName,
    required this.productCategory,
    required this.quantityOrdered,
    required this.quantityReturned,
    required this.availableToReturn,
    required this.unitPrice,
    required this.canReturn,
  });

  factory ReturnableItem.fromJson(Map<String, dynamic> json) {
    // Debug logging untuk melihat data yang masuk
    print('DEBUG: Creating ReturnableItem from JSON: $json');
    print('DEBUG: order_id value: ${json['order_id']} (${json['order_id'].runtimeType})');
    
    try {
      return ReturnableItem(
        orderItemId: _parseIntFromDynamic(json['order_item_id']),
        orderId: _parseIntFromDynamic(json['order_id']),
        orderNumber: json['order_number']?.toString() ?? '',
        orderDate: json['order_date']?.toString() ?? '',
        productName: json['product_name']?.toString() ?? '',
        productCategory: json['product_category']?.toString() ?? '',
        quantityOrdered: _parseIntFromDynamic(json['quantity_ordered']),
        quantityReturned: _parseIntFromDynamic(json['quantity_returned']),
        availableToReturn: _parseIntFromDynamic(json['available_to_return']),
        unitPrice: _parseDoubleFromDynamic(json['unit_price']),
        canReturn: json['can_return'] == true || json['can_return'] == 'true',
      );
    } catch (e) {
      print('DEBUG: Error in ReturnableItem.fromJson: $e');
      rethrow;
    }
  }

  // Helper method to safely parse int from dynamic value
  static int _parseIntFromDynamic(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  // Helper method to safely parse double from dynamic value
  static double _parseDoubleFromDynamic(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'order_item_id': orderItemId,
      'order_id': orderId,
      'order_number': orderNumber,
      'order_date': orderDate,
      'product_name': productName,
      'product_category': productCategory,
      'quantity_ordered': quantityOrdered,
      'quantity_returned': quantityReturned,
      'available_to_return': availableToReturn,
      'unit_price': unitPrice,
      'can_return': canReturn,
    };
  }

  String get formattedPrice {
    return 'Rp ${unitPrice.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(orderDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return orderDate;
    }
  }
}
