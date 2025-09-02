// User management page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import 'admin_provider.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});
  static const routeName = '/admin/users';

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminProvider>().loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          )
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, p, _) {
          if (p.isLoading && p.users.isEmpty) return const Center(child: LoadingIndicator());
          if (p.state == AdminState.error && p.users.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Error',
                subtitle: p.error ?? 'Failed to load users',
              ),
            );
          }
          if (p.users.isEmpty) {
            return const EmptyState(
              icon: Icons.person_off,
              title: 'No Users',
              subtitle: 'No registered users found',
            );
          }
          return ListView.builder(
            itemCount: p.users.length,
            itemBuilder: (_, i) {
              final u = p.users[i];
              return ListTile(
                leading: Icon(u.role == 'superuser' ? Icons.admin_panel_settings : Icons.person),
                title: Text(u.name),
                subtitle: Text(u.email),
                trailing: Switch(
                  value: u.isActive,
                  onChanged: (v) => p.toggleUser(u.id, v),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Search Users'),
          content: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(hintText: 'Name or email'),
          ),
          actions: [
            TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () {
              Navigator.pop(context);
              context.read<AdminProvider>().loadUsers(search: _searchCtrl.text.trim());
            }, child: const Text('Search')),
          ],
        );
      },
    );
  }
}
