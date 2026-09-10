import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Settings → Privacy: "show on rankings" toggle.
///
/// Copy arrives as parameters rather than through a translator: this widget
/// lives in a package and has no product catalogue of its own, and passing the
/// strings in keeps each product's wording a compile-time obligation instead of
/// a key that silently renders raw when the other app never defined it.
class PrivacySection extends StatelessWidget {
  const PrivacySection({
    super.key,
    required this.sectionLabel,
    required this.sectionTitle,
    required this.showOnRankingsLabel,
    required this.showOnRankings,
    required this.onShowOnRankingsChanged,
  });

  final Widget Function(String label) sectionLabel;

  /// Rendered uppercased by this section, as every Settings section does.
  final String sectionTitle;
  final String showOnRankingsLabel;
  final bool showOnRankings;
  final ValueChanged<bool> onShowOnRankingsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(sectionTitle.toUpperCase()),
        SettingsToggleCard(
          children: [
            SettingsSwitchTile(
              icon: Icons.leaderboard_outlined,
              label: showOnRankingsLabel,
              value: showOnRankings,
              onChanged: onShowOnRankingsChanged,
            ),
          ],
        ),
      ],
    );
  }
}
