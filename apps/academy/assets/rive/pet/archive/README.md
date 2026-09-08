# Archived Rive companion

`dogcompanion-v1-animated.riv` is the fully-animated dog rig built on
`feat/pet-rive-rig` (the `pet-rive-rig` skill + `dog_rig_v2`, cut from
`generated_dog.png` at silhouette IoU 0.9941) — 9 objects, six real pose
timelines driven by a `Companion` state machine (`state`, `reducedMotion`,
`interacting`), joints instead of image-centre pivots for the ears/tail.

**Nothing in the app loads this file.** Production moved to a pure-Flutter
animation engine (`PetAnimationEngine`, see
`lib/features/pet/presentation/mascot/animation/`) — see that decision's
commits on this branch. `PetRiveCompanion`, the widget that *can* play a
file like this, still exists in the codebase but nothing calls it anymore.

**Why this file sits in `archive/` and not `assets/rive/pet/` directly:**
`pubspec.yaml` declares `assets/rive/pet/` as a directory asset, which
Flutter bundles non-recursively — every file placed directly in that
folder ships in every install whether anything loads it or not.
`archive/` is one level down, so this ~360KB file stays in the repo for
whoever picks Rive back up without adding dead weight to the shipped app.

To use it: build it into the `Companion` state machine's asset path
(`assets/rive/pet/dog.riv`, currently the older `dog.riv` stopgap) and
wire `PetRiveCompanion` back into the call sites that were switched to
`PetMascotWidget` (see git log for which — search for "stop rendering the
pet companion through Rive" on this branch and `feat/pet-rive-rig`).
