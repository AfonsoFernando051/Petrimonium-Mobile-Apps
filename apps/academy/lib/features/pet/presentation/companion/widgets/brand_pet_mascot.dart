import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:petrimonium_academy/core/utils/pet_assets.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/rive/pet_rive_companion.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';

/// Academy's mascot as a live Rive character, for the screens that show the
/// *brand's* pet rather than the player's: the splash, login, and the
/// onboarding steps that run before a pet exists to load.
///
/// Those screens can't use [PetRiveCompanion] directly, because it follows a
/// [MascotController]'s saved profile — which is exactly what they have no
/// business loading (there is no signed-in player yet, and on first launch no
/// saved pet at all). Here the species is fixed instead, and the controller
/// exists only to satisfy the companion's contract: it is deliberately never
/// loaded, so it stays on its placeholder profile and the character idles.
///
/// Species without a `Companion`-contract `.riv` keep the exact portrait
/// these screens showed before (`allowStopgapRigs: false` + the portrait as
/// the fallback), so this can never downgrade a screen to the differently-
/// drawn `dog.riv`/`owl.riv` reference art.
class BrandPetMascot extends StatefulWidget {
  const BrandPetMascot({
    super.key,
    this.size,
    this.specie,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  /// Side of the square box the character is laid out in. `null` fills
  /// whatever the parent allows — for a caller that already constrains it
  /// (e.g. `PetHeroCapsule`, whose padding decides the real size).
  final double? size;

  /// `null` means Academy's brand mascot — the wolf, same species
  /// [PetAssets.imageFor] falls back to. Onboarding passes the species being
  /// named so the two stay in step if the picker is ever shown again.
  final PetSpecieEnum? specie;

  final BoxFit fit;
  final Alignment alignment;

  @override
  State<BrandPetMascot> createState() => _BrandPetMascotState();
}

class _BrandPetMascotState extends State<BrandPetMascot> {
  /// Never `loadProfile()`d — see the class doc. Still disposed, since
  /// [PetRiveCompanion] subscribes to it.
  late final MascotController _controller = MascotController(repository: DI.mascotRepository);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PetSpecieEnum get _specie => widget.specie ?? PetSpecieEnum.WOLF;

  Widget _companion(double size) {
    return PetRiveCompanion(
      controller: _controller,
      size: size,
      interactive: false,
      allowStopgapRigs: false,
      specieOverride: _specie,
      stateOverride: PetAnimationState.idle,
      fit: widget.fit,
      alignment: widget.alignment,
      fallbackBuilder: (context) => Image.asset(
        PetAssets.imageFor(_specie.name),
        width: size,
        height: size,
        fit: widget.fit,
        alignment: widget.alignment,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.pets, size: size * 0.5, color: context.colors.mentor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    if (size != null) return _companion(size);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : constraints.maxHeight;
        final height = constraints.maxHeight.isFinite ? constraints.maxHeight : constraints.maxWidth;
        return _companion(math.min(width, height));
      },
    );
  }
}
