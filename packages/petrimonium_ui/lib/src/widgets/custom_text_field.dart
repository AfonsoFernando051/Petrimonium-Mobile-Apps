import 'package:flutter/material.dart';
import '../tokens/app_color_tokens.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController? controller;

  /// Shown below the field in [AppColorTokens.error] and turns the field's
  /// own border/glow red — `null` (the default) leaves the field exactly as
  /// before for every call site that doesn't opt in.
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.controller,
    this.errorText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  // Starts obscured whenever the field asked for it; the eye toggle below
  // only ever reveals it for this field instance, never affects others.
  late bool _obscureText = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final hasError = widget.errorText != null;

    // No bespoke Container/border/shadow here on purpose: the flat fill,
    // radius and focus/error border colors all come from the shared
    // `inputDecorationTheme` in `PetrimoniumTheme.build`, so this field reads
    // exactly like a plain `TextField` styled by the ambient theme.
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscure && _obscureText,
      style: TextStyle(color: tokens.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(widget.icon, color: hasError ? tokens.error : tokens.textSecondary),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: tokens.textTertiary,
                ),
                tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
        hintText: widget.hint,
        errorText: widget.errorText,
        errorMaxLines: 2,
      ),
    );
  }
}
