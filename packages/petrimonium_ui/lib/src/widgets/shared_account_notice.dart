import 'package:flutter/material.dart';

import '../tokens/app_color_tokens.dart';

/// Nota do ecrã de login que explica que a conta é a mesma nos três apps.
///
/// Vive no pacote partilhado porque os artboards `Login*` do canvas desenham
/// exactamente a mesma caixa nos três produtos: escudo na cor do Mentor à
/// esquerda, texto alinhado à esquerda ao lado, sobre fundo esbatido com
/// contorno. No canvas ela fecha o ecrã, depois do botão do Google e do
/// "Esqueceu a senha?" — não separa os campos do botão de entrar.
class SharedAccountNotice extends StatelessWidget {
  const SharedAccountNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.textPrimary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.verified_user_outlined, size: 18, color: tokens.mentor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: tokens.textSecondary, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
