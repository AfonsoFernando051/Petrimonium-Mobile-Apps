import 'package:flutter/material.dart';
import '../tokens/app_color_tokens.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';
import 'glass_card.dart';

/// Where/how prominently an [ErrorStateView] renders — previously each
/// screen (`AssetDetailsScreen`, `PortfolioScreen`,
/// `DividendNotificationsSheet`) hand-rolled its own near-identical
/// icon+message+retry block with its own "Tentar novamente" button.
enum ErrorStateStyle {
  /// Full-bleed section error, no card chrome (e.g. Asset Details body).
  standard,

  /// Same content wrapped in a [GlassCard] for a screen whose other states
  /// (loading/content) already sit inside cards (e.g. Portfolio).
  card,

  /// Small inline error inside an already-scoped container (e.g. a bottom
  /// sheet section) — smaller icon, a text-only retry action instead of a
  /// filled button.
  compact,
}

/// Shared "something failed, here's why, try again" state. See
/// [ErrorStateStyle] for the three visual treatments in use across the app.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.retryLabel,
    this.title,
    this.style = ErrorStateStyle.standard,
  });

  /// Optional bold headline shown above [message]. `compact` style never
  /// shows a title (there isn't room for one in an inline section error).
  final String? title;
  final String message;
  final Future<void> Function() onRetry;

  /// Already-localized label for the retry action. Passed in for the same
  /// reason as everywhere else in this package: no shared string catalog.
  final String retryLabel;
  final ErrorStateStyle style;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

    if (style == ErrorStateStyle.compact) {
      return Column(
        children: [
          Icon(Icons.satellite_alt, color: tokens.error, size: 32),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, color: context.brand.accent, size: 16),
            label: Text(retryLabel, style: TextStyle(color: context.brand.accent)),
          ),
        ],
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.satellite_alt, size: 56, color: tokens.error),
        const SizedBox(height: AppSpacing.lg),
        if (title != null) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(retryLabel),
          style: ElevatedButton.styleFrom(backgroundColor: context.brand.accentDeep, foregroundColor: Colors.white),
        ),
      ],
    );

    if (style == ErrorStateStyle.card) {
      return Center(
        child: GlassCard(
          backgroundColor: tokens.surface.withValues(alpha: context.isDarkMode ? 0.6 : 0.94),
          borderColor: tokens.error.withValues(alpha: 0.4),
          borderRadius: AppRadii.xxl,
          child: Padding(padding: const EdgeInsets.all(28), child: content),
        ),
      );
    }

    return Center(
      child: Padding(padding: const EdgeInsets.all(AppSpacing.xxxl), child: content),
    );
  }
}
