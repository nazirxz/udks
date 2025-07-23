// lib/widgets/cart_badge_widget.dart
import 'package:flutter/material.dart';

class CartBadgeWidget extends StatelessWidget {
  final int itemCount;
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;

  const CartBadgeWidget({
    Key? key,
    required this.itemCount,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (itemCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: badgeSize ?? 20,
                minHeight: badgeSize ?? 20,
              ),
              child: Center(
                child: Text(
                  itemCount > 99 ? '99+' : itemCount.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Alternative cart badge for app bar icons
class AppBarCartBadge extends StatelessWidget {
  final int itemCount;
  final VoidCallback onPressed;
  final Color? badgeColor;
  final Color? iconColor;

  const AppBarCartBadge({
    Key? key,
    required this.itemCount,
    required this.onPressed,
    this.badgeColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CartBadgeWidget(
      itemCount: itemCount,
      badgeColor: badgeColor,
      child: IconButton(
        icon: Icon(
          Icons.shopping_cart,
          color: iconColor,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

// Cart FAB with badge
class CartFloatingActionButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? badgeColor;
  final String? heroTag;

  const CartFloatingActionButton({
    Key? key,
    required this.itemCount,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.badgeColor,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CartBadgeWidget(
      itemCount: itemCount,
      badgeColor: badgeColor,
      child: FloatingActionButton(
        heroTag: heroTag ?? "cart_fab",
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? Colors.orange,
        foregroundColor: foregroundColor ?? Colors.white,
        child: const Icon(
          Icons.shopping_cart,
          size: 28,
        ),
      ),
    );
  }
}

// Mini cart summary widget for quick display
class MiniCartSummary extends StatelessWidget {
  final int itemCount;
  final int totalPrice;
  final VoidCallback onTap;

  const MiniCartSummary({
    Key? key,
    required this.itemCount,
    required this.totalPrice,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CartBadgeWidget(
                itemCount: itemCount,
                badgeColor: Colors.red,
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$itemCount item${itemCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Rp ${_formatCurrency(totalPrice)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
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