// Auth provider
import 'package:flutter/foundation.dart';
import '../../../core/utils/error_handler.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // State variables
  AuthState _authState = AuthState.initial;
  User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthState get authState => _authState;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authState == AuthState.authenticated && _currentUser != null;
  bool get isUnauthenticated => _authState == AuthState.unauthenticated;
  bool get hasError => _authState == AuthState.error;

  // User role getters
  bool get isCustomer => _currentUser?.isCustomer ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSuperuser => _currentUser?.isSuperuser ?? false;
  String get userRole => _currentUser?.role ?? 'customer';

  // Initialize auth state
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authRepository.getCurrentUser();
        if (_currentUser != null) {
          _setAuthState(AuthState.authenticated);
        } else {
          _setAuthState(AuthState.unauthenticated);
        }
      } else {
        _setAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('Failed to initialize authentication');
      _setAuthState(AuthState.unauthenticated);
    } finally {
      _setLoading(false);
    }
  }

  // Register user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final request = RegisterRequest(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      final authResponse = await _authRepository.register(request);
      _currentUser = authResponse.user;
      _setAuthState(AuthState.authenticated);
      
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setAuthState(AuthState.error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final request = LoginRequest(email: email, password: password);
      final authResponse = await _authRepository.login(request);
      _currentUser = authResponse.user;
      _setAuthState(AuthState.authenticated);
      
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Invalid email or password');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      _setAuthState(AuthState.error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authRepository.logout();
    } catch (e) {
      // Continue with logout even if API call fails
      debugPrint('Logout error: $e');
    } finally {
      _currentUser = null;
      _setAuthState(AuthState.unauthenticated);
      _setLoading(false);
      _clearError();
    }
  }

  // Get user profile (refresh)
  Future<bool> refreshProfile() async {
    if (!isAuthenticated) return false;

    try {
      _setLoading(true);
      _clearError();

      _currentUser = await _authRepository.getProfile();
      notifyListeners();
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        await logout();
        return false;
      }
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
  }) async {
    if (!isAuthenticated) return false;

    try {
      _setLoading(true);
      _clearError();

      final profileData = <String, dynamic>{};
      if (name != null && name.isNotEmpty) profileData['name'] = name;
      if (phone != null && phone.isNotEmpty) profileData['phone'] = phone;

      if (profileData.isEmpty) return true; // No changes

      _currentUser = await _authRepository.updateProfile(profileData);
      notifyListeners();
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        await logout();
        return false;
      }
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) return false;

    try {
      _setLoading(true);
      _clearError();

      final request = ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      await _authRepository.changePassword(request);
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        await logout();
        return false;
      }
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Forgot password
  Future<bool> forgotPassword({required String email}) async {
    try {
      _setLoading(true);
      _clearError();

      final request = ForgotPasswordRequest(email: email);
      await _authRepository.forgotPassword(request);
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final request = ResetPasswordRequest(
        token: token,
        newPassword: newPassword,
      );

      await _authRepository.resetPassword(request);
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get user stats
  Future<Map<String, dynamic>?> getUserStats() async {
    if (!isAuthenticated) return null;

    try {
      return await _authRepository.getUserStats();
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        await logout();
      }
      return null;
    }
  }

  // Refresh token (internal use)
  Future<bool> _refreshToken() async {
    try {
      final authResponse = await _authRepository.refreshToken();
      if (authResponse != null) {
        _currentUser = authResponse.user;
        _setAuthState(AuthState.authenticated);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check and refresh token if needed
  Future<bool> checkAndRefreshToken() async {
    if (!isAuthenticated) return false;
    
    // In a real app, you might want to check token expiry here
    // For now, just return true if authenticated
    return true;
  }

  // Private helper methods
  void _setAuthState(AuthState state) {
    if (_authState != state) {
      _authState = state;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
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

  // Clear all data (for testing or logout)
  void clear() {
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    _authState = AuthState.unauthenticated;
    notifyListeners();
  }
}
