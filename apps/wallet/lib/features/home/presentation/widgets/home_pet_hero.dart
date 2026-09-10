import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/widgets/pet_mascot_widget.dart';

/// Home's own big, expressive pet — the companion the Wallet's empty-state
/// dashboard and (smaller) greeting row show, as opposed to the small,
/// always-present `PetCompanionHeader` avatar in the AppBar chrome. "O PET
/// eh um personagem vivo que ajude o usuario na jornada, ele deve ser maior
/// e aparecer mais no dashboard, nao ficar pequeno e discreto" — this is
/// that bigger, more present treatment, reusing `PetMascotWidget`'s own
/// breathing/tap animation rather than a new one.
///
/// When [anchor] is supplied, registers this widget's on-screen position via
/// `CompositedTransformTarget` — the same pattern `PetCompanionHeader` uses
/// for its own anchor — so `PetSpeechBubbleOverlay` glues the companion's
/// contextual messages to wherever the Pet actually renders on Home, instead
/// of silently never appearing (an unlinked `CompositedTransformFollower`
/// shows nothing).
class HomePetHero extends StatelessWidget {
  const HomePetHero({super.key, required this.mascotController, this.anchor, this.size = 168, this.showGlow = true});

  final MascotController mascotController;
  final PetSpeechBubbleAnchor? anchor;
  final double size;
  final bool showGlow;

  Widget _wrapWithAnchor(Widget child) {
    final anchor = this.anchor;
    if (anchor == null) return child;
    return CompositedTransformTarget(
      link: anchor.link,
      child: KeyedSubtree(key: anchor.boxKey, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mascot = PetMascotWidget(controller: mascotController, size: size * 0.86, interactive: true);

    if (!showGlow) return _wrapWithAnchor(mascot);

    return _wrapWithAnchor(
      Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [context.colors.primary.withValues(alpha: 0.3), context.colors.primary.withValues(alpha: 0)],
            stops: const [0.0, 0.78],
          ),
        ),
        child: mascot,
      ),
    );
  }
}
