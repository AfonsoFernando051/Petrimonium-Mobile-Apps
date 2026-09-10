import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Settings → Appearance: lets the user pick Light / Dark / System. Wraps
/// its own `ValueListenableBuilder` on [ThemeController.themeModeNotifier]
/// so the selected-state highlight updates immediately on tap, independent
/// of whatever else triggers a `SettingsScreen` rebuild.
///
/// Copy arrives as parameters — see [PrivacySection] for why. The swatch
/// colours deliberately do not: they are the theme being previewed, the same
/// in every product, not the product's own accent.
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({
    super.key,
    required this.sectionLabel,
    required this.sectionTitle,
    required this.lightLabel,
    required this.lightDescription,
    required this.darkLabel,
    required this.darkDescription,
    required this.systemLabel,
    required this.systemDescription,
  });

  /// Callback that renders this section's uppercase label the same way
  /// every other Settings section does (kept in the parent screen so the
  /// styling stays defined in exactly one place).
  final Widget Function(String label) sectionLabel;
  final String sectionTitle;
  final String lightLabel;
  final String lightDescription;
  final String darkLabel;
  final String darkDescription;
  final String systemLabel;
  final String systemDescription;

  Future<void> _select(ThemeMode mode) => ThemeController.setThemeMode(mode);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, mode, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionLabel(sectionTitle.toUpperCase()),
            AppearanceOptionCard(
              icon: Icons.light_mode_rounded,
              label: lightLabel,
              description: lightDescription,
              swatchColors: const [Color(0xFFFFD97A), Color(0xFF00B4C6)],
              selected: mode == ThemeMode.light,
              onTap: () => _select(ThemeMode.light),
            ),
            const SizedBox(height: 10),
            AppearanceOptionCard(
              icon: Icons.dark_mode_rounded,
              label: darkLabel,
              description: darkDescription,
              swatchColors: const [Color(0xFF1A0B2E), Color(0xFF101835)],
              selected: mode == ThemeMode.dark,
              onTap: () => _select(ThemeMode.dark),
            ),
            const SizedBox(height: 10),
            AppearanceOptionCard(
              icon: Icons.brightness_auto_rounded,
              label: systemLabel,
              description: systemDescription,
              swatchColors: const [Color(0xFF8A2BE2), Color(0xFF00E5FF)],
              selected: mode == ThemeMode.system,
              onTap: () => _select(ThemeMode.system),
            ),
          ],
        );
      },
    );
  }
}
