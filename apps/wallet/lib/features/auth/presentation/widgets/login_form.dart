import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import '../../../../core/utils/translator.dart';
import '../../../../core/utils/game_snack.dart';
import '../../../../core/utils/friendly_error_message.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../main.dart';
import 'forgot_password_button.dart';
import 'google_signin_button.dart';
import 'login_button.dart';
import 'or_divider.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

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

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      GameSnack.show(context, 'Preencha e-mail e senha para continuar.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await DI.authRepository.login(email, password);

      // Rebuilds fresh from `MyApp._getStartRoute()` — the single source of
      // truth for where a user belongs (meet pet / goal / tutorial /
      // portfolio choice / home) — instead of a separate, narrower redirect.
      if (mounted) {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyApp()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        GameSnack.show(
          context,
          'Login falhou: ${friendlyErrorMessage(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      await DI.authRepository.loginWithGoogle();

      if (mounted) {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyApp()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        GameSnack.show(
          context,
          'Login falhou: ${friendlyErrorMessage(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomTextField(
          hint: Translator.translate(AppStrings.emailOrUserHint),
          icon: Icons.email_outlined,
          controller: _emailController,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          hint: Translator.translate(AppStrings.passwordHint),
          icon: Icons.lock_outline,
          obscure: true,
          controller: _passwordController,
        ),
        const SizedBox(height: 20),
        LoginButton(
          onPressed: _handleLogin,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        const OrDivider(),
        const SizedBox(height: 16),
        GoogleSignInButton(
          onPressed: _handleGoogleLogin,
          isLoading: _isGoogleLoading,
        ),
        const SizedBox(height: 24),
        const ForgotPasswordButton(),
        const SizedBox(height: 24),
        SharedAccountNotice(text: Translator.translate(AppStrings.sharedAccountNotice)),
      ],
    );
  }
}
