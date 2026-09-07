import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import '../../../../core/utils/translator.dart';
import 'login_form.dart';
import 'signup_form.dart';

/// Flat, edge-to-edge layout (no glass card/floating badge) — matches the
/// Wallet design system's "menos decorativo" direction: the mascot + brand
/// title sit directly on [LoginBackground], not inside a bordered panel.
///
/// Login and Cadastro live on this one screen, switched by [_AuthModeToggle]
/// — matching the Wallet design's segmented Login/Cadastro tabs — instead of
/// Cadastro being a separate modal dialog reachable only via a text link.
class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  bool _isSignup = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sem recorte circular: a arte do mascote já vem com fundo
              // transparente e assenta direto sobre o fundo da tela.
              Image.asset(
                'assets/images/generated_dog.png',
                height: 96,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.pets, size: 48, color: tokens.mentor);
                },
              ),
              const SizedBox(height: 14),
              Text(
                Translator.translate(AppStrings.brandTitle).toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.mentor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Translator.translate(AppStrings.brandTagline),
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 28),
              _AuthModeToggle(
                isSignup: _isSignup,
                onChanged: (value) {
                  if (value != _isSignup) setState(() => _isSignup = value);
                },
              ),
              const SizedBox(height: 20),
              if (_isSignup) const SignupForm() else const LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Login/Cadastro segmented control — the single way to switch between
/// [LoginForm] and [SignupForm], per the Wallet design's auth-screen tabs.
class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({required this.isSignup, required this.onChanged});

  final bool isSignup;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthModeTab(
              label: Translator.translate(AppStrings.authTabLoginLabel),
              active: !isSignup,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _AuthModeTab(
              label: Translator.translate(AppStrings.authTabSignupLabel),
              active: isSignup,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeTab extends StatelessWidget {
  const _AuthModeTab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? tokens.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? tokens.textPrimary : tokens.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
