// lib/services/cart_service.dart
import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  final Cart _cart = Cart();

  // Getters
  Cart get cart => _cart;
  List<CartItem> get items => _cart.items;
  int get totalItems => _cart.totalItems;
  int get totalPrice => _cart.totalPrice;
  bool get isEmpty => _cart.isEmpty;
  bool get isNotEmpty => _cart.isNotEmpty;

  // Add item to cart
  void addItem(CartItem item) {
    _cart.addItem(item);
    notifyListeners();
    
    // Debug print
    if (kDebugMode) {
      print('Added to cart: ${item.name} (Quantity: ${item.quantity})');
      print('Total items in cart: $totalItems');
    }
  }

  // Add item from product data
  void addProductToCart(Map<String, dynamic> product, {int quantity = 1}) {
    final cartItem = CartItem.fromProduct(product, quantity: quantity);
    addItem(cartItem);
  }

  // Remove item from cart
  void removeItem(int productId) {
    final item = _cart.getItem(productId);
    _cart.removeItem(productId);
    notifyListeners();
    
    // Debug print
    if (kDebugMode && item != null) {
      print('Removed from cart: ${item.name}');
      print('Total items in cart: $totalItems');
    }
  }

  // Update item quantity
  void updateItemQuantity(int productId, int newQuantity) {
    final oldQuantity = _cart.getItemQuantity(productId);
    _cart.updateItemQuantity(productId, newQuantity);
    notifyListeners();
    
    // Debug print
    if (kDebugMode) {
      final item = _cart.getItem(productId);
      if (item != null) {
        print('Updated quantity for ${item.name}: $oldQuantity -> $newQuantity');
      }
      print('Total items in cart: $totalItems');
    }
  }

  // Increase item quantity by 1
  void increaseQuantity(int productId) {
    final currentQuantity = _cart.getItemQuantity(productId);
    updateItemQuantity(productId, currentQuantity + 1);
  }

  // Decrease item quantity by 1
  void decreaseQuantity(int productId) {
    final currentQuantity = _cart.getItemQuantity(productId);
    if (currentQuantity > 1) {
      updateItemQuantity(productId, currentQuantity - 1);
    } else {
      removeItem(productId);
    }
  }

  // Get item quantity
  int getItemQuantity(int productId) {
    return _cart.getItemQuantity(productId);
  }

  // Check if product is in cart
  bool hasItem(int productId) {
    return _cart.hasItem(productId);
  }

  // Get specific item
  CartItem? getItem(int productId) {
    return _cart.getItem(productId);
  }

  // Clear cart
  void clearCart() {
    _cart.clear();
    notifyListeners();
    
    // Debug print
    if (kDebugMode) {
      print('Cart cleared');
    }
  }

  // Calculate subtotal (before tax, shipping, etc.)
  int get subtotal => totalPrice;

  // Calculate tax (example: 10%)
  int calculateTax({double taxRate = 0.1}) {
    return (subtotal * taxRate).round();
  }

  // Calculate shipping cost (example: free shipping above 100k)
  int calculateShipping({int freeShippingThreshold = 100000, int shippingCost = 15000}) {
    return subtotal >= freeShippingThreshold ? 0 : shippingCost;
  }

  // Calculate final total (subtotal + tax + shipping)
  int calculateFinalTotal({double taxRate = 0.1, int freeShippingThreshold = 100000, int shippingCost = 15000}) {
    final tax = calculateTax(taxRate: taxRate);
    final shipping = calculateShipping(freeShippingThreshold: freeShippingThreshold, shippingCost: shippingCost);
    return subtotal + tax + shipping;
  }

  // Get cart summary for display
  Map<String, dynamic> getCartSummary() {
    final tax = calculateTax();
    final shipping = calculateShipping();
    final finalTotal = calculateFinalTotal();

    return {
      'items': items,
      'itemCount': totalItems,
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'total': finalTotal,
    };
  }

  // Save cart to local storage (optional, can be implemented later)
  Future<void> saveCart() async {
    // TODO: Implement persistence if needed
    // await StorageService.saveCart(_cart.toJson());
  }

  // Load cart from local storage (optional, can be implemented later)
  Future<void> loadCart() async {
    // TODO: Implement persistence if needed
    // final cartData = await StorageService.getCart();
    // if (cartData != null) {
    //   final loadedCart = Cart.fromJson(cartData);
    //   _cart.clear();
    //   for (final item in loadedCart.items) {
    //     _cart.addItem(item);
    //   }
    //   notifyListeners();
    // }
  }
}