// Admin request status page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/request_model.dart';
import 'request_provider.dart';
import 'request_detail_page.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  @override
  void initState() {
    super.initState();
    context.read<RequestProvider>().loadTickets(forAdmin: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: Consumer<RequestProvider>(
        builder: (context, provider, _) {
          if (provider.state == RequestState.loading && provider.tickets.isEmpty) {
            return const Center(child: LoadingIndicator());
          }
          if (provider.state == RequestState.error && provider.tickets.isEmpty) {
            return Center(child: Text(provider.errorMessage ?? 'Error loading requests'));
          }
          if (provider.tickets.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox,
              title: 'No Requests Found',
              subtitle: 'You have not submitted any requests yet.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadTickets(forAdmin: false, refresh: true),
            child: ListView.builder(
              itemCount: provider.tickets.length,
              itemBuilder: (context, index) {
                final ticket = provider.tickets[index];
                return ListTile(
                  title: Text(ticket.subject),
                  subtitle: Text('Status: ${ticket.status.capitalize()}'),
                  trailing: Text(ticket.createdAt.toLocal().toString().split(' ')[0]),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailPage(ticketId: ticket.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/submit-request'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

extension StringCap on String {
  String capitalize() => this.isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}
