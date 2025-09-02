// Admin request repository implementation
import '../../../core/utils/error_handler.dart';
import '../domain/request_model.dart';
import 'request_api.dart';

class RequestRepository {
  final RequestApi _api = RequestApi();

  Future<TicketsResponse> getTickets({RequestFilters? filters, bool forAdmin = false}) async {
    final response = await _api.getTickets(filters: filters, forAdmin: forAdmin);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    throw AppException(message: response.error?.message ?? 'Failed to load tickets');
  }

  Future<RequestTicket> getTicket(int id) async {
    final response = await _api.getTicket(id);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    throw AppException(message: response.error?.message ?? 'Failed to load ticket');
  }

  Future<RequestTicket> createTicket(Map<String, dynamic> body) async {
    final response = await _api.createTicket(body);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    throw AppException(message: response.error?.message ?? 'Failed to create ticket');
  }

  Future<RequestTicket> addComment(int ticketId, Map<String, dynamic> body) async {
    final response = await _api.addComment(ticketId, body);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    throw AppException(message: response.error?.message ?? 'Failed to add comment');
  }

  Future<void> updateTicketStatus(int ticketId, String status, {int? assigneeId}) async {
    final response = await _api.updateTicketStatus(ticketId, status, assigneeId: assigneeId);
    if (!response.isSuccess) {
      throw AppException(message: response.error?.message ?? 'Failed to update ticket status');
    }
  }

  Future<void> deleteTicket(int ticketId) async {
    final response = await _api.deleteTicket(ticketId);
    if (!response.isSuccess) {
      throw AppException(message: response.error?.message ?? 'Failed to delete ticket');
    }
  }
}
