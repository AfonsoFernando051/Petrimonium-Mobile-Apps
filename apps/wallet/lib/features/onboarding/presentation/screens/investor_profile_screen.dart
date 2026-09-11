import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/utils/friendly_error_message.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/onboarding/data/models/investor_profile_experience_enum.dart';
import 'package:petrimonium_wallet/features/onboarding/data/models/investor_profile_goal_enum.dart';
import 'package:petrimonium_wallet/features/onboarding/data/models/investor_profile_horizon_enum.dart';
import 'package:petrimonium_wallet/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:petrimonium_wallet/main.dart';

/// Wallet's own take on the investor-profile step Academy's onboarding
/// already asks (goal/horizon/experience) — same questions, submitted to the
/// same backend classification (`POST /api/onboarding/submit`), but only
/// shown when `StartRouteResolver` finds neither a real answer (possibly
/// already given via Academy, on the same account) nor a local skip. Reuses
/// this app's own plain, no-celebration onboarding chrome
/// ([OnboardingScaffold] + [OptionPill]) rather than Academy's more playful
/// per-row cards — "Mentor mais discreto" applies here as much as it does to
/// `AddAssetScreen`.
///
/// Always the last onboarding step: it comes after quick setup and, whether
/// answered or skipped, hands off to [MyApp] to re-resolve the start route
/// (which will now find it resolved and land on Home) — the same
/// restart-and-re-resolve pattern `QuickSetupScreen` already uses.
class InvestorProfileScreen extends StatefulWidget {
  const InvestorProfileScreen({super.key});

  @override
  State<InvestorProfileScreen> createState() => _InvestorProfileScreenState();
}

class _InvestorProfileScreenState extends State<InvestorProfileScreen> {
  InvestorProfileGoalEnum? _goal;
  InvestorProfileHorizonEnum? _horizon;
  InvestorProfileExperienceEnum? _experience;
  bool _isLoading = false;

  bool get _canSubmit => _goal != null && _horizon != null && _experience != null;

  Future<void> _handleContinue() async {
    if (!_canSubmit) return;
    setState(() => _isLoading = true);
    try {
      await DI.onboardingRepository.submitAssessment(
        goal: _goal!.wireValue,
        investmentHorizon: _horizon!.wireValue,
        experienceLevel: _experience!.wireValue,
      );
      await _restartApp();
    } catch (e) {
      if (mounted) {
        GameSnack.show(
          context,
          '${Translator.translate(AppStrings.investorProfileFailedSnack)} ${friendlyErrorMessage(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSkip() async {
    await DI.onboardingStateRepository.markInvestorProfileSkipped();
    await _restartApp();
  }

  /// Re-resolves `StartRoute` from scratch — this step is now either
  /// answered or skipped, so it lands on Home. Mirrors
  /// `QuickSetupScreen._handleContinue`.
  Future<void> _restartApp() async {
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MyApp()), (route) => false);
  }

  Widget _buildFields(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(Translator.translate(AppStrings.investorProfileGoalLabel)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final goal in InvestorProfileGoalEnum.values)
              OptionPill(label: goal.label, selected: goal == _goal, onTap: () => setState(() => _goal = goal)),
          ],
        ),
        const SizedBox(height: 20),
        FieldLabel(Translator.translate(AppStrings.investorProfileHorizonLabel)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final horizon in InvestorProfileHorizonEnum.values)
              OptionPill(
                label: horizon.label,
                selected: horizon == _horizon,
                onTap: () => setState(() => _horizon = horizon),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FieldLabel(Translator.translate(AppStrings.investorProfileExperienceLabel)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final experience in InvestorProfileExperienceEnum.values)
              OptionPill(
                label: experience.label,
                selected: experience == _experience,
                onTap: () => setState(() => _experience = experience),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 1,
      totalSteps: 1,
      title: Translator.translate(AppStrings.investorProfileTitle),
      subtitle: Translator.translate(AppStrings.investorProfileSubtitle),
      ctaLabel: Translator.translate(AppStrings.investorProfileCta),
      isCtaLoading: _isLoading,
      onCta: _canSubmit ? _handleContinue : null,
      showSkip: true,
      onSkip: _handleSkip,
      maxContentWidth: 640,
      body: _buildFields(context),
    );
  }
}
