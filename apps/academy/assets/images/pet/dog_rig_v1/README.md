# Dog rig v1

Layered production source for the Academy dog companion.

- `dog_rig_atlas.png` is the generated transparent source atlas.
- `layers/` contains cleaned, tightly cropped PNG layers produced by
  `tools/pet_rig/split_dog_atlas.py`.
- `rig_manifest.json` records the intended draw order, normalized pivots and
  the Flutter-facing Rive state-machine contract.

The first animation pass targets `idle`, `blink`, `think` and `celebrate`.
Keep the state machine named `Companion`; the app contract uses the inputs
`state`, `reducedMotion` and `interacting`.
