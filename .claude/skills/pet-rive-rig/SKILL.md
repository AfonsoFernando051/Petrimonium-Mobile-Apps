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

> **Do not trust `rive-cli render` for raster rigs.** Its preview rasteriser
> renders image layers as faceted garbage while the file itself is correct — the
> embedded PNGs come back byte-identical to their sources. Verify with
> `--composite` (step 5) and the real Flutter runtime, never with the preview.

### 5. Verify

```bash
python3 .claude/skills/pet-rive-rig/scripts/verify_assembly.py \
  --specie cat --composite --overlay diff.png
```

Gates: silhouette IoU >= 0.95, centroid drift <= 2px, **colour error <= 12**.
The colour gate is not optional — silhouette alone passes a render whose outline
is right and whose interior is destroyed. Read the overlay's diff panel: red is
reference-only and is how a missing part announces itself.

Then load the `.riv` in the app and see it. `flutter test` cannot do this:
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
