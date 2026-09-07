import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/features/onboarding/presentation/screens/quick_setup_screen.dart';
import 'package:petrimonium/features/onboarding/presentation/widgets/onboarding_scaffold.dart';

/// The second-to-last screen in the Wallet's mini-onboarding: the Mentor
/// introduces itself and sets guardrail expectations up front (real data, no
/// execution, always-cited interpretation) — never a pet-hero/gamification
/// moment like the Academy's `WelcomeScreen`, per "Mentor mais discreto".
///
/// [totalSteps] is 2 for the common case (account already has a Pet) or 3
/// when [PetSetupScreen] ran first (a Wallet-first signup with no Pet yet) —
/// this screen is always its second-to-last step, so its own step number is
/// `totalSteps - 1`, and it forwards [totalSteps] on to [QuickSetupScreen].
class MentorWelcomeScreen extends StatelessWidget {
  const MentorWelcomeScreen({super.key, this.totalSteps = 2});

  final int totalSteps;

  Future<void> _goNext(BuildContext context) async {
    await DI.onboardingStateRepository.markMentorWelcomeSeen();
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuickSetupScreen(totalSteps: totalSteps)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: totalSteps - 1,
      totalSteps: totalSteps,
      title: '',
      ctaLabel: Translator.translate(AppStrings.mentorWelcomeCta),
      onCta: () => _goNext(context),
      body: const _MentorCard(),
    );
  }
}

class _MentorCard extends StatelessWidget {
  const _MentorCard();

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
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
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.pets, size: 20, color: tokens.mentor);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mentor',
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            Translator.translate(AppStrings.mentorWelcomeHeadline),
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          _paragraph(context, AppStrings.mentorWelcomeParagraph1),
          const SizedBox(height: 12),
          _paragraph(context, AppStrings.mentorWelcomeParagraph2),
          const SizedBox(height: 12),
          _paragraph(context, AppStrings.mentorWelcomeParagraph3),
        ],
      ),
    );
  }

  Widget _paragraph(BuildContext context, String stringKey) {
    return Text(
      Translator.translate(stringKey),
      style: TextStyle(color: context.colors.textSecondary, fontSize: 14, height: 1.5),
    );
  }
}
