import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/constants/app_colors.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/mentor/domain/entities/chat_message.dart';
import 'package:petrimonium_wallet/features/mentor/domain/services/wallet_mentor_reply_layers.dart';
import 'package:petrimonium_wallet/features/mentor/presentation/widgets/mentor_reply_layers_view.dart';

/// Maps a real source key from `MentorSystemPromptBuilder.walletSourcesFor`
/// to its translated label — falls back to the raw key for a source added
/// backend-side before the client knows about it, rather than hiding it.
String _sourceLabel(String key) {
  final stringKey = switch (key) {
    'portfolio_summary' => AppStrings.mentorSourcePortfolioSummary,
    'portfolio_allocation' => AppStrings.mentorSourcePortfolioAllocation,
    'pet' => AppStrings.mentorSourcePet,
    'client_goal' => AppStrings.mentorSourceClientGoal,
    'client_horizon' => AppStrings.mentorSourceClientHorizon,
    'client_screen' => AppStrings.mentorSourceClientScreen,
    _ => null,
  };
  return stringKey == null ? key : Translator.translate(stringKey);
}

/// The pet's speech card on the Mentor stage: the reply to the question on
/// stage, pointing up at the pet above it.
///
/// A reply touching real portfolio data keeps its DADO / CÁLCULO /
/// INTERPRETAÇÃO split through [MentorReplyLayersView] — the card being
/// Mentor-coloured does not make a raw figure the Mentor's opinion. "Por que
/// estou vendo isto?" only appears when the backend cited real sources; it is
/// never filled client-side.
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
  bool _showSources = false;

  @override
  void didUpdateWidget(MentorSpeechCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reply.id != oldWidget.reply.id) _showSources = false;
  }

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
              _buildReplyText(context),
              if (widget.reply.sources.isNotEmpty) _buildSources(context),
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

  Widget _buildReplyText(BuildContext context) {
    final revealingText = widget.revealingText;
    if (revealingText == null) return _replyContent(context, widget.reply.text);
    return ValueListenableBuilder<String>(
      valueListenable: revealingText,
      builder: (context, text, _) => _replyContent(context, text),
    );
  }

  Widget _replyContent(BuildContext context, String text) {
    if (text.isEmpty) return const SizedBox(height: 4);
    final layers = widget.reply.isError ? null : WalletMentorReplyLayers.tryParse(text);
    if (layers == null) return MentorReplyLayersView.markdown(context, text);
    return MentorReplyLayersView(layers: layers, timestamp: widget.reply.timestamp);
  }

  Widget _buildSources(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 9),
        InkWell(
          onTap: () => setState(() => _showSources = !_showSources),
          child: Text(
            Translator.translate(AppStrings.homeMentorWhySeeing),
            style: TextStyle(color: tokens.mentor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        if (_showSources)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translator.translate(AppStrings.mentorSourcesLabel).toUpperCase(),
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                for (final source in widget.reply.sources)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(color: tokens.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _sourceLabel(source),
                            style: TextStyle(color: tokens.textSecondary, fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
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
