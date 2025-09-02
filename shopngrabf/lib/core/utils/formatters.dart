// Formatting utilities
import 'package:intl/intl.dart';

class Formatters {
  // Currency formatter for Indian Rupees
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // Number formatter
  static final NumberFormat _numberFormatter = NumberFormat('#,##,###');

  // Date formatters
  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormatter = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeFormatter = DateFormat('hh:mm a');
  static final DateFormat _apiDateFormatter = DateFormat('yyyy-MM-dd');

  // Format currency
  static String currency(double amount) {
    return _currencyFormatter.format(amount);
  }

  // Format currency without symbol
  static String currencyWithoutSymbol(double amount) {
    return _numberFormatter.format(amount);
  }

  // Format number with commas
  static String number(int number) {
    return _numberFormatter.format(number);
  }

  // Format date
  static String date(DateTime date) {
    return _dateFormatter.format(date);
  }

  // Format date and time
  static String dateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  // Format time
  static String time(DateTime time) {
    return _timeFormatter.format(time);
  }

  // Format for API (ISO format)
  static String apiDate(DateTime date) {
    return _apiDateFormatter.format(date);
  }

  // Parse API date
  static DateTime? parseApiDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Format relative time (e.g., "2 hours ago")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return date(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Format phone number
  static String phone(String phone) {
    // Remove all non-digits
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length == 10) {
      // Format as: (XXX) XXX-XXXX
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      // US format with country code
      return '+1 ${digits.substring(1, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    } else if (digits.length > 10) {
      // International format
      return '+${digits.substring(0, digits.length - 10)} ${digits.substring(digits.length - 10, digits.length - 7)} ${digits.substring(digits.length - 7, digits.length - 4)} ${digits.substring(digits.length - 4)}';
    }
    
    return phone; // Return original if can't format
  }

  // Format file size
  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Format percentage
  static String percentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // Format order status
  static String orderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'returned':
        return 'Returned';
      default:
        return status.toUpperCase();
    }
  }

  // Format rating
  static String rating(double rating) {
    return rating.toStringAsFixed(1);
  }

  // Truncate text
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Format address
  static String address(Map<String, dynamic> address) {
    final parts = <String>[];
    
    if (address['street']?.isNotEmpty == true) {
      parts.add(address['street']);
    }
    
    if (address['city']?.isNotEmpty == true) {
      parts.add(address['city']);
    }
    
    if (address['state']?.isNotEmpty == true) {
      parts.add(address['state']);
    }
    
    if (address['pincode']?.isNotEmpty == true) {
      parts.add(address['pincode']);
    }
    
    return parts.join(', ');
  }

  // Format discount
  static String discount(double discount, String type) {
    if (type.toLowerCase() == 'percentage') {
      return '${discount.toStringAsFixed(0)}% OFF';
    } else {
      return 'Save ${currency(discount)}';
    }
  }

  // Capitalize first letter
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Format list to string
  static String listToString(List<String> items, {String separator = ', '}) {
    return items.join(separator);
  }
}
