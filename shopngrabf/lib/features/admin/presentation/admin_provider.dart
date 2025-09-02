// Admin provider
import 'package:flutter/foundation.dart';
import '../data/admin_repository.dart';
import '../domain/admin_model.dart';
import '../../../core/utils/error_handler.dart';

enum AdminState { initial, loading, loaded, error }

class AdminProvider with ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  AdminState _state = AdminState.initial;
  List<AdminUser> _users = [];
  SystemSettings? _settings;
  DashboardMetrics? _metrics;
  String? _error;

  bool _isTogglingUser = false;
  bool _isUpdatingSettings = false;

  AdminState get state => _state;
  List<AdminUser> get users => _users;
  SystemSettings? get settings => _settings;
  DashboardMetrics? get metrics => _metrics;
  String? get error => _error;
  bool get isLoading => _state == AdminState.loading;
  bool get isTogglingUser => _isTogglingUser;
  bool get isUpdatingSettings => _isUpdatingSettings;

  Future<void> loadUsers({String? search}) async {
    try {
      _state = AdminState.loading;
      notifyListeners();
      _users = await _repo.fetchUsers(search: search);
      _state = AdminState.loaded;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _state = AdminState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> toggleUser(int id, bool isActive) async {
    try {
      _isTogglingUser = true;
      notifyListeners();
      await _repo.toggleUser(id, isActive);
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) _users[index] = AdminUser(
        id: _users[index].id,
        name: _users[index].name,
        email: _users[index].email,
        role: _users[index].role,
        isActive: isActive,
        createdAt: _users[index].createdAt,
      );
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isTogglingUser = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    try {
      _isUpdatingSettings = true;
      notifyListeners();
      _settings = await _repo.loadSettings();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isUpdatingSettings = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings(SystemSettings settings) async {
    try {
      _isUpdatingSettings = true;
      notifyListeners();
      _settings = await _repo.updateSettings(settings);
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isUpdatingSettings = false;
      notifyListeners();
    }
  }

  Future<void> loadMetrics() async {
    try {
      _metrics = await _repo.loadMetrics();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }
}
