import 'package:flutter/material.dart';
import '../tokens/app_color_tokens.dart';
import '../tokens/app_radii.dart';

/// What the user proved themselves with. Exactly one field is non-null.
class ReauthenticationResult {
  const ReauthenticationResult.password(String this.password) : googleIdToken = null;
  const ReauthenticationResult.google(String this.googleIdToken) : password = null;

  final String? password;
  final String? googleIdToken;
}

/// Collects a credential before an irreversible action, so that holding a
/// session is not on its own enough to perform it.
///
/// Both ways in are offered because an account has one or the other: a local
/// account has a password, an account created through Google has none at all,
/// and one that was created locally and later linked to Google has both. The
/// dialog does not try to guess which — the client has no reliable local
/// record of the account's provider, and guessing wrong would strand whoever
/// it guessed wrong about. The backend is what decides whether the credential
/// actually fits the account.
///
/// Copy is passed in for the same reason [ConfirmLogoutDialog]'s is: the
/// products do not share a string catalog, and this package must never reach
/// for one.
class ReauthenticateDialog {
  ReauthenticateDialog._();

  /// Resolves to null if the user backed out.
  ///
  /// [onGoogleReauth] runs the product's own Google Sign-In flow and returns a
  /// fresh ID token, or null if the user cancelled it. Omit it to hide the
  /// Google option entirely (a product without Google Sign-In wired up).
  static Future<ReauthenticationResult?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String passwordLabel,
    required String cancelLabel,
    required String confirmLabel,
    String? googleLabel,
    Future<String?> Function()? onGoogleReauth,
  }) {
    return showDialog<ReauthenticationResult>(
      context: context,
      builder: (dialogContext) => _ReauthenticateDialogBody(
        title: title,
        message: message,
        passwordLabel: passwordLabel,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        googleLabel: googleLabel,
        onGoogleReauth: onGoogleReauth,
      ),
    );
  }
}

class _ReauthenticateDialogBody extends StatefulWidget {
  const _ReauthenticateDialogBody({
    required this.title,
    required this.message,
    required this.passwordLabel,
    required this.cancelLabel,
    required this.confirmLabel,
    this.googleLabel,
    this.onGoogleReauth,
  });

  final String title;
  final String message;
  final String passwordLabel;
  final String cancelLabel;
  final String confirmLabel;
  final String? googleLabel;
  final Future<String?> Function()? onGoogleReauth;

  @override
  State<_ReauthenticateDialogBody> createState() => _ReauthenticateDialogBodyState();
}

class _ReauthenticateDialogBodyState extends State<_ReauthenticateDialogBody> {
  final TextEditingController _passwordController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submitPassword() {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    Navigator.pop(context, ReauthenticationResult.password(password));
  }

  Future<void> _submitGoogle() async {
    final run = widget.onGoogleReauth;
    if (run == null || _busy) return;

    setState(() => _busy = true);
    String? idToken;
    try {
      idToken = await run();
    } catch (_) {
      // A failed or cancelled Google flow leaves the dialog open so the user
      // can still fall back to the password field, rather than dropping them
      // back onto Settings with nothing said.
      idToken = null;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (idToken == null || idToken.isEmpty) return;
    Navigator.pop(context, ReauthenticationResult.google(idToken));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final googleLabel = widget.googleLabel;
    final canUseGoogle = widget.onGoogleReauth != null && googleLabel != null;

    return AlertDialog(
      backgroundColor: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
      title: Text(
        widget.title,
        style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.message, style: TextStyle(color: tokens.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            enabled: !_busy,
            style: TextStyle(color: tokens.textPrimary),
            decoration: InputDecoration(
              labelText: widget.passwordLabel,
              labelStyle: TextStyle(color: tokens.textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
            ),
            onSubmitted: (_) => _submitPassword(),
          ),
          if (canUseGoogle) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _submitGoogle,
              child: Text(googleLabel, style: TextStyle(color: tokens.primary)),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(widget.cancelLabel, style: TextStyle(color: tokens.primary)),
        ),
        TextButton(
          onPressed: _busy ? null : _submitPassword,
          child: Text(widget.confirmLabel, style: TextStyle(color: tokens.error)),
        ),
      ],
    );
  }
}
