import 'package:flutter/material.dart';

import '../tokens/app_color_tokens.dart';

/// Linha de escolha única de uma lista de definições — idioma, país.
///
/// Desenhada a partir dos artboards `Settings*` do canvas, que usam a mesma
/// linha nos três produtos: bandeira, rótulo e, à direita, um círculo de
/// seleção **sempre presente** (vazio quando não escolhido, preenchido com
/// visto quando escolhido). A cor do rótulo não muda com a seleção; só o
/// peso — a mesma regra dos rótulos de espécie no onboarding.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.showDivider = true,
  });

  /// Emoji da bandeira, quando a opção tem uma.
  final String? leading;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Falso na última linha do cartão, que não leva separador.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: showDivider
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: tokens.textPrimary.withValues(alpha: 0.12)),
                ),
              )
            : null,
        child: Row(
          children: [
            if (leading != null) ...[
              Text(leading!, style: const TextStyle(fontSize: 22, height: 1)),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: tokens.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            _SelectionDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? tokens.primary : Colors.transparent,
        border: Border.all(
          color: selected ? tokens.primary : tokens.textPrimary.withValues(alpha: 0.24),
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 12, color: tokens.backgroundPrimary)
          : null,
    );
  }
}
