# Safe browser automation in the Rive Editor

Use this reference when an agent controls the web editor through computer-use tooling.

## Operating discipline

- Attach to the exact Rive tab the user selected. Do not create a competing copy when the intended cloud file is already open.
- Take a screenshot before each logical edit batch and verify the active animation, playhead, selected hierarchy item, and Inspector object name.
- Keep batches small: one property or one expressive beat, then inspect the result.
- CanvasKit accessibility is partial. Treat visible state and the Inspector as the source of truth.
- Scroll the Hierarchy and Timeline independently; their rows move. Never reuse a coordinate after scrolling without taking a new screenshot.
- After clicking a row, verify the Inspector names the intended object before sending arrow keys.

## Reliable keyboard workflow

These shortcuts were reliable in the Rive web editor during hands-on authoring:

| Action | Shortcut |
|---|---|
| Move playhead 1 frame | `Period` / `Comma` |
| Move playhead 10 frames | `Shift+Period` / `Shift+Comma` |
| Next/previous selected key | `Control+Period` / `Control+Comma` |
| Reveal selected layer's keyed properties | `U` |
| Switch Design/Animate mode | `Tab` |

For a numeric Inspector field:

1. Click the displayed number, not its property label or key diamond.
2. Use `ARROWUP` or `ARROWDOWN` once per integer step.
3. Press `ENTER` to commit.
4. Re-read the value in a screenshot.

Automation APIs may distinguish uppercase key names. If `ArrowUp` produces no change, use `ARROWUP`.

## Creating safe keys

- At frame 0, click the key diamond for every property the animation will own.
- Navigate from a hierarchy or timeline row, not while a numeric field remains focused.
- At the final frame, restore and key the documented destination value.
- To edit an existing motion, select its timeline channel and use next/previous-key shortcuts rather than guessing frame positions.

The most dangerous failure is creating the first key only at an expressive frame. Rive may then hold that value before or after the key, shifting the starting pose. Always inspect frame 0 after introducing a previously unanimated property.

## Renaming limitations

Text entry in CanvasKit-rendered lists can fail even when clicking and numeric edits work. Try the normal rename interaction once. If it remains inaccessible:

- do not delete and recreate a valid animation merely to obtain a name;
- keep the automatic `Timeline N` name;
- record a temporary mapping such as `Timeline 7 = attention` in the handoff;
- leave manual renaming as an explicit follow-up.

## Visibility and pose swaps

When editing opacity handoffs, inspect each boundary directly. For example, verify frames 39, 40, 41 when the handoff occurs at frame 40. A screenshot at only the peak or endpoint will not reveal one-frame ghosting.

## Recovery from a wrong click

1. Stop sending keys.
2. Inspect the current playhead, selected object, and Inspector value.
3. Determine whether a property changed or only focus changed.
4. Restore the specific value if necessary.
5. Re-verify frame 0, the edited frame, and the final frame.

Do not use broad undo chains without knowing what they will revert, especially in a shared cloud file.

## Handoff

Leave playback paused on a representative frame, keep the edited timeline selected, and mark the browser tab for handoff when the tool supports it. Report:

- exact animation names or temporary mappings;
- properties and frames changed;
- whether playback and endpoints were verified;
- any rename, export, publish, or runtime step intentionally left undone.
