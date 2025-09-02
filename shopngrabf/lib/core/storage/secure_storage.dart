// JWT token storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/app_config.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: IOSAccessibility.first_unlock_this_device,
    ),
  );

  // Auth token management
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: AppConfig.authTokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: AppConfig.authTokenKey);
  }

  Future<void> deleteAuthToken() async {
    await _storage.delete(key: AppConfig.authTokenKey);
  }

  // Refresh token management
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConfig.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConfig.refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: AppConfig.refreshTokenKey);
  }

  // User data management
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _storage.write(key: AppConfig.userDataKey, value: jsonString);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _storage.read(key: AppConfig.userDataKey);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        // If parsing fails, delete corrupted data
        await deleteUserData();
        return null;
      }
    }
    return null;
  }

  Future<void> deleteUserData() async {
    await _storage.delete(key: AppConfig.userDataKey);
  }

  // Cart data management (for offline cart)
  Future<void> saveCartData(List<Map<String, dynamic>> cartItems) async {
    final jsonString = jsonEncode(cartItems);
    await _storage.write(key: AppConfig.cartDataKey, value: jsonString);
  }

  Future<List<Map<String, dynamic>>?> getCartData() async {
    final jsonString = await _storage.read(key: AppConfig.cartDataKey);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        await deleteCartData();
        return null;
      }
    }
    return null;
  }

  Future<void> deleteCartData() async {
    await _storage.delete(key: AppConfig.cartDataKey);
  }

  // Wishlist data management (for offline wishlist)
  Future<void> saveWishlistData(List<Map<String, dynamic>> wishlistItems) async {
    final jsonString = jsonEncode(wishlistItems);
    await _storage.write(key: AppConfig.wishlistDataKey, value: jsonString);
  }

  Future<List<Map<String, dynamic>>?> getWishlistData() async {
    final jsonString = await _storage.read(key: AppConfig.wishlistDataKey);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        await deleteWishlistData();
        return null;
      }
    }
    return null;
  }

  Future<void> deleteWishlistData() async {
    await _storage.delete(key: AppConfig.wishlistDataKey);
  }

  // Biometric settings
  Future<void> saveBiometricEnabled(bool enabled) async {
    await _storage.write(key: 'biometric_enabled', value: enabled.toString());
  }

  Future<bool> getBiometricEnabled() async {
    final value = await _storage.read(key: 'biometric_enabled');
    return value?.toLowerCase() == 'true';
  }

  // Device ID for security
  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: 'device_id', value: deviceId);
  }

  Future<String?> getDeviceId() async {
    return await _storage.read(key: 'device_id');
  }

  // PIN for app lock
  Future<void> saveAppPin(String pin) async {
    await _storage.write(key: 'app_pin', value: pin);
  }

  Future<String?> getAppPin() async {
    return await _storage.read(key: 'app_pin');
  }

  Future<void> deleteAppPin() async {
    await _storage.delete(key: 'app_pin');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    final userData = await getUserData();
    return token != null && token.isNotEmpty && userData != null;
  }

  // Get user role
  Future<String?> getUserRole() async {
    final userData = await getUserData();
    return userData?['role'];
  }

  // Get user ID
  Future<int?> getUserId() async {
    final userData = await getUserData();
    return userData?['id'];
  }

  // Clear all auth data (logout)
  Future<void> clearAuthData() async {
    await Future.wait([
      deleteAuthToken(),
      deleteRefreshToken(),
      deleteUserData(),
      deleteCartData(),
      deleteWishlistData(),
    ]);
  }

  // Clear all storage (reset app)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if storage contains key
  Future<bool> containsKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }

  // Get all keys (for debugging)
  Future<Map<String, String>> getAllData() async {
    return await _storage.readAll();
  }

  // Save custom data
  Future<void> saveCustomData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Get custom data
  Future<String?> getCustomData(String key) async {
    return await _storage.read(key: key);
  }

  // Delete custom data
  Future<void> deleteCustomData(String key) async {
    await _storage.delete(key: key);
  }
}
