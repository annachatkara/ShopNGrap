// Address repository implementation
import '../../../core/storage/preferences.dart';
import '../../../core/utils/error_handler.dart';
import '../domain/address_model.dart';
import 'address_api.dart';

class ShopAddressRepository {
  final ShopAddressApi _shopAddressApi = ShopAddressApi();
  final Preferences _preferences = Preferences();

  // Cache for shop addresses
  List<ShopAddress>? _cachedShopAddresses;
  Map<int, ShopAddress> _individualShopCache = {};
  DateTime? _lastFetchTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 10);

  // Get all shop addresses (for customers to browse pickup locations)
  Future<List<ShopAddress>> getAllShopAddresses({
    bool forceRefresh = false,
    int? categoryId,
    String? city,
    String? state,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh && _isCacheValid() && _cachedShopAddresses != null) {
        return _filterCachedAddresses(categoryId, city, state);
      }

      final response = await _shopAddressApi.getAllShopAddresses(
        categoryId: categoryId,
        city: city,
        state: state,
      );
      
      if (response.isSuccess && response.data != null) {
        _cachedShopAddresses = response.data!;
        _lastFetchTime = DateTime.now();
        
        // Also cache individually
        for (final address in response.data!) {
          _individualShopCache[address.shopId] = address;
        }
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to load shop locations',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load shop locations. Please try again.',
        originalError: e,
      );
    }
  }

  // Get nearby shop addresses
  Future<List<ShopAddress>> getNearbyShopAddresses({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int? categoryId,
    String? searchQuery,
  }) async {
    try {
      final request = NearbyShopsRequest(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );

      final response = await _shopAddressApi.getNearbyShopAddresses(request);
      
      if (response.isSuccess && response.data != null) {
        // Sort by distance
        final userLocation = [latitude, longitude];
        response.data!.sort((a, b) {
          final distanceA = a.distanceFrom(latitude, longitude);
          final distanceB = b.distanceFrom(latitude, longitude);
          return distanceA.compareTo(distanceB);
        });
        
        // Cache results
        for (final address in response.data!) {
          _individualShopCache[address.shopId] = address;
        }
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to find nearby shops',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to find nearby shops. Please try again.',
        originalError: e,
      );
    }
  }

  // Get single shop address (for pickup details)
  Future<ShopAddress> getShopAddress(int shopId) async {
    try {
      // Check individual cache first
      if (_individualShopCache.containsKey(shopId)) {
        return _individualShopCache[shopId]!;
      }

      final response = await _shopAddressApi.getShopAddress(shopId);
      
      if (response.isSuccess && response.data != null) {
        // Cache the result
        _individualShopCache[shopId] = response.data!;
        return response.data!;
      } else {
        if (response.isNotFound) {
          throw AppException(
            message: 'Shop location not found',
            code: 'SHOP_ADDRESS_NOT_FOUND',
          );
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load shop location',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load shop location. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Get my shop address
  Future<ShopAddress?> getMyShopAddress() async {
    try {
      final response = await _shopAddressApi.getMyShopAddress();
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        if (response.isNotFound) {
          return null; // Shop address not set up yet
        }
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load shop address',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load shop address. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Create or update my shop address
  Future<ShopAddress> createOrUpdateMyShopAddress(
    CreateShopAddressRequest request,
  ) async {
    try {
      final response = await _shopAddressApi.createOrUpdateMyShopAddress(request);
      
      if (response.isSuccess && response.data != null) {
        // Update caches
        _individualShopCache[response.data!.shopId] = response.data!;
        _clearListCache(); // Clear list cache to force refresh
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to save shop address',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to save shop address. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Update my shop address
  Future<ShopAddress> updateMyShopAddress(UpdateShopAddressRequest request) async {
    try {
      final response = await _shopAddressApi.updateMyShopAddress(request);
      
      if (response.isSuccess && response.data != null) {
        // Update caches
        _individualShopCache[response.data!.shopId] = response.data!;
        _clearListCache(); // Clear list cache to force refresh
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        if (response.isNotFound) {
          throw AppException(
            message: 'Shop address not found',
            code: 'SHOP_ADDRESS_NOT_FOUND',
          );
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to update shop address',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to update shop address. Please try again.',
        originalError: e,
      );
    }
  }

  // Validate pincode
  Future<Map<String, dynamic>?> validatePincode(String pincode) async {
    try {
      if (pincode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pincode)) {
        return null;
      }

      final response = await _shopAddressApi.validatePincode(pincode);
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get location from coordinates
  Future<Map<String, dynamic>?> getLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _shopAddressApi.getLocationFromCoordinates(
        latitude,
        longitude,
      );
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Search locations for autocomplete
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    try {
      if (query.length < 3) return [];

      final response = await _shopAddressApi.searchLocations(query);
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get cities with shops
  Future<List<String>> getCitiesWithShops() async {
    try {
      final addresses = await getAllShopAddresses();
      final cities = addresses.map((address) => address.city).toSet().toList();
      cities.sort();
      return cities;
    } catch (e) {
      return [];
    }
  }

  // Get states with shops
  Future<List<String>> getStatesWithShops() async {
    try {
      final addresses = await getAllShopAddresses();
      final states = addresses.map((address) => address.state).toSet().toList();
      states.sort();
      return states;
    } catch (e) {
      return [];
    }
  }

  // Check if shop has address set up
  Future<bool> doesShopHaveAddress(int shopId) async {
    try {
      await getShopAddress(shopId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear all caches
  void clearCache() {
    _cachedShopAddresses = null;
    _individualShopCache.clear();
    _lastFetchTime = null;
  }

  // Private helper methods
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    
    final now = DateTime.now();
    return now.difference(_lastFetchTime!) < _cacheValidityDuration;
  }

  void _clearListCache() {
    _cachedShopAddresses = null;
    _lastFetchTime = null;
  }

  List<ShopAddress> _filterCachedAddresses(int? categoryId, String? city, String? state) {
    if (_cachedShopAddresses == null) return [];
    
    return _cachedShopAddresses!.where((address) {
      if (city != null && address.city.toLowerCase() != city.toLowerCase()) return false;
      if (state != null && address.state.toLowerCase() != state.toLowerCase()) return false;
      return address.isActive;
    }).toList();
  }
}
