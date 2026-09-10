import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// The shared login form: two fields, a primary CTA, Google sign-in, a
/// forgot-password link and the shared-account notice. Academy and Wallet's
/// versions of this form were already identical in layout, fields,
/// validation, loading and error presentation — only copy, accent color and
/// what happens after a successful login differed, and those arrive here as
/// parameters and callbacks rather than branches (see
/// `docs/MOBILE_ARCHITECTURE.md`).
///
/// [onLogin]/[onGoogleLogin] perform the actual network call (e.g.
/// `DI.authRepository.login`); letting them throw is how a failure reaches
/// [errorMessageBuilder]. [errorMessageBuilder] is each product's own
/// `friendlyErrorMessage` — the two are functionally identical, differing
/// only in which product's `Translator` supplies the "no connection"/
/// "unexpected error" copy inside them.
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.emailHint,
    required this.passwordHint,
    required this.loginButtonLabel,
    this.loginButtonGradient,
    required this.googleButtonLabel,
    required this.orDividerLabel,
    required this.forgotPasswordLabel,
    required this.onForgotPassword,
    required this.sharedAccountNoticeText,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onSuccess,
    required this.errorMessageBuilder,
  });

  final String emailHint;
  final String passwordHint;
  final String loginButtonLabel;

  /// Gradient for the login CTA's glow chrome — each product's own brand
  /// gradient (e.g. `context.brand.gradient`). `null` keeps [GameButton]'s
  /// flat default fill instead.
  final List<Color>? loginButtonGradient;
  final String googleButtonLabel;
  final String orDividerLabel;
  final String forgotPasswordLabel;
  final VoidCallback onForgotPassword;
  final String sharedAccountNoticeText;

  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function() onGoogleLogin;

  /// Called once the corresponding call above completes without throwing.
  final VoidCallback onSuccess;

  final String Function(Object error) errorMessageBuilder;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    GameSnack.show(context, 'Login falhou: ${widget.errorMessageBuilder(error)}', isError: true);
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      GameSnack.show(context, 'Preencha e-mail e senha para continuar.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onLogin(email, password);
      if (mounted) widget.onSuccess();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      await widget.onGoogleLogin();
      if (mounted) widget.onSuccess();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomTextField(hint: widget.emailHint, icon: Icons.email_outlined, controller: _emailController),
        const SizedBox(height: 14),
        CustomTextField(
          hint: widget.passwordHint,
          icon: Icons.lock_outline,
          obscure: true,
          controller: _passwordController,
        ),
        const SizedBox(height: 20),
        GameButton(
          label: widget.loginButtonLabel,
          icon: Icons.arrow_forward,
          iconTrailing: true,
          gradientColors: widget.loginButtonGradient,
          pulse: true,
          onPressed: _handleLogin,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        OrDivider(label: widget.orDividerLabel),
        const SizedBox(height: 16),
        GoogleSignInButton(label: widget.googleButtonLabel, onPressed: _handleGoogleLogin, isLoading: _isGoogleLoading),
        const SizedBox(height: 24),
        ForgotPasswordButton(label: widget.forgotPasswordLabel, onTap: widget.onForgotPassword),
        const SizedBox(height: 24),
        SharedAccountNotice(text: widget.sharedAccountNoticeText),
      ],
    );
  }
}
