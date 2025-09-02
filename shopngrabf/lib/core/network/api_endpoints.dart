// Endpoint URL constants
class ApiEndpoints {
  // Base
  static const String health = '/health';
  static const String apiInfo = '/';
  
  // Authentication
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  
  // User Profile
  static const String profile = '/users/profile';
  static const String changePassword = '/users/change-password';
  static const String userStats = '/users/stats';
  
  // Admin Requests
  static const String adminRequests = '/admin-requests';
  static const String myAdminRequests = '/admin-requests/my-requests';
  static const String adminRequestStats = '/admin-requests/stats';
  
  static String approveAdminRequest(int requestId) => '/admin-requests/$requestId/approve';
  static String rejectAdminRequest(int requestId) => '/admin-requests/$requestId/reject';
  
  // Products
  static const String products = '/products';
  static const String myProducts = '/products/admin/my-products';
  
  static String product(int productId) => '/products/$productId';
  static String userProducts(int userId) => '/products/user/$userId';
  
  // Categories
  static const String categories = '/categories';
  static const String myCategories = '/categories/admin/my-categories';
  
  static String category(int categoryId) => '/categories/$categoryId';
  
  // Shopping Cart
  static const String cart = '/cart';
  
  static String cartItem(int itemId) => '/cart/$itemId';
  
  // Orders
  static const String orders = '/orders';
  static const String shopOrders = '/orders/admin/shop-orders';
  
  static String order(int orderId) => '/orders/$orderId';
  static String cancelOrder(int orderId) => '/orders/$orderId/cancel';
  static String updateOrderStatus(int orderId) => '/orders/admin/$orderId/status';
  
  // Addresses
  static const String addresses = '/addresses';
  
  static String address(int addressId) => '/addresses/$addressId';
  static String setDefaultAddress(int addressId) => '/addresses/$addressId/default';
  
  // Wishlist
  static const String wishlist = '/wishlist';
  
  static String wishlistItem(int itemId) => '/wishlist/$itemId';
  static String removeFromWishlistByProduct(int productId) => '/wishlist/product/$productId';
  static String moveToCart(int itemId) => '/wishlist/$itemId/move-to-cart';
  
  // Reviews
  static const String reviews = '/reviews';
  static const String myReviews = '/reviews/my-reviews';
  
  static String review(int reviewId) => '/reviews/$reviewId';
  static String productReviews(int productId) => '/reviews/product/$productId';
  
  // Coupons
  static const String coupons = '/coupons';
  static const String activeCoupons = '/coupons/active';
  static const String validateCoupon = '/coupons/validate';
  
  static String coupon(int couponId) => '/coupons/$couponId';
  
  // Admin Management
  static const String adminUsers = '/admin/users';
  static const String adminShops = '/admin/shops';
  static const String adminLogs = '/admin/logs';
  static const String adminDashboard = '/admin/dashboard';
  
  static String blockUser(int userId) => '/admin/users/$userId/block';
  static String shopVisibility(int shopId) => '/admin/shops/$shopId/visibility';
}
