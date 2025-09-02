// Theme colors
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Light Theme)
  static const Color primary = Color(0xFF1976D2); // Blue
  static const Color primaryVariant = Color(0xFF1565C0);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary Colors (Light Theme)
  static const Color secondary = Color(0xFFFF9800); // Orange
  static const Color secondaryVariant = Color(0xFFF57C00);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Surface Colors (Light Theme)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF000000);
  static const Color onSurfaceVariant = Color(0xFF757575);

  // Background Colors (Light Theme)
  static const Color background = Color(0xFFFAFAFA);
  static const Color onBackground = Color(0xFF000000);

  // Error Colors (Light Theme)
  static const Color error = Color(0xFFD32F2F);
  static const Color onError = Color(0xFFFFFFFF);

  // Outline Colors (Light Theme)
  static const Color outline = Color(0xFFE0E0E0);

  // Shadow Colors (Light Theme)
  static const Color shadow = Color(0x1F000000);

  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF2196F3);
  static const Color primaryVariantDark = Color(0xFF1976D2);
  static const Color onPrimaryDark = Color(0xFF000000);

  static const Color secondaryDark = Color(0xFFFFB74D);
  static const Color secondaryVariantDark = Color(0xFFFF9800);
  static const Color onSecondaryDark = Color(0xFF000000);

  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceVariantDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onSurfaceVariantDark = Color(0xFFBDBDBD);

  static const Color backgroundDark = Color(0xFF000000);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);

  static const Color errorDark = Color(0xFFEF5350);
  static const Color onErrorDark = Color(0xFF000000);

  static const Color outlineDark = Color(0xFF424242);
  static const Color shadowDark = Color(0x3FFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // E-commerce Specific Colors
  static const Color price = Color(0xFF4CAF50); // Green for price
  static const Color discount = Color(0xFFE91E63); // Pink for discounts
  static const Color outOfStock = Color(0xFF9E9E9E); // Grey for out of stock
  static const Color rating = Color(0xFFFFC107); // Amber for ratings

  // Order Status Colors
  static const Color orderPending = Color(0xFFFF9800); // Orange
  static const Color orderConfirmed = Color(0xFF2196F3); // Blue
  static const Color orderShipped = Color(0xFF9C27B0); // Purple
  static const Color orderDelivered = Color(0xFF4CAF50); // Green
  static const Color orderCancelled = Color(0xFFF44336); // Red
  static const Color orderReturned = Color(0xFF795548); // Brown

  // Category Colors (for category chips/badges)
  static const List<Color> categoryColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];

  // Payment Method Colors
  static const Color creditCard = Color(0xFF1976D2);
  static const Color debitCard = Color(0xFF388E3C);
  static const Color netBanking = Color(0xFFD32F2F);
  static const Color upi = Color(0xFF7B1FA2);
  static const Color wallet = Color(0xFFFF5722);
  static const Color cod = Color(0xFF5D4037);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Social Media Colors
  static const Color facebook = Color(0xFF3B5998);
  static const Color google = Color(0xFFDB4437);
  static const Color apple = Color(0xFF000000);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color instagram = Color(0xFFE4405F);
  static const Color twitter = Color(0xFF1DA1F2);

  // Utility Colors
  static const Color transparent = Color(0x00000000);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF424242);

  // Helper methods
  static Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return orderPending;
      case 'confirmed':
        return orderConfirmed;
      case 'shipped':
        return orderShipped;
      case 'delivered':
        return orderDelivered;
      case 'cancelled':
        return orderCancelled;
      case 'returned':
        return orderReturned;
      default:
        return grey;
    }
  }

  static Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  static Color getRatingColor(double rating) {
    if (rating >= 4.0) return success;
    if (rating >= 3.0) return warning;
    return error;
  }

  static Color getDiscountColor(double discount) {
    if (discount >= 50) return error;
    if (discount >= 20) return warning;
    return info;
  }
}
