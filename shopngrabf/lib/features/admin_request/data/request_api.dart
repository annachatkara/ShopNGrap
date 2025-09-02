// Admin request API implementation
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/request_model.dart';

class RequestApi {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<TicketsResponse>> getTickets({RequestFilters? filters, bool forAdmin = false}) async {
    final Map<String, dynamic> params = filters?.toQueryParams() ?? {};
    String url = ApiEndpoints.requests;
    if (forAdmin) {
      url = ApiEndpoints.adminRequests;
    }
    final response = await _client.get<Map<String, dynamic>>(
      url,
      queryParams: params,
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse(
        isSuccess: true,
        data: TicketsResponse.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse(
      isSuccess: false,
      error: response.error,
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<RequestTicket>> getTicket(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiEndpoints.requests}/$id',
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: RequestTicket.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.failure(
      error: response.error,
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<RequestTicket>> createTicket(Map<String, dynamic> body) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.requests,
      body: body,
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: RequestTicket.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.failure(
      error: response.error,
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<RequestTicket>> addComment(int ticketId, Map<String, dynamic> body) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiEndpoints.requests}/$ticketId/comments',
      body: body,
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: RequestTicket.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.failure(
      error: response.error,
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<void>> updateTicketStatus(int ticketId, String status, {int? assigneeId}) async {
    final body = {'status': status};
    if (assigneeId != null) body['assigneeId'] = assigneeId;
    final response = await _client.put<void>(
      '${ApiEndpoints.requests}/$ticketId/status',
      body: body,
      requiresAuth: true,
    );
    if (response.isSuccess) {
      return ApiResponse.success(data: null, statusCode: response.statusCode);
    }
    return ApiResponse.failure(error: response.error, statusCode: response.statusCode);
  }

  Future<ApiResponse<void>> deleteTicket(int ticketId) async {
    final response = await _client.delete(
      '${ApiEndpoints.requests}/$ticketId',
      requiresAuth: true,
    );
    if (response.isSuccess) {
      return ApiResponse.success(data: null, statusCode: response.statusCode);
    }
    return ApiResponse.failure(error: response.error, statusCode: response.statusCode);
  }
}
