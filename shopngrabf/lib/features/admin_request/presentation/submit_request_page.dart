// Admin request form UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../domain/request_model.dart';
import 'request_provider.dart';

class SubmitRequestPage extends StatefulWidget {
  const SubmitRequestPage({super.key});

  @override
  State<SubmitRequestPage> createState() => _SubmitRequestPageState();
}

class _SubmitRequestPageState extends State<SubmitRequestPage> {
  final _formKey = GlobalKey<FormState>();
  String? _type;
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  static const List<String> _types = [
    'Support',
    'Feature Request',
    'Shop Registration',
    'Other',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Request')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Request Type'),
                items: _types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _type = val),
                validator: (val) => val == null ? 'Please select a request type' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _subjectController,
                label: 'Subject',
                validator: (v) => v == null || v.isEmpty ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _messageController,
                label: 'Message',
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: 24),
              provider.isSubmitting
                  ? const Center(child: LoadingIndicator())
                  : CustomButton(
                      onPressed: _submit,
                      child: const Text('Submit'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<RequestProvider>();
    final success = await provider.submitTicket({
      'type': _type!.toLowerCase().replaceAll(' ', '_'),
      'subject': _subjectController.text.trim(),
      'message': _messageController.text.trim(),
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to submit request')),
      );
    }
  }
}
