// Admin dashboard page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/admin_model.dart';
import 'admin_provider.dart';
import 'admin_user_management_page.dart';
import 'admin_settings_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminProvider>();
    provider.loadMetrics();
    provider.loadSettings();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Consumer<AdminProvider>(
              builder: (context, p, _) {
                final m = p.metrics;
                if (m == null) return const LoadingIndicator();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricCard('Users', m.totalUsers.toString(), Icons.people),
                    _metricCard('Shops', m.totalShops.toString(), Icons.store),
                    _metricCard('Orders', m.totalOrders.toString(), Icons.shopping_bag),
                    _metricCard('Revenue', Formatters.currency(m.totalRevenue), Icons.attach_money),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/admin/users'),
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Manage Users'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/admin/settings'),
              icon: const Icon(Icons.settings),
              label: const Text('System Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
