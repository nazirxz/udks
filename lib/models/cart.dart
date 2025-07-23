// lib/models/cart.dart
import 'cart_item.dart';

class Cart {
  final List<CartItem> _items = [];

  // Default constructor
  Cart();

  // Get all items in cart
  List<CartItem> get items => List.unmodifiable(_items);

  // Get total number of items in cart
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  // Get total price of all items in cart
  int get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  // Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  // Check if cart has items
  bool get isNotEmpty => _items.isNotEmpty;

  // Add item to cart
  void addItem(CartItem newItem) {
    final existingItemIndex = _items.indexWhere(
      (item) => item.productId == newItem.productId,
    );

    if (existingItemIndex >= 0) {
      // Item already exists, increase quantity
      _items[existingItemIndex].quantity += newItem.quantity;
    } else {
      // Add new item to cart
      _items.add(newItem);
    }
  }

  // Remove item from cart
  void removeItem(int productId) {
    _items.removeWhere((item) => item.productId == productId);
  }

  // Update item quantity
  void updateItemQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final itemIndex = _items.indexWhere(
      (item) => item.productId == productId,
    );

    if (itemIndex >= 0) {
      _items[itemIndex].quantity = newQuantity;
    }
  }

  // Get specific item by product ID
  CartItem? getItem(int productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Check if product is in cart
  bool hasItem(int productId) {
    return _items.any((item) => item.productId == productId);
  }

  // Get quantity of specific product
  int getItemQuantity(int productId) {
    final item = getItem(productId);
    return item?.quantity ?? 0;
  }

  // Clear all items from cart
  void clear() {
    _items.clear();
  }

  // Convert cart to JSON
  Map<String, dynamic> toJson() {
    return {
      'items': _items.map((item) => item.toJson()).toList(),
      'totalItems': totalItems,
      'totalPrice': totalPrice,
    };
  }

  // Create cart from JSON
  factory Cart.fromJson(Map<String, dynamic> json) {
    final cart = Cart();
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    
    for (final itemJson in itemsJson) {
      final cartItem = CartItem.fromJson(itemJson as Map<String, dynamic>);
      cart._items.add(cartItem);
    }
    
    return cart;
  }

  @override
  String toString() {
    return 'Cart(items: ${_items.length}, totalItems: $totalItems, totalPrice: $totalPrice)';
  }
}