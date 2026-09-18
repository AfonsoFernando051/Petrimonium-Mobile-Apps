import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/core/widgets/layer_chip.dart';
import 'package:petrimonium_academy/features/mentor/domain/entities/chat_message.dart';
import 'package:petrimonium_academy/features/mentor/domain/services/mentor_reply_layers.dart';

/// The pet's speech card on the Mentor stage: the reply to the question on
/// stage, pointing up at the pet above it.
///
/// A reply explaining a concept keeps its CONTEÚDO / INTERPRETAÇÃO split
/// (see [MentorReplyLayers]) — an objective explanation and the Mentor's
/// personalized read are never presented as the same kind of statement.
/// Unlike Wallet's speech card, there is no DADO layer or source citation
/// here: the Academy Mentor explains concepts, it never cites real portfolio
/// figures (see `MentorChatResult.sources`'s doc comment — Wallet only).
class MentorSpeechCard extends StatefulWidget {
  const MentorSpeechCard({super.key, required this.reply, this.topic, this.revealingText});

  final ChatMessage reply;

  /// The conversation title, shown as the card's pill. Hidden when `null`.
  final String? topic;

  /// Non-null only while [reply] is mid-typewriter-reveal (see
  /// `MentorChatController.revealingMessageId`): the text then tracks this
  /// notifier instead of the still-empty stored text, rebuilding only the
  /// card's content on each tick.
  final ValueListenable<String>? revealingText;

  @override
  State<MentorSpeechCard> createState() => _MentorSpeechCardState();
}

class _MentorSpeechCardState extends State<MentorSpeechCard> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final accent = widget.reply.isError ? AppColors.warningAmber : tokens.mentor;
    final background = accent.withValues(alpha: 0.07);
    final border = accent.withValues(alpha: 0.4);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.topic != null) ...[_TopicPill(label: widget.topic!), const SizedBox(height: 11)],
              _buildReplyContent(context),
            ],
          ),
        ),
        // The notch pointing at the pet: a rotated square whose two top edges
        // continue the card's border.
        Positioned(
          top: -7,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(background, tokens.backgroundPrimary),
                  border: Border(
                    left: BorderSide(color: border),
                    top: BorderSide(color: border),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyContent(BuildContext context) {
    final revealingText = widget.revealingText;
    if (revealingText == null) return _replyContent(context, widget.reply.text);
    return ValueListenableBuilder<String>(
      valueListenable: revealingText,
      builder: (context, text, _) => _replyContent(context, text),
    );
  }

  Widget _replyContent(BuildContext context, String text) {
    if (text.isEmpty) return const SizedBox(height: 4);
    final layers = widget.reply.isError ? null : MentorReplyLayers.tryParse(text);
    if (layers == null) return _markdown(context, text);

    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayerChip(label: Translator.translate(AppStrings.academyContentLabel), color: AppColors.neonCyan),
        const SizedBox(height: 8),
        _markdown(context, layers.content),
        if (layers.interpretation != null) ...[
          const SizedBox(height: 14),
          LayerChip(label: Translator.translate(AppStrings.mentorInterpretationLabel), color: tokens.mentor),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            style: const TextStyle(fontStyle: FontStyle.italic),
            child: _markdown(context, layers.interpretation!),
          ),
        ],
      ],
    );
  }

  Widget _markdown(BuildContext context, String data) {
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
}

class _TopicPill extends StatelessWidget {
  const _TopicPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final mentor = context.colors.mentor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: mentor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: mentor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: mentor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}
