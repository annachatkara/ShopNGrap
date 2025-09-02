// Address model
class ShopAddress {
  final int id;
  final int shopId;
  final String shopName;
  final String contactPerson;
  final String phone;
  final String alternatePhone;
  final String email;
  final String street;
  final String landmark;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final double latitude;
  final double longitude;
  final String openingHours;
  final String closingHours;
  final List<String> workingDays;
  final bool isActive;
  final String? instructions; // Special pickup instructions
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopAddress({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.contactPerson,
    required this.phone,
    required this.alternatePhone,
    required this.email,
    required this.street,
    required this.landmark,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.openingHours,
    required this.closingHours,
    required this.workingDays,
    required this.isActive,
    this.instructions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopAddress.fromJson(Map<String, dynamic> json) {
    return ShopAddress(
      id: json['id'] ?? 0,
      shopId: json['shopId'] ?? json['shop']?['id'] ?? 0,
      shopName: json['shopName'] ?? json['shop']?['shopName'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      phone: json['phone'] ?? '',
      alternatePhone: json['alternatePhone'] ?? '',
      email: json['email'] ?? '',
      street: json['street'] ?? '',
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? 'India',
      pincode: json['pincode'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      openingHours: json['openingHours'] ?? '10:00',
      closingHours: json['closingHours'] ?? '20:00',
      workingDays: List<String>.from(json['workingDays'] ?? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']),
      isActive: json['isActive'] ?? true,
      instructions: json['instructions'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'shopName': shopName,
      'contactPerson': contactPerson,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'email': email,
      'street': street,
      'landmark': landmark,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'openingHours': openingHours,
      'closingHours': closingHours,
      'workingDays': workingDays,
      'isActive': isActive,
      'instructions': instructions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for pickup locations
  String get fullAddress {
    return '$street, $landmark, $city, $state, $country - $pincode';
  }

  String get shortAddress {
    return '$street, $city - $pincode';
  }

  String get pickupLocation {
    return '$shopName\n$street, $landmark\n$city, $state $pincode';
  }

  String get businessHours {
    return '$openingHours - $closingHours';
  }

  String get workingDaysText {
    if (workingDays.length == 7) return 'All Days';
    if (workingDays.length == 6 && !workingDays.contains('Sunday')) return 'Monday - Saturday';
    return workingDays.join(', ');
  }

  bool get isOpenToday {
    final today = DateTime.now();
    final dayName = _getDayName(today.weekday);
    return workingDays.contains(dayName) && isActive;
  }

  bool get isCurrentlyOpen {
    if (!isOpenToday) return false;
    
    final now = TimeOfDay.now();
    final openTime = _parseTime(openingHours);
    final closeTime = _parseTime(closingHours);
    
    return _isTimeBetween(now, openTime, closeTime);
  }

  String get statusText {
    if (!isActive) return 'Shop Closed';
    if (!isOpenToday) return 'Closed Today';
    if (isCurrentlyOpen) return 'Open Now';
    
    final openTime = _parseTime(openingHours);
    return 'Opens at ${openTime.format(context)}';
  }

  Color get statusColor {
    if (!isActive || !isOpenToday) return Colors.red;
    if (isCurrentlyOpen) return Colors.green;
    return Colors.orange;
  }

  double distanceFrom(double userLat, double userLng) {
    return _calculateDistance(userLat, userLng, latitude, longitude);
  }

  String getDistanceText(double userLat, double userLng) {
    final distance = distanceFrom(userLat, userLng);
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m away';
    }
    return '${distance.toStringAsFixed(1)}km away';
  }

  // Google Maps URL for directions
  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  // Apple Maps URL for directions
  String get appleMapsUrl {
    return 'http://maps.apple.com/?daddr=$latitude,$longitude';
  }

  bool get hasValidCoordinates => latitude != 0.0 && longitude != 0.0;

  // Private helper methods
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Crosses midnight
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopAddress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ShopAddress(id: $id, shopName: $shopName, city: $city)';
  }
}

class CreateShopAddressRequest {
  final String contactPerson;
  final String phone;
  final String alternatePhone;
  final String email;
  final String street;
  final String landmark;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final double latitude;
  final double longitude;
  final String openingHours;
  final String closingHours;
  final List<String> workingDays;
  final String? instructions;

  const CreateShopAddressRequest({
    required this.contactPerson,
    required this.phone,
    required this.alternatePhone,
    required this.email,
    required this.street,
    required this.landmark,
    required this.city,
    required this.state,
    this.country = 'India',
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.openingHours = '10:00',
    this.closingHours = '20:00',
    this.workingDays = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    this.instructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'contactPerson': contactPerson,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'email': email,
      'street': street,
      'landmark': landmark,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'openingHours': openingHours,
      'closingHours': closingHours,
      'workingDays': workingDays,
      if (instructions != null && instructions!.isNotEmpty) 'instructions': instructions,
    };
  }
}

class UpdateShopAddressRequest {
  final String? contactPerson;
  final String? phone;
  final String? alternatePhone;
  final String? email;
  final String? street;
  final String? landmark;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? openingHours;
  final String? closingHours;
  final List<String>? workingDays;
  final String? instructions;
  final bool? isActive;

  const UpdateShopAddressRequest({
    this.contactPerson,
    this.phone,
    this.alternatePhone,
    this.email,
    this.street,
    this.landmark,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.latitude,
    this.longitude,
    this.openingHours,
    this.closingHours,
    this.workingDays,
    this.instructions,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    
    if (contactPerson != null) data['contactPerson'] = contactPerson;
    if (phone != null) data['phone'] = phone;
    if (alternatePhone != null) data['alternatePhone'] = alternatePhone;
    if (email != null) data['email'] = email;
    if (street != null) data['street'] = street;
    if (landmark != null) data['landmark'] = landmark;
    if (city != null) data['city'] = city;
    if (state != null) data['state'] = state;
    if (country != null) data['country'] = country;
    if (pincode != null) data['pincode'] = pincode;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (openingHours != null) data['openingHours'] = openingHours;
    if (closingHours != null) data['closingHours'] = closingHours;
    if (workingDays != null) data['workingDays'] = workingDays;
    if (instructions != null) data['instructions'] = instructions;
    if (isActive != null) data['isActive'] = isActive;
    
    return data;
  }
}

// For finding nearby shops
class NearbyShopsRequest {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final int? categoryId;
  final String? searchQuery;

  const NearbyShopsRequest({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
    this.categoryId,
    this.searchQuery,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radius': radiusKm,
    };
    
    if (categoryId != null) params['categoryId'] = categoryId;
    if (searchQuery != null && searchQuery!.isNotEmpty) params['search'] = searchQuery;
    
    return params;
  }
}
