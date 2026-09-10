import 'package:flutter/material.dart';

import '../../../core/app/health_scope.dart';
import '../../../core/theme/health_theme.dart';
import '../../../core/widgets/health_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../health/presentation/health_controller.dart';

/// Login/cadastro screen — `Petrimonium Health.dc.html`'s `screenIsLogin`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(HealthController controller) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _formError = null);
    try {
      if (controller.authMode == AuthMode.signup) {
        await controller.register(_nameController.text.trim(), _emailController.text.trim(), _passwordController.text);
      } else {
        await controller.login(_emailController.text.trim(), _passwordController.text);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = l10n.authFailed);
    }
  }

  Future<void> _submitGoogle(HealthController controller) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _formError = null);
    try {
      await controller.loginWithGoogle();
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = l10n.authFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = HealthScope.of(context);
    final l10n = AppLocalizations.of(context);
    final isSignup = controller.authMode == AuthMode.signup;
    final busy = controller.busy;

    return Scaffold(
      backgroundColor: HealthColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: ConstrainedBox(
                // Centrado na vertical como no artboard: em ecrãs altos a
                // coluna assenta no meio, em ecrãs baixos volta a rolar.
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                child: HealthContent(
                  width: HealthContent.bodyWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sem recorte circular: a arte do mascote já vem com
                      // fundo transparente e assenta direto sobre o fundo.
                      Image.asset('assets/pets/fox.png', height: 96, fit: BoxFit.contain),
                      const SizedBox(height: 14),
                      Text(
                        'PETRIMONIUM HEALTH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.healthTagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: HealthColors.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      _AuthModeToggle(
                        isSignup: isSignup,
                        loginLabel: l10n.loginToggleLogin,
                        signupLabel: l10n.loginToggleSignup,
                        onChanged: (signup) => controller.setAuthMode(signup ? AuthMode.signup : AuthMode.login),
                      ),
                      const SizedBox(height: 28),
                      if (isSignup) ...[
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(hintText: l10n.name),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(hintText: l10n.email),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(hintText: l10n.password),
                      ),
                      if (_formError != null) ...[
                        const SizedBox(height: 12),
                        Text(_formError!, style: const TextStyle(color: HealthColors.negative, fontSize: 12.5)),
                      ],
                      const SizedBox(height: 20),
                      HealthPrimaryButton(
                        label: isSignup ? l10n.loginCtaSignup : l10n.login,
                        busy: busy,
                        onPressed: () => _submit(controller),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: HealthColors.textMuted, height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              l10n.orDivider,
                              style: const TextStyle(fontSize: 12, color: HealthColors.textMuted),
                            ),
                          ),
                          const Expanded(child: Divider(color: HealthColors.textMuted, height: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _GoogleButton(
                        label: l10n.continueWithGoogle,
                        busy: busy,
                        onPressed: () => _submitGoogle(controller),
                      ),
                      if (!isSignup) ...[
                        const SizedBox(height: 24),
                        Text(
                          l10n.forgotPassword,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12.5, color: HealthColors.textMuted),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // A nota fecha o ecrã, depois do Google — no artboard
                      // ela é rodapé explicativo, não um aviso a meio do
                      // formulário separando os campos do botão.
                      _SharedAccountNote(text: isSignup ? l10n.loginNoteSignup : l10n.loginNoteLogin),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Controlo segmentado do artboard: carril esmaecido e a face activa como
/// pastilha branca. Não reutiliza o [HealthChip] — esse desenha a selecção a
/// terracota cheio e é partilhado por mais cinco ecrãs, que não mudam aqui.
class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.isSignup,
    required this.loginLabel,
    required this.signupLabel,
    required this.onChanged,
  });

  final bool isSignup;
  final String loginLabel;
  final String signupLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HealthColors.textPrimary.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthModeOption(label: loginLabel, selected: !isSignup, onTap: () => onChanged(false)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _AuthModeOption(label: signupLabel, selected: isSignup, onTap: () => onChanged(true)),
          ),
        ],
      ),
    );
  }
}

class _AuthModeOption extends StatelessWidget {
  const _AuthModeOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? HealthColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.black87 : HealthColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Rodapé que explica que a conta é a mesma nos três apps.
class _SharedAccountNote extends StatelessWidget {
  const _SharedAccountNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HealthColors.inputFill,
        border: Border.all(color: HealthColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.verified_user_outlined, size: 18, color: HealthColors.mentorAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, height: 1.45, color: HealthColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

/// Alternativa ao e-mail/palavra-passe, não a acção principal: fundo do
/// cartão com contorno, em vez do terracota cheio do [HealthPrimaryButton].
/// O glifo é o mesmo `Icons.g_mobiledata` que a Wallet e a Academy usam — a
/// marca de quatro cores do Google exigiria um asset, que este repo não tem.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: busy ? null : onPressed,
        icon: const Icon(Icons.g_mobiledata, size: 28, color: HealthColors.textPrimary),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: HealthColors.textPrimary),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: HealthColors.card,
          side: const BorderSide(color: HealthColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
