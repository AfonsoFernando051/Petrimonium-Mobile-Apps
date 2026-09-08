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

import companion_scene as CS

FPS = 60

# Fraction of the artboard the pet fills, and where its feet land as a fraction
# of artboard height. Overridable per species via a "framing" block.
DEFAULT_FILL = 0.92
DEFAULT_BASELINE = 0.964

def content_box(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    left, top, right, bottom = bbox
    return (left, top, right - left, bottom - top)


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
    sizes: dict[str, tuple[int, int]] = {}

    order = manifest["drawOrderBackToFront"]
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
        sizes[name] = scaled.size

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

    present = {image["name"] for image in images}
    positions = {image["name"]: (image["x"], image["y"]) for image in images}
    # Rive draws children frontmost first; joints wrap the parts that rotate.
    children_nodes, joints = CS.joint_children(list(reversed(images)), sizes)
    animations = CS.build_animations(positions, present, joints)

    scene = {
        "scene_format_version": 1,
        "artboard": {
            "name": board["name"],
            "width": board_w,
            "height": board_h,
            "children": children + children_nodes,
            "animations": animations,
            "state_machines": [CS.build_state_machine()],
        },
    }
    (out / "scene.json").write_text(json.dumps(scene, indent=2) + "\n")
    print(f"{len(images)} layers  S_ref={scale_ref:.4f}  artboard {board_w:.0f}x{board_h:.0f}")
    print(f"scene -> {out / 'scene.json'}")
    print(f"next: rive-cli generate {out / 'scene.json'} -o {args.specie}.riv")


if __name__ == "__main__":
    main()
