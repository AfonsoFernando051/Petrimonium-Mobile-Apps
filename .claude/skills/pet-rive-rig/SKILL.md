---
name: pet-rive-rig
description: Build an animated Rive companion for a Petrimonium pet species (dog, cat, wolf, fox, bear, lion, owl) — cutting the character into rig layers, assembling it on the artboard without drift, animating the six PetAnimationState poses, and shipping a `Companion`-contract .riv the Flutter apps load with no code change. Use when adding or replacing a pet's `.riv`, when an assembly comes out skewed or misaligned, or when authoring the idle/celebrate/think/sleep/victory/happy set.
---

# Pet companion Rive rig

Turns `generated_{specie}.png` into `assets/rive/pet/{specie}.riv` satisfying the
`Companion` contract, so `PetRiveCompanion` picks it up with no Dart change.

## The rule that decides everything

**Layers are cut out of the assembled reference, never generated on a sprite sheet.**

A part cut from the assembled render already carries its placement: its bounding
box in the reference *is* where it goes, at scale 1.0. Assembly becomes
transcription. Generate parts on a sheet instead and that information is gone for
good — the sheet's parts are *redrawn*, not copied, so no template matching can
recover it. That was measured, not assumed: fitting `dog_rig_v1`'s sheet against
its reference finds no photometric optimum except on the muzzle, and every other
part collapses to whatever scale the cost function happens to favour. The result
is the familiar "close, but everything is slightly crooked".

Corollaries, all non-negotiable:

- Every position is **calculated and typed** into the inspector. Nothing is dragged.
- `Scale X` always equals `Scale Y`. Non-uniform scale doesn't reposition, it
  **deforms** — it is the single most common cause of a skewed rig.
- Rotation stays `0` unless the art is genuinely rotated. Rotation used to
  compensate a bad translation just hides the error.
- Mesh deform is for animation, never for making a part "fit".

## Pipeline

### 1. Rig folder

```
apps/{app}/assets/images/
  generated_{specie}.png          # the assembled reference
  pet/{specie}_rig_v1/
    rig_manifest.json             # artboard, draw order, pivots
    mask_shapes.json              # you author this
    masks/  layers/               # generated
```

**Check the reference actually contains every part you plan to rig.** This is the
first thing to get wrong: `dog_rig_v1`'s atlas depicts a full sitting dog while
`generated_dog.png` is a cropped 3/4 pose with no rear haunch and no ground
shadow. Parts that are not in the reference cannot be cut from it and have no
placement to measure — either drop them or produce a reference that shows them.

### 2. Author the masks

Describe each part as ellipses/polygons in `mask_shapes.json` rather than
painting PNGs — it stays diffable, and iterating means moving a vertex and
re-running. Shapes **may and should overlap**: give each part its *full* extent
including what is hidden behind parts in front of it.

```bash
python3 .claude/skills/pet-rive-rig/scripts/draft_masks.py --specie cat
```

Colour gets you only the crisp features (eyes, nose, collar, glow marks — about
20% of the dog). The structural cuts sit inside one flat tone and are judgement,
not measurement. Expect to iterate against the overlay from step 5.

### 3. Extract

```bash
python3 .claude/skills/pet-rive-rig/scripts/extract_layers.py --specie cat
```

Writes `layers/*.png` and an **exact** `placements` block. The `hidden` column is
how much of each part was inpainted — high is normal for base layers (a torso
under everything), suspicious for a part that should be mostly visible.

### 3.5. Synthesize what the reference can't show (optional)

A single reference photo shows one expression. `sleep` needs closed eyes and the
three joy poses read better with a flushed cheek, and neither exists anywhere to
cut out. `synth_face_assets.py` draws them instead, sampling colour from the
rig's own layers so they land on-model rather than introducing a foreign
palette:

```bash
python3 .claude/skills/pet-rive-rig/scripts/synth_face_assets.py --specie cat --rig cat_rig_v1
```

Adds `eyelid_left/right` and `blush_left/right` as new layers, opaque overlays
sitting at opacity 0 until `companion_scene.py` raises them for the relevant
poses. Skip this for a species without comparable eyes, or extend the script's
per-part logic for a different face shape.

Check both cheeks after generating: a coat marking under one eye and not the
other (the dog's is exactly this asymmetric) can wash the flush out on just that
side even though the placement is geometrically symmetric. Re-render at the
pose's peak frame and zoom in -- tune `make_blush`'s tone/alpha before touching
position, since the placement is usually already correct.

### 4. Build the .riv

```bash
python3 .claude/skills/pet-rive-rig/scripts/build_scene.py --specie cat --out build/
rive-cli generate build/scene.json -o build/cat.riv
rive-cli validate build/cat.riv
```

`build_scene.py` emits layers, draw order, the six pose timelines and the
`Companion` state machine as JSON. Nothing is placed by hand, so nothing drifts.
`rive_values.py` is the fallback for assembling in the editor instead — same
numbers, typed rather than compiled.

> **Draw order is front-to-back.** Rive draws an artboard's children in the order
> they appear, frontmost first, so `build_scene.py` emits the reverse of the
> manifest's `drawOrderBackToFront`. Getting this backwards stacks the rig inside
> out — the head hides the face — and the result looks like a corrupted render
> rather than an ordering mistake. Silhouette and centroid both still pass; only
> the colour gate catches it.

### 5. Verify

```bash
python3 .claude/skills/pet-rive-rig/scripts/verify_assembly.py \
  --specie cat --composite --overlay diff.png
```

Gates: silhouette IoU >= 0.95, centroid drift <= 2px, **colour error <= 12**.
The colour gate is not optional — silhouette alone passes a render whose outline
is right and whose interior is destroyed. Read the overlay's diff panel: red is
reference-only and is how a missing part announces itself.

`rive-cli render` drives the real Rive runtime in headless Chromium, so rendering
the built file and checking it with `--export` is a genuine test, not a preview
approximation. Use `--frames 0,15,30,45 --contact-sheet` to confirm a timeline
actually moves.

It still is not the Flutter runtime. `flutter test` cannot stand in either:
`flutter_tester` on Linux lacks `rive_common`'s FFI symbols, and the Chrome
harness hangs in `RiveFile.initialize()`. Run the app.

### 6. Rig, animate, ship

`build_scene.py`'s pose timelines are placeholders that prove each state is
reachable and distinct. Real character animation is authored on bones, using the
manifest pivots as joint positions. `reducedMotion` must still the rig, not
merely slow it.

Export to `apps/academy/assets/rive/pet/{specie}.riv` **and** the same path under
`apps/wallet/`. No Dart change is needed — unless replacing the `dog`/`owl`
stopgaps, which also requires deleting that species' entry from `_kRigForSpecie`
in `pet_rive_companion.dart`.

## Done means

- `verify_assembly.py --composite` passes all three gates, overlay attached.
- The `.riv` validates and its embedded PNGs match the source layers.
- The app renders it instead of the `PetMascotWidget` fallback, `state` drives
  the poses, and `reducedMotion` stills it.
