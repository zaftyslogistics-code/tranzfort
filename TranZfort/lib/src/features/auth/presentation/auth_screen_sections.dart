part of 'auth_screens.dart';

class AuthEntryScreen extends ConsumerStatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  ConsumerState<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends ConsumerState<AuthEntryScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isForgotPasswordLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _continueWithGoogle() async {
    final result = await ref.read(authScreenControllerProvider.notifier).signInWithGoogle();
    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      AppSnackbar.show(
        context: context,
        message: l10n.authGoogleFailureMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    if (!mounted) {
      return;
    }
    context.go(AppRoutes.authPath);
  }

  Future<void> _signInWithEmail() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
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

    final result = await ref.read(authScreenControllerProvider.notifier).signInWithEmail(email: email, password: password);
    if (!mounted) return;

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

    if (!mounted) return;
    context.go(AppRoutes.authPath);
  }

  Future<void> _forgotPassword() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      AppSnackbar.show(context: context, message: l10n.authPasswordInvalidEmailMessage, variant: AppSnackbarVariant.error);
      return;
    }
    setState(() => _isForgotPasswordLoading = true);
    final result = await ref.read(authScreenControllerProvider.notifier).resetPassword(email: email);
    if (!mounted) return;
    setState(() => _isForgotPasswordLoading = false);
    AppSnackbar.show(
      context: context,
      message: result.isSuccess
          ? AppLocalizations.of(context).authPasswordResetSentSuccess(email)
          : AppLocalizations.of(context).authPasswordResetSentFailure,
      variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final appConfig = ref.watch(appConfigProvider);
    final authScreenState = ref.watch(authScreenControllerProvider);
    final ttsSummary = '${l10n.authWelcomeTitle}. ${l10n.authWelcomeSubtitle}';
    return Scaffold(
      appBar: AppBar(
        actions: [
          TtsActionButton(fallbackSummary: ttsSummary),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
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
                          title: l10n.authConfigIncompleteTitle,
                          message: l10n.authConfigIncompleteSignInMessage,
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
                        hintText: l10n.authEmailHint,
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
                      const SizedBox(height: 20),
                      GradientButton(
                        label: l10n.authPasswordSignInAction,
                        onPressed: _signInWithEmail,
                        isLoading: authScreenState.isLoading,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(l10n.authSignInDividerLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlineButton(
                        label: l10n.authContinueWithGoogle,
                        onPressed: _continueWithGoogle,
                        isLoading: authScreenState.isLoading,
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
                                  label: l10n.authForgotPasswordAction,
                                  onPressed: _forgotPassword,
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            TtsScreenSummaryEffect(
              summary: ttsSummary,
              screenKey: AppRoutes.authPath,
            ),
          ],
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

  Future<void> _resendVerificationEmail() async {
    final l10n = AppLocalizations.of(context);
    final screenState = ref.read(authScreenControllerProvider);
    final email = (screenState.pendingVerificationEmail ?? '').trim();
    if (email.isEmpty) {
      AppSnackbar.show(
        context: context,
        message: l10n.authPasswordInvalidEmailMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    final result = await ref.read(authScreenControllerProvider.notifier).resendVerificationEmail(email: email);
    if (!mounted) {
      return;
    }

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
    final screenState = ref.read(authScreenControllerProvider);
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

    if (screenState.isSignUpMode && password != confirmPassword) {
      AppSnackbar.show(
        context: context,
        message: l10n.authPasswordConfirmMismatchMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    final controller = ref.read(authScreenControllerProvider.notifier);
    final result = screenState.isSignUpMode
        ? await controller.signUpWithEmail(email: email, password: password)
        : await controller.signInWithEmail(email: email, password: password);
    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      final failure = result.failureOrNull;
      final failureMessage = switch (failure) {
        ValidationFailure(message: final message) => message,
        BusinessRuleFailure(message: final message) => message,
        _ => screenState.isSignUpMode
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
    final refreshedAuthState = ref.read(currentAuthStateProvider);
    if (screenState.isSignUpMode && !refreshedAuthState.hasSession) {
      _passwordController.clear();
      _confirmPasswordController.clear();
      return;
    }

    if (!mounted) {
      return;
    }
    context.go(AppRoutes.authPath);
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
    final screenState = ref.watch(authScreenControllerProvider);
    final ttsSummary = screenState.showCheckEmailState
        ? '${l10n.authPasswordCheckEmailTitle}. ${l10n.authPasswordCheckEmailSubtitle(screenState.pendingVerificationEmail ?? '')}'
        : '${screenState.isSignUpMode ? l10n.authPasswordModeSignUp : l10n.authPasswordModeSignIn}. ${l10n.authPasswordSubtitle}';
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.authPasswordTitle),
        actions: [
          TtsActionButton(fallbackSummary: ttsSummary),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: screenState.showCheckEmailState
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
                          l10n.authPasswordCheckEmailSubtitle(screenState.pendingVerificationEmail ?? ''),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: l10n.authPasswordBackToSignInAction,
                          onPressed: () {
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                            ref.read(authScreenControllerProvider.notifier).returnToSignIn();
                          },
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: l10n.authPasswordResendVerificationAction,
                          onPressed: _resendVerificationEmail,
                          isLoading: screenState.isResendingVerification,
                        ),
                        const SizedBox(height: 16),
                        TextActionButton(
                          label: l10n.authPasswordUseDifferentEmailAction,
                          onPressed: () {
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                            ref.read(authScreenControllerProvider.notifier).editEmailForSignUp();
                          },
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          screenState.isSignUpMode ? l10n.authPasswordModeSignUp : l10n.authPasswordModeSignIn,
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
                        if (screenState.isSignUpMode) ...[
                          const SizedBox(height: 16),
                          _PasswordFieldWithToggle(
                            controller: _confirmPasswordController,
                            label: l10n.authPasswordConfirmLabel,
                            hintText: l10n.authPasswordHint,
                          ),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: screenState.isSignUpMode ? l10n.authPasswordSignUpAction : l10n.authPasswordSignInAction,
                          onPressed: _submit,
                          isLoading: screenState.isLoading,
                        ),
                        const SizedBox(height: 16),
                        TextActionButton(
                          label: screenState.isSignUpMode
                              ? l10n.authPasswordSwitchToSignIn
                              : l10n.authPasswordSwitchToSignUp,
                          onPressed: () {
                            ref.read(authScreenControllerProvider.notifier).setSignUpMode(!screenState.isSignUpMode);
                          },
                        ),
                      ],
                    ),
                ),
              ),
            ),
            TtsScreenSummaryEffect(
              summary: ttsSummary,
              screenKey: '${AppRoutes.authPasswordPath}:${screenState.isSignUpMode}:${screenState.showCheckEmailState}',
            ),
          ],
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
