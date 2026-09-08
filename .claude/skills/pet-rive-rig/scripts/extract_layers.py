#!/usr/bin/env python3
"""Cut rig layers out of the assembled reference art, keeping their placement.

This is the whole point of the pipeline. A layer cut from the assembled render
already knows where it belongs -- its bounding box in the reference *is* its
placement, at scale 1.0 -- so the Rive assembly is a transcription rather than a
search. Generating parts on a sprite sheet instead throws that information away,
and no amount of template matching gets it back: the sheet's parts are redrawn,
not copied, so there is no photometric optimum to find.

Input is one mask PNG per part under `masks/`, white where the part belongs.
Masks may overlap: paint each part's *full* extent, including the portion hidden
behind parts in front of it. Draw order decides who owns a contested pixel, and
the loser's hidden region is inpainted from its own visible colour so it stays
whole when the rig moves it.

Writes `layers/*.png` plus an exact `placements` block in rig_manifest.json.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

# Grown around every mask so neighbouring parts overlap by a hair instead of
# leaving a hairline gap at the seam once the rig separates them.
SEAM_BLEED = 2


def load_mask(path: Path, size: tuple[int, int]) -> np.ndarray:
    image = Image.open(path)
    # An alpha channel wins if there is one -- masks painted in an image editor
    # usually arrive as transparent-background shapes rather than white-on-black.
    channel = image.getchannel("A") if "A" in image.getbands() else image.convert("L")
    if channel.size != size:
        raise SystemExit(f"{path.name}: mask is {channel.size}, reference is {size}")
    return np.asarray(channel, dtype=np.uint8) >= 128


def inpaint(rgb: np.ndarray, known: np.ndarray, target: np.ndarray) -> np.ndarray:
    """Fill `target` pixels with the nearest `known` colour.

    Nearest-neighbour rather than a diffusion solve: this art is flat cel-shaded,
    so a hidden haunch behind a leg is a near-solid colour block, and anything
    fancier would only invent detail that never shows.
    """
    if not target.any() or not known.any():
        return rgb
    _, indices = ndimage.distance_transform_edt(~known, return_indices=True)
    filled = rgb.copy()
    filled[target] = rgb[indices[0][target], indices[1][target]]
    return filled


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
    manifest_path = rig_dir / "rig_manifest.json"
    manifest = json.loads(manifest_path.read_text())

    reference = Image.open(assets / manifest["source"]).convert("RGBA")
    ref = np.asarray(reference, dtype=np.uint8)
    rgb, ref_alpha = ref[:, :, :3], ref[:, :, 3]
    size = (reference.width, reference.height)

    order = manifest["drawOrderBackToFront"]
    masks: dict[str, np.ndarray] = {}
    for name in order:
        path = rig_dir / "masks" / f"{name}.png"
        if not path.exists():
            raise SystemExit(f"missing mask for '{name}' -- expected {path}")
        masks[name] = load_mask(path, size)

    layers_dir = rig_dir / "layers"
    layers_dir.mkdir(parents=True, exist_ok=True)

    placements: dict[str, dict] = {}
    print(f"{'layer':16} {'refBox':28} {'hidden':>7}")
    for index, name in enumerate(order):
        mask = masks[name] & (ref_alpha >= 8)
        if not mask.any():
            print(f"{name:16} {'-- mask covers nothing --':28}")
            continue

        # Everything drawn in front of this part steals the pixels it overlaps.
        occluded = np.zeros_like(mask)
        for front in order[index + 1 :]:
            occluded |= masks[front]
        hidden = mask & occluded
        visible = mask & ~occluded

        plate = inpaint(rgb, visible, hidden) if hidden.any() else rgb

        alpha = np.zeros_like(ref_alpha)
        grown = ndimage.binary_dilation(mask, iterations=SEAM_BLEED) & (ref_alpha >= 8)
        alpha[grown] = ref_alpha[grown]

        out = np.dstack([plate, alpha])
        image = Image.fromarray(out, "RGBA")
        bbox = image.getchannel("A").getbbox()
        cropped = image.crop(bbox)
        cropped.save(layers_dir / f"{name}.png", optimize=True)

        x0, y0, x1, y1 = bbox
        placements[name] = {
            "refBox": [x0, y0, x1 - x0, y1 - y0],
            "rotation": 0,
            "exact": True,
        }
        share = hidden.sum() / max(1, mask.sum())
        print(f"{name:16} {str(placements[name]['refBox']):28} {share:6.1%}")

    manifest["placements"] = placements
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"\n{len(placements)} layers -> {layers_dir}")
    print(f"exact placements -> {manifest_path}")
    print("next: rive_values.py for the numbers to type into the inspector")


if __name__ == "__main__":
    main()
