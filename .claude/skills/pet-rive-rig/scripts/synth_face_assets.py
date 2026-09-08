#!/usr/bin/env python3
"""Synthesize a closed-eyelid and a blush asset from the rig's own palette.

Sleep and happy read weakly with transform-only animation: a squashed-open eye
reads as "eye melted", not "eye closed", and nothing at all signals joy on the
face. Both need new art, and neither is available from the reference photo (it
shows one open-eyed, neutral expression), so there is nothing to cut out the way
`extract_layers.py` cuts body parts. These are drawn instead, sampling colour
directly from the rig's own layers so they sit on-model rather than introducing
a foreign palette.

Adds `eyelid_left`/`eyelid_right` (opaque, occludes the eye when opacity -> 1)
and `blush_left`/`blush_right` (a soft translucent flush) as new layers, plus
their `placements` and draw-order entries, appended in front of everything so
they need no interaction with the existing stack.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SUPERSAMPLE = 4


def dominant_colors(image: Image.Image, n: int = 6) -> list[tuple[tuple[int, int, int], int]]:
    arr = np.asarray(image.convert("RGBA"))
    mask = arr[:, :, 3] >= 200
    rgb = arr[:, :, :3][mask]
    if len(rgb) == 0:
        return []
    buckets: dict[tuple[int, int, int], int] = {}
    step = max(1, len(rgb) // 20000)
    for r, g, b in rgb[::step]:
        key = (int(r) // 12, int(g) // 12, int(b) // 12)
        buckets[key] = buckets.get(key, 0) + 1
    ranked = sorted(buckets.items(), key=lambda kv: -kv[1])[:n]
    return [
        (tuple(min(255, k * 12 + 6) for k in key), count) for key, count in ranked
    ]


def sample_palette(layers_dir: Path) -> dict[str, tuple[int, int, int]]:
    """Pull a lid colour, a linework colour and a cheek base from the rig itself."""
    fur = dominant_colors(Image.open(layers_dir / "head.png"), n=4)
    line = dominant_colors(Image.open(layers_dir / "eyebrow_left.png"), n=4)
    fur_tone = max(fur, key=lambda cn: cn[1])[0] if fur else (240, 220, 195)
    # The linework sample also contains fur pixels (padding around the stroke);
    # the darkest cluster is the actual line, not the most frequent one.
    dark = min(line, key=lambda cn: sum(cn[0])) if line else (60, 36, 30)
    return {"fur": fur_tone, "line": dark[0]}


def make_eyelid(size: tuple[int, int], fur: tuple[int, int, int], line: tuple[int, int, int]) -> Image.Image:
    """A relaxed closed lid: a soft fur-toned patch with a drooping crease line."""
    w, h = size
    hi_w, hi_h = w * SUPERSAMPLE, h * SUPERSAMPLE
    # Transparent but pre-tinted to the fill colour: Image.composite blends
    # toward this base wherever the feathered mask is partial, so the edge
    # ramps to fur-coloured-and-fading rather than black-and-fading.
    canvas = Image.new("RGBA", (hi_w, hi_h), (*fur, 0))

    # The occluding patch: an inset ellipse, feathered, so it blends into the
    # surrounding fur rather than reading as a sticker over the eye.
    patch = Image.new("L", (hi_w, hi_h), 0)
    inset_x, inset_y = int(hi_w * 0.05), int(hi_h * 0.08)
    ImageDraw.Draw(patch).ellipse([inset_x, inset_y, hi_w - inset_x, hi_h - inset_y], fill=255)
    patch = patch.filter(ImageFilter.GaussianBlur(hi_w * 0.035))
    fill = Image.new("RGBA", (hi_w, hi_h), (*fur, 255))
    canvas = Image.composite(fill, canvas, patch)

    # A gentle downward crease -- a shallow arc, not a flat line, reads as
    # relaxed rather than surprised or stitched shut.
    mid_y = hi_h * 0.52
    droop = hi_h * 0.10
    left = (hi_w * 0.14, mid_y - droop * 0.3)
    mid = (hi_w * 0.50, mid_y + droop)
    right = (hi_w * 0.86, mid_y - droop * 0.3)
    stroke = max(2, int(hi_w * 0.045))
    draw = ImageDraw.Draw(canvas)
    draw.line(
        [left, ((left[0] + mid[0]) / 2, (left[1] + mid[1]) / 2 + droop * 0.4), mid,
         ((mid[0] + right[0]) / 2, (mid[1] + right[1]) / 2 + droop * 0.4), right],
        fill=(*line, 255), width=stroke, joint="curve",
    )
    for endpoint, direction in ((left, -1), (right, 1)):
        draw.line(
            [endpoint, (endpoint[0] + direction * hi_w * 0.05, endpoint[1] + hi_h * 0.10)],
            fill=(*line, 255), width=max(1, stroke - 1),
        )
    return canvas.resize((w, h), Image.LANCZOS)


def make_blush(size: tuple[int, int], tone: tuple[int, int, int] = (255, 90, 110), peak_alpha: int = 205) -> Image.Image:
    """A soft warm flush -- radial falloff, no hard edge, no hard peak either."""
    w, h = size
    hi_w, hi_h = w * SUPERSAMPLE, h * SUPERSAMPLE
    yy, xx = np.mgrid[0:hi_h, 0:hi_w]
    cx, cy = hi_w / 2, hi_h / 2
    dist = np.sqrt(((xx - cx) / (hi_w / 2)) ** 2 + ((yy - cy) / (hi_h / 2)) ** 2)
    alpha = np.clip(1.0 - dist, 0, 1) ** 2.4
    arr = np.zeros((hi_h, hi_w, 4), dtype=np.uint8)
    arr[..., 0], arr[..., 1], arr[..., 2] = tone
    arr[..., 3] = (alpha * peak_alpha).astype(np.uint8)
    image = Image.fromarray(arr, "RGBA")
    # A touch of blur on top of the power-law falloff: without it, downsizing a
    # sharply-defined radial function still reads as a "dot" rather than a flush.
    blurred_alpha = image.getchannel("A").filter(ImageFilter.GaussianBlur(hi_w * 0.08))
    image.putalpha(blurred_alpha)
    return image.resize((w, h), Image.LANCZOS)


def find_mobile_root() -> Path:
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
    layers_dir = rig_dir / "layers"
    placements = manifest["placements"]

    if "eye_left" not in placements or "eye_right" not in placements:
        raise SystemExit("rig has no eye_left/eye_right placements to anchor the new assets to")

    palette = sample_palette(layers_dir)
    print(f"sampled fur={palette['fur']} line={palette['line']}")

    added: dict[str, dict] = {}
    for side in ("left", "right"):
        eye_box = placements[f"eye_{side}"]["refBox"]
        eye_x, eye_y, eye_w, eye_h = eye_box
        lid = make_eyelid((eye_w, eye_h), palette["fur"], palette["line"])
        lid.save(layers_dir / f"eyelid_{side}.png", optimize=True)
        added[f"eyelid_{side}"] = {"refBox": eye_box, "rotation": 0, "synthesized": True}

        # Cheek: level with the lower half of the eye, shifted toward the muzzle
        # centreline's far side -- i.e. outward from the eye, not toward the nose.
        muzzle = placements.get("muzzle", {}).get("refBox")
        cheek_w, cheek_h = round(eye_w * 0.85), round(eye_h * 0.62)
        outward = -1 if side == "left" else 1
        cx = eye_x + eye_w / 2 + outward * eye_w * 0.35
        cy = eye_y + eye_h * 1.15
        if muzzle:
            cy = max(cy, muzzle[1] + muzzle[3] * 0.15)
        blush = make_blush((cheek_w, cheek_h))
        blush.save(layers_dir / f"blush_{side}.png", optimize=True)
        added[f"blush_{side}"] = {
            "refBox": [round(cx - cheek_w / 2), round(cy - cheek_h / 2), cheek_w, cheek_h],
            "rotation": 0,
            "synthesized": True,
        }

    placements.update(added)
    for name in added:
        manifest["pivots"].setdefault(name, [0.5, 0.5])
    # Frontmost: lids must sit above the eyes they cover; blush reads fine
    # anywhere in front of the fur it sits on. Appending both keeps this a
    # pure addition with no reordering of the existing stack.
    manifest["drawOrderBackToFront"] += list(added)

    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"added {list(added)} -> {layers_dir}")
    print("re-run build_scene.py to fold these into the .riv")


if __name__ == "__main__":
    main()
