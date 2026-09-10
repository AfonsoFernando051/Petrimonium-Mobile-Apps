import 'package:flutter/material.dart';
import '../tokens/app_color_tokens.dart';
import '../tokens/app_radii.dart';

/// The single logout-confirmation dialog, shown from both Dashboard and
/// Settings in every product. Centralizing it means there is exactly one
/// place that defines what this dialog looks like and how it behaves.
///
/// Copy is passed in rather than resolved here: the products do not share a
/// string catalog, and a shared widget that reached for one would couple this
/// package to a single product's localization system.
class ConfirmLogoutDialog {
  ConfirmLogoutDialog._();

  /// Shows the dialog and resolves to `true` if the user confirmed logout.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
  }) async {
    final tokens = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tokens.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
        title: Text(
          title,
          style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: TextStyle(color: tokens.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel, style: TextStyle(color: tokens.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel, style: TextStyle(color: tokens.error)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
