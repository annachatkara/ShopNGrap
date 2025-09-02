// Address provider
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/error_handler.dart';
import '../data/address_repository.dart';
import '../domain/address_model.dart';

enum AddressState {
  initial,
  loading,
  loaded,
  error,
  empty,
}

class AddressProvider with ChangeNotifier {
  final ShopAddressRepository _addressRepository = ShopAddressRepository();

  // State variables
  AddressState _state = AddressState.initial;
  List<ShopAddress> _shopAddresses = [];
  ShopAddress? _selectedShopAddress;
  ShopAddress? _myShopAddress;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isUpdating = false;

  // Location and filtering
  Position? _currentPosition;
  List<ShopAddress> _nearbyShops = [];
  List<String> _availableCities = [];
  List<String> _availableStates = [];
  String? _selectedCity;
  String? _selectedState;
  int? _selectedCategoryId;

  // Location search
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _isSearchingLocations = false;

  // Getters
  AddressState get state => _state;
  List<ShopAddress> get shopAddresses => _shopAddresses;
  ShopAddress? get selectedShopAddress => _selectedShopAddress;
  ShopAddress? get myShopAddress => _myShopAddress;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get hasError => _state == AddressState.error;
  bool get isEmpty => _state == AddressState.empty;

  // Location getters
  Position? get currentPosition => _currentPosition;
  List<ShopAddress> get nearbyShops => _nearbyShops;
  List<String> get availableCities => _availableCities;
  List<String> get availableStates => _availableStates;
  String? get selectedCity => _selectedCity;
  String? get selectedState => _selectedState;
  int? get selectedCategoryId => _selectedCategoryId;

  // Search getters
  List<Map<String, dynamic>> get locationSuggestions => _locationSuggestions;
  bool get isSearchingLocations => _isSearchingLocations;

  // Helper getters
  bool get hasShopAddress => _myShopAddress != null;
  bool get hasCurrentLocation => _currentPosition != null;
  int get totalShops => _shopAddresses.length;
  List<ShopAddress> get openShops => _shopAddresses.where((shop) => shop.isCurrentlyOpen).toList();
  List<ShopAddress> get closedShops => _shopAddresses.where((shop) => !shop.isCurrentlyOpen).toList();

  // Initialize
  Future<void> initialize() async {
    await loadShopAddresses();
    await loadFilterOptions();
  }

  // Load all shop addresses (for customers)
  Future<void> loadShopAddresses({bool forceRefresh = false}) async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      final addresses = await _addressRepository.getAllShopAddresses(
        forceRefresh: forceRefresh,
        categoryId: _selectedCategoryId,
        city: _selectedCity,
        state: _selectedState,
      );

      _shopAddresses = addresses;
      
      if (addresses.isEmpty) {
        _setState(AddressState.empty);
      } else {
        _setState(AddressState.loaded);
      }
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setState(AddressState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Load nearby shop addresses
  Future<void> loadNearbyShops({
    double radiusKm = 10.0,
    String? searchQuery,
  }) async {
    if (_currentPosition == null) {
      await getCurrentLocation();
      if (_currentPosition == null) return;
    }

    try {
      _setLoading(true);
      _clearError();

      final nearbyAddresses = await _addressRepository.getNearbyShopAddresses(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: radiusKm,
        categoryId: _selectedCategoryId,
        searchQuery: searchQuery,
      );

      _nearbyShops = nearbyAddresses;
      
      if (nearbyAddresses.isEmpty) {
        _setState(AddressState.empty);
      } else {
        _setState(AddressState.loaded);
      }
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setState(AddressState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Get single shop address
  Future<bool> getShopAddress(int shopId) async {
    try {
      _setLoading(true);
      _clearError();

      final address = await _addressRepository.getShopAddress(shopId);
      _selectedShopAddress = address;
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Admin: Load my shop address
  Future<void> loadMyShopAddress() async {
    try {
      _setLoading(true);
      _clearError();

      final address = await _addressRepository.getMyShopAddress();
      _myShopAddress = address;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to manage shop address');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
    } finally {
      _setLoading(false);
    }
  }

  // Admin: Create or update my shop address
  Future<bool> saveMyShopAddress(CreateShopAddressRequest request) async {
    try {
      _setUpdating(true);
      _clearError();

      final address = await _addressRepository.createOrUpdateMyShopAddress(request);
      _myShopAddress = address;
      
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to manage shop address');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Admin: Update my shop address
  Future<bool> updateMyShopAddress(UpdateShopAddressRequest request) async {
    try {
      _setUpdating(true);
      _clearError();

      final address = await _addressRepository.updateMyShopAddress(request);
      _myShopAddress = address;
      
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to manage shop address');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Get current location
  Future<bool> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled. Please enable them to find nearby shops.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permissions are denied. Please grant location access to find nearby shops.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Location permissions are permanently denied. Please enable them in settings to find nearby shops.');
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = position;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to get current location. Please try again.');
      return false;
    }
  }

  // Filter by city
  Future<void> filterByCity(String? city) async {
    _selectedCity = city;
    await loadShopAddresses(forceRefresh: true);
  }

  // Filter by state
  Future<void> filterByState(String? state) async {
    _selectedState = state;
    await loadShopAddresses(forceRefresh: true);
  }

  // Filter by category
  Future<void> filterByCategory(int? categoryId) async {
    _selectedCategoryId = categoryId;
    await loadShopAddresses(forceRefresh: true);
  }

  // Clear filters
  Future<void> clearFilters() async {
    _selectedCity = null;
    _selectedState = null;
    _selectedCategoryId = null;
    await loadShopAddresses(forceRefresh: true);
  }

  // Load filter options
  Future<void> loadFilterOptions() async {
    try {
      _availableCities = await _addressRepository.getCitiesWithShops();
      _availableStates = await _addressRepository.getStatesWithShops();
      notifyListeners();
    } catch (e) {
      // Silently handle error
    }
  }

  // Search locations for autocomplete
  Future<void> searchLocations(String query) async {
    if (query.length < 3) {
      _locationSuggestions.clear();
      notifyListeners();
      return;
    }

    try {
      _setSearchingLocations(true);
      
      final suggestions = await _addressRepository.searchLocations(query);
      _locationSuggestions = suggestions;
    } catch (e) {
      _locationSuggestions.clear();
    } finally {
      _setSearchingLocations(false);
    }
  }

  // Validate pincode
  Future<Map<String, dynamic>?> validatePincode(String pincode) async {
    try {
      return await _addressRepository.validatePincode(pincode);
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
      return await _addressRepository.getLocationFromCoordinates(latitude, longitude);
    } catch (e) {
      return null;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadShopAddresses(forceRefresh: true);
    await loadFilterOptions();
  }

  // Get distance to shop from current location
  String getDistanceToShop(ShopAddress shop) {
    if (_currentPosition == null) return '';
    
    return shop.getDistanceText(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
  }

  // Sort shops by distance
  void sortShopsByDistance() {
    if (_currentPosition == null) return;
    
    _shopAddresses.sort((a, b) {
      final distanceA = a.distanceFrom(_currentPosition!.latitude, _currentPosition!.longitude);
      final distanceB = b.distanceFrom(_currentPosition!.latitude, _currentPosition!.longitude);
      return distanceA.compareTo(distanceB);
    });
    
    notifyListeners();
  }

  // Sort shops by name
  void sortShopsByName() {
    _shopAddresses.sort((a, b) => a.shopName.compareTo(b.shopName));
    notifyListeners();
  }

  // Sort shops by status (open first)
  void sortShopsByStatus() {
    _shopAddresses.sort((a, b) {
      if (a.isCurrentlyOpen && !b.isCurrentlyOpen) return -1;
      if (!a.isCurrentlyOpen && b.isCurrentlyOpen) return 1;
      return 0;
    });
    notifyListeners();
  }

  // Private helper methods
  void _setState(AddressState state) {
    if (_state != state) {
      _state = state;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setUpdating(bool updating) {
    if (_isUpdating != updating) {
      _isUpdating = updating;
      notifyListeners();
    }
  }

  void _setSearchingLocations(bool searching) {
    if (_isSearchingLocations != searching) {
      _isSearchingLocations = searching;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Clear data
  void clearData() {
    _shopAddresses.clear();
    _nearbyShops.clear();
    _selectedShopAddress = null;
    _locationSuggestions.clear();
    _currentPosition = null;
    _selectedCity = null;
    _selectedState = null;
    _selectedCategoryId = null;
    _setState(AddressState.initial);
  }

  // Reset state
  void reset() {
    clearData();
    _myShopAddress = null;
    _errorMessage = null;
    _isLoading = false;
    _isUpdating = false;
    _isSearchingLocations = false;
    notifyListeners();
  }
}
