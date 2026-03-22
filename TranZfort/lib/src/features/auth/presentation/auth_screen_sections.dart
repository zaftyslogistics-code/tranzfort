part of 'auth_screens.dart';

class _SetupActionCard extends StatelessWidget {
  final String title;
  final String status;
  final String actionLabel;
  final Future<void> Function() onPressed;

  const _SetupActionCard({
    required this.title,
    required this.status,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(status, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            OutlineButton(
              label: actionLabel,
              onPressed: () => unawaited(onPressed()),
            ),
          ],
        ),
      ),
    );
  }
}

void _routeFromResolvedAuthState(BuildContext context, AuthStateSnapshot authState) {
  final profile = authState.profile;
  final hasKnownRole = (profile?.hasRole ?? false) || authState.role != AppUserRole.unknown;
  final isProfileComplete = (profile?.hasName ?? false) && (profile?.hasMobile ?? false) && hasKnownRole;

  if (authState.isDeactivated) {
    context.go(AppRoutes.deleteAccountPath);
    return;
  }

  if (authState.isBanned) {
    context.go(AppRoutes.bannedPath);
    return;
  }

  if (!hasKnownRole || !isProfileComplete) {
    context.go(AppRoutes.onboardingPath);
    return;
  }

  if (authState.role == AppUserRole.supplier) {
    context.go(AppRoutes.supplierDashboardPath);
  } else {
    context.go(AppRoutes.truckerDashboardPath);
  }
}

class AuthEntryScreen extends ConsumerStatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  ConsumerState<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends ConsumerState<AuthEntryScreen> {
  late final ContextualTtsService _contextualTtsService;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isGoogleLoading = false;
  bool _isEmailLoading = false;
  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _isForgotPasswordLoading = false;

  @override
  void initState() {
    super.initState();
    _contextualTtsService = ref.read(contextualTtsServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  Future<void> _speakPrompt() async {
    await _contextualTtsService.speakSummary(
          languageCode: 'hi',
          message: AppLocalizations.of(context).authTtsSignInPrompt,
        );
  }

  Future<void> _continueWithGoogle() async {
    if (!_termsAccepted) {
      _showTermsRequiredMessage();
      return;
    }
    setState(() => _isGoogleLoading = true);
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _isGoogleLoading = false);

    if (result.isFailure) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      AppSnackbar.show(
        context: context,
        message: l10n.authGoogleFailureMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    ref.invalidate(authStateProvider);
    final refreshedAuthState = await ref.read(authStateProvider.future);
    if (!mounted) {
      return;
    }
    _routeFromResolvedAuthState(context, refreshedAuthState);
  }

  Future<void> _signInWithEmail() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!_termsAccepted) {
      _showTermsRequiredMessage();
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      AppSnackbar.show(context: context, message: l10n.authPasswordInvalidEmailMessage, variant: AppSnackbarVariant.error);
      return;
    }
    if (password.trim().length < 8) {
      AppSnackbar.show(context: context, message: l10n.authPasswordTooShortMessage, variant: AppSnackbarVariant.error);
      return;
    }

    setState(() => _isEmailLoading = true);
    final result = await ref.read(authRepositoryProvider).signInWithPassword(email: email, password: password);
    if (!mounted) return;
    setState(() => _isEmailLoading = false);

    if (result.isFailure) {
      final failure = result.failureOrNull;
      final failureMessage = switch (failure) {
        ValidationFailure(message: final message) => message,
        BusinessRuleFailure(message: final message) => message,
        _ => l10n.authPasswordSignInFailureMessage,
      };
      AppSnackbar.show(context: context, message: failureMessage, variant: AppSnackbarVariant.error);
      return;
    }

    ref.invalidate(authStateProvider);
    AuthStateSnapshot refreshedAuthState;
    try {
      refreshedAuthState = await ref.read(authStateProvider.future).timeout(const Duration(seconds: 4));
    } catch (_) {
      refreshedAuthState = ref.read(currentAuthStateProvider);
    }
    if (!mounted) return;
    _routeFromResolvedAuthState(context, refreshedAuthState);
  }

  Future<void> _forgotPassword() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      AppSnackbar.show(context: context, message: l10n.authPasswordInvalidEmailMessage, variant: AppSnackbarVariant.error);
      return;
    }
    setState(() => _isForgotPasswordLoading = true);
    final result = await ref.read(authRepositoryProvider).resetPasswordForEmail(email: email);
    if (!mounted) return;
    setState(() => _isForgotPasswordLoading = false);
    AppSnackbar.show(
      context: context,
      message: result.isSuccess
          ? 'Password reset link sent to $email. Check your inbox.'
          : 'Unable to send reset link. Please try again.',
      variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
    );
  }

  void _showTermsRequiredMessage() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    AppSnackbar.show(
      context: context,
      message: l10n.authTermsInfoMessage,
      variant: AppSnackbarVariant.error,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    unawaited(_contextualTtsService.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final appConfig = ref.watch(appConfigProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!appConfig.isSupabaseConfigured) ...[
                    WarningBlock(
                      title: 'App configuration incomplete',
                      message: 'Supabase is not configured in this build, so sign-in and live account data will remain unavailable until the environment is fixed.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/main-logo-transparent.png',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_shipping_outlined, size: 64),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.authWelcomeTitle,
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.authWelcomeSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _emailController,
                    label: l10n.profileEmailLabel,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'you@example.com',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    label: l10n.authPasswordLabel,
                    hintText: l10n.authPasswordHint,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                          activeColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                          child: Text(
                            l10n.authTermsOfService,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: l10n.authPasswordSignInAction,
                    onPressed: _signInWithEmail,
                    isLoading: _isEmailLoading,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlineButton(
                    label: l10n.authContinueWithGoogle,
                    onPressed: _continueWithGoogle,
                    isLoading: _isGoogleLoading,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    spacing: 12,
                    children: [
                      TextActionButton(
                        label: l10n.authPasswordSwitchToSignUp,
                        onPressed: () => context.go(AppRoutes.authPasswordPath),
                      ),
                      _isForgotPasswordLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : TextActionButton(
                              label: 'Forgot password?',
                              onPressed: _forgotPassword,
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmailPasswordAuthScreen extends ConsumerStatefulWidget {
  const EmailPasswordAuthScreen({super.key});

  @override
  ConsumerState<EmailPasswordAuthScreen> createState() => _EmailPasswordAuthScreenState();
}

class _EmailPasswordAuthScreenState extends ConsumerState<EmailPasswordAuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isSignUpMode = false;
  bool _isSubmitting = false;
  bool _isResendingVerification = false;
  bool _showCheckEmailState = false;
  String _pendingVerificationEmail = '';

  void _openCheckEmailState(String email) {
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _isSignUpMode = false;
      _showCheckEmailState = true;
      _pendingVerificationEmail = email;
    });
  }

  void _returnToSignIn() {
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _isSignUpMode = false;
      _showCheckEmailState = false;
    });
  }

  void _editEmailForSignUp() {
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _isSignUpMode = true;
      _showCheckEmailState = false;
      _pendingVerificationEmail = '';
    });
  }

  Future<void> _resendVerificationEmail() async {
    final l10n = AppLocalizations.of(context);
    final email = _pendingVerificationEmail.trim();
    if (email.isEmpty) {
      AppSnackbar.show(
        context: context,
        message: l10n.authPasswordInvalidEmailMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    setState(() => _isResendingVerification = true);
    final result = await ref.read(authRepositoryProvider).resendSignUpVerificationEmail(email: email);
    if (!mounted) {
      return;
    }
    setState(() => _isResendingVerification = false);

    if (result.isFailure) {
      final failure = result.failureOrNull;
      final failureMessage = switch (failure) {
        ValidationFailure(message: final message) => message,
        BusinessRuleFailure(message: final message) => message,
        _ => l10n.authPasswordResendVerificationFailureMessage,
      };
      AppSnackbar.show(
        context: context,
        message: failureMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    AppSnackbar.show(
      context: context,
      message: l10n.authPasswordResendVerificationSuccessMessage(email),
      variant: AppSnackbarVariant.success,
    );
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      AppSnackbar.show(
        context: context,
        message: l10n.authPasswordInvalidEmailMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    if (password.trim().length < 8) {
      AppSnackbar.show(
        context: context,
        message: l10n.authPasswordTooShortMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    if (_isSignUpMode && password != confirmPassword) {
      AppSnackbar.show(
        context: context,
        message: l10n.authPasswordConfirmMismatchMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final repository = ref.read(authRepositoryProvider);
    final result = _isSignUpMode
        ? await repository.signUpWithPassword(email: email, password: password)
        : await repository.signInWithPassword(email: email, password: password);
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (result.isFailure) {
      final failure = result.failureOrNull;
      final failureMessage = switch (failure) {
        ValidationFailure(message: final message) => message,
        BusinessRuleFailure(message: final message) => message,
        _ => _isSignUpMode
            ? l10n.authPasswordSignUpFailureMessage
            : l10n.authPasswordSignInFailureMessage,
      };
      AppSnackbar.show(
        context: context,
        message: failureMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    ref.invalidate(authStateProvider);
    AuthStateSnapshot refreshedAuthState;
    try {
      refreshedAuthState = await ref.read(authStateProvider.future).timeout(const Duration(seconds: 4));
    } catch (_) {
      refreshedAuthState = ref.read(currentAuthStateProvider);
    }
    if (!mounted) {
      return;
    }

    if (_isSignUpMode && !refreshedAuthState.hasSession) {
      _openCheckEmailState(email);
      return;
    }

    _routeFromResolvedAuthState(context, refreshedAuthState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authPasswordTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _showCheckEmailState
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 64),
                        const SizedBox(height: 24),
                        Text(
                          l10n.authPasswordCheckEmailTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.authPasswordCheckEmailSubtitle(_pendingVerificationEmail),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: l10n.authPasswordBackToSignInAction,
                          onPressed: _returnToSignIn,
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: l10n.authPasswordResendVerificationAction,
                          onPressed: _resendVerificationEmail,
                          isLoading: _isResendingVerification,
                        ),
                        const SizedBox(height: 16),
                        TextActionButton(
                          label: l10n.authPasswordUseDifferentEmailAction,
                          onPressed: _editEmailForSignUp,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isSignUpMode ? l10n.authPasswordModeSignUp : l10n.authPasswordModeSignIn,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.authPasswordSubtitle),
                        const SizedBox(height: 24),
                        AppTextField(
                          controller: _emailController,
                          label: l10n.profileEmailLabel,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _PasswordFieldWithToggle(
                          controller: _passwordController,
                          label: l10n.authPasswordLabel,
                          hintText: l10n.authPasswordHint,
                        ),
                        if (_isSignUpMode) ...[
                          const SizedBox(height: 16),
                          _PasswordFieldWithToggle(
                            controller: _confirmPasswordController,
                            label: l10n.authPasswordConfirmLabel,
                            hintText: l10n.authPasswordHint,
                          ),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: _isSignUpMode ? l10n.authPasswordSignUpAction : l10n.authPasswordSignInAction,
                          onPressed: _submit,
                          isLoading: _isSubmitting,
                        ),
                        const SizedBox(height: 16),
                        TextActionButton(
                          label: _isSignUpMode
                              ? l10n.authPasswordSwitchToSignIn
                              : l10n.authPasswordSwitchToSignUp,
                          onPressed: () {
                            setState(() {
                              _showCheckEmailState = false;
                              _isSignUpMode = !_isSignUpMode;
                            });
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordFieldWithToggle extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;

  const _PasswordFieldWithToggle({
    required this.controller,
    required this.label,
    required this.hintText,
  });

  @override
  State<_PasswordFieldWithToggle> createState() => _PasswordFieldWithToggleState();
}

class _PasswordFieldWithToggleState extends State<_PasswordFieldWithToggle> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hintText: widget.hintText,
      obscureText: _obscure,
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
