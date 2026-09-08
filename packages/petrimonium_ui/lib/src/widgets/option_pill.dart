import 'package:flutter/material.dart';

import '../tokens/app_color_tokens.dart';

/// Escolha inline em forma de pastilha — o controlo que os artboards `Prefs*`
/// do canvas usam para país/mercado e moeda-base.
///
/// Substitui o par campo-que-abre-folha nos ecrãs de onboarding: o canvas põe
/// as opções à vista, sem um toque extra para as descobrir.
class OptionPill extends StatelessWidget {
  const OptionPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Emoji opcional à esquerda (a bandeira do país, no artboard).
  final String? leading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    // Tinta sobre o acento: o menta da Wallet e o ciano da Academy são claros
    // e pedem tinta escura; o verde do tema claro pede tinta clara.
    final inkOnAccent = ThemeData.estimateBrightnessForColor(tokens.primary) == Brightness.light
        ? tokens.backgroundPrimary
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? tokens.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? tokens.primary : tokens.textPrimary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              Text(leading!, style: const TextStyle(fontSize: 16, height: 1)),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? inkOnAccent : tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
