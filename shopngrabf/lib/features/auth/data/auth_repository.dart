// Auth repository implementation
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/error_handler.dart';
import '../domain/user_model.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi _authApi = AuthApi();
  final SecureStorage _secureStorage = SecureStorage();

  // Register user
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _authApi.register(request);
      
      if (response.isSuccess && response.data != null) {
        // Save auth data
        await _saveAuthData(response.data!);
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Registration failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Registration failed. Please try again.',
        originalError: e,
      );
    }
  }

  // Login user
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _authApi.login(request);
      
      if (response.isSuccess && response.data != null) {
        // Save auth data
        await _saveAuthData(response.data!);
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Login failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Login failed. Please try again.',
        originalError: e,
      );
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Call logout API (optional, for server-side cleanup)
      await _authApi.logout();
    } catch (e) {
      // Continue with logout even if API fails
    } finally {
      // Clear local auth data
      await _clearAuthData();
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final userData = await _secureStorage.getUserData();
      if (userData != null) {
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await _secureStorage.getAuthToken();
      final userData = await _secureStorage.getUserData();
      return token != null && token.isNotEmpty && userData != null;
    } catch (e) {
      return false;
    }
  }

  // Get user profile from server
  Future<User> getProfile() async {
    try {
      final response = await _authApi.getProfile();
      
      if (response.isSuccess && response.data != null) {
        // Update stored user data
        await _secureStorage.saveUserData(response.data!.toJson());
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          await _clearAuthData();
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to get profile',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to get profile. Please try again.',
        originalError: e,
      );
    }
  }

  // Update user profile
  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _authApi.updateProfile(profileData);
      
      if (response.isSuccess && response.data != null) {
        // Update stored user data
        await _secureStorage.saveUserData(response.data!.toJson());
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          await _clearAuthData();
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to update profile',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to update profile. Please try again.',
        originalError: e,
      );
    }
  }

  // Change password
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      final response = await _authApi.changePassword(request);
      
      if (!response.isSuccess) {
        if (response.isUnauthorized) {
          await _clearAuthData();
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to change password',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to change password. Please try again.',
        originalError: e,
      );
    }
  }

  // Forgot password
  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _authApi.forgotPassword(request);
      
      if (!response.isSuccess) {
        throw AppException(
          message: response.error?.message ?? 'Failed to send reset email',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to send reset email. Please try again.',
        originalError: e,
      );
    }
  }

  // Reset password
  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _authApi.resetPassword(request);
      
      if (!response.isSuccess) {
        throw AppException(
          message: response.error?.message ?? 'Failed to reset password',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to reset password. Please try again.',
        originalError: e,
      );
    }
  }

  // Refresh token
  Future<AuthResponse?> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final response = await _authApi.refreshToken(refreshToken);
      
      if (response.isSuccess && response.data != null) {
        // Save new auth data
        await _saveAuthData(response.data!);
        return response.data!;
      } else {
        // Refresh failed, clear auth data
        await _clearAuthData();
        return null;
      }
    } catch (e) {
      await _clearAuthData();
      return null;
    }
  }

  // Get user stats
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _authApi.getUserStats();
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          await _clearAuthData();
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to get user stats',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to get user stats. Please try again.',
        originalError: e,
      );
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final user = await getCurrentUser();
      return user?.role;
    } catch (e) {
      return null;
    }
  }

  // Check if user has specific role
  Future<bool> hasRole(String role) async {
    try {
      final userRole = await getUserRole();
      return userRole?.toLowerCase() == role.toLowerCase();
    } catch (e) {
      return false;
    }
  }

  // Check if user is customer
  Future<bool> isCustomer() async {
    return await hasRole('customer');
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    return await hasRole('admin');
  }

  // Check if user is superuser
  Future<bool> isSuperuser() async {
    return await hasRole('superuser');
  }

  // Private helper methods
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await Future.wait([
      _secureStorage.saveAuthToken(authResponse.token),
      _secureStorage.saveUserData(authResponse.user.toJson()),
      if (authResponse.refreshToken != null)
        _secureStorage.saveRefreshToken(authResponse.refreshToken!),
    ]);
  }

  Future<void> _clearAuthData() async {
    await _secureStorage.clearAuthData();
  }
}
