part of 'auth_screens.dart';

class EmailPasswordAuthScreen extends ConsumerStatefulWidget {
  const EmailPasswordAuthScreen({super.key});

  @override
  ConsumerState<EmailPasswordAuthScreen> createState() => _EmailPasswordAuthScreenState();
}

class _EmailPasswordAuthScreenState extends ConsumerState<EmailPasswordAuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _hasUnsavedChanges() {
    return _emailController.text.isNotEmpty ||
        _passwordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

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
    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (_hasUnsavedChanges()) {
          final navigator = Navigator.of(context);
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            // Clear form fields when discarding changes
            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            // Navigate back
            navigator.pop();
          }
        }
      },
      child: Scaffold(
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
