import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/game_snack.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/cosmic_background.dart';
import 'package:petrimonium/core/widgets/game_button.dart';
import 'package:petrimonium/features/pet/data/models/investment_horizon_enum.dart';
import 'package:petrimonium/features/pet/data/models/pet_goal_enum.dart';

/// Perfil's "Preferências do Mentor" — the goal/investment-horizon context
/// `MentorChatRepository.sendMessage` already sends with every message (see
/// its `context` map), made visible and editable instead of only ever set
/// once during onboarding and never revisited.
class MentorPreferencesScreen extends StatefulWidget {
  const MentorPreferencesScreen({super.key});

  @override
  State<MentorPreferencesScreen> createState() => _MentorPreferencesScreenState();
}

class _MentorPreferencesScreenState extends State<MentorPreferencesScreen> {
  PetGoalEnum _goal = PetGoalEnum.buildWealth;
  InvestmentHorizonEnum _horizon = InvestmentHorizonEnum.mediumTerm;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goal = await DI.petPreferencesRepository.loadGoal();
    final horizon = await DI.petPreferencesRepository.loadHorizon();
    if (!mounted) return;
    setState(() {
      _goal = goal;
      _horizon = horizon;
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    await DI.petPreferencesRepository.saveGoal(_goal);
    await DI.petPreferencesRepository.saveHorizon(_horizon);
    if (!mounted) return;
    setState(() => _isLoading = false);
    GameSnack.show(context, Translator.translate(AppStrings.mentorPreferencesSavedSnack));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          Translator.translate(AppStrings.profileMentorPreferencesLabel),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
            children: [
              Text(
                Translator.translate(AppStrings.mentorPreferencesGoalLabel),
                style: TextStyle(color: tokens.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
              ),
              const SizedBox(height: 8),
              for (final goal in PetGoalEnum.values)
                _OptionTile(
                  icon: goal.icon,
                  label: goal.label,
                  selected: goal == _goal,
                  onTap: () => setState(() => _goal = goal),
                ),
              const SizedBox(height: 20),
              Text(
                Translator.translate(AppStrings.mentorPreferencesHorizonLabel),
                style: TextStyle(color: tokens.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
              ),
              const SizedBox(height: 8),
              for (final horizon in InvestmentHorizonEnum.values)
                _OptionTile(
                  icon: horizon.icon,
                  label: horizon.label,
                  description: horizon.description,
                  selected: horizon == _horizon,
                  onTap: () => setState(() => _horizon = horizon),
                ),
              const SizedBox(height: 28),
              GameButton(
                label: Translator.translate(AppStrings.quickSetupSaveCta),
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final IconData icon;
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final accent = selected ? tokens.primary : tokens.textTertiary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? tokens.primary : tokens.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: tokens.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  if (description != null)
                    Text(description!, style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: tokens.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
