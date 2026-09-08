# Dog rig v2

Bust-plus rig cut from `generated_dog.png` with the `pet-rive-rig` skill, replacing
`dog_rig_v1`'s sprite-sheet approach.

`dog_rig_v1` generated its parts on an atlas depicting a **full sitting dog**, while
the reference is a cropped 3/4 pose. The full-body parts (`rear_haunch`,
`ground_shadow`) exist nowhere in the reference, so they could never be placed by
measurement — which is why assemblies from v1 came out skewed. v2 rigs the 14 parts
the reference actually contains.

`mask_shapes.json` is a **first draft**: ellipses and polygons fitted by eye against
the reference. Colour separates only the crisp features; the cuts through flat tone
(head/torso/legs) are judgement and want a designer's pass. Edit a vertex, re-run
`draft_masks.py` → `extract_layers.py` → `verify_assembly.py --composite`, and read
the diff panel.

Current: silhouette IoU 0.9941, centroid drift 0.61px, colour error 0.27.

## Face overlays (eyelid, blush)

`eyelid_left/right.png` and `blush_left/right.png` are synthesized by
`synth_face_assets.py`, not cut from the reference -- it shows one open-eyed,
neutral expression, so there is no closed eye or flushed cheek to extract.
Colour is sampled from the rig's own fur and linework so they sit on-model.

Both are drawn as opaque overlays at opacity 0 by default; `companion_scene.py`
raises `eyelid_*` to 1 for `sleep` and `blush_*` for the three joy poses. This
replaced an earlier approach that squashed the eye's own `scale_y` to fake
closed eyes -- it reads as the eye melting, not closing, once seen next to a
drawn lid.

Their `placements` entries carry `"synthesized": true`, which
`verify_assembly.py --composite` uses to exclude them from the neutral-assembly
check -- they are invisible in the base rig by design, not missing from it.
