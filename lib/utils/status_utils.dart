// Import for math functions
import 'package:flutter/material.dart';

class StatusUtils {
  // Order status values and their Indonesian translations
  static const Map<String, String> _statusTranslations = {
    'confirmed': 'Dikonfirmasi',
    'processing': 'Sedang Diproses',
    'shipped': 'Sedang Dikirim',
    'delivered': 'Terkirim',
    'cancelled': 'Dibatalkan',
  };

  // Status color mapping
  static const Map<String, Color> _statusColors = {
    'confirmed': Colors.blue,
    'processing': Colors.orange,
    'shipped': Colors.purple,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  /// Get localized display text for a status
  /// If the status is not in predefined list, return as-is with proper formatting
  static String getStatusDisplayText(String status) {
    if (status.isEmpty) return 'Status Tidak Diketahui';
    
    // Check if it's a predefined status
    String normalizedStatus = status.toLowerCase().replaceAll(' ', '_');
    if (_statusTranslations.containsKey(normalizedStatus)) {
      return _statusTranslations[normalizedStatus]!;
    }
    
    // If not found in predefined list, return as-is with proper case formatting
    return status.split('_')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
            : '')
        .join(' ');
  }

  /// Get color for a status
  static Color getStatusColor(String status) {
    if (status.isEmpty) return Colors.grey;
    
    String normalizedStatus = status.toLowerCase().replaceAll(' ', '_');
    return _statusColors[normalizedStatus] ?? Colors.grey;
  }

  /// Check if a status is considered "active" (not final)
  static bool isActiveStatus(String status) {
    String normalizedStatus = status.toLowerCase().replaceAll(' ', '_');
    return !['delivered', 'cancelled'].contains(normalizedStatus);
  }

  /// Check if a status is considered "successful" completion
  static bool isSuccessfulStatus(String status) {
    String normalizedStatus = status.toLowerCase().replaceAll(' ', '_');
    return ['delivered'].contains(normalizedStatus);
  }

  /// Check if a status is considered "problematic"
  static bool isProblematicStatus(String status) {
    String normalizedStatus = status.toLowerCase().replaceAll(' ', '_');
    return ['cancelled'].contains(normalizedStatus);
  }

  /// Get all available status filters for UI
  static List<Map<String, String>> getStatusFilters() {
    List<Map<String, String>> filters = [
      {'value': '', 'label': 'Semua Status'},
    ];
    
    _statusTranslations.forEach((key, value) {
      filters.add({'value': key, 'label': value});
    });
    
    return filters;
  }

  /// Get status icon based on status
  static IconData getStatusIcon(String status) {
    String normalizedStatus = status.toLowerCase().replaceAll(' ', '_');
    
    switch (normalizedStatus) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.settings;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Get progress value (0.0 to 1.0) for status
  static double getStatusProgress(String status) {
    String normalizedStatus = status.toLowerCase().replaceAll(' ', '_');
    
    switch (normalizedStatus) {
      case 'confirmed':
        return 0.2;
      case 'processing':
        return 0.4;
      case 'shipped':
        return 0.8;
      case 'delivered':
        return 1.0;
      case 'cancelled':
        return 0.0; // No progress for cancelled orders
      default:
        return 0.0;
    }
  }
}
