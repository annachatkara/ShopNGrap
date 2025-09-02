// Profile page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/profile_model.dart';
import 'profile_provider.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: LoadingIndicator());
          }
          if (provider.state == ProfileState.error) {
            return Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Error',
                subtitle: provider.errorMessage ?? 'Failed to load profile',
              ),
            );
          }
          final profile = provider.profile!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null 
                          ? const Icon(Icons.person, size: 50) 
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfilePage()),
                        ),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoTile(Icons.person, 'Name', profile.name),
              _buildInfoTile(Icons.email, 'Email', profile.email),
              _buildInfoTile(Icons.phone, 'Phone', profile.phone),
              _buildInfoTile(Icons.cake, 'Date of Birth',
                  Formatters.dateOnly(profile.dateOfBirth)),
              _buildInfoTile(Icons.wc, 'Gender', profile.gender.capitalize()),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Default Address'),
                subtitle: Text(profile.defaultAddress?.shortAddress ?? 'Not set'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_location),
                  onPressed: () {
                    // Navigate to address management
                    Navigator.pushNamed(context, '/address-management');
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Favorites'),
                subtitle: Text('${profile.favoriteProductIds.length} products, '
                    '${profile.favoriteCategoryIds.length} categories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to favorites page
                  Navigator.pushNamed(context, '/favorites');
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                subtitle: Text(provider.profile!.notificationPreferences.entries
                    .where((e) => e.value)
                    .map((e) => e.key.capitalize())
                    .join(', ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to notification settings
                  Navigator.pushNamed(context, '/notification-settings');
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Logout
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

extension StringCap on String {
  String capitalize() => 
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : this;
}
