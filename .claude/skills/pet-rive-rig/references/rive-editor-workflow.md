# Rive Editor workflow

Use this reference to create or repair the Rive file after the transparent assets are ready.

## 1. Create the file and artboard

Before creating anything, inspect the consuming application for required artboard dimensions, fit behavior, artboard name, state-machine name, and runtime API. If there is no contract, use an artboard that preserves the source aspect ratio; `500 x 650` is a practical portrait starting point for a seated companion.

Set the artboard origin, dimensions, and baseline before animation. Changing them later shifts every measured placement.

## 2. Work in Design mode for assembly

Import PNG assets by dragging them into the editor or through the asset panel. Keep runtime assets embedded unless the host product explicitly supports referenced assets.

Create and change art assets in Design mode. Editing graphics while a timeline is selected may create accidental keys.

## 3. Assemble the neutral pose

1. Add every neutral-pose layer to the active artboard.
2. Rename the hierarchy immediately using stable snake-case names.
3. Reproduce the planned draw order. In a standard Rive hierarchy, visually frontmost items belong above items behind them; verify this with an obvious face-over-head check rather than trusting a remembered convention.
4. Apply one uniform reference-to-artboard scale to all layers.
5. Enter measured X/Y values. Do not independently nudge each layer until it merely “looks close.”
6. Compare the assembly at 100% zoom with the source reference.

If using full-canvas layers, identical origin, position, and scale should align them. If using tight crops, compute position from each recorded reference rectangle and the single global scale.

## 4. Establish transform spaces and pivots

Use parent groups or bones for parts that rotate. Place their transform origin at the real joint:

- head: neck connection near the lower center of the head;
- ear: root where the ear meets the skull;
- tail: base where it leaves the haunch;
- medallion: top attachment point;
- limbs: shoulder/hip for swinging, paw for planted-foot corrections.

Parent all facial layers to the head transform so a head tilt cannot leave the eyes or mouth behind. Parent the collar according to the artwork: to the torso if it should stay planted, or to a neck group if it follows the head partially.

Use meshes only for intentional soft deformation such as breathing, ear flex, or squash. Do not use mesh deformation to repair incorrect assembly.

## 5. Create a neutral baseline

Before expressive timelines, make a short neutral/idle test:

- all alternate-pose assets opacity `0%`;
- neutral parts in their exact assembled transforms;
- overlays such as `mouth_open`, closed lids, and blush opacity `0%`;
- shadow at its normal position, scale, and opacity.

This is the reference pose every one-shot should return to and every state transition should understand.

## 6. Create timelines deliberately

- Name a timeline before authoring it.
- Set FPS, duration, and loop mode before adding keys.
- Key only the properties the animation owns.
- Add explicit start and end keys for every owned property.
- Use cubic easing for organic movement, hold for visibility cuts, and linear only when constant motion is intentional.
- Preview at the actual product size, not only zoomed in.

For full-pose image visibility, key both outgoing and incoming opacity. Never assume an unkeyed image will reset after another animation.

## 7. State-machine design

Treat the state machine as runtime API design:

1. Confirm the current host contract.
2. Add each timeline as a state.
3. Set idle or the required neutral state as Entry.
4. Use exit time for one-shots that must finish before returning.
5. Allow urgent overrides such as reduced motion or sleep to interrupt when required.
6. Test every transition in both directions.

Rive recommends Data Binding for new projects, but existing runtime code may still depend on legacy state-machine inputs. Do not migrate the file independently from its consumer.

Keep optional animations such as `attention`, `encourage`, `talk`, `wake_up`, or `blink` as standalone timelines until the product contract exposes a way to select them.

## 8. Export and handoff

Export the runtime `.riv` only when requested. Before copying it into an app:

- verify artboard and state-machine names;
- verify embedded asset settings;
- play every timeline from beginning to end;
- test loops over at least two repetitions;
- inspect state-machine input or data-binding values;
- verify reduced motion;
- run the actual application at representative sizes.

Do not publish to the Marketplace, overwrite production assets, or delete earlier animations without explicit authorization.

## Visual QA gates

- Frame 0 matches the intended source state.
- Expressive peaks read clearly at approximately 220 px tall.
- Final frame matches the next expected state.
- No full-pose ghosting or duplicate face appears.
- Limbs, ears, tail, and head remain attached at their joints.
- Feet remain planted unless the action is a jump.
- Shadow behavior agrees with contact and height.
- Blink and mouth overlays fully disappear when inactive.
- Loop seam has no position, rotation, scale, or opacity snap.
