import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/widgets/pet_mascot_widget.dart';

/// How a species' bundled `.riv` should be driven to reflect
/// [PetAnimationState]. Every bundled file is expected to satisfy the
/// default [_CompanionRig] — a single artboard exposing a `Companion` state
/// machine with a persistent `state` number input plus `reducedMotion`/
/// `interacting` bools (see `docs/RIVE_PET_COMPANION_BRIEF.md`) — except the
/// two stopgap reference assets bundled ahead of any real `Companion`-
/// contract file existing, which need their own adapter:
/// - `dog.riv` ([_TriggerRig]) is `pet_cachorro_state_machine.riv` verbatim:
///   one artboard, but poses are fired as one-shot triggers on a
///   differently-named state machine, not a persistent number input.
/// - `owl.riv` ([_PoseSwapRig]) is the owl mascot expression-pack reference
///   asset verbatim: no unified state machine at all — each pose is its own
///   self-contained, autoplaying artboard, so "switching pose" means
///   swapping which artboard is mounted rather than driving any input.
///   `RiveAnimation` already re-initializes when its `artboard` parameter
///   changes, so no manual key/remount plumbing is needed for this.
///
/// [_kRigForSpecie] is deliberately keyed only by the species that actually
/// have a bundled stopgap today; anything else falls through to
/// [_CompanionRig], which is what a real future asset is meant to satisfy.
sealed class _RiveCompanionRig {
  const _RiveCompanionRig(this.stateMachineName);

  final String stateMachineName;
}

class _CompanionRig extends _RiveCompanionRig {
  const _CompanionRig() : super('Companion');
}

class _TriggerRig extends _RiveCompanionRig {
  const _TriggerRig(super.stateMachineName, this.triggerForState);

  /// `null` means "no trigger — stay on/return to the rig's built-in idle
  /// pose".
  final String? Function(PetAnimationState) triggerForState;
}

class _PoseSwapRig extends _RiveCompanionRig {
  const _PoseSwapRig(super.stateMachineName, this.artboardForState);

  final String Function(PetAnimationState) artboardForState;
}

/// [PetAnimationState.sleep] has no real counterpart in `dog.riv`, so it
/// borrows `Blink` (eyes closing) as the closest available stand-in until a
/// proper sleep pose is authored.
String? _dogTriggerForState(PetAnimationState state) {
  switch (state) {
    case PetAnimationState.idle:
      return null;
    case PetAnimationState.happy:
      return 'Happy';
    case PetAnimationState.celebrate:
      return 'Tail Wag';
    case PetAnimationState.victory:
      return 'Excited';
    case PetAnimationState.think:
      return 'Sit';
    case PetAnimationState.sleep:
      return 'Blink';
  }
}

/// Owl expression-pack artboard names (see `assets/rive/pet/owl.riv`, a
/// marketplace expression pack copied in verbatim) chosen for each
/// [PetAnimationState]. Like the dog stopgap, [PetAnimationState.sleep]
/// has no literal sleep pose in this pack — artboard `13` (calm, one eye
/// closed) is the closest available stand-in.
String _owlArtboardForState(PetAnimationState state) {
  switch (state) {
    case PetAnimationState.idle:
      return '1';
    case PetAnimationState.happy:
      return '5';
    case PetAnimationState.celebrate:
      return '10';
    case PetAnimationState.think:
      return '11';
    case PetAnimationState.sleep:
      return '13';
    case PetAnimationState.victory:
      return '14';
  }
}

const Map<String, _RiveCompanionRig> _kRigForSpecie = {
  'dog': _TriggerRig('Pet State Machine', _dogTriggerForState),
  'owl': _PoseSwapRig('State Machine 1', _owlArtboardForState),
};

_RiveCompanionRig _rigFor(String specieKey) => _kRigForSpecie[specieKey] ?? const _CompanionRig();

/// Drop-in replacement for [PetMascotWidget] that renders the pet companion
/// through its Rive character (`assets/rive/pet/{specie}.riv`) once one
/// exists, and falls back to [PetMascotWidget] until then.
///
/// `dog.riv` and `owl.riv` are bundled today as stopgap reference assets
/// (verbatim — see [_kRigForSpecie]); `wolf.riv` is the first real
/// `Companion`-contract file and uses the default [_CompanionRig]. Every other
/// species still renders the fallback because nothing is bundled at that asset
/// path yet (see `assets/rive/pet/README.md`).
class PetRiveCompanion extends StatefulWidget {
  const PetRiveCompanion({
    super.key,
    required this.controller,
    this.size = 220,
    this.interactive = true,
    this.interacting = false,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.fallbackBuilder,
    this.stateOverride,
    this.specieOverride,
    this.allowStopgapRigs = true,
  });

  final MascotController controller;
  final double size;
  final bool interactive;

  /// How the artboard is laid out inside the `size`×`size` box — e.g.
  /// `BoxFit.cover` + `Alignment.topCenter` to crop to the pet's head inside
  /// a small circular avatar.
  final BoxFit fit;
  final Alignment alignment;

  /// What to render when there's no usable `.riv` for the species (missing,
  /// unparsable, or a stopgap rig with [allowStopgapRigs] off). Defaults to
  /// [PetMascotWidget]. Screens that previously showed the species' static
  /// portrait pass that portrait here, so species without a Rive character
  /// look exactly as they did before.
  final WidgetBuilder? fallbackBuilder;

  /// Drives the `state` input instead of [MascotController.animationState],
  /// for a screen-local mood that shouldn't leak into every other place the
  /// shared controller is shown (e.g. `think` only in the Mentor chat while a
  /// reply is being generated). `null` follows the controller.
  final PetAnimationState? stateOverride;

  /// Renders this species instead of the controller profile's — for previews
  /// of a species that isn't saved yet (onboarding species picker). Skips
  /// waiting for [MascotController.hasLoadedProfile].
  final PetSpecieEnum? specieOverride;

  /// Whether the `dog.riv`/`owl.riv` stopgap rigs (see [_kRigForSpecie]) may
  /// render here. Newer call sites that replace a static portrait pass
  /// `false`, so only real `Companion`-contract characters (today: wolf) swap
  /// in and dog/owl keep their original portrait art instead of the
  /// differently-drawn reference assets.
  final bool allowStopgapRigs;

  /// Whether the companion's interaction panel is currently open — mirrors
  /// the optional `interacting` state-machine input from the target
  /// `Companion` contract (`docs/RIVE_PET_COMPANION_BRIEF.md`). Only
  /// consumed by [_CompanionRig]; the `dog.riv`/`owl.riv` stopgap rigs have
  /// no such input, so it's accepted but unused for those two species.
  final bool interacting;

  @override
  State<PetRiveCompanion> createState() => _PetRiveCompanionState();
}

class _PetRiveCompanionState extends State<PetRiveCompanion> {
  // Asset paths that have already failed to load once — checked again on
  // every rebuild otherwise, since a StatefulWidget doesn't cache across
  // instances (header + interaction sheet each mount their own). Process-
  // lifetime only; there's no cache-invalidation need since app assets don't
  // change without a fresh install.
  static final Set<String> _knownMissing = {};

  RiveFile? _riveFile;
  _RiveCompanionRig _rig = const _CompanionRig();
  StateMachineController? _smController;

  // _CompanionRig inputs.
  SMINumber? _stateInput;
  SMIBool? _reducedMotionInput;
  SMIBool? _interactingInput;

  // _TriggerRig state.
  final Map<PetAnimationState, SMITrigger> _triggers = {};

  /// The animation state last synced to a [_TriggerRig], so state *changes*
  /// — not every rebuild — fire a trigger. Triggers are edge events in Rive
  /// (unlike [_CompanionRig]'s persistent `state` number input), so firing
  /// on every rebuild would spam the rig with redundant pulses.
  PetAnimationState? _lastSyncedState;

  /// Species key the current/last [_load] was for. Compared in
  /// [didUpdateWidget] instead of `oldWidget.controller.profile` — the old
  /// and new widgets usually share the *same* controller, whose profile is
  /// already the new one by then, so that comparison could never see a change.
  String? _loadedKey;

  String get _specieKey {
    final specie = (widget.specieOverride ?? widget.controller.profile.specie).name;
    return specie.trim().isEmpty ? 'dog' : specie.trim().toLowerCase();
  }

  PetAnimationState get _animationState => widget.stateOverride ?? widget.controller.profile.animationState;

  bool get _canLoad => widget.specieOverride != null || widget.controller.hasLoadedProfile;

  String get _riveAssetPath => 'assets/rive/pet/$_specieKey.riv';

  @override
  void initState() {
    super.initState();
    if (_canLoad) {
      _load();
    } else {
      // The controller's `profile.specie` is just the constructor's
      // placeholder (DOG) until its first `loadProfile()` resolves —
      // loading now would race a real species reveal with the placeholder
      // one. Wait for the real profile instead of guessing.
      widget.controller.addListener(_onProfileMaybeLoaded);
    }
  }

  void _onProfileMaybeLoaded() {
    if (!_canLoad) return;
    widget.controller.removeListener(_onProfileMaybeLoaded);
    _load();
  }

  @override
  void didUpdateWidget(covariant PetRiveCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((_loadedKey != null && _loadedKey != _specieKey) || oldWidget.allowStopgapRigs != widget.allowStopgapRigs) {
      _smController?.dispose();
      _smController = null;
      _riveFile = null;
      _lastSyncedState = null;
      if (_canLoad) _load();
    }
  }

  Future<void> _load() async {
    final path = _riveAssetPath;
    _loadedKey = _specieKey;
    if (_knownMissing.contains(path)) return;
    final rig = _rigFor(_specieKey);
    if (!widget.allowStopgapRigs && rig is! _CompanionRig) {
      // Stopgap rig not wanted here — keep the fallback. Deliberately *not*
      // added to `_knownMissing`: the file exists, and other call sites that
      // allow stopgaps share that cache.
      return;
    }
    try {
      final file = await RiveFile.asset(path);
      if (rig is _PoseSwapRig && !_posesExistIn(file, rig)) {
        // The file loaded but doesn't have every artboard/state-machine
        // combination this rig expects — `RiveAnimation` throws a hard
        // `FormatException` for an unknown artboard name (unlike a missing
        // state-machine name, which just no-ops), so this has to be
        // verified before ever handing the file to it.
        _knownMissing.add(path);
        return;
      }
      // The species may have changed while the asset was loading (e.g. the
      // user tapping through the onboarding species picker) — drop a stale
      // result instead of showing the previous species.
      if (mounted && path == _riveAssetPath) {
        setState(() {
          _riveFile = file;
          _rig = rig;
        });
      }
    } catch (_) {
      // No `.riv` at this path yet (or it failed to parse) — stay on the
      // PetMascotWidget fallback. Deliberately not rethrown: a missing
      // companion asset must never be a fatal error for the screen hosting
      // it (see the accelerometer fix this session for why unawaited
      // platform failures are dangerous here).
      _knownMissing.add(path);
    }
  }

  bool _posesExistIn(RiveFile file, _PoseSwapRig rig) {
    for (final state in PetAnimationState.values) {
      final artboard = file.artboardByName(rig.artboardForState(state));
      if (artboard == null) return false;
      if (artboard.stateMachines.every((sm) => sm.name != rig.stateMachineName)) {
        return false;
      }
    }
    return true;
  }

  void _markMissingAndFallBack() {
    _knownMissing.add(_riveAssetPath);
    if (mounted) setState(() => _riveFile = null);
  }

  void _onRiveInit(Artboard artboard) {
    final rig = _rig;
    switch (rig) {
      case _CompanionRig():
        final controller = StateMachineController.fromArtboard(artboard, rig.stateMachineName);
        if (controller == null) {
          // The file loaded but doesn't expose the expected state machine
          // name — treat it the same as a missing asset rather than
          // showing a static first frame with no reactions.
          _markMissingAndFallBack();
          return;
        }
        artboard.addController(controller);
        _smController = controller;
        _stateInput = controller.findInput<double>('state') as SMINumber?;
        _reducedMotionInput = controller.findInput<bool>('reducedMotion') as SMIBool?;
        _interactingInput = controller.findInput<bool>('interacting') as SMIBool?;
        // Prime the inputs now: `_syncInputs` already ran for this build
        // before the artboard existed, and the next rebuild may be a while
        // away (e.g. a pet resting in `sleep`, or the Mentor's `think`
        // override), which would otherwise show `idle` until then.
        _syncInputs(context);
      case _TriggerRig(:final triggerForState):
        final controller = StateMachineController.fromArtboard(artboard, rig.stateMachineName);
        if (controller == null) {
          _markMissingAndFallBack();
          return;
        }
        artboard.addController(controller);
        _smController = controller;
        _triggers.clear();
        for (final state in PetAnimationState.values) {
          final triggerName = triggerForState(state);
          if (triggerName == null) continue;
          final trigger = controller.getTriggerInput(triggerName);
          if (trigger != null) _triggers[state] = trigger;
        }
        // Reflect whatever state the mascot is already in (e.g. resting
        // asleep after a few inactive days) rather than always opening on
        // the rig's built-in idle pose. `_syncInputs` already ran once by
        // the time this fires (`onInit` resolves after the first build,
        // once the artboard is actually mounted) and found `_triggers`
        // empty, so it has to be primed here directly rather than by
        // relying on the next rebuild.
        final state = _animationState;
        _lastSyncedState = state;
        _triggers[state]?.fire();
      case _PoseSwapRig():
        // Nothing to configure — each pose artboard autoplays on its own
        // once mounted; `build()` picks which artboard via `artboard:`, and
        // `RiveAnimation` re-initializes (calling this again) whenever that
        // changes.
        break;
    }
  }

  void _syncInputs(BuildContext context) {
    final rig = _rig;
    switch (rig) {
      case _CompanionRig():
        _stateInput?.value = _animationState.index.toDouble();
        _reducedMotionInput?.value = MediaQuery.of(context).disableAnimations;
        _interactingInput?.value = widget.interacting;
      case _TriggerRig():
        final state = _animationState;
        if (state == _lastSyncedState) return;
        _lastSyncedState = state;
        // Accessibility stand-in for [_CompanionRig]'s `reducedMotion`
        // input, which this rig doesn't expose: skip firing motion
        // triggers entirely rather than play them anyway.
        if (MediaQuery.of(context).disableAnimations) return;
        _triggers[state]?.fire();
      case _PoseSwapRig():
        break; // Handled directly in build() via `artboard:`.
    }
  }

  /// Mirrors [PetMascotWidget]'s own tap-to-pet reaction, so switching a
  /// species over to Rive doesn't change what tapping the companion does in
  /// contexts that still want that behavior (`interactive: true`) — today
  /// that's neither of the two real call sites, both of which pass `false`
  /// and own their own tap handling instead.
  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.controller.triggerEventAnimation(PetAnimationState.happy, duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onProfileMaybeLoaded);
    _smController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = _riveFile;
    if (file == null) {
      final fallback = widget.fallbackBuilder;
      if (fallback != null) return fallback(context);
      return PetMascotWidget(controller: widget.controller, size: widget.size, interactive: widget.interactive);
    }
    final rig = _rig;

    final content = ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        _syncInputs(context);
        if (rig is _PoseSwapRig) {
          return RiveAnimation.direct(
            file,
            artboard: rig.artboardForState(_animationState),
            stateMachines: [rig.stateMachineName],
            fit: widget.fit,
            alignment: widget.alignment,
          );
        }
        return RiveAnimation.direct(
          file,
          stateMachines: [rig.stateMachineName],
          fit: widget.fit,
          alignment: widget.alignment,
          onInit: _onRiveInit,
        );
      },
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: widget.interactive ? GestureDetector(onTap: _handleTap, child: content) : content,
    );
  }
}
