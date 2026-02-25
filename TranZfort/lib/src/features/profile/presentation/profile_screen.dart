import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Full Name'),
                subtitle: Text('${profile['full_name'] ?? '-'}'),
              ),
              ListTile(
                title: const Text('Mobile'),
                subtitle: Text('${profile['mobile'] ?? '-'}'),
              ),
              ListTile(
                title: const Text('Role'),
                subtitle: Text('${profile['user_role_type'] ?? '-'}'),
              ),
              ListTile(
                title: const Text('Verification Status'),
                subtitle: Text('${profile['verification_status'] ?? '-'}'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
      ),
    );
  }
}
