// lib/models/cart_item.dart
import 'package:flutter/material.dart';

class CartItem {
  final int productId;
  final String name;
  final String category;
  final int price;
  final String unit;
  final String? image;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    this.image,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.quantity = 1,
  });

  // Total price for this item (price * quantity)
  int get totalPrice => price * quantity;

  // Create CartItem from product data
  factory CartItem.fromProduct(Map<String, dynamic> product, {int quantity = 1}) {
    return CartItem(
      productId: product['id'] ?? 0,
      name: product['name'] ?? '',
      category: product['category'] ?? '',
      price: product['price'] ?? 0,
      unit: product['unit'] ?? 'pcs',
      image: product['image'],
      icon: product['icon'],
      iconColor: product['iconColor'],
      backgroundColor: product['backgroundColor'],
      quantity: quantity,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'image': image,
      'quantity': quantity,
    };
  }

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? 0,
      unit: json['unit'] ?? 'pcs',
      image: json['image'],
      quantity: json['quantity'] ?? 1,
    );
  }

  // Copy with new values
  CartItem copyWith({
    int? productId,
    String? name,
    String? category,
    int? price,
    String? unit,
    String? image,
    IconData? icon,
    Color? iconColor,
    Color? backgroundColor,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      image: image ?? this.image,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;

  @override
  String toString() {
    return 'CartItem(productId: $productId, name: $name, quantity: $quantity, totalPrice: $totalPrice)';
  }
}