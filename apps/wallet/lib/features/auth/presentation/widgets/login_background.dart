import 'package:flutter/material.dart';
import '../../../../core/widgets/cosmic_background.dart';

/// Same flat petrol-green background every other Wallet screen uses — see
/// [CosmicBackground]. Previously this overrode it with a nebula/starfield
/// effect and, before that, `questionary_space_paw.png` (a leftover artwork
/// asset from the old pre-redesign questionnaire screen); both read as
/// off-brand against the Notion mockups' static, uniform background.
class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const CosmicBackground(child: SizedBox.shrink());
  }
}
