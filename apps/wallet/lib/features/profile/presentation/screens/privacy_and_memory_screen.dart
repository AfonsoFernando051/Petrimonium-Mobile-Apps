import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/cosmic_background.dart';
import 'package:petrimonium/core/widgets/game_button.dart';
import 'package:petrimonium/features/mentor/presentation/screens/conversation_list_screen.dart';

/// Perfil's "Privacidade e memória" — explains what the Mentor remembers
/// (goal/horizon context on every message, stored conversations) and links
/// into the real conversation-management screen (`ConversationListScreen`,
/// already reachable from the Mentor tab's history icon) rather than
/// inventing a second, weaker memory-management UI.
class PrivacyAndMemoryScreen extends StatelessWidget {
  const PrivacyAndMemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          Translator.translate(AppStrings.profilePrivacyMemoryLabel),
          style: TextStyle(color: tokens.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  Translator.translate(AppStrings.privacyMemoryBody),
                  style: TextStyle(color: tokens.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 28),
                GameButton(
                  label: Translator.translate(AppStrings.privacyMemoryConversationsButton),
                  icon: Icons.chat_bubble_outline,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConversationListScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
