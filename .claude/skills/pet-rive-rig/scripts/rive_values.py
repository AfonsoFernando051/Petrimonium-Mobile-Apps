#!/usr/bin/env python3
"""Turn a rig manifest's placements into the numbers to type into Rive.

Placement lives in reference-image pixels; the Rive inspector wants Origin,
Position and Scale on the artboard, and it measures Origin over the whole PNG
including any transparent padding. Doing that conversion by hand per layer is
where mistakes creep in, so it is done here once and printed as a table.

Nothing here is a suggestion to nudge: every value is typed in verbatim.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image

# Fraction of the artboard the pet's bounding box is allowed to fill, and where
# its feet land as a fraction of artboard height. Overridable per species via a
# "framing" block in the manifest.
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
    parser.add_argument("--json", action="store_true", help="emit JSON instead of a table")
    args = parser.parse_args()

    root = Path(args.root) if args.root else find_mobile_root()
    assets = root / "apps" / args.app / "assets" / "images"
    rig_dir = assets / "pet" / (args.rig or f"{args.specie}_rig_v1")
    manifest = json.loads((rig_dir / "rig_manifest.json").read_text())

    placements = manifest.get("placements")
    if not placements:
        raise SystemExit(
            "manifest has no `placements` block -- run extract_layers.py first; "
            "placement is measured, never estimated in the editor"
        )

    reference = Image.open(assets / manifest["source"]).convert("RGBA")
    rx0, ry0, rw, rh = content_box(reference)

    board = manifest["artboard"]
    board_w, board_h = float(board["width"]), float(board["height"])
    framing = manifest.get("framing", {})
    fill = float(framing.get("fill", DEFAULT_FILL))
    baseline = float(framing.get("baseline", DEFAULT_BASELINE))

    # One uniform reference->artboard scale shared by every layer. A per-layer
    # deviation here is exactly what makes an assembly look skewed.
    scale_ref = min(board_w * fill / rw, board_h * fill / rh)
    origin_x = (board_w - rw * scale_ref) / 2.0
    origin_y = board_h * baseline - rh * scale_ref

    pivots = manifest.get("pivots", {})
    rows = []
    for name in manifest["drawOrderBackToFront"]:
        placement = placements.get(name)
        if not placement:
            continue
        path = rig_dir / "layers" / f"{name}.png"
        if not path.exists():
            continue
        layer = Image.open(path).convert("RGBA")
        cx0, cy0, cw, ch = content_box(layer)
        x, y, w, h = placement["refBox"]
        px, py = pivots.get(name, [0.5, 0.5])

        rows.append(
            {
                "layer": name,
                "originX": round((cx0 + px * cw) / layer.width * 100, 1),
                "originY": round((cy0 + py * ch) / layer.height * 100, 1),
                "x": round(origin_x + (x + px * w - rx0) * scale_ref, 1),
                "y": round(origin_y + (y + py * h - ry0) * scale_ref, 1),
                "scale": round(w * scale_ref / cw * 100, 1),
                "rotation": placement.get("rotation", 0),
            }
        )

    if args.json:
        print(json.dumps(rows, indent=2))
        return

    print(f"artboard {board['name']} {board_w:.0f}x{board_h:.0f}   S_ref={scale_ref:.4f}")
    print(f"reference {manifest['source']} content box=({rx0},{ry0},{rw},{rh})\n")
    print(f"{'layer':16} {'OriginX':>8} {'OriginY':>8} {'PosX':>8} {'PosY':>8} {'Scale':>8} {'Rot':>5}")
    print("-" * 66)
    for r in rows:
        print(
            f"{r['layer']:16} {r['originX']:7.1f}% {r['originY']:7.1f}% "
            f"{r['x']:8.1f} {r['y']:8.1f} {r['scale']:7.1f}% {r['rotation']:5}"
        )
    print("\nDraw order is the row order above: first row furthest back.")
    print("Scale is uniform -- lock the ratio and put this value in both X and Y.")


if __name__ == "__main__":
    main()
