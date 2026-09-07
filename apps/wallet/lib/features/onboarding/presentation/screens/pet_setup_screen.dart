import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/friendly_error_message.dart';
import 'package:petrimonium/core/utils/game_snack.dart';
import 'package:petrimonium/core/utils/pet_assets.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/select_field.dart';
import 'package:petrimonium/features/onboarding/presentation/screens/mentor_welcome_screen.dart';
import 'package:petrimonium/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:petrimonium/features/pet/data/models/pet_specie_enum.dart';

/// Step 1 of 3 — only reached when [StartRouteResolver] finds no Pet on the
/// account yet (a Wallet-first signup with no prior Academy account). An
/// account that already has a Pet (e.g. from the Academy) skips straight to
/// [MentorWelcomeScreen] instead, since its species/progress already carry
/// over — see [AppStrings.petSetupFooterNote].
class PetSetupScreen extends StatefulWidget {
  const PetSetupScreen({super.key});

  @override
  State<PetSetupScreen> createState() => _PetSetupScreenState();
}

class _PetSetupScreenState extends State<PetSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  PetSpecieEnum _selectedSpecie = PetSpecieEnum.FOX;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Re-renders on every keystroke so the CTA enables the moment a name is
    // typed, instead of only after a failed submit attempt.
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _nameController.text.trim().isNotEmpty && !_isLoading;

  void _selectSpecie(PetSpecieEnum specie) => setState(() => _selectedSpecie = specie);

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await DI.petRepository.configurePet(_selectedSpecie);
      await DI.mascotRepository.saveName(name);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MentorWelcomeScreen(totalSteps: 3)),
        );
      }
    } catch (e) {
      if (mounted) {
        GameSnack.show(
          context,
          '${Translator.translate(AppStrings.petSetupFailedSnack)} ${friendlyErrorMessage(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 1,
      totalSteps: 3,
      title: Translator.translate(AppStrings.petSetupTitle),
      subtitle: Translator.translate(AppStrings.petSetupSubtitle),
      ctaLabel: Translator.translate(AppStrings.petSetupCta),
      isCtaLoading: _isLoading,
      onCta: _canSubmit ? _handleSubmit : null,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(Translator.translate(AppStrings.petSetupSpeciesLabel)),
          const SizedBox(height: 10),
          _SpeciesGrid(selected: _selectedSpecie, onSelect: _selectSpecie),
          const SizedBox(height: 20),
          FieldLabel(Translator.translate(AppStrings.petSetupNameLabel)),
          const SizedBox(height: 8),
          _PetNameField(controller: _nameController),
          const SizedBox(height: 16),
          Text(
            Translator.translate(AppStrings.petSetupFooterNote),
            style: TextStyle(color: context.colors.textTertiary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SpeciesGrid extends StatelessWidget {
  const _SpeciesGrid({required this.selected, required this.onSelect});

  final PetSpecieEnum selected;
  final ValueChanged<PetSpecieEnum> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: [
        for (final specie in PetSpecieEnum.values)
          _SpeciesCard(
            specie: specie,
            selected: specie == selected,
            onTap: () => onSelect(specie),
          ),
      ],
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({required this.specie, required this.selected, required this.onTap});

  final PetSpecieEnum specie;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? tokens.primaryContainer : tokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? tokens.primary : tokens.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              PetAssets.imageFor(specie.name),
              width: 38,
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.pets, size: 28, color: tokens.textSecondary);
              },
            ),
            const SizedBox(height: 6),
            Text(
              specie.displayLabel,
              style: TextStyle(
                color: selected ? tokens.textPrimary : tokens.textSecondary,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PetNameField extends StatelessWidget {
  const _PetNameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: TextField(
        controller: controller,
        maxLength: 16,
        style: TextStyle(color: tokens.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          hintText: Translator.translate(AppStrings.petSetupNameHint),
          hintStyle: TextStyle(color: tokens.textTertiary, fontSize: 14),
        ),
      ),
    );
  }
}
