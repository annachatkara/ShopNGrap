// Profile model
import 'dart:convert';

class UserProfile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final DateTime dateOfBirth;
  final String gender;
  final Address? defaultAddress; // Personal delivery address
  final List<Address> addressBook; // Saved personal addresses
  final List<int> favoriteProductIds;
  final List<int> favoriteCategoryIds;
  final Map<String, bool> notificationPreferences; // {'orderUpdates':true, 'promotions':false}
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.dateOfBirth,
    required this.gender,
    this.defaultAddress,
    this.addressBook = const [],
    this.favoriteProductIds = const [],
    this.favoriteCategoryIds = const [],
    this.notificationPreferences = const {
      'orderUpdates': true,
      'promotions': false,
    },
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final addressBookJson = json['addressBook'] as List<dynamic>? ?? [];
    final addressBook = addressBookJson.map((a) => Address.fromJson(a)).toList();
    final prefs = Map<String, bool>.from(json['notificationPreferences'] ?? {});
    return UserProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'],
      dateOfBirth: DateTime.parse(json['dateOfBirth'] ?? DateTime.now().toIso8601String()),
      gender: json['gender'] ?? 'other',
      defaultAddress: json['defaultAddress'] != null ? Address.fromJson(json['defaultAddress']) : null,
      addressBook: addressBook,
      favoriteProductIds: List<int>.from(json['favoriteProductIds'] ?? []),
      favoriteCategoryIds: List<int>.from(json['favoriteCategoryIds'] ?? []),
      notificationPreferences: prefs,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'defaultAddress': defaultAddress?.toJson(),
      'addressBook': addressBook.map((a) => a.toJson()).toList(),
      'favoriteProductIds': favoriteProductIds,
      'favoriteCategoryIds': favoriteCategoryIds,
      'notificationPreferences': notificationPreferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    Address? defaultAddress,
    List<Address>? addressBook,
    List<int>? favoriteProductIds,
    List<int>? favoriteCategoryIds,
    Map<String, bool>? notificationPreferences,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      addressBook: addressBook ?? this.addressBook,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      favoriteCategoryIds: favoriteCategoryIds ?? this.favoriteCategoryIds,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// Reuse Address model from features/address/domain/address_model.dart
