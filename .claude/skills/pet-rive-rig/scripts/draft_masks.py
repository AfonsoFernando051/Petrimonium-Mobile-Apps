#!/usr/bin/env python3
"""Rasterise part masks from editable shape geometry.

Masks are the one genuinely authored step in the pipeline, and painting sixteen
PNGs by hand is miserable to iterate on. Describing them as ellipses and polygons
in a JSON file instead keeps them diffable, reviewable and easy to nudge: move a
vertex, re-run, look at the overlay.

Shapes may overlap freely -- paint each part's *full* extent, including whatever
sits behind a part in front of it. `extract_layers.py` resolves ownership by draw
order and inpaints each loser's hidden region.

Reads `mask_shapes.json` from the rig folder, writes `masks/*.png`.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw


def draw_shape(canvas: ImageDraw.ImageDraw, shape: dict) -> None:
    kind = shape["type"]
    if kind == "ellipse":
        cx, cy = shape["center"]
        rx, ry = shape["radii"]
        canvas.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=255)
    elif kind == "polygon":
        canvas.polygon([tuple(p) for p in shape["points"]], fill=255)
    elif kind == "box":
        x, y, w, h = shape["rect"]
        canvas.rectangle([x, y, x + w, y + h], fill=255)
    else:
        raise SystemExit(f"unknown shape type '{kind}'")


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
    args = parser.parse_args()

    root = Path(args.root) if args.root else find_mobile_root()
    assets = root / "apps" / args.app / "assets" / "images"
    rig_dir = assets / "pet" / (args.rig or f"{args.specie}_rig_v1")
    manifest = json.loads((rig_dir / "rig_manifest.json").read_text())
    shapes = json.loads((rig_dir / "mask_shapes.json").read_text())

    reference = Image.open(assets / manifest["source"]).convert("RGBA")
    masks_dir = rig_dir / "masks"
    masks_dir.mkdir(parents=True, exist_ok=True)

    for name in manifest["drawOrderBackToFront"]:
        parts = shapes.get(name)
        if not parts:
            raise SystemExit(f"mask_shapes.json has no geometry for '{name}'")
        mask = Image.new("L", reference.size, 0)
        canvas = ImageDraw.Draw(mask)
        for shape in parts:
            draw_shape(canvas, shape)
        mask.save(masks_dir / f"{name}.png")
        print(f"{name:16} {len(parts)} shape(s)")

    print(f"\n{len(manifest['drawOrderBackToFront'])} masks -> {masks_dir}")


if __name__ == "__main__":
    main()
