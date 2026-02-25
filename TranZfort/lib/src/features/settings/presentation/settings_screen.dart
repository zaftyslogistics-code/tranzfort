import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final role = (ref.watch(userProfileProvider).value?['user_role_type'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('General'),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: settings.language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsProvider.notifier).setLanguage(val);
                }
              },
            ),
          ),
          const Divider(),
          _SectionTitle('Voice & Bot'),
          SwitchListTile(
            title: const Text('TTS Mute'),
            subtitle: const Text('Mutes all automatic speech'),
            value: settings.ttsMuted,
            onChanged: (val) => ref.read(settingsProvider.notifier).toggleTts(val),
          ),
          const Divider(),
          _SectionTitle('Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: settings.pushEnabled,
            onChanged: (val) => ref.read(settingsProvider.notifier).togglePush(val),
          ),
          const Divider(),
          _SectionTitle('Account'),
          ListTile(
            title: const Text('My Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile'),
          ),
          if (role == 'supplier')
            ListTile(
              title: const Text('Payout Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/payout-profile'),
            ),
          const Divider(),
          _SectionTitle('Support'),
          ListTile(
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support screen pending in Sprint 9')),
              );
            },
          ),
          const Divider(),
          _SectionTitle('Data'),
          ListTile(
            title: const Text('App Version'),
            trailing: const Text('1.0.0'),
          ),
          ListTile(
            title: Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account?'),
                  content: const Text(
                    'This will permanently delete your account and all data. This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final success = await ref.read(settingsProvider.notifier).deleteAccount();
                if (success && context.mounted) {
                  context.go('/auth');
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to request account deletion')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 24),
          OutlineButton(
            label: 'Sign Out',
            onPressed: () async {
              await ref.read(settingsProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/auth');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
