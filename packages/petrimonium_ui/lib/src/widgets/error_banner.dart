import 'package:flutter/material.dart';

import '../tokens/app_color_tokens.dart';
import 'glass_card.dart';

/// Small non-blocking banner shown above a tab's content when a refresh
/// fails but cached data is still being displayed — so a transient network
/// hiccup doesn't replace the whole screen with an error state.
///
/// [message] is a parameter rather than a constant: this package carries no
/// string catalog, so each product supplies its own copy.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return GlassCard(
      backgroundColor: tokens.error.withValues(alpha: 0.1),
      borderColor: tokens.error.withValues(alpha: 0.4),
      borderRadius: 14,
      borderWidth: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.satellite_alt, color: tokens.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: tokens.textPrimary, fontSize: 12),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: tokens.error, size: 18),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
