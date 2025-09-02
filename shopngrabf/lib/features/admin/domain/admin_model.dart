// Admin model
class AdminUser {
  final int id;
  final String name;
  final String email;
  final String role; // 'admin', 'superuser'
  final bool isActive;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'admin',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class SystemSettings {
  final bool registrationOpen;
  final bool requireEmailVerification;
  final double taxRate;   // e.g., 0.18 for 18%
  final String currency;  // e.g., 'INR'
  final DateTime updatedAt;

  SystemSettings({
    required this.registrationOpen,
    required this.requireEmailVerification,
    required this.taxRate,
    required this.currency,
    required this.updatedAt,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      registrationOpen: json['registrationOpen'] ?? true,
      requireEmailVerification: json['requireEmailVerification'] ?? true,
      taxRate: (json['taxRate'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'INR',
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registrationOpen': registrationOpen,
      'requireEmailVerification': requireEmailVerification,
      'taxRate': taxRate,
      'currency': currency,
    };
  }
}

class DashboardMetrics {
  final int totalUsers;
  final int activeUsers;
  final int totalShops;
  final int activeShops;
  final int totalOrders;
  final int pendingOrders;
  final double totalRevenue;
  final double todayRevenue;

  DashboardMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalShops,
    required this.activeShops,
    required this.totalOrders,
    required this.pendingOrders,
    required this.totalRevenue,
    required this.todayRevenue,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      totalShops: json['totalShops'] ?? 0,
      activeShops: json['activeShops'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      todayRevenue: (json['todayRevenue'] ?? 0.0).toDouble(),
    );
  }
}
