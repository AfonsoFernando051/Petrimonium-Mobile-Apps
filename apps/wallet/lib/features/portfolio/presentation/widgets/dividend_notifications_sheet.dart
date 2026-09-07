import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/app_loading_indicator.dart';
import 'package:petrimonium/core/widgets/error_state_view.dart';
import 'package:petrimonium/features/portfolio/domain/entities/dividend_event.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/dividend_event_tile.dart';

/// Bell-icon notification popover — real, provider-confirmed upcoming
/// dividend / JCP / yield payments for the user's real holdings (the same
/// [DividendEvent] data backing `DividendRadarSection` on the Proventos tab,
/// just surfaced app-wide via the AppBar instead of gated behind that tab).
/// Reuses [DividendEventTile] rather than inventing a second row layout for
/// the same data — matches AI_RULES.md's "reuse before you invent".
///
/// A compact anchored popover, not a full-width bottom sheet — see
/// `DashboardScreen._openNotifications`, which positions this near the bell
/// via a top-right-aligned dialog rather than `showModalBottomSheet`.
class DividendNotificationsSheet extends StatelessWidget {
  const DividendNotificationsSheet({
    super.key,
    required this.isLoading,
    required this.error,
    required this.upcoming,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final List<DividendEvent> upcoming;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 320,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.border),
          boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              Translator.translate(AppStrings.proventosNotificationsTitle).toUpperCase(),
              style: TextStyle(
                color: tokens.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            _buildBody(context),
            const SizedBox(height: 12),
            Text(
              Translator.translate(AppStrings.proventosNotificationsFooter),
              style: TextStyle(color: tokens.textTertiary, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final tokens = context.colors;
    if (isLoading && upcoming.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: AppLoadingIndicator(strokeWidth: 2),
      );
    }

    if (error != null && upcoming.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ErrorStateView(
          message: 'Não foi possível carregar suas notificações.',
          onRetry: () async => onRetry(),
          style: ErrorStateStyle.compact,
        ),
      );
    }

    if (upcoming.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(Icons.notifications_off_outlined, color: tokens.textTertiary, size: 28),
            const SizedBox(height: 8),
            Text(
              'Nenhum provento confirmado a caminho para os seus ativos no momento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [for (final event in upcoming) DividendEventTile(event: event)],
    );
  }
}
