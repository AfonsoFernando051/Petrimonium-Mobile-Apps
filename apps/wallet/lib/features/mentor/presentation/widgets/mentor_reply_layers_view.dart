import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:petrimonium/core/constants/app_colors.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/layer_chip.dart';
import 'package:petrimonium/features/mentor/domain/services/wallet_mentor_reply_layers.dart';

/// Renders a Mentor reply's DADO / CÁLCULO / INTERPRETAÇÃO layers, each behind
/// its own [LayerChip] — the Wallet's rule that a real figure, a derived one
/// and the Mentor's opinion must never look like the same kind of statement.
///
/// Shared by the Mentor tab's chat bubble and Home's insight card. It lives
/// here rather than inside `chat_bubble.dart` because Home used to render
/// `message.text` raw, which put the literal `[[DATA]]` markers on screen: any
/// surface showing a reply needs this, so there is exactly one implementation
/// of it to reach for.
class MentorReplyLayersView extends StatelessWidget {
  const MentorReplyLayersView({
    super.key,
    required this.layers,
    required this.timestamp,
  });

  final WalletMentorReplyLayers layers;

  /// Stamps the DADO chip. This is when the *reply* was produced — it is not a
  /// market-data timestamp and must not be presented as one.
  final DateTime timestamp;

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  /// The reply body as markdown, with the Wallet's chat typography.
  static Widget markdown(BuildContext context, String data) {
    final tokens = context.colors;
    return MarkdownBody(
      data: data,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: tokens.textPrimary, fontSize: 14, height: 1.4),
        strong: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold),
        em: TextStyle(color: tokens.textSecondary, fontStyle: FontStyle.italic),
        listBullet: const TextStyle(color: AppColors.neonCyan, fontSize: 14),
        h1: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        h2: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        code: TextStyle(
          color: AppColors.neonCyan,
          fontFamily: 'monospace',
          backgroundColor: tokens.backgroundSecondary.withValues(alpha: 0.5),
        ),
        blockquoteDecoration: BoxDecoration(
          color: tokens.backgroundSecondary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        tableBorder: TableBorder.all(color: tokens.border),
        tableHead: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold),
        tableBody: TextStyle(color: tokens.textSecondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final time = '${_twoDigits(timestamp.hour)}:${_twoDigits(timestamp.minute)}';
    final date = '${_twoDigits(timestamp.day)}/${_twoDigits(timestamp.month)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (layers.data != null) ...[
          LayerChip(
            layer: DataLayer.data,
            label: '${Translator.translate(AppStrings.homeWealthDataChipLabel)} · brapi.dev, $date $time',
          ),
          const SizedBox(height: 8),
          markdown(context, layers.data!),
        ],
        if (layers.calculation != null) ...[
          if (layers.data != null) const SizedBox(height: 14),
          LayerChip(
            layer: DataLayer.calculation,
            label: Translator.translate(AppStrings.homeChangeCalcChipLabel),
          ),
          const SizedBox(height: 8),
          markdown(context, layers.calculation!),
        ],
        if (layers.interpretation != null) ...[
          if (layers.data != null || layers.calculation != null) const SizedBox(height: 14),
          LayerChip(
            layer: DataLayer.mentor,
            label: Translator.translate(AppStrings.mentorInterpretationLabel),
          ),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            style: TextStyle(color: tokens.textSecondary, fontStyle: FontStyle.italic),
            child: markdown(context, layers.interpretation!),
          ),
        ],
      ],
    );
  }
}
