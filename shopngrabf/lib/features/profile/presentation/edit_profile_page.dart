// Edit profile page UI
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../domain/profile_model.dart';
import 'profile_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  DateTime? _dob;
  String? _gender;
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile!;
    _nameCtrl = TextEditingController(text: profile.name);
    _emailCtrl = TextEditingController(text: profile.email);
    _phoneCtrl = TextEditingController(text: profile.phone);
    _dob = profile.dateOfBirth;
    _gender = profile.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : provider.profile!.avatarUrl != null
                              ? NetworkImage(provider.profile!.avatarUrl!) as ImageProvider
                              : null,
                      child: _avatarFile == null && provider.profile!.avatarUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    controller: _nameCtrl,
                    label: 'Name',
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v != null && v.contains('@') ? null : 'Invalid email',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneCtrl,
                    label: 'Phone',
                    keyboardType: TextInputType.phone,
                    validator: (v) => v != null && v.length >= 10 ? null : 'Invalid phone',
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(Icons.cake),
                    title: Text(_dob != null
                        ? 'DOB: ${_dob!.toLocal().toIso8601String().split('T')[0]}'
                        : 'Select Date of Birth'),
                    onTap: _pickDOB,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: ['male','female','other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g.capitalize())))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),

                  provider.isUpdating
                      ? const LoadingIndicator()
                      : CustomButton(
                          onPressed: _save,
                          child: const Text('Save'),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _avatarFile = File(image.path);
      });
      // Upload immediately
      final url = await context.read<ProfileProvider>().uploadAvatar(image.path, image.name);
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Avatar upload failed'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _pickDOB() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _dob == null || _gender == null) return;
    final provider = context.read<ProfileProvider>();
    final profile = provider.profile!;
    final updated = profile.copyWith(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      updatedAt: DateTime.now(),
    );
    final success = await provider.updateProfile(updated);
    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Update failed'), backgroundColor: Colors.red),
      );
    }
  }
}

extension StringCap on String {
  String capitalize() => length>0? '${this[0].toUpperCase()}${substring(1)}': this;
}
