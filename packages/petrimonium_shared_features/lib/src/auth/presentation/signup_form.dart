import 'package:flutter/material.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Mirrors the backend's `RegisterRequest` username size — see
/// `Petrimonium-Backend/.../presentation/auth/dto/RegisterRequest.java`.
const int _minNameLength = 3;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// The shared signup form — see [LoginForm]'s doc for why this is safe to
/// share: Academy and Wallet's versions differed by a single cosmetic
/// `SizedBox` height before this extraction, with every validation rule,
/// message and the register→auto-login flow already identical.
///
/// [onRegister] creates the account; since the register endpoint doesn't
/// return an access token, [onLoginAfterRegister] is called right after it
/// succeeds to establish the session — mirroring the two products' identical
/// `register` then `login` call chain.
class SignupForm extends StatefulWidget {
  const SignupForm({
    super.key,
    required this.nameHint,
    required this.emailHint,
    required this.passwordHint,
    required this.confirmPasswordHint,
    required this.signupButtonLabel,
    this.signupButtonGradient,
    required this.googleButtonLabel,
    required this.orDividerLabel,
    required this.sharedAccountNoticeText,
    required this.onRegister,
    required this.onLoginAfterRegister,
    required this.onGoogleSignup,
    required this.onSuccess,
    required this.errorMessageBuilder,
  });

  final String nameHint;
  final String emailHint;
  final String passwordHint;
  final String confirmPasswordHint;
  final String signupButtonLabel;

  /// Gradient for the signup CTA's glow chrome. `null` keeps [GameButton]'s
  /// flat default fill instead.
  final List<Color>? signupButtonGradient;
  final String googleButtonLabel;
  final String orDividerLabel;
  final String sharedAccountNoticeText;

  final Future<void> Function(String name, String email, String password) onRegister;
  final Future<void> Function(String email, String password) onLoginAfterRegister;
  final Future<void> Function() onGoogleSignup;

  /// Called once the corresponding call chain above completes without throwing.
  final VoidCallback onSuccess;

  final String Function(Object error) errorMessageBuilder;

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    // Re-renders on every keystroke so field-level validation below updates
    // live, instead of only surfacing errors after a failed submit.
    for (final controller in [
      _nameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  /// `null` while the field is empty (untouched) or valid — errors only
  /// surface once there's something to correct.
  String? get _nameError {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length >= _minNameLength) return null;
    return 'Mínimo de $_minNameLength caracteres.';
  }

  String? get _emailError {
    final email = _emailController.text.trim();
    if (email.isEmpty || _emailPattern.hasMatch(email)) return null;
    return 'Digite um e-mail válido.';
  }

  String? get _confirmPasswordError {
    final confirm = _confirmPasswordController.text;
    if (confirm.isEmpty || confirm == _passwordController.text) return null;
    return 'As senhas não coincidem.';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    GameSnack.show(context, 'Cadastro falhou: ${widget.errorMessageBuilder(error)}', isError: true);
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      GameSnack.show(context, 'Preencha todos os campos obrigatórios.', isError: true);
      return;
    }

    // Field-level errors already surface live under each input as the user
    // types (see _nameError/_emailError/_confirmPasswordError/
    // _PasswordRequirementsChecklist) — this is the final gate before
    // hitting the network, reusing the same checks as the single source of
    // truth.
    final passwordError = PasswordPolicy.validate(password);
    final firstError = _nameError ?? _emailError ?? _confirmPasswordError ?? passwordError;
    if (firstError != null) {
      GameSnack.show(context, firstError, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onRegister(name, email, password);
      // Auto-login since register doesn't return an accessToken.
      await widget.onLoginAfterRegister(email, password);
      if (mounted) widget.onSuccess();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => _isGoogleLoading = true);
    try {
      await widget.onGoogleSignup();
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
        CustomTextField(
          hint: widget.nameHint,
          icon: Icons.person,
          controller: _nameController,
          errorText: _nameError,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          hint: widget.emailHint,
          icon: Icons.email,
          controller: _emailController,
          errorText: _emailError,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          hint: widget.passwordHint,
          icon: Icons.lock,
          obscure: true,
          controller: _passwordController,
        ),
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          _PasswordRequirementsChecklist(password: _passwordController.text),
        ],
        const SizedBox(height: 14),
        CustomTextField(
          hint: widget.confirmPasswordHint,
          icon: Icons.lock_outline,
          obscure: true,
          controller: _confirmPasswordController,
          errorText: _confirmPasswordError,
        ),
        const SizedBox(height: 20),
        GameButton(
          label: widget.signupButtonLabel,
          gradientColors: widget.signupButtonGradient,
          pulse: true,
          borderRadius: 16,
          onPressed: _handleRegister,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        OrDivider(label: widget.orDividerLabel),
        const SizedBox(height: 16),
        GoogleSignInButton(
          label: widget.googleButtonLabel,
          onPressed: _handleGoogleSignup,
          isLoading: _isGoogleLoading,
        ),
        const SizedBox(height: 24),
        SharedAccountNotice(text: widget.sharedAccountNoticeText),
      ],
    );
  }
}

/// Live checklist for [PasswordPolicy]'s rules — shown under the password
/// field as the user types so they can see what's still missing instead of
/// discovering it only after a failed submit.
class _PasswordRequirementsChecklist extends StatelessWidget {
  final String password;

  const _PasswordRequirementsChecklist({required this.password});

  @override
  Widget build(BuildContext context) {
    final rules = <String, bool>{
      'Mínimo de ${PasswordPolicy.minLength} caracteres': password.length >= PasswordPolicy.minLength,
      'Uma letra maiúscula': password.contains(RegExp(r'[A-Z]')),
      'Uma letra minúscula': password.contains(RegExp(r'[a-z]')),
      'Um número': password.contains(RegExp(r'[0-9]')),
    };

    final tokens = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: rules.entries.map((rule) {
          final met = rule.value;
          final color = met ? tokens.success : tokens.textTertiary;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  met ? Icons.check_circle : Icons.circle_outlined,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(rule.key, style: TextStyle(color: color, fontSize: 12)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
