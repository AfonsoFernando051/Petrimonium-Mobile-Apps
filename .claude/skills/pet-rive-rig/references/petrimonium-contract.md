# Petrimonium companion contract

Read this reference only when the Rive pet is intended for the Petrimonium mobile workspace.

## Current source of truth

Inspect these files before shipping because code may evolve:

- `packages/petrimonium_shared_features/lib/src/pet/domain/pet_animation_state.dart`
- `apps/academy/lib/features/pet/presentation/companion/rive/pet_rive_companion.dart`
- `apps/wallet/lib/features/pet/presentation/companion/rive/pet_rive_companion.dart`
- `apps/academy/assets/rive/pet/README.md`
- `apps/wallet/assets/rive/pet/README.md`

Do not infer the runtime contract from timeline names visible in an experimental Rive cloud file.

## Contract-compliant rig

The regular Petrimonium rig expects one active artboard exposing a state machine named exactly `Companion` with legacy inputs:

| Input | Type | Meaning |
|---|---|---|
| `state` | number | Persistent `PetAnimationState.index`. |
| `reducedMotion` | bool | Still or near-still accessible presentation. |
| `interacting` | bool | Companion interaction panel is open. |

Although current Rive guidance favors Data Binding for new files, the application code still drives these inputs. Do not migrate the Rive file to Data Binding without an explicitly authorized, coordinated runtime change.

`state` numbering is fixed by the Dart enum declaration order:

| Value | State | Intended motion |
|---:|---|---|
| 0 | `idle` | Calm resting loop. |
| 1 | `celebrate` | Goal or milestone success. |
| 2 | `think` | Deliberating, loading, or preparing guidance. |
| 3 | `sleep` | Genuine lying-down sleep loop. |
| 4 | `victory` | Largest achievement reaction. |
| 5 | `happy` | Small positive acknowledgement. |

Do not insert new enum-like values between these numbers inside Rive. `talk`, `wake_up`, `attention`, `encourage`, and `blink` may exist as useful timelines, but the app cannot select them through `state` until the runtime contract is extended.

## Product contexts

| Timeline | Recommended context |
|---|---|
| `idle` | Header companion while no event is active. |
| `talk` | Daily tip or mentor speech bubble; requires separate runtime trigger/wiring. |
| `think` | Waiting for mentor reply or processing. |
| `sleep` | Inactivity and initial app-entry sleep state. |
| `wake_up` | Transition fired when the user enters and wakes the pet. |
| `happy` | Tap, acknowledgement, or lightweight positive feedback. |
| `celebrate` | Goal, streak, or task completion. |
| `victory` | Major challenge, level, or exceptional milestone. |
| `attention` | Highlighting a pending action or new tip. |
| `encourage` | Retry, partial progress, or habit continuation. |

If a requested context is not represented by the runtime API, finish and document the timeline but do not silently change Dart code. Ask for a separate integration task.

## Stopgap assets

At the time this skill was authored, `dog.riv` and `owl.riv` were handled by per-species adapters because they did not implement `Companion`. Replacing either with a compliant file requires reviewing and likely removing its stopgap entry from `_kRigForSpecie`; otherwise the app may continue driving the old contract.

## Asset placement

The runtime path is:

```text
apps/{academy,wallet}/assets/rive/pet/{species}.riv
```

The apps bundle their own copies. Copy or replace these assets only when the user requests runtime integration. A task limited to the cloud Rive Editor does not authorize modifying repository `.riv` files.

## Verification

- Confirm the file loads rather than silently falling back to `PetMascotWidget`.
- Confirm all six enum states are reachable and visually distinct.
- Confirm `reducedMotion` stops decorative movement.
- Confirm switching from sleep to an awake state does not leave the sleep pose visible.
- Confirm one-shot reactions return according to the state-machine design.
- Run the relevant Flutter tests and workspace verification only when repository integration files are changed.
