import 'package:flutter/material.dart';
import '../tokens/app_color_tokens.dart';

/// A labeled horizontal rule ("— or —") separating a primary action from an
/// alternative below it. [label] is the divider word/phrase, supplied by the
/// caller so this widget carries no string catalog of its own.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: tokens.textTertiary)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: TextStyle(color: tokens.textTertiary, fontSize: 12)),
        ),
        Expanded(child: Divider(color: tokens.textTertiary)),
      ],
    );
  }
}
