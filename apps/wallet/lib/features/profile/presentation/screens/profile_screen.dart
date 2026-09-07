import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/display_name.dart';
import 'package:petrimonium/core/utils/fade_route.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/cosmic_background.dart';
import 'package:petrimonium/features/onboarding/presentation/screens/quick_setup_screen.dart';
import 'package:petrimonium/features/pet/presentation/companion/pet_companion_controller.dart';
import 'package:petrimonium/features/pet/presentation/companion/widgets/pet_companion_header.dart';
import 'package:petrimonium/features/pet/presentation/companion/widgets/pet_speech_bubble.dart';
import 'package:petrimonium/features/pet/presentation/companion/widgets/pet_speech_bubble_anchor.dart';
import 'package:petrimonium/features/profile/presentation/screens/mentor_preferences_screen.dart';
import 'package:petrimonium/features/profile/presentation/screens/privacy_and_memory_screen.dart';
import 'package:petrimonium/features/settings/presentation/screens/settings_screen.dart';

/// The "Perfil" experience — reached via the AppBar's config/gear icon.
/// Identity (name + "same account as the Academy") plus exactly the 3 rows
/// the Notion mockup shows: Mentor preferences (goal/horizon — the same
/// context `MentorChatRepository` already sends with every message),
/// Privacidade e memória (links to the real conversation-history screen),
/// and Moeda-base e mercado (the quick-setup pickers, reused in settings
/// mode). The legacy `SettingsScreen` (language, appearance, notification
/// toggles, pet rename, logout — none of it in the mockup, all of it real
/// and still needed) stays reachable via a small gear icon in this screen's
/// AppBar instead of a 4th menu row, so the body matches the mockup's 3
/// rows exactly.
///
/// Keeps the same [PetCompanionController] instance `DashboardScreen` owns
/// (not a new one) so the companion's message/cooldown state stays
/// continuous across the push — see that controller's class doc.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.companionController});

  final PetCompanionController companionController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // This screen's own Pet anchor (a fresh `LayerLink`/`GlobalKey` pair, not
  // shared with `DashboardScreen`'s — Profile is pushed on top of it, so
  // both remain mounted simultaneously and a shared `GlobalKey` would
  // collide). See `PetSpeechBubbleAnchor`'s doc comment.
  final PetSpeechBubbleAnchor _headerAnchor = PetSpeechBubbleAnchor();

  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final email = await DI.authRepository.getSavedEmail();
    final name = deriveDisplayNameFromEmail(email);
    if (!mounted || name == null) return;
    setState(() => _displayName = name);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PetCompanionHeader(
              controller: widget.companionController,
              onDestinationSelected: (destination) => Navigator.of(context).pop(destination),
              anchor: _headerAnchor,
            ),
            const SizedBox(width: 10),
            Text(Translator.translate(AppStrings.profileTitle), style: TextStyle(color: tokens.textPrimary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: tokens.textSecondary),
            tooltip: Translator.translate(AppStrings.profileAppSettingsLabel),
            onPressed: () => Navigator.of(context).push(fadeRoute(const SettingsScreen())),
          ),
        ],
      ),
      body: CosmicBackground(
        child: Stack(
          children: [
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                children: [
                  _IdentityRow(displayName: _displayName),
                  const SizedBox(height: 24),
                  _ProfileMenuRow(
                    label: Translator.translate(AppStrings.profileMentorPreferencesLabel),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MentorPreferencesScreen()),
                    ),
                  ),
                  _ProfileMenuRow(
                    label: Translator.translate(AppStrings.profilePrivacyMemoryLabel),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyAndMemoryScreen()),
                    ),
                  ),
                  _ProfileMenuRow(
                    label: Translator.translate(AppStrings.profileCurrencyMarketLabel),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuickSetupScreen(isSettingsMode: true)),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: PetSpeechBubbleOverlay(
                controller: widget.companionController,
                anchor: _headerAnchor,
                onActionSelected: (action) => Navigator.of(context).pop(action.destination),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.displayName});

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/generated_fox.png',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.pets, size: 32, color: tokens.primary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayName != null)
                Text(
                  displayName!,
                  style: TextStyle(color: tokens.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              Text(
                Translator.translate(AppStrings.profileIdentitySubtitle),
                style: TextStyle(color: tokens.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(color: tokens.textPrimary, fontSize: 14)),
            ),
            Icon(Icons.chevron_right, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}
