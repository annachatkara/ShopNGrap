// Admin repository implementation
import '../../../core/utils/error_handler.dart';
import '../domain/admin_model.dart';
import 'admin_api.dart';

class AdminRepository {
  final AdminApi _api = AdminApi();

  Future<List<AdminUser>> fetchUsers({String? search}) async {
    final resp = await _api.getUsers(search: search);
    if (resp.isSuccess && resp.data != null) return resp.data!;
    throw AppException(message: resp.error?.message ?? 'Failed to load users');
  }

  Future<void> toggleUser(int userId, bool isActive) async {
    final resp = await _api.toggleUser(userId, isActive);
    if (!resp.isSuccess) {
      throw AppException(message: resp.error?.message ?? 'Failed to update user');
    }
  }

  Future<SystemSettings> loadSettings() async {
    final resp = await _api.getSettings();
    if (resp.isSuccess && resp.data != null) return resp.data!;
    throw AppException(message: resp.error?.message ?? 'Failed to load settings');
  }

  Future<SystemSettings> updateSettings(SystemSettings settings) async {
    final resp = await _api.updateSettings(settings);
    if (resp.isSuccess && resp.data != null) return resp.data!;
    throw AppException(message: resp.error?.message ?? 'Failed to update settings');
  }

  Future<DashboardMetrics> loadMetrics() async {
    final resp = await _api.getMetrics();
    if (resp.isSuccess && resp.data != null) return resp.data!;
    throw AppException(message: resp.error?.message ?? 'Failed to load metrics');
  }
}
