import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/request_model.dart';
import 'request_provider.dart';
import 'request_detail_page.dart';

class AdminRequestsDashboard extends StatefulWidget {
  const AdminRequestsDashboard({super.key});
  
  @override
  State<AdminRequestsDashboard> createState() => _AdminRequestsDashboardState();
}

class _AdminRequestsDashboardState extends State<AdminRequestsDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTickets());
  }
  
  void _loadTickets({int? statusFilter}) {
    final provider = context.read<RequestProvider>();
    final filters = RequestFilters(
      status: _tabController.index == 0 ? null : _statusForTab(_tabController.index),
      page: 1,
      limit: 20,
    );
    provider.loadTickets(filters: filters, forAdmin: true, refresh: true);
  }
  
  String? _statusForTab(int index) {
    switch (index) {
      case 1: return 'open';
      case 2: return 'in_progress';
      case 3: return 'resolved';
      default: return null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Requests"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Open"),
            Tab(text: "In Progress"),
            Tab(text: "Resolved"),
          ],
          onTap: (_) => _loadTickets(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Consumer<RequestProvider>(
        builder: (context, provider, child) {
          if (provider.state == RequestState.loading && provider.tickets.isEmpty) {
            return const Center(child: LoadingIndicator());
          }
          if (provider.state == RequestState.error && provider.tickets.isEmpty) {
            return Center(child: Text(provider.errorMessage ?? "Error loading tickets"));
          }
          if (provider.tickets.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox,
              title: "No Requests Found",
              subtitle: "No requests in this category yet",
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadTickets(
              filters: RequestFilters(
                status: _statusForTab(_tabController.index),
                page: 1,
                limit: 20,
              ),
              forAdmin: true,
              refresh: true,
            ),
            child: ListView.builder(
              itemCount: provider.tickets.length,
              itemBuilder: (context, index) {
                final ticket = provider.tickets[index];
                return ListTile(
                  title: Text(ticket.subject),
                  subtitle: Text(
                    "${ticket.userName} • Status: ${ticket.status.replaceAll('_', ' ').toUpperCase()}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    ticket.createdAt.toLocal().toString().split(" ")[0],
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RequestDetailPage(ticketId: ticket.id),
                  )),
                );
              },
            ),
          );
        },
      ),
    );
  }
  
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Search Requests"),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: "Search by subject, user...",
          ),
          autofocus: true,
          onSubmitted: (val) {
            Navigator.pop(context);
            _performSearch(val);
          },
        ),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () {
            Navigator.pop(context);
            _performSearch(_searchController.text);
          }, child: const Text("Search")),
        ],
      ),
    );
  }
  
  void _performSearch(String query) {
    final provider = context.read<RequestProvider>();
    if(query.trim().isEmpty) {
      provider.loadTickets(forAdmin: true, refresh: true);
    } else {
      // Implement search filtering here...
      provider.loadTickets(
        filters: RequestFilters(
          page: 1,
          limit: 20,
          // Note: Back-end support is needed for real search.
        ),
        forAdmin: true,
        refresh: true,
      );
    }
  }
}
