import 'dart:async';

import 'package:petrimonium_academy/features/pet/presentation/companion/rive/pet_rive_companion.dart';

/// Runs once for the whole `flutter test` run, before any test file.
///
/// `flutter_tester` cannot initialize Rive's text engine, and the failure is
/// not something a caller can catch — see
/// [PetRiveCompanion.debugLoadRiveAssets] for the mechanism. Any screen that
/// renders the pet would otherwise fail whichever test reached it first and
/// leave the zone poisoned for the rest of the run, so `.riv` loading is off
/// here and every pet renders its portrait fallback instead. The real rigs
/// are verified by running the app (`flutter run -d linux`).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PetRiveCompanion.debugLoadRiveAssets = false;
  await testMain();
}
