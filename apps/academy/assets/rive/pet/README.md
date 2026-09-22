# Pet companion Rive assets

Drop a species' `.riv` file here as `{specie}.riv` (lowercase — `dog.riv`, `cat.riv`, `wolf.riv`,
`fox.riv`, `bear.riv`, `lion.riv`, `owl.riv`), matching `PetSpecieEnum`/`PetAssets.imageFor`'s
existing naming convention.

The target design and technical contract each file should satisfy — character structure, a
`Companion` state machine, its three inputs (`state`, `reducedMotion`, `interacting`) and their
exact meaning — is specified in `docs/RIVE_PET_COMPANION_BRIEF.md`, not here.

## `wolf.riv` — contract-compliant (`Companion`)

First species built directly against the target contract, so it needs no adapter — `wolf` is not in
`_kRigForSpecie` and uses `_CompanionRig` as-is:

- Artboard `Wolf` (500×686), default state machine **`Companion`**.
- `state` (number) = `PetAnimationState.index`: 0 idle, 1 celebrate, 2 think, 3 sleep, 4 victory, 5 happy.
- `reducedMotion` (bool) → an equivalent static pose per state, switched instantly.
- `interacting` (bool) → a gentle medallion pulse while the interaction sheet is open.

Generated reproducibly from `assets/images/generated_wolf.png` by `tools/rive_pet/` (see its README,
including how it is verified against the official Rive runtime).

Verified in the app itself (not only in the generator's C++ harness) on 2026-09-22, with the pinned
`rive 0.13.x`: the file loads, `mainArtboard` is `Wolf` 500×686, `Companion` exposes exactly
`state`/`reducedMotion`/`interacting`, and each `PetAnimationState` renders a visibly distinct pose
— including `sleep` right at mount, which is what the `onInit` input priming in `PetRiveCompanion`
exists for.

**Do not try to assert any of that in a widget test.** `flutter_tester` cannot parse a `.riv` at all
on this toolchain — `RiveFile.asset` dies inside `rive_common`'s text-engine FFI init
(`Failed to lookup symbol 'init'`), before any of this project's code runs. That is why
`pet_rive_companion_test.dart` only ever exercises the fallback path, and why anything that needs
real parsing is checked by running the app on a real device (`flutter run -d linux`).

## Where the Rive pet renders (Academy)

Every surface that shows the pet goes through `PetRiveCompanion`, in two groups split by whose pet
is on screen.

**The player's pet**, driven by the shared `MascotController`:

| Surface | Notes |
|---|---|
| Companion header + interaction sheet | `interacting` drives the medallion pulse |
| Home hero (`LearningHeroCard`) | tap-to-pet plays `happy` from rest; Flutter breathe only on the portrait fallback |
| Home Mentor card, lesson complete card, choice-question feedback | follow the controller as-is |
| Journey stage tile (`JourneyStageTile`) | follows the controller as-is |
| Mentor tab stage (`MentorPetStage`) | `think` while a reply is generated, screen-local via `stateOverride` so it never leaks into the surfaces above. No rig has a *talking* pose, so talking keeps the character at rest and the stage's pulsing ring and bob carry it |

**The brand's pet**, on screens that run before a pet exists to load — splash, login, onboarding.
These go through `BrandPetMascot`, which fixes the species instead of reading a profile (there is
no signed-in player yet) and owns a `MascotController` it deliberately never loads:

| Surface | Notes |
|---|---|
| Splash, login card, onboarding welcome | the brand mascot (`PetAssets.defaultSpecie` — the wolf) |
| Academy intro avatar | head crop (`BoxFit.cover` + `topCenter`) in a 36px circle |
| Onboarding "name your pet" (`PetConfigurationScreen`) | `specieOverride` = the species being named, so it still tracks the picker if `_kSpeciesPickerVisible` is ever flipped back on |

Every one of these passes `allowStopgapRigs: false` plus a `fallbackBuilder` with the species'
original portrait, so only real `Companion`-contract characters swap in and dog/owl keep their
portrait art rather than the differently-drawn reference assets.

Deliberately still static: the level-up / module-completion **share cards** (rasterized to a PNG
for sharing — see `LevelUpShareCard`) and the species-picker grid tiles.

## `dog.riv` and `owl.riv` — stopgaps, not yet contract-compliant

These two are reference assets copied in as-is rather than real
`Companion`-contract files — see `_RiveCompanionRig` in
`lib/features/pet/presentation/companion/rive/pet_rive_companion.dart` for the full adapter that
wires each one around the target contract. Every species other than dog, owl and wolf still has no
`.riv` and renders the `PetMascotWidget` (Lottie/PNG) fallback.

**`dog.riv`** (copied verbatim from a `pet_cachorro_state_machine.riv` reference asset, kept only in git history):

- Artboard "Pet Cachorro", state machine **"Pet State Machine"** (not `Companion`).
- Five one-shot **trigger** inputs (`Happy`, `Blink`, `Tail Wag`, `Sit`, `Excited`) instead of the
  target's persistent `state` number input — no `reducedMotion`/`interacting` inputs at all.
- No dedicated `sleep` pose; `PetAnimationState.sleep` borrows `Blink` as the closest stand-in.

**`owl.riv`** (the owl mascot expression-pack reference asset, verbatim) is structured completely
differently — no unified state machine or input at all:

- 21 independent artboards, each a self-contained expression (a static-ish pose plus its own tiny
  autoplaying idle loop) with no cross-artboard wiring or listeners — a marketplace "expression
  pack" meant for picking one pose per context, not a single interactive rig.
- Six of those artboards (named `1`, `5`, `10`, `11`, `13`, `14`) are mapped one-per-`PetAnimationState`
  in `_owlArtboardForState`; "switching pose" means mounting a different artboard (`RiveAnimation`'s
  `artboard:` parameter), not driving an input.
- No dedicated `sleep` pose either; artboard `13` (calm, one eye closed, mid-whistle) is the
  closest available stand-in, same reasoning as `dog.riv`'s `Blink`.

Replacing either with a real `Companion`-contract export (see the brief) needs no code changes
beyond deleting that species' entry from `_kRigForSpecie` — `PetRiveCompanion` was written against
the target contract first; the per-species stopgaps are the deviation.

## Wiring (already done for `dog.riv`/`owl.riv`; repeat per new species)

1. Add the file here as `{specie}.riv`. This directory is declared in `pubspec.yaml`'s
   `flutter: assets:` list.
2. Nothing else. `PetRiveCompanion` already tries to load `assets/rive/pet/{specie}.riv` for
   whichever species the current player's pet is, and falls back to `PetMascotWidget` whenever
   that file is missing, fails to parse, or doesn't expose the expected state machine.
