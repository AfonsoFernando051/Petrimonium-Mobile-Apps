/// Reactive animation states the mascot can be rendered in.
///
/// [idle], [celebrate], [think], [sleep], [victory] and [sad] are driven by
/// app events (see `MascotController.triggerEventAnimation`). [happy] is a
/// short-lived reaction to direct user interaction (tap / pet). [talking]
/// and [listening] are driven by the Pet Companion's own UI state — a
/// speech bubble being shown, or the interaction sheet being open — rather
/// than by [PetBehavior]/[PetMessage] content, so they carry no opinion
/// about *what* the pet is discussing.
enum PetAnimationState {
  idle,
  celebrate,
  think,
  sleep,
  victory,
  happy,
  talking,
  listening,
  sad,
}

extension PetAnimationStateAsset on PetAnimationState {
  /// File name (without extension) used to look up the Lottie animation
  /// under `assets/mascot/animations/`.
  String get assetKey => name;
}
