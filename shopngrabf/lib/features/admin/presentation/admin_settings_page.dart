import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/admin_model.dart';
import 'admin_provider.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});
  static const routeName = '/admin/settings';

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _taxCtrl = TextEditingController();
  bool? _registrationOpen;
  bool? _requireEmailVerification;
  String? _currency;

  @override
  void initState() {
    super.initState();
    final p = context.read<AdminProvider>();
    p.loadSettings().then((_) {
      final s = p.settings!;
      setState(() {
        _registrationOpen = s.registrationOpen;
        _requireEmailVerification = s.requireEmailVerification;
        _taxCtrl.text = (s.taxRate * 100).toStringAsFixed(0);
        _currency = s.currency;
      });
    });
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminProvider>();
    if (p.isUpdatingSettings) return const Center(child: LoadingIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('System Settings')),
      body: p.error != null
          ? Center(child: Text(p.error!))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Open Registration'),
                  value: _registrationOpen ?? true,
                  onChanged: (v) => setState(() => _registrationOpen = v),
                ),
                SwitchListTile(
                  title: const Text('Require Email Verification'),
                  value: _requireEmailVerification ?? true,
                  onChanged: (v) => setState(() => _requireEmailVerification = v),
                ),
                TextField(
                  controller: _taxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tax Rate (%)',
                    suffixText: '%',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: ['INR','USD','EUR','GBP']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Settings'),
                ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    final provider = context.read<AdminProvider>();
    final s = provider.settings!;
    final updated = SystemSettings(
      registrationOpen: _registrationOpen!,
      requireEmailVerification: _requireEmailVerification!,
      taxRate: double.tryParse(_taxCtrl.text.trim())! / 100,
      currency: _currency!,
      updatedAt: s.updatedAt,
    );
    final success = await provider.updateSettings(updated);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
