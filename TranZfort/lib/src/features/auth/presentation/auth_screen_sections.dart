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
  bool _showEmailSignIn = false;

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
    final ttsSummary = limitTtsSentences(TtsLocalizations.of(context).ttsAuthWelcomeShort);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 112,
                        height: 112,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBase,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider),
                          boxShadow: AppShadows.elevation2,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.local_shipping_outlined,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appTitle,
                      style: AppTypography.pageTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.authWelcomeSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (!appConfig.isSupabaseConfigured) ...[
                      WarningBlock(
                        title: l10n.authConfigIncompleteTitle,
                        message: l10n.authConfigIncompleteSignInMessage,
                      ),
                      const SizedBox(height: 16),
                    ],
                    GoogleSignInButton(
                      continueWithLabel: l10n.authContinueWith,
                      semanticLabel: l10n.authContinueWithGoogle,
                      onPressed: _continueWithGoogle,
                      isLoading: authScreenState.isLoading,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.authOrWithEmail,
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.divider)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextActionButton(
                      label: l10n.authSignInWithEmail,
                      onPressed: () => setState(() => _showEmailSignIn = !_showEmailSignIn),
                    ),
                    const SizedBox(height: 8),
                    TextActionButton(
                      label: l10n.authPasswordSwitchToSignUp,
                      onPressed: () => context.go(AppRoutes.authPasswordPath),
                    ),
                    if (_showEmailSignIn) ...[
                      const SizedBox(height: 20),
                      AppDecorations.brandGradientCard(
                        innerColor: AppColors.surfaceBase,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                controller: _emailController,
                                label: l10n.profileEmailLabel,
                                keyboardType: TextInputType.emailAddress,
                                hintText: l10n.authEmailHint,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _passwordController,
                                label: l10n.authPasswordLabel,
                                hintText: l10n.authPasswordHint,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              const SizedBox(height: 16),
                              PrimaryButton(
                                label: l10n.authPasswordSignInAction,
                                onPressed: _signInWithEmail,
                                isLoading: authScreenState.isLoading,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                runSpacing: 4,
                                spacing: 12,
                                children: [
                                  _isForgotPasswordLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
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
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          TtsScreenSummaryEffect(
            summary: ttsSummary,
            screenKey: AppRoutes.authPath,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TtsActionButton(),
                LanguageToggleAction(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
