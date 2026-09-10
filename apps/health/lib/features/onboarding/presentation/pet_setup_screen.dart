import 'package:flutter/material.dart';

import '../../../core/app/health_scope.dart';
import '../../../core/theme/health_theme.dart';
import '../../../core/widgets/health_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../health/domain/pet_species.dart';

const bool _kSpeciesPickerVisible = false;

/// `screenIsPetSetup` — shown only when the account has no Pet yet (a new
/// signup, or a Health-only account never onboarded through Academy/Wallet).
///
/// Species choice is hidden while Rive rigging cost keeps every app locked to
/// one mascot (Health = fox); flip [_kSpeciesPickerVisible] back on when that
/// changes instead of rebuilding the species grid below.
class PetSetupScreen extends StatefulWidget {
  const PetSetupScreen({super.key});

  @override
  State<PetSetupScreen> createState() => _PetSetupScreenState();
}

class _PetSetupScreenState extends State<PetSetupScreen> {
  PetSpecies _species = PetSpecies.fox;
  final _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final controller = HealthScope.of(context);
    setState(() => _error = null);
    try {
      await controller.createPet(species: _species, name: name);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = HealthScope.of(context);
    final l10n = AppLocalizations.of(context);
    final canSubmit = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      body: DecoratedBox(
        // Gradiente do artboard: os dois stops são os tokens que já existem.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HealthColors.background, HealthColors.surface],
          ),
        ),
        child: SafeArea(
          // Sem este limite a coluna estica na largura toda da janela: numa
          // janela de desktop a grelha dava cartões de ~480px.
          child: HealthContent(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Indicador de passo no topo e cabeçalho alinhado à esquerda,
                // como o artboard `PetHealth` — estava em baixo, junto ao CTA.
                ProgressDots(
                  total: controller.onboardingTotalSteps,
                  current: 1,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.petSetupTitle,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: HealthColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.petSetupSubtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: HealthColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Picker escondido (ver _kSpeciesPickerVisible), mas o
                        // pet ainda precisa aparecer para quem está a dar-lhe
                        // um nome — o mesmo retrato do mascote do ecrã de
                        // login, não a grelha interativa.
                        Center(
                          child: Image.asset(
                            _species.assetPath,
                            height: 96,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.pets,
                                size: 48,
                                color: HealthColors.textSecondary,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_kSpeciesPickerVisible) ...[
                          Text(
                            l10n.petSetupSpeciesLabel,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: HealthColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.8,
                            children: PetSpecies.values
                                .map((species) {
                                  final selected = species == _species;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _species = species),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        // Não-selecionado é totalmente transparente (o
                                        // artboard usa `transparent` no contorno e no
                                        // fundo), para a grelha não virar uma grade.
                                        color: selected
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: .08)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: selected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            species.assetPath,
                                            height: 46,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _speciesLabel(l10n, species),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              // Só o peso muda com a selecção: no
                                              // artboard a cor do rótulo é a mesma nas
                                              // sete espécies.
                                              fontSize: 10.5,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color: HealthColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                })
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Text(
                          l10n.petSetupNameLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: HealthColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          maxLength: 16,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: l10n.petSetupNameHint,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: HealthColors.inputFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: HealthColors.border),
                          ),
                          child: Text(
                            l10n.petSetupFooterNote,
                            style: const TextStyle(
                              fontSize: 12,
                              color: HealthColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: HealthColors.negative,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: HealthPrimaryButton(
                    label: l10n.petSetupCta,
                    busy: controller.busy,
                    onPressed: canSubmit ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _speciesLabel(AppLocalizations l10n, PetSpecies species) =>
      switch (species) {
        PetSpecies.fox => l10n.speciesFox,
        PetSpecies.dog => l10n.speciesDog,
        PetSpecies.cat => l10n.speciesCat,
        PetSpecies.owl => l10n.speciesOwl,
        PetSpecies.wolf => l10n.speciesWolf,
        PetSpecies.bear => l10n.speciesBear,
        PetSpecies.lion => l10n.speciesLion,
      };
}
