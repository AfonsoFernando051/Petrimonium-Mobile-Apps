import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:flutter/services.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/core/widgets/cosmic_background.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/pet_companion_controller.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/widgets/pet_companion_header.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/widgets/pet_speech_bubble.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/settings/presentation/screens/settings_screen.dart';

/// The "Perfil" experience — previously its own bottom-nav tab, now reached
/// via the AppBar's config/gear icon instead (the Perfil tab was removed;
/// the gear icon is now responsible for everything it used to cover).
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
  PetCompanionController get companionController => widget.companionController;
  late final Future<Set<String>> _completedLessons = DI.academyProgressRepository.loadCompletedLessonIds();

  // This screen's own Pet anchor (a fresh `LayerLink`/`GlobalKey` pair, not
  // shared with `DashboardScreen`'s — Profile is pushed on top of it, so
  // both remain mounted simultaneously and a shared `GlobalKey` would
  // collide). See `PetSpeechBubbleAnchor`'s doc comment.
  final PetSpeechBubbleAnchor _headerAnchor = PetSpeechBubbleAnchor();

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final level = LevelCalculator.fromXp(companionController.mascotController.profile.xp).level;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PetCompanionHeader(
              controller: companionController,
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
      ),
      body: CosmicBackground(
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: GlassCard(
                  backgroundColor: tokens.surface.withValues(alpha: context.isDarkMode ? 0.6 : 0.94),
                  borderColor: AppColors.neonPink.withValues(alpha: 0.3),
                  borderRadius: 24,
                  borderWidth: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.manage_accounts, size: 64, color: AppColors.neonPink.withValues(alpha: 0.7)),
                        const SizedBox(height: 16),
                        Text(
                          Translator.translate(AppStrings.profileCommanderTitle),
                          style: TextStyle(color: tokens.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          Translator.translate(
                            AppStrings.appBarPlayerGenericGreeting,
                            params: {
                              'level': '$level',
                              'tier': Translator.translate(levelTierKey(LevelTier.forLevel(level))),
                            },
                          ),
                          style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          Translator.translate(
                            AppStrings.profileXp,
                            params: {'xp': '${companionController.mascotController.profile.xp}'},
                          ),
                          style: TextStyle(color: tokens.primary),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<Set<String>>(
                          future: _completedLessons,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(Translator.translate(AppStrings.profileProgressUnavailable));
                            }
                            if (!snapshot.hasData) return const CircularProgressIndicator();
                            final count = snapshot.data!.length;
                            return Text(
                              Translator.translate(
                                count == 0
                                    ? AppStrings.profileLearningEmpty
                                    : count == 1
                                    ? AppStrings.profileLearningProgressOne
                                    : AppStrings.profileLearningProgress,
                                params: {'count': '$count'},
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: tokens.textSecondary),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Translator.translate(AppStrings.profileSettingsHint),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: tokens.textTertiary, fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.settings_outlined, color: AppColors.neonPink),
                          label: Text(
                            Translator.translate(AppStrings.settingsTitle),
                            style: const TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.neonPink),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).push(fadeRoute(const SettingsScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: PetSpeechBubbleOverlay(
                controller: companionController,
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
