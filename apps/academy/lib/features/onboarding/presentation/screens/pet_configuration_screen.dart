import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:petrimonium_academy/core/utils/friendly_error_message.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/screens/academy_intro_screen.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:petrimonium_academy/features/pet/data/models/pet_specie_enum.dart';
import 'package:petrimonium_academy/features/pet/presentation/widgets/pet_name_field.dart';
import 'package:petrimonium_academy/features/pet/presentation/widgets/pet_species_selector.dart';

/// Onboarding's "Configure Your Pet" step — the pet introduces itself, and
/// the player picks its species and name together in one screen right after
/// the emotional Welcome opener. The financial goal (`FinancialGoalScreen`)
/// and the Academy/Gamification narrative screens come after this one.
class PetConfigurationScreen extends StatefulWidget {
  const PetConfigurationScreen({super.key});

  @override
  State<PetConfigurationScreen> createState() => _PetConfigurationScreenState();
}

class _PetConfigurationScreenState extends State<PetConfigurationScreen> {
  static const _nameSuggestions = [
    'Atlas',
    'Bolt',
    'Loki',
    'Charlie',
    'Max',
    'Nino',
  ];

  // Lobo por omissão: é o mascote da Academy (o mesmo do ecrã de login) e é
  // o que o artboard `PetAcademy` do canvas mostra pré-selecionado.
  PetSpecieEnum _selectedSpecie = PetSpecieEnum.WOLF;
  bool _isLoading = false;
  bool _showNameError = false;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _pickSuggestion(String name) {
    HapticFeedback.selectionClick();
    setState(() {
      _nameController.text = name;
      _showNameError = false;
    });
  }

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await DI.petRepository.configurePet(_selectedSpecie, name: name);
      await DI.mascotRepository.saveName(name);
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AcademyIntroScreen()));
      }
    } catch (e) {
      if (mounted) {
        GameSnack.show(
          context,
          '${Translator.translate(AppStrings.failedToSavePet)}: ${friendlyErrorMessage(e)}',
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
      step: 2,
      totalSteps: 8,
      maxContentWidth: 900,
      title: Translator.translate(AppStrings.meetPetTitle),
      subtitle: Translator.translate(AppStrings.meetPetIntro),
      ctaLabel: Translator.translate(AppStrings.meetPetContinue),
      isCtaLoading: _isLoading,
      onCta: _handleContinue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        // Coluna única e plana, como o artboard `PetAcademy`: sem GlassCard a
        // envolver, sem a cápsula circular do mascote e sem o painel lateral
        // — o canvas leva do rótulo da espécie direto para a grelha e daí
        // para o nome.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(Translator.translate(AppStrings.meetPetSpeciesPrompt)),
            const SizedBox(height: 10),
            PetSpeciesSelector(
              selected: _selectedSpecie,
              onSelected: (specie) => setState(() => _selectedSpecie = specie),
            ),
            const SizedBox(height: 20),
            FieldLabel(Translator.translate(AppStrings.meetPetNeedName)),
            const SizedBox(height: 8),
            PetNameField(
              controller: _nameController,
              showError: _showNameError,
              suggestions: _nameSuggestions,
              onChanged: (_) {
                if (_showNameError) setState(() => _showNameError = false);
              },
              onSuggestionSelected: _pickSuggestion,
            ),
          ],
        ),
      ),
    );
  }
}
