// Profile provider
import 'package:flutter/foundation.dart';
import '../../../core/utils/error_handler.dart';
import '../data/profile_repository.dart';
import '../domain/profile_model.dart';

enum ProfileState { initial, loading, loaded, error }

class ProfileProvider with ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();

  ProfileState _state = ProfileState.initial;
  UserProfile? _profile;
  String? _errorMessage;
  bool _isUpdating = false;
  bool _isUploadingAvatar = false;

  ProfileState get state => _state;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ProfileState.loading;
  bool get isUpdating => _isUpdating;
  bool get isUploadingAvatar => _isUploadingAvatar;

  Future<void> loadProfile({bool forceRefresh = false}) async {
    try {
      _state = ProfileState.loading;
      notifyListeners();
      _profile = await _repository.getProfile(forceRefresh: forceRefresh);
      _state = ProfileState.loaded;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _state = ProfileState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> updateProfile(UserProfile updated) async {
    try {
      _isUpdating = true;
      notifyListeners();
      _profile = await _repository.updateProfile(updated);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<String?> uploadAvatar(String path, String name) async {
    try {
      _isUploadingAvatar = true;
      notifyListeners();
      final url = await _repository.uploadAvatar(path, name);
      if (url != null && _profile != null) {
        _profile = _profile!.copyWith(avatarUrl: url);
      }
      return url;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return null;
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
