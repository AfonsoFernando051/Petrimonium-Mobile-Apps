import 'package:flutter/material.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/debug/pet_animation_playground_screen.dart';

/// Separate entrypoint for [PetAnimationPlaygroundScreen] — a second
/// `main()`, the standard Flutter way to ship a dev tool that is never
/// reachable from the real app. `main.dart` (the app's real entrypoint)
/// does not import anything under `lib/dev/`, so nothing here ships in a
/// release build regardless of build mode.
///
/// Run with:
/// ```
/// flutter run -t lib/dev/main_pet_playground.dart
/// ```
void main() {
  runApp(const MaterialApp(home: PetAnimationPlaygroundScreen()));
}
