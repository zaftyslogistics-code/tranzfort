import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/admin_auth_flow_providers.dart';
import '../../../core/providers/admin_app_state_providers.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../core/repositories/admin_auth_repository.dart';
import '../../super_ops/presentation/admin_super_load_console_screen.dart';
import '../../support/presentation/admin_support_queue_screen.dart';
import '../../super_ops/presentation/admin_operational_case_queue_screen.dart';
import '../../verification/presentation/admin_verification_queue_screen.dart';

class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminVerificationQueueScreen();
  }
}

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminSupportQueueScreen();
  }
}

class AdminSuperOpsScreen extends StatelessWidget {
  const AdminSuperOpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: AdminColors.cardSurface,
            child: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Operational cases'),
                Tab(text: 'Super Loads'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                AdminOperationalCaseQueueScreen(),
                AdminSuperLoadConsoleScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminScrollView(
      children: [
        _AdminSectionCard(
          title: 'Admin settings',
          child: Column(
            children: [
              _AdminInfoRow(label: 'Theme', value: 'Dark admin shell active'),
              _AdminInfoRow(label: 'Notification routing', value: 'Admin alerts entry available'),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminScrollView(
      children: [
        _AdminSectionCard(
          title: 'Admin alerts',
          child: Column(
            children: [
              _AdminInfoRow(label: 'Verification escalation', value: '12 min ago'),
              _AdminInfoRow(label: 'Support SLA warning', value: '23 min ago'),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final result = await ref.read(adminLoginControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      return;
    }

    final message = switch (result.failureReason) {
      AdminSignInFailureReason.invalidCredentials => 'We could not sign you in with those admin credentials. Check your email and password and try again.',
      AdminSignInFailureReason.notAuthorized => 'This account is not authorized for admin access. Use an approved admin account instead.',
      AdminSignInFailureReason.deactivated => 'This admin account has been deactivated. Contact a super admin if you need access restored.',
      _ => 'Admin sign-in is unavailable right now. Try again shortly.',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Enter a valid admin email first so the password reset can be sent.')),
        );
      return;
    }

    final ok = await ref.read(adminLoginControllerProvider.notifier).requestPasswordReset(email);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Password reset instructions have been sent to your admin email.'
                : 'We could not send the password reset email right now. Try again shortly.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(adminLoginControllerProvider);
    final client = ref.watch(adminSupabaseClientProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (client == null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AdminColors.warning.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Supabase is not configured or unavailable in this build, so admin sign-in and live admin data will remain unavailable until startup configuration is fixed.',
                              style: TextStyle(color: AdminColors.warning, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Icon(Icons.admin_panel_settings_outlined, size: 56, color: AdminColors.accentTeal),
                        const SizedBox(height: 16),
                        Text('Admin Login', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in with your approved admin email and password to access dashboard, queues, and operational controls.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Admin email',
                            hintText: 'ops@example.com',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Enter admin email';
                            }
                            if (!text.contains('@')) {
                              return 'Enter a valid admin email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Enter password';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loginState.isLoading ? null : _submit,
                          child: loginState.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Sign In'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: loginState.isLoading ? null : _requestPasswordReset,
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminScrollView extends StatelessWidget {
  final List<Widget> children;

  const _AdminScrollView({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      itemBuilder: (context, index) => children[index],
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemCount: children.length,
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _AdminSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _AdminInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _AdminInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
