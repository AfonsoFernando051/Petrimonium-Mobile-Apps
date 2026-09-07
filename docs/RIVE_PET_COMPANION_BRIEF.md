# Optional Rive Pet companion — authoring brief

## Status and boundary

Academy and Wallet can render a Pet through Rive when a compatible species
asset is bundled. Rive is an optional presentation adapter, not an ecosystem
architecture dependency. Missing, incompatible or incomplete assets must fall
back to the app's Lottie/PNG presenter without breaking the host screen.

Health does not currently use this adapter. Do not make Health or a shared
package depend on Rive merely to standardize the renderer.

## File locations

One optional file per species, lowercase:

```text
apps/academy/assets/rive/pet/{species}.riv
apps/wallet/assets/rive/pet/{species}.riv
```

Current species keys are `dog`, `cat`, `wolf`, `fox`, `bear`, `lion` and
`owl`. Verify the current enum and asset lookup before adding a new species.
The same binary is currently duplicated per consuming app so releases remain
self-contained.

## Runtime compatibility

Academy and Wallet currently pin `rive: ^0.13.20`, the pre-`rive_native`
runtime. A file exported with newer editor features may fail to parse. Test the
actual export with both consuming apps before considering it complete. A safe
fallback is required even after validation.

Changing the runtime version is a dependency/toolchain migration, not part of
asset authoring. Evaluate it separately across both apps.

## Default state-machine contract

A contract-compliant artboard exposes a state machine named `Companion`
(case-sensitive) with these inputs:

| Input | Type | Meaning |
| --- | --- | --- |
| `state` | Number | Persistent index of the semantic animation state below |
| `reducedMotion` | Boolean | Use restrained/static transitions and a stable resting frame |
| `interacting` | Boolean | Optional attention cue while the interaction surface is open |

`state` is level-driven, not a one-shot trigger. Every branch needs a stable
loop or resting pose when held for an extended period.

| Index | State | Presentation meaning |
| --- | --- | --- |
| 0 | `idle` | Default resting loop |
| 1 | `celebrate` | Learning or approved-practice acknowledgement; never a financial outcome |
| 2 | `think` | Attentive reflection or calculation |
| 3 | `sleep` | Calm rest after inactivity/night-time presentation |
| 4 | `victory` | Rare learning/progression milestone |
| 5 | `happy` | Short response to direct user interaction |

The order mirrors `PetAnimationState`; verify the enum in both apps before
exporting because changing enum order changes the numeric contract.

## Current stopgaps

`dog.riv` and `owl.riv` are bundled in Academy and Wallet but do not implement
the default contract:

- `dog.riv` uses the `Pet State Machine` state machine and one-shot triggers;
- `owl.riv` is an expression pack with separate artboards per pose.

Each app's `pet_rive_companion.dart` contains local adapters for these files.
A future contract-compliant replacement should use `Companion`; then remove
only the corresponding stopgap adapter after both apps are verified.

## Character and canvas guidance

- Keep a single centered character that reads at small avatar and larger panel
  sizes.
- Make the six states visually distinct without depending on tiny details.
- Keep important expressions inside safe bounds for `BoxFit.contain`.
- Use minimal motion for `reducedMotion`; do not freeze on a transition frame.
- Do not bake localized dialogue into the file. Flutter owns text, semantics,
  layout and screen-reader announcements.

## Verification

1. Add the asset to one app at a time and confirm it is declared by that app's
   `pubspec.yaml`.
2. Run the app and verify the Rive renderer appears instead of the fallback.
3. Exercise all six states, reduced motion and interaction mode.
4. Verify failure/fallback by testing an absent or invalid asset.
5. Check both small-header and large-interaction sizes.
6. Repeat in the other consuming app; do not assume identical adapter code.
