// Input validation logic
class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase and number';
    }
    
    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Name validation
  static String? name(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters long';
    }
    
    if (value.trim().length > 50) {
      return '$fieldName must be less than 50 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName should only contain letters and spaces';
    }
    
    return null;
  }

  // Phone validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digits
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digits.length > 15) {
      return 'Phone number must be less than 15 digits';
    }
    
    return null;
  }

  // Required field validation
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Pincode validation (India)
  static String? pincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pincode is required';
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Please enter a valid 6-digit pincode';
    }
    
    return null;
  }

  // Price validation
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price < 0) {
      return 'Price cannot be negative';
    }
    
    if (price > 1000000) {
      return 'Price cannot exceed ₹10,00,000';
    }
    
    return null;
  }

  // Stock validation
  static String? stock(String? value) {
    if (value == null || value.isEmpty) {
      return 'Stock is required';
    }
    
    final stock = int.tryParse(value);
    if (stock == null) {
      return 'Please enter a valid stock number';
    }
    
    if (stock < 0) {
      return 'Stock cannot be negative';
    }
    
    if (stock > 10000) {
      return 'Stock cannot exceed 10,000';
    }
    
    return null;
  }

  // Description validation
  static String? description(String? value, {int minLength = 10, int maxLength = 500}) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.trim().length < minLength) {
      return 'Description must be at least $minLength characters long';
    }
    
    if (value.trim().length > maxLength) {
      return 'Description must be less than $maxLength characters';
    }
    
    return null;
  }

  // URL validation
  static String? url(String? value, {bool required = false}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }
    
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    if (!RegExp(r'^https?:\/\/[\w\-]+(\.[\w\-]+)+([\w\-\.,@?^=%&:/~\+#]*[\w\-\@?^=%&/~\+#])?$').hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Rating validation
  static String? rating(String? value) {
    if (value == null || value.isEmpty) {
      return 'Rating is required';
    }
    
    final rating = int.tryParse(value);
    if (rating == null) {
      return 'Please enter a valid rating';
    }
    
    if (rating < 1 || rating > 5) {
      return 'Rating must be between 1 and 5';
    }
    
    return null;
  }

  // Quantity validation
  static String? quantity(String? value, {int maxQuantity = 100}) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    
    final qty = int.tryParse(value);
    if (qty == null) {
      return 'Please enter a valid quantity';
    }
    
    if (qty < 1) {
      return 'Quantity must be at least 1';
    }
    
    if (qty > maxQuantity) {
      return 'Quantity cannot exceed $maxQuantity';
    }
    
    return null;
  }

  // Discount validation
  static String? discount(String? value, String type) {
    if (value == null || value.isEmpty) {
      return null; // Discount is optional
    }
    
    final discount = double.tryParse(value);
    if (discount == null) {
      return 'Please enter a valid discount';
    }
    
    if (discount < 0) {
      return 'Discount cannot be negative';
    }
    
    if (type.toLowerCase() == 'percentage' && discount > 100) {
      return 'Percentage discount cannot exceed 100%';
    }
    
    return null;
  }
}
