---
name: pet-rive-rig
description: Create or refine an animated pet in the Rive Editor from existing character images, including layer decomposition, transparent asset preparation, precise assembly, pivots, timelines, state machines, export, and visual QA. Use for raster pet rigs and companion animation sets; do not use for unrelated Rive UI graphics or when the request is only runtime integration code.
---

# Pet Rive rig

Build a reusable animated pet from existing artwork while preserving its visual identity and the host product's runtime contract.

## Start by classifying the work

- **New rig:** begin with the source-image audit and layer plan.
- **Existing Rive file:** inventory every artboard, asset, timeline, state machine, and runtime-facing name before changing anything. Preserve existing work unless the user explicitly authorizes replacement.
- **Animation-only request:** do not modify application code, exported `.riv` files, or source artwork unless those changes are required and authorized.
- **Runtime integration:** inspect the consuming code before naming artboards, state machines, inputs, view-model properties, or animations. Treat those names as an API.

## Required workflow

1. Inspect the source artwork at full resolution and identify the pose, baseline, silhouette, lighting, perspective, and occlusions.
2. Write a layer plan before cutting anything. Read [asset-pipeline.md](references/asset-pipeline.md).
3. Prepare transparent layers cut from the assembled reference. Generate only the hidden geometry or alternate poses that the source cannot provide.
4. Create the Rive file and assemble the neutral pose in Design mode with measured positions, uniform scale, deliberate draw order, and anatomical pivots. Read [rive-editor-workflow.md](references/rive-editor-workflow.md).
5. Verify the neutral assembly against the reference before adding animation.
6. Create timelines from the smallest meaningful property set. Read [animation-recipes.md](references/animation-recipes.md) for the established pet motion language.
7. Build or update the state machine only after checking the host application's contract. For Petrimonium, read [petrimonium-contract.md](references/petrimonium-contract.md).
8. Inspect frame 0, every expressive peak, and the final frame; then preview the complete timeline and state-machine transitions.
9. Export or copy the `.riv` only when requested. Keep source layers and a layer manifest alongside the editable source when the project stores them.

When controlling the web editor through browser automation, read [rive-ui-automation.md](references/rive-ui-automation.md) before touching the file.

## Invariants learned from real failures

- Cut parts from the assembled reference. A regenerated sprite sheet loses exact placement and usually changes shape, shading, or perspective.
- Never repair assembly with non-uniform scale. Keep Scale X and Scale Y equal unless deformation is an intentional animation effect.
- Position parts numerically when exact placement data exists. Dragging is for exploration, not final assembly.
- Put pivots at anatomical joints before animating. Rotating an ear, tail, or head around the image center makes it detach or orbit.
- Key the neutral value at frame 0 and again at the end of every one-shot or loop for each animated property. A lone key can alter the entire timeline.
- A sleeping pet must visibly lie down. Closing eyes on the sitting rig is only a blink or a transition into sleep.
- When switching between full-pose raster images, avoid a long crossfade. Two complete pets visible together create ghosting; use a short opacity handoff or a clean cut.
- During a jump, move the pet but keep the ground shadow on the floor. Shrink and lighten the shadow near the apex, then restore it.
- Preserve readable differences between reactions: `happy` is a small acknowledgement, `celebrate` is a real jump, `think` is asymmetric and held, `attention` is an ear/head reaction, and `encourage` is a gentle nod.
- Do not leave anonymous timelines when renaming works. If the CanvasKit UI blocks renaming, keep a temporary mapping in the handoff and continue without deleting or recreating good work.

## Definition of done

- Neutral pose matches the reference without drift, seams, duplicated parts, or distorted scale.
- All moving parts rotate from plausible joints and remain attached throughout playback.
- Every loop closes without a visible snap; every one-shot returns or intentionally lands in its documented destination pose.
- No unintended asset remains visible, especially alternate full-body poses and open-mouth/closed-eye overlays.
- Timeline names, loop modes, duration, state-machine wiring, and runtime-facing identifiers are documented and verified.
- Reduced-motion behavior is still or near-still when the product contract requires it.
- The editor is left in a reviewable state and the handoff lists what changed, temporary timeline mappings, and anything requiring manual follow-up.
