// Admin request provider
import 'package:flutter/foundation.dart';
import '../../../core/utils/error_handler.dart';
import '../domain/request_model.dart';
import '../data/request_repository.dart';

enum RequestState { initial, loading, loaded, error }

class RequestProvider with ChangeNotifier {
  final RequestRepository _repo = RequestRepository();

  RequestState _state = RequestState.initial;
  List<RequestTicket> _tickets = [];
  RequestTicket? _selectedTicket;
  String? _errorMessage;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;

  RequestState get state => _state;
  List<RequestTicket> get tickets => _tickets;
  RequestTicket? get selectedTicket => _selectedTicket;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == RequestState.loading;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadTickets({RequestFilters? filters, bool forAdmin = false, bool refresh = false}) async {
    if (_state == RequestState.loading && !refresh) return;

    try {
      if(refresh) _tickets.clear();
      _state = RequestState.loading;
      notifyListeners();

      final response = await _repo.getTickets(filters: filters, forAdmin: forAdmin);

      if(refresh) {
        _tickets = response.tickets;
      } else {
        _tickets.addAll(response.tickets);
      }

      if (_tickets.isEmpty) {
        _state = RequestState.initial;
      } else {
        _state = RequestState.loaded;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _state = RequestState.error;
      notifyListeners();
    }
  }

  Future<bool> loadTicketDetail(int id, {bool refresh = false}) async {
    try {
      if(!refresh && _selectedTicket != null && _selectedTicket!.id == id) return true;

      _state = RequestState.loading;
      notifyListeners();

      _selectedTicket = await _repo.getTicket(id);

      _state = RequestState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _state = RequestState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitTicket(Map<String, dynamic> data) async {
    try {
      _isSubmitting = true;
      notifyListeners();

      final ticket = await _repo.createTicket(data);

      _tickets.insert(0, ticket);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> addComment(int ticketId, String message) async {
    try {
      final data = {'message': message};
      final ticket = await _repo.addComment(ticketId, data);

      if (_selectedTicket != null && _selectedTicket!.id == ticketId) {
        _selectedTicket = ticket;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(int ticketId, String status, {int? assigneeId}) async {
    try {
      await _repo.updateTicketStatus(ticketId, status, assigneeId: assigneeId);

      // Refresh ticket detail
      if(_selectedTicket != null && _selectedTicket!.id == ticketId){
        await loadTicketDetail(ticketId, refresh: true);
      }

      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTicket(int ticketId) async {
    try {
      await _repo.deleteTicket(ticketId);
      _tickets.removeWhere((ticket) => ticket.id == ticketId);
      if(_selectedTicket != null && _selectedTicket!.id == ticketId) {
        _selectedTicket = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
