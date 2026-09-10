import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Settings → Privacy: "show on rankings" toggle.
class PrivacySection extends StatelessWidget {
  const PrivacySection({
    super.key,
    required this.sectionLabel,
    required this.showOnRankings,
    required this.onShowOnRankingsChanged,
  });

  final Widget Function(String label) sectionLabel;
  final bool showOnRankings;
  final ValueChanged<bool> onShowOnRankingsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(Translator.translate(AppStrings.privacySectionTitle).toUpperCase()),
        SettingsToggleCard(children: [
          SettingsSwitchTile(
            icon: Icons.leaderboard_outlined,
            label: Translator.translate(AppStrings.showOnRankings),
            value: showOnRankings,
            onChanged: onShowOnRankingsChanged,
          ),
        ]),
      ],
    );
  }
}
