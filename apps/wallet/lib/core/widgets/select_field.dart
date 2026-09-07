import 'package:flutter/material.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';

/// A small, bold, uppercase-style label above a [SelectField] — matches the
/// Wallet quick-setup screen's field labels ("País / mercado", "Moeda-base").
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(color: context.colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

/// A tappable field that opens an [OptionSheet] picker — shared by the
/// Wallet's quick-setup onboarding screen and its Profile settings
/// equivalent, so both stay pixel-identical without duplicating the field
/// chrome.
class SelectField extends StatelessWidget {
  const SelectField({super.key, required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(value, style: TextStyle(color: tokens.textPrimary, fontSize: 15)),
            ),
            Icon(Icons.expand_more, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing every value of [T], selectable — the picker
/// [SelectField] opens.
class OptionSheet<T> extends StatelessWidget {
  const OptionSheet({super.key, required this.options, required this.current, required this.labelOf});

  final List<T> options;
  final T current;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              ListTile(
                title: Text(labelOf(option), style: TextStyle(color: tokens.textPrimary)),
                trailing: option == current ? Icon(Icons.check, color: tokens.primary) : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }
}
