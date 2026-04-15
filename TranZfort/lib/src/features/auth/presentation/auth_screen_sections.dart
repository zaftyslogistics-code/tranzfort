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
    if (email.isEmpty || !Validators.isValidEmail(email)) {
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
    if (email.isEmpty || !Validators.isValidEmail(email)) {
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
                      GoogleSignInButton(
                        label: l10n.authContinueWithGoogle,
                        onPressed: _continueWithGoogle,
                        isLoading: authScreenState.isLoading,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.authGoogleFastestMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(l10n.authOrWithEmail, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                      OutlineButton(
                        label: l10n.authPasswordSignInAction,
                        onPressed: _signInWithEmail,
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
