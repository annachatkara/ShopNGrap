// Profile repository implementation
import '../../../core/utils/error_handler.dart';
import '../../../core/storage/preferences.dart';
import '../domain/profile_model.dart';
import 'profile_api.dart';

class ProfileRepository {
  final ProfileApi _api = ProfileApi();
  final Preferences _prefs = Preferences();

  UserProfile? _cache;

  Future<UserProfile> getProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    final resp = await _api.getProfile();
    if (resp.isSuccess && resp.data != null) {
      _cache = resp.data!;
      return _cache!;
    }
    if (resp.isUnauthorized) throw AppException.unauthorized();
    throw AppException(message: resp.error?.message ?? 'Failed to load profile');
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final resp = await _api.updateProfile(profile.toJson());
    if (resp.isSuccess && resp.data != null) {
      _cache = resp.data!;
      return _cache!;
    }
    if (resp.isUnauthorized) throw AppException.unauthorized();
    throw AppException(message: resp.error?.message ?? 'Failed to update profile');
  }

  Future<String?> uploadAvatar(String path, String name) async {
    final resp = await _api.uploadAvatar(path, name);
    if (resp.isSuccess) return resp.data?['url'];
    throw AppException(message: resp.error?.message ?? 'Avatar upload failed');
  }
}
