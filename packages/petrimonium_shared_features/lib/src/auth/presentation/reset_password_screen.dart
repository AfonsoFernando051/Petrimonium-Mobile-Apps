import 'package:flutter/material.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Every string this screen shows, supplied by the product.
///
/// Note what is *not* here: the password-strength messages. Those come from
/// [PasswordPolicy], which returns hard-coded Portuguese in every language —
/// a pre-existing gap, left alone rather than changed under a refactor.
typedef ResetPasswordCopy = ({
  String title,
  String subtitle,
  String tokenHint,
  String newPasswordHint,
  String confirmPasswordHint,
  String submitLabel,
  String successMessage,
  String mismatchError,
  String fieldsRequiredError,
});

/// Second half of the forgot-password flow. The user pastes the reset code
/// emailed to them (see [ForgotPasswordScreen]) alongside a new password —
/// there's no deep-linking infrastructure in this app, so the code is
/// entered manually rather than opened via a link (see the class doc on
/// `ForgotPasswordScreen`).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.copy,
    required this.background,
    required this.onResetPassword,
    required this.errorMessageBuilder,
  });

  final ResetPasswordCopy copy;

  /// The product's own backdrop — see [ForgotPasswordScreen.background].
  final Widget background;

  /// Performs the reset (e.g. `DI.authRepository.resetPassword`). Letting it
  /// throw is how a failure reaches [errorMessageBuilder].
  final Future<void> Function(String token, String newPassword) onResetPassword;

  /// Each product's own `friendlyErrorMessage`.
  final String Function(Object error) errorMessageBuilder;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (token.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      GameSnack.show(context, widget.copy.fieldsRequiredError, isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      GameSnack.show(context, widget.copy.mismatchError, isError: true);
      return;
    }

    final passwordError = PasswordPolicy.validate(newPassword);
    if (passwordError != null) {
      GameSnack.show(context, passwordError, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onResetPassword(token, newPassword);
      if (mounted) {
        GameSnack.show(context, widget.copy.successMessage, isSuccess: true);
        // Returns to LoginScreen — the Navigator's first route whenever the
        // user reached this flow unauthenticated (see MyApp._getStartRoute).
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        GameSnack.show(context, widget.errorMessageBuilder(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          widget.background,
          SafeArea(
            child: Column(
              children: [
                const _BackButton(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.password, size: 56, color: tokens.textPrimary),
                            const SizedBox(height: 16),
                            Text(
                              widget.copy.title,
                              style: TextStyle(color: tokens.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.copy.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: tokens.textSecondary),
                            ),
                            const SizedBox(height: 24),
                            CustomTextField(
                              hint: widget.copy.tokenHint,
                              icon: Icons.vpn_key,
                              controller: _tokenController,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hint: widget.copy.newPasswordHint,
                              icon: Icons.lock,
                              obscure: true,
                              controller: _newPasswordController,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hint: widget.copy.confirmPasswordHint,
                              icon: Icons.lock_outline,
                              obscure: true,
                              controller: _confirmPasswordController,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.brand.accent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                      )
                                    : Text(
                                        widget.copy.submitLabel,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
