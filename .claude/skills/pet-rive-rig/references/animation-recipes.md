# Pet animation recipes

These are starting patterns, not fixed choreography. Preserve the character's proportions, temperament, and the product's visual quietness. Values assume 60 fps and a small companion rendered near 220 px tall.

## Motion language

- Use single-digit pixel or degree changes for ordinary reactions.
- Lead with the body part that communicates intent: ear for attention, brows/head for thought, tail for joy, torso for breathing.
- Offset secondary motion by 2–6 frames so the pet feels organic.
- Build asymmetry into thought and curiosity; perfect mirrored motion looks mechanical.
- Keep interface companions calm enough that they support the content rather than compete with it.

## Timeline catalog

| Timeline | Mode | Typical duration | Product use |
|---|---|---:|---|
| `idle` | loop | 120f | Pet is present and available. |
| `blink` | one-shot or sparse idle layer | 12–20f | Natural eye moisture; never substitute for sleep. |
| `talk` | loop/controlled one-shot | 45–75f | Daily tip, explanation, or speech bubble. |
| `happy` | one-shot | 45–60f | Tap acknowledgement or small positive feedback. |
| `celebrate` | one-shot | 60–90f | Goal, milestone, reward, or success. |
| `think` | loop | 90–120f | Loading, evaluating, or preparing advice. |
| `sleep` | loop | 120–180f | Inactivity or app-entry starting state. |
| `wake_up` | one-shot | 90–150f | User enters and wakes the pet. |
| `attention` | one-shot/loop | 60–90f | Awaiting action or highlighting something. |
| `encourage` | one-shot | 60f | Retry, partial progress, or habit continuation. |
| `victory` | one-shot | 75–120f | Larger achievement than ordinary celebration. |

## Idle

- Torso breath: base at frame 0, `+0.5–1.0%` Scale Y near the midpoint, base at the end.
- Head drift: `1–2 px` or `1°` maximum.
- Tail: one slow small arc, not constant energetic wagging.
- Add a blink on a separate state-machine layer or at irregular intervals when the runtime design supports it.

## Talk / daily tip

- Use two or three short mouth openings rather than a uniform flap.
- Example mouth opacity beats: `0%` at 0/12, `100%` at 14–17, `0%` at 19, `100%` at 23–27, `0%` at 30/end.
- Tilt the head `1–3°` on the strongest syllable.
- Add a friendly tail wag with alternating extremes around a stable center.
- Close the loop with mouth hidden and head/tail at their baseline.

## Think

- Move into a `2–6°` head tilt over 20–35 frames and hold briefly.
- Raise one brow and lower or relax the other.
- Flick or raise only one ear.
- Keep the eyes open unless a separate contemplative blink is intended.
- Use slower easing than `happy` or `talk`.

## Happy

- Small body compression and release; feet remain grounded.
- Lift the head a few pixels and open the mouth briefly.
- Add one quick tail wag.
- A `2–3°` playful head tilt at the peak distinguishes it from a vertical bounce.

## Celebrate

- Frame 0: neutral grounded pose, normal shadow.
- Around frame 10–15: anticipation squash.
- Around frame 28–35: whole pet elevated; ears and tail trail the body.
- Apex shadow: keep Y fixed, reduce Scale X approximately `10–18%`, reduce opacity approximately `15–25%`.
- Final frame: exact neutral transforms and exact normal shadow values.
- Move all pet parts together, then explicitly counter-move the shadow if a multi-selection includes it.

## Sleep

- Use a visibly prone or curled full-body pose. A sitting pet with hidden eyes is not sleeping.
- Hold the sleep pose at `100%` and neutral rig at `0%` during the sleep loop.
- Add slow breathing: approximately `1%` Scale Y or `1–2 px` vertical drift at the midpoint of a 2–3 second loop.
- Keep eyes closed and limbs relaxed. Avoid tail wagging.

## Wake up

Use an intentional pose sequence:

1. Start in the exact sleep pose.
2. Transfer quickly to a stretch pose.
3. Hold the stretch long enough to read.
4. Transfer quickly to the neutral sitting rig.
5. Add a small settling motion after the final transfer.

For complete raster poses, prefer a short hold/cut or a handoff over roughly 4–10 frames. Long alpha crossfades show two complete bodies simultaneously and look like a ghost.

## Attention

- First beat: one ear flicks `4–7°`.
- Head follows with a `3–5°` tilt.
- Optional second tilt in the opposite direction at slightly lower amplitude.
- Return both ear and head to `0°` at the end.

## Encourage

- Use a gentle nod driven mostly by head Position Y.
- Example at 60f: baseline at 0, `+4–6 px` at 15, `-2–4 px` at 30, `+2–3 px` at 45, baseline at 60.
- Keep rotation and mouth restrained; it should feel reassuring, not celebratory.

## Alternate-pose opacity handoff

When `sleep_pose`, `wake_stretch_pose`, and the neutral rig share an artboard:

- explicitly key every participating image/group at every handoff;
- use `100/0` ownership, not two long partially visible ranges;
- inspect the frame immediately before, at, and immediately after each handoff;
- use hold interpolation when a clean pose cut looks better than a blend;
- confirm hidden pose assets remain `0%` in every unrelated timeline.

## Keyframe closure rule

For each animated property `P`:

```text
P(frame 0) = documented start value
P(expressive frames) = intentional changes
P(final frame) = documented destination value
```

For loops, the destination normally equals the start. For one-shots such as `wake_up`, the destination is the neutral awake pose. Never rely on an implicit value inherited from whichever animation happened to play previously.
