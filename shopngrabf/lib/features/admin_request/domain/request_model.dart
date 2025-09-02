// Admin request model
class RequestTicket {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String type;         // e.g., 'support', 'feature', 'shop_registration'
  final String subject;
  final String message;
  final String status;       // 'open', 'in_progress', 'resolved', 'closed'
  final int? assigneeId;     // Admin user handling
  final String? assigneeName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RequestComment> comments;

  RequestTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.subject,
    required this.message,
    required this.status,
    this.assigneeId,
    this.assigneeName,
    required this.createdAt,
    required this.updatedAt,
    this.comments = const [],
  });

  factory RequestTicket.fromJson(Map<String, dynamic> json) {
    final commentsJson = json['comments'] as List<dynamic>? ?? [];
    final comments = commentsJson.map((c) => RequestComment.fromJson(c)).toList();
    return RequestTicket(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? json['user']?['id'] ?? 0,
      userName: json['userName'] ?? json['user']?['name'] ?? '',
      userEmail: json['userEmail'] ?? json['user']?['email'] ?? '',
      type: json['type'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'open',
      assigneeId: json['assigneeId'],
      assigneeName: json['assigneeName'] ?? json['assignee']?['name'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      comments: comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'subject': subject,
      'message': message,
      'status': status,
      'assigneeId': assigneeId,
    };
  }
}

class RequestComment {
  final int id;
  final int ticketId;
  final int userId;    // Could be admin or user
  final String userName;
  final String message;
  final DateTime createdAt;

  RequestComment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
  });

  factory RequestComment.fromJson(Map<String, dynamic> json) {
    return RequestComment(
      id: json['id'] ?? 0,
      ticketId: json['ticketId'] ?? 0,
      userId: json['userId'] ?? json['user']?['id'] ?? 0,
      userName: json['userName'] ?? json['user']?['name'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'message': message,
    };
  }
}

class TicketFilters {
  final String? type;
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int? assigneeId;
  final int page;
  final int limit;

  const TicketFilters({
    this.type,
    this.status,
    this.fromDate,
    this.toDate,
    this.assigneeId,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;
    if (fromDate != null) params['fromDate'] = fromDate!.toIso8601String();
    if (toDate != null) params['toDate'] = toDate!.toIso8601String();
    if (assigneeId != null) params['assigneeId'] = assigneeId;
    return params;
  }
}

class TicketsResponse {
  final List<RequestTicket> tickets;
  final Pagination pagination;

  TicketsResponse({
    required this.tickets,
    required this.pagination,
  });

  factory TicketsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['tickets'] as List<dynamic>? ?? [])
        .map((t) => RequestTicket.fromJson(t)).toList();
    return TicketsResponse(
      tickets: list,
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}
