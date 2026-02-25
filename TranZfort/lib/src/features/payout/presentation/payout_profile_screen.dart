import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/payout_profile_provider.dart';

class PayoutProfileScreen extends ConsumerWidget {
  const PayoutProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutAsync = ref.watch(payoutProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payout Profile')),
      body: payoutAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No payout profile found yet.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Account Holder'),
                subtitle: Text('${profile['account_holder_name'] ?? '-'}'),
              ),
              ListTile(
                title: const Text('Account Last 4'),
                subtitle: Text('${profile['account_number_last4'] ?? '-'}'),
              ),
              ListTile(
                title: const Text('IFSC'),
                subtitle: Text('${profile['ifsc_code'] ?? '-'}'),
              ),
              ListTile(
                title: const Text('Status'),
                subtitle: Text('${profile['status'] ?? '-'}'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Failed to load payout profile: $e')),
      ),
    );
  }
}
