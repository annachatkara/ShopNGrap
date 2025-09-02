import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopngrabf/features/admin_request/presentation/request_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/formatters.dart';
import '../domain/request_model.dart';
import 'request_detail.dart'; // Remove if self-import
import 'request_detail_comment.dart';
import 'request_detail_assignment.dart';
import 'request_detail_status_update.dart';
import 'request_detail_new_comment.dart';
import 'request_detail_add_comment.dart';

import '../domain/request_model.dart'; // Already imported above, remove one

class RequestDetailPage extends StatefulWidget {
  final int ticketId;

  const RequestDetailPage({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<RequestProvider>();
    provider.loadTicketDetail(widget.ticketId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request #${widget.ticketId}"),
      ),
      body: Consumer<RequestProvider>(
        builder: (context, provider, _) {
          if (provider.state == RequestState.loading) {
            return const Center(child: LoadingIndicator());
          }
          if (provider.state == RequestState.error) {
            return Center(
              child: Text(provider.errorMessage ?? "Failed to load request."),
            );
          }
          final ticket = provider.selectedTicket;
          if (ticket == null) {
            return const Center(child: Text("Request not found."));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(ticket),
                    const SizedBox(height: 16),
                    _buildDetails(ticket),
                    const SizedBox(height: 16),
                    _buildComments(ticket),
                  ],
                ),
              ),
              _buildCommentInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(RequestTicket ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ticket.subject,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Submitted by ${ticket.userName} (${ticket.userEmail})",
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text("Status: ${ticket.status.replaceAll('_', ' ').toUpperCase()}",
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text("Created on ${Formatters.dateTime(ticket.createdAt)}",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDetails(RequestTicket ticket) {
    return Text(ticket.message, style: const TextStyle(fontSize: 16));
  }

  Widget _buildComments(RequestTicket ticket) {
    if (ticket.comments.isEmpty) {
      return const Text("No comments yet.");
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ticket.comments
          .map(
            (comment) => ListTile(
              title: Text(comment.userName),
              subtitle: Text(comment.message),
              trailing: Text(
                Formatters.dateTime(comment.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: "Add a comment...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<RequestProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: provider.isLoading ? const CircularProgressIndicator() : const Icon(Icons.send),
                onPressed: provider.isLoading ? null : _submitComment,
              );
            },
          )
        ],
      ),
    );
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<RequestProvider>();
    final success = await provider.addComment(widget.ticketId, text);
    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      provider.loadTicketDetail(widget.ticketId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? "Failed to add comment.")),
      );
    }
  }
}

extension StringCap on String {
  String capitalize() => this.isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}
