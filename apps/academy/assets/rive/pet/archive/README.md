# Archived Rive companion

`dogcompanion-v1-animated.riv` is the fully-animated dog rig built on
`feat/pet-rive-rig` (the `pet-rive-rig` skill + `dog_rig_v2`, cut from
`generated_dog.png` at silhouette IoU 0.9941) — 313 objects, six real pose
timelines driven by a `Companion` state machine (`state`, `reducedMotion`,
`interacting`), joints instead of image-centre pivots for the ears/tail.

`sleep` closes the eyes with real drawn eyelid art (`eyelid_left`/
`eyelid_right`, synthesized in `synth_face_assets.py` on `feat/pet-rive-rig`
to match this rig's own fur/line colour, added there in commit `58eb95e`)
layered opaquely over `eye_left`/`eye_right` rather than the earlier
scale-`y` squash, which read as the eye melting rather than closing. Every
other pose explicitly keys both lids to opacity 0 — a property Rive was
never told to touch keeps whatever the previous animation left it at, so
waking from sleep into any other pose would otherwise stay stuck
eyes-shut. Verified pixel-identical to the previous file on the other five
animations (0.000 mean error, 3 sampled frames each) — the eyelid change
touches nothing else.

A separately-discovered, pre-existing gap, not introduced by that change:
driving this file's `Companion` state machine via its `state` number input
externally (`rive-cli render --state-machine Companion --input state=3`)
does not actually transition into any non-idle pose — confirmed on both
the old and new file, so whatever's wrong lives in either the state
machine's transition graph or in how rive-cli evaluates number-input
conditions, not in this edit. Every render in this repo's history verified
poses by selecting the animation directly (`--animation sleep`), never by
driving the state machine end-to-end, so this was never caught before.
Matters only if this file is ever wired back into the app; harmless while
archived.

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
