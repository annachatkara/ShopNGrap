class AppConfig {
  // Environment
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  // Base URLs
  static const String _devBaseUrl = 'http://localhost:3000/api';
  static const String _prodBaseUrl = 'https://your-production-api.com/api';
  
  static String get baseUrl {
    switch (environment) {
      case 'production':
        return _prodBaseUrl;
      case 'staging':
        return 'https://staging-api.your-domain.com/api';
      default:
        return _devBaseUrl;
    }
  }
  
  // API Configuration
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const String apiVersion = 'v1';
  
  // App Configuration
  static const String appName = 'ShopNGrab';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String cartDataKey = 'cart_data';
  static const String wishlistDataKey = 'wishlist_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';
  
  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;
  
  // Security
  static const String jwtPrefix = 'Bearer ';
  
  // Features flags
  static const bool enableDebugLogs = true;
  static const bool enableCrashlytics = false;
  static const bool enableAnalytics = false;
  
  // Business Rules
  static const int maxCartItems = 50;
  static const int maxWishlistItems = 100;
  static const double minOrderAmount = 100.0;
  static const int maxAddresses = 10;
  
  // File Upload
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Cache
  static const Duration cacheValidityDuration = Duration(hours: 1);
  
  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Please check your internet connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unauthorizedMessage = 'Session expired. Please login again.';
  
  // Development helpers
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
}

