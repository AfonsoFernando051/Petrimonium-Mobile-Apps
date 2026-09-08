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
