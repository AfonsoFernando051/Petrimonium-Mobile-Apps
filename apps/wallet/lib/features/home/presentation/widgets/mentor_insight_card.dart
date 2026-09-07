import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/features/mentor/domain/services/wallet_mentor_reply_layers.dart';
import 'package:petrimonium/features/mentor/presentation/widgets/mentor_reply_layers_view.dart';

/// Home's single Mentor interpretation — a real backend call (the same
/// `MentorChatRepository` the Mentor tab uses), not hardcoded copy. Fetched
/// once per session (this widget's own `State` outlives tab switches, since
/// `DashboardScreen` keeps every tab mounted in an `IndexedStack`) and
/// dismissible — "aparece uma vez por sessão... não conduz a navegação" per
/// the Wallet design system. On any failure the card just disappears rather
/// than showing an error on the primary financial screen.
class MentorInsightCard extends StatefulWidget {
  const MentorInsightCard({super.key, required this.onOpenMentor});

  final ValueChanged<int?> onOpenMentor;

  @override
  State<MentorInsightCard> createState() => _MentorInsightCardState();
}

class _MentorInsightCardState extends State<MentorInsightCard> {
  String? _reply;
  int? _conversationId;
  DateTime? _receivedAt;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final result = await DI.mentorChatRepository.sendMessage(
        message: 'Como está meu patrimônio hoje?',
        currentScreen: 'home',
      );
      if (!mounted) return;
      setState(() {
        _reply = result.reply;
        _conversationId = result.conversationId;
        _receivedAt = DateTime.now();
      });
    } catch (_) {
      // Silent — see class doc. The Mentor tab remains reachable for a
      // manual retry.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _reply == null) return const SizedBox.shrink();

    final tokens = context.colors;
    final layers = WalletMentorReplyLayers.tryParse(_reply!);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/generated_fox.png',
                  // 52px per the Wallet design system's "avatar menor" rule
                  // — never the Academy's larger, animated hero treatment.
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.pets, size: 18, color: tokens.mentor);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mentor',
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _dismissed = true),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: tokens.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // The reply carries [[DATA]]/[[CALCULATION]]/[[INTERPRETATION]]
          // markers. Rendering it as plain Text put those markers on screen and
          // flattened a real figure, a derived one and an opinion into one
          // undifferentiated paragraph — the exact thing the layers exist to
          // prevent. Falls back to plain markdown when the reply has no layers.
          if (layers == null)
            MentorReplyLayersView.markdown(context, _reply!)
          else
            MentorReplyLayersView(layers: layers, timestamp: _receivedAt ?? DateTime.now()),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => widget.onOpenMentor(_conversationId),
            child: Text(
              Translator.translate(AppStrings.homeMentorWhySeeing),
              style: TextStyle(color: tokens.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
