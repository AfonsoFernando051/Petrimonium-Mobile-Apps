# The `Companion` contract

What `PetRiveCompanion` expects of a species' `.riv`. Source of truth:
`apps/academy/lib/features/pet/presentation/companion/rive/pet_rive_companion.dart`
and `apps/academy/lib/features/pet/domain/enums/pet_animation_state.dart`.

## Asset path

`apps/{academy,wallet}/assets/rive/pet/{specie}.riv`, species key lowercase.
Valid keys come from `PetSpecieEnum`: `dog`, `cat`, `wolf`, `fox`, `bear`,
`lion`, `owl`. Both apps bundle their own copy; ship to both.

Loading is already wired. A missing, unparseable, or wrong-state-machine file is
not an error — the widget silently falls back to `PetMascotWidget`. So "nothing
changed in the app" almost always means the contract wasn't met, not that the
file is absent.

## State machine

Exactly one artboard exposing a state machine named **`Companion`**.

| Input | Type | Meaning |
|---|---|---|
| `state` | number | Which pose to hold. Persistent, not a trigger. |
| `reducedMotion` | bool | `MediaQuery.disableAnimations`. Must still the rig. |
| `interacting` | bool | The interaction panel is open. |

`state` is written as `PetAnimationState.index`, so the numbering is fixed by the
Dart enum's declaration order:

| `state` | Pose | Meaning |
|---|---|---|
| 0 | `idle` | Resting loop. |
| 1 | `celebrate` | Goal or milestone reached. |
| 2 | `think` | Deliberating / loading. |
| 3 | `sleep` | Inactive for days. |
| 4 | `victory` | Challenge won. |
| 5 | `happy` | Short reaction to a tap. |

### The manifest's `stateMachine.states` block is wrong

`dog_rig_v1/rig_manifest.json` records `{"0": "idle", "1": "blink", "2": "think",
"3": "celebrate"}`. That contradicts the enum on two counts: `blink` is not a
`PetAnimationState` at all, and `celebrate` is `1`, not `3`. It also stops at four
entries when six exist.

Do not copy that block into a new species. Use the table above. If you touch
`dog_rig_v1`, fix it there too.

## `reducedMotion`

Not a speed control. When true the rig holds a still or near-still pose. The
stopgap rigs approximate this by refusing to fire motion at all
(`_syncInputs`), which is the floor of acceptable behaviour, not the target.

## Pose coverage

All six states must be reachable. Both bundled stopgaps lack a real `sleep` pose
and borrow a stand-in — `dog.riv` reuses `Blink`, `owl.riv` mounts artboard `13`.
A contract-compliant rig does not get that latitude: author `sleep` properly.

## Retiring a stopgap

`dog` and `owl` are reference assets wrapped by per-species adapters in
`_kRigForSpecie`. Replacing either with a real `Companion` export requires
deleting that species' entry from that map — otherwise the adapter keeps driving
the old, now-absent state machine and the widget falls back. Every other species
already routes to `_CompanionRig` and needs no code change at all.
