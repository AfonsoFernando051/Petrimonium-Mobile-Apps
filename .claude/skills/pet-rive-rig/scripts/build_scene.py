#!/usr/bin/env python3
"""Emit a rive-cli scene from measured placements, plus the Companion contract.

The last hand step disappears here. rive_values.py exists for the case where a
human types numbers into the Rive inspector; this instead writes the whole
artboard -- layers, draw order, the six pose timelines and the state machine --
as JSON that `rive-cli generate` turns into a real .riv. Nothing is positioned by
hand, so nothing drifts.

rive-cli's `image` object carries no static scale field (scale is animatable
only), so layers are pre-scaled to artboard resolution on the way out and placed
at scale 1. Its origin is the image centre, which is why placement here is the
content box's centre rather than the manifest pivot -- pivots are joint
positions, and they belong to the bones added in the animation pass.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image

# state input value per pose -- fixed by PetAnimationState's declaration order in
# Dart. See references/companion-contract.md; do not renumber.
POSES = ["idle", "celebrate", "think", "sleep", "victory", "happy"]

FPS = 60
DURATION = 60

DEFAULT_FILL = 0.92
DEFAULT_BASELINE = 0.964


def content_box(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    left, top, right, bottom = bbox
    return (left, top, right - left, bottom - top)


def pose_animation(name: str, moves: dict[str, list[tuple[int, str, float]]]) -> dict:
    """One timeline. `moves` maps a layer to (frame, property, value) triples."""
    groups: dict[tuple[str, str], list] = {}
    for layer, triples in moves.items():
        for frame, prop, value in triples:
            groups.setdefault((layer, prop), []).append({"frame": frame, "value": value})
    return {
        "name": name,
        "fps": FPS,
        "duration": DURATION,
        "loop_type": "loop" if name == "idle" else "oneshot",
        "keyframes": [
            {"object": layer, "property": prop, "frames": sorted(f, key=lambda k: k["frame"])}
            for (layer, prop), f in groups.items()
        ],
    }


def find_mobile_root() -> Path:
    """Walk up from this script to the Flutter monorepo root.

    Located by structure rather than a fixed number of parent hops so the skill
    can be versioned inside the repo or live outside it without the scripts
    caring which.
    """
    for parent in Path(__file__).resolve().parents:
        if (parent / "apps").is_dir() and (parent / "tools").is_dir():
            return parent
        candidate = parent / "petrimonium-mobile"
        if (candidate / "apps").is_dir():
            return candidate
    raise SystemExit("could not locate petrimonium-mobile -- pass --root")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--specie", required=True)
    parser.add_argument("--app", default="academy")
    parser.add_argument("--root", default=None)
    parser.add_argument("--rig", default=None)
    parser.add_argument("--out", required=True, help="build directory for scene.json + layers")
    args = parser.parse_args()

    root = Path(args.root) if args.root else find_mobile_root()
    assets = root / "apps" / args.app / "assets" / "images"
    rig_dir = assets / "pet" / (args.rig or f"{args.specie}_rig_v1")
    manifest = json.loads((rig_dir / "rig_manifest.json").read_text())
    placements = manifest.get("placements")
    if not placements:
        raise SystemExit("no `placements` -- run extract_layers.py first")

    reference = Image.open(assets / manifest["source"]).convert("RGBA")
    rx0, ry0, rw, rh = content_box(reference)
    board = manifest["artboard"]
    board_w, board_h = float(board["width"]), float(board["height"])
    framing = manifest.get("framing", {})
    fill = float(framing.get("fill", DEFAULT_FILL))
    baseline = float(framing.get("baseline", DEFAULT_BASELINE))

    scale_ref = min(board_w * fill / rw, board_h * fill / rh)
    left = (board_w - rw * scale_ref) / 2.0
    top = board_h * baseline - rh * scale_ref

    out = Path(args.out)
    (out / "layers").mkdir(parents=True, exist_ok=True)

    # Rive draws an artboard's children front-to-back, so the frontmost layer is
    # emitted first. Feeding the manifest's back-to-front order straight through
    # stacks the rig inside out -- the head ends up hiding the face, which reads
    # as a corrupted render rather than as an ordering mistake.
    order = list(reversed(manifest["drawOrderBackToFront"]))
    children: list[dict] = []
    images: list[dict] = []
    for name in order:
        placement = placements.get(name)
        source = rig_dir / "layers" / f"{name}.png"
        if not placement or not source.exists():
            continue
        layer = Image.open(source).convert("RGBA")
        scaled = layer.resize(
            (max(1, round(layer.width * scale_ref)), max(1, round(layer.height * scale_ref))),
            Image.LANCZOS,
        )
        scaled.save(out / "layers" / f"{name}.png", optimize=True)

        x, y, w, h = placement["refBox"]
        children.append({"type": "image_asset", "name": f"{name}_asset", "source": f"layers/{name}.png"})
        images.append(
            {
                "type": "image",
                "name": name,
                "asset": f"{name}_asset",
                "x": round(left + (x + w / 2.0 - rx0) * scale_ref, 2),
                "y": round(top + (y + h / 2.0 - ry0) * scale_ref, 2),
            }
        )

    placed = {image["name"] for image in images}
    head = "head" if "head" in placed else order[-1]
    base_y = next(i["y"] for i in images if i["name"] == head)

    def bob(layer: str, amount: float) -> list[tuple[int, str, float]]:
        start = next(i["y"] for i in images if i["name"] == layer)
        return [(0, "y", start), (30, "y", start + amount), (59, "y", start)]

    def tilt(layer: str, degrees: float) -> list[tuple[int, str, float]]:
        return [(0, "rotation", 0.0), (30, "rotation", degrees), (59, "rotation", 0.0)]

    # Placeholder motion: enough to prove each pose is reachable and distinct.
    # Real character animation is authored on top of the bones, not here.
    ears = [n for n in ("ear_left", "ear_right") if n in placed]
    recipes = {
        "idle": {head: bob(head, 4.0)},
        "celebrate": {head: bob(head, -14.0), **{e: tilt(e, -10.0) for e in ears}},
        "think": {head: bob(head, 3.0), **{e: tilt(e, 6.0) for e in ears[:1]}},
        "sleep": {head: bob(head, 12.0)},
        "victory": {head: bob(head, -18.0), **{e: tilt(e, 12.0) for e in ears}},
        "happy": {head: bob(head, -8.0)},
    }
    animations = [pose_animation(p, recipes[p]) for p in POSES]

    IDLE = 2  # 0 = entry, 1 = exit
    states = [{"type": "entry"}, {"type": "exit"}] + [
        {"type": "animation", "animation": p} for p in POSES
    ]
    transitions = [{"from": 0, "to": IDLE}]
    for index, pose in enumerate(POSES[1:], start=1):
        node = IDLE + index
        transitions.append(
            {"from": IDLE, "to": node, "conditions": [{"input": "state", "op": "==", "value": float(index)}]}
        )
        transitions.append(
            {"from": node, "to": IDLE, "conditions": [{"input": "state", "op": "==", "value": 0.0}]}
        )

    scene = {
        "scene_format_version": 1,
        "artboard": {
            "name": board["name"],
            "width": board_w,
            "height": board_h,
            "children": children + images,
            "animations": animations,
            "state_machines": [
                {
                    "name": "Companion",
                    "inputs": [
                        {"type": "number", "name": "state", "value": 0.0},
                        {"type": "bool", "name": "reducedMotion", "value": False},
                        {"type": "bool", "name": "interacting", "value": False},
                    ],
                    "layers": [{"states": states, "transitions": transitions}],
                }
            ],
        },
    }
    (out / "scene.json").write_text(json.dumps(scene, indent=2) + "\n")
    print(f"{len(images)} layers  S_ref={scale_ref:.4f}  artboard {board_w:.0f}x{board_h:.0f}")
    print(f"scene -> {out / 'scene.json'}")
    print(f"next: rive-cli generate {out / 'scene.json'} -o {args.specie}.riv")


if __name__ == "__main__":
    main()
