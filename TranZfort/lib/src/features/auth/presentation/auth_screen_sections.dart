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
    final ttsSummary = limitTtsSentences(TtsLocalizations.of(context).ttsAuthWelcomeShort);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // ─── Dark hero banner (top third) ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.38,
              decoration: BoxDecoration(
                gradient: AppColors.heroDark,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.heroDarkGlow,
                ),
              ),
            ),
          ),
          // ─── Content ───
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // ── Brand logo + welcome on dark hero ──
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.hero),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/main-logo-transparent.png',
                            height: 64,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.local_shipping_outlined, size: 56, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.authWelcomeTitle,
                      style: AppTypography.displayHero.copyWith(
                        color: AppColors.inkTextPrimary,
                        fontSize: 30,
                        letterSpacing: -0.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.authWelcomeSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkTextSecondary,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    // ── Primary Sign-In Card (lifts out of hero onto light canvas) ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBase,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                        boxShadow: AppShadows.elevation3,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!appConfig.isSupabaseConfigured) ...[
                            WarningBlock(
                              title: l10n.authConfigIncompleteTitle,
                              message: l10n.authConfigIncompleteSignInMessage,
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Recommended banner
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryChipBg,
                                  borderRadius: BorderRadius.circular(AppRadius.chip),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.authRecommendedChip,
                                      style: AppTypography.labelMicro.copyWith(
                                        color: AppColors.primaryChipText,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                l10n.authFastestMostSecure,
                                style: AppTypography.labelMicro.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Big prominent Google sign-in: the Google wordmark
                          // fills most of the card from left to right so the
                          // one-tap path is visually dominant.
                          GoogleSignInButton(
                            label: l10n.authContinueWithGoogle,
                            onPressed: _continueWithGoogle,
                            isLoading: authScreenState.isLoading,
                          ),
                          const SizedBox(height: 10),
                          // Trust row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline, size: 14, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text(
                                l10n.authOneTapNoPasswordSecure,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── Divider: "or sign in with email" ──
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.authOrWithEmail.toUpperCase(),
                            style: AppTypography.labelMicro.copyWith(
                              color: AppColors.textMuted,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.divider)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ── Email + password (de-emphasized) ──
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
                    OutlineButton(
                      label: l10n.authPasswordSignInAction,
                      onPressed: _signInWithEmail,
                      isLoading: authScreenState.isLoading,
                      height: 48,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 4,
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
          // Voice + language controls in top-right (last children for tap priority).
          // Language toggle is surfaced here so new users can switch English/Hindi
          // before signing in — the onboarding flow intentionally keeps the rest
          // of the top-bar minimal.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Material(
              color: Colors.transparent,
              child: Theme(
                data: Theme.of(context).copyWith(
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    TtsActionButton(),
                    LanguageToggleAction(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
