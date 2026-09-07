import 'package:flutter/material.dart';

import '../tokens/app_color_tokens.dart';

/// Rótulo de um campo ou de um bloco de opções — o "Escolha uma espécie" /
/// "Dê um nome a ele" dos ecrãs de onboarding.
///
/// Vive no pacote partilhado porque os três apps desenham o mesmo rótulo: no
/// canvas de design é sempre 12.5px / w600 na cor secundária, alinhado à
/// esquerda, nos artboards `Pet*` e `Prefs*` dos três produtos.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.colors.textSecondary,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
