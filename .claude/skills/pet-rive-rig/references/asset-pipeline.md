# Asset preparation and layer decomposition

Use this reference when starting from a flat PNG/JPG or when an existing rig lacks a required moving part or alternate pose.

## 1. Audit the source

Inspect the image at full resolution before editing. Record:

- image dimensions and transparent/content bounds;
- feet baseline and ground-shadow bounds;
- character centerline and facing direction;
- light direction, edge softness, texture, and outline weight;
- which parts are completely visible, partly occluded, or absent;
- whether the source pose can physically support the requested animation.

Do not promise articulation that the artwork cannot support. A sitting character cannot become convincingly prone by merely scaling its torso and closing its eyes.

## 2. Plan the layers

Split at joints and at expression boundaries. A typical quadruped companion needs:

| Group | Common layers | Why separate |
|---|---|---|
| Ground | `ground_shadow` | Must stay planted while the pet jumps. |
| Rear body | `rear_haunch`, `torso` | Supports breathing and body compression. |
| Limbs | `front_leg_left`, `front_leg_right` | Allows bounce, stretch, and planted-foot corrections. |
| Tail | `tail` | Needs a pivot at its base and independent wagging. |
| Neck | `collar`, `medallion` | Can lag behind head/body motion. |
| Head | `head` | Parent for facial features and ears. |
| Ears | `ear_left`, `ear_right` | Independent ear flicks and emotional asymmetry. |
| Face | `muzzle`, `eye_left`, `eye_right`, `eyebrow_left`, `eyebrow_right` | Blink, thought, concern, and gaze cues. |
| Overlays | `mouth_open`, closed-eye overlays, blush | Toggle through opacity without redrawing the base. |
| Alternate poses | `sleep_pose`, `wake_stretch_pose` | Whole-body topology genuinely changes. |

Use only layers the character needs. More pieces increase seam risk and authoring cost.

## 3. Cut from the assembled reference

The preferred source for every visible layer is the original assembled artwork.

1. Duplicate the reference for each planned part.
2. Create an alpha mask for the part at the original resolution.
3. Include the complete visible contour and a small hidden overlap at every seam.
4. Reconstruct only the hidden portion needed when the part moves away from its neighbor.
5. Remove unrelated pixels and color fringes.
6. Export lossless RGBA PNG.

Masks may overlap. Overlap is safer than a transparent crack when parts rotate.

### Canvas strategy

Choose one strategy and document it:

- **Full-canvas layers:** every PNG keeps the reference dimensions. Initial assembly is trivial because every layer shares the same center, but assets are larger and pivots require care.
- **Tight crops with placement manifest:** crop each alpha bound and record its reference rectangle. This is smaller and cleaner, but every initial position must be reconstructed from the manifest.

For tight crops, record at least:

```json
{
  "source": "pet_reference.png",
  "artboard": {"name": "Pet", "width": 500, "height": 650},
  "layersBackToFront": ["ground_shadow", "tail", "rear_haunch", "torso", "head", "muzzle"],
  "layers": {
    "tail": {
      "file": "tail.png",
      "referenceBox": [96, 312, 104, 188],
      "pivot": [0.78, 0.84]
    }
  }
}
```

`referenceBox` is `[left, top, width, height]`. Pivot values are normalized within the cropped layer.

## 4. Reconstruct hidden geometry conservatively

Paint or inpaint only what animation can reveal. Match neighboring color, texture, outline thickness, lighting, and perspective. Do not redesign the character.

Useful hidden extensions include:

- the base of a tail behind the torso;
- the top of a leg behind chest fur;
- the ear root behind the head;
- a small torso overlap behind the head or collar.

Reject a reconstruction if it looks correct only in the neutral pose but exposes a hard patch during motion.

## 5. Create missing expression assets

Generate new assets only when transforms cannot produce the expression:

- a real closed eyelid rather than vertically squashing an open eye;
- an open mouth for bark/talk beats;
- a cheek/blush overlay;
- a thought symbol or accessory;
- a genuinely different whole-body pose.

If an image-generation or image-editing tool is available, provide the original pet as reference and require:

- identical character identity, palette, rendering style, camera, and light;
- transparent background;
- no extra limbs, accessories, shadows, or duplicated anatomy;
- enough overlap at connection points;
- output at the source resolution or a documented uniform scale.

Inspect generated assets over the neutral reference at 100% opacity and as an animated handoff. A beautiful isolated layer can still be unusable if its perspective or edge treatment differs.

## 6. Whole-pose assets

Use a full-pose raster asset when the silhouette and joint topology change too much for the neutral rig, especially:

- prone sleep;
- wake stretch;
- curled or tucked poses;
- costume or prop poses that replace most of the body.

Keep the same artboard baseline, apparent character scale, camera, and light. Alternate-pose PNGs should not contain a second ground shadow unless the animation deliberately swaps shadows too.

## Asset QA

- Transparent background has no matte halo.
- Every seam has enough hidden overlap.
- No layer contains pixels belonging to a different moving part.
- All parts retain the same perspective and light.
- The neutral reassembly can reproduce the source silhouette.
- File names are stable, lowercase snake case, and match Rive layer names.
