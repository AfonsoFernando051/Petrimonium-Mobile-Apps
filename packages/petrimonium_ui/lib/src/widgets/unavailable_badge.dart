import 'package:flutter/material.dart';
import '../tokens/app_color_tokens.dart';

/// Shared "coming soon" visual language for any control that looks
/// interactive but isn't implemented yet — extracted from the Financial
/// Lab's `_LabTile` pattern (`financial_lab_home_screen.dart`), which was
/// already the one place in the app that got this right: reduced opacity,
/// a small muted label, and hit-testing actually disabled rather than
/// merely styled to look disabled. Reused wherever a false affordance
/// (Search, Sell, Reports, Import) needs the same honest treatment instead
/// of each screen inventing its own variant.
class UnavailableBadge extends StatelessWidget {
  const UnavailableBadge({super.key, required this.label});

  /// The already-localized reason, e.g. a translated "coming soon". This
  /// package holds no string catalog of its own - Academy/Wallet and Health
  /// localize through different mechanisms, so text is always passed in by
  /// the product rather than resolved here.
  final String label;

  /// The opacity every unavailable control in the app should apply to its
  /// whole subtree — one constant instead of each call site guessing a
  /// number, so "how faded is unavailable" reads the same everywhere.
  static const double opacity = 0.55;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: context.colors.textTertiary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
