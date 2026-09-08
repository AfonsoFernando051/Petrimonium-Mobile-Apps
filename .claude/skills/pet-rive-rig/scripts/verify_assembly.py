#!/usr/bin/env python3
"""Check an assembly against the reference art, numerically.

Two things can drift apart and both look "nearly right" by eye, which is why
neither is ever signed off by eye:

  --composite   the extracted layers, restacked at their recorded placements,
                versus the reference. Proves the cut kept the art intact.
  --export FILE a PNG exported from the Rive artboard, versus the reference put
                through the same framing transform rive_values.py used. Proves
                the numbers actually reached the inspector.

Reports silhouette IoU, centroid drift, and mean colour error inside the shared
silhouette. All three gates matter: silhouette alone will happily pass a render
whose outline is right but whose interior is garbage, which is exactly what a
mis-decoded image layer looks like.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

IOU_GATE = 0.95
CENTROID_GATE = 2.0
# Mean per-channel difference (0-255) inside the overlap. Cel-shaded art
# reassembled correctly lands near zero; a garbled interior blows past this even
# when the outline matches perfectly.
COLOR_GATE = 12.0

DEFAULT_FILL = 0.92
DEFAULT_BASELINE = 0.964


def silhouette(image: Image.Image) -> np.ndarray:
    return np.asarray(image.getchannel("A"), dtype=np.uint8) >= 8


def iou(a: np.ndarray, b: np.ndarray) -> float:
    union = (a | b).sum()
    return float((a & b).sum() / union) if union else 1.0


def colour_error(got: Image.Image, want: Image.Image, overlap: np.ndarray) -> float:
    """Mean per-channel RGB distance where both images are opaque."""
    if not overlap.any():
        return 255.0
    a = np.asarray(got.convert("RGB"), dtype=np.float64)
    b = np.asarray(want.convert("RGB"), dtype=np.float64)
    return float(np.abs(a[overlap] - b[overlap]).mean())


def centroid(mask: np.ndarray) -> tuple[float, float]:
    ys, xs = np.nonzero(mask)
    return (float(xs.mean()), float(ys.mean())) if xs.size else (0.0, 0.0)


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
    parser.add_argument("--composite", action="store_true")
    parser.add_argument("--export", default=None, help="PNG exported from the Rive artboard")
    parser.add_argument("--overlay", default=None, help="write a side-by-side diff here")
    args = parser.parse_args()

    root = Path(args.root) if args.root else find_mobile_root()
    assets = root / "apps" / args.app / "assets" / "images"
    rig_dir = assets / "pet" / (args.rig or f"{args.specie}_rig_v1")
    manifest = json.loads((rig_dir / "rig_manifest.json").read_text())
    reference = Image.open(assets / manifest["source"]).convert("RGBA")
    placements = manifest.get("placements", {})

    if args.composite:
        canvas = Image.new("RGBA", reference.size)
        for name in manifest["drawOrderBackToFront"]:
            placement = placements.get(name)
            path = rig_dir / "layers" / f"{name}.png"
            if not placement or not path.exists():
                continue
            if placement.get("synthesized"):
                # Pose-only overlays (a closed lid, a blush) aren't part of the
                # neutral assembly this check validates -- they're invisible at
                # opacity 0 until a specific animation raises them, so stacking
                # them at full opacity here would fault the base rig for
                # artwork that was never meant to show in it.
                continue
            x, y, w, h = placement["refBox"]
            layer = Image.open(path).convert("RGBA")
            if (layer.width, layer.height) != (w, h):
                layer = layer.resize((w, h), Image.LANCZOS)
            canvas.alpha_composite(layer, (x, y))
        got, want = canvas, reference
    elif args.export:
        board = manifest["artboard"]
        board_w, board_h = int(board["width"]), int(board["height"])
        framing = manifest.get("framing", {})
        fill = float(framing.get("fill", DEFAULT_FILL))
        baseline = float(framing.get("baseline", DEFAULT_BASELINE))
        rx0, ry0, rw, rh = content_box(reference)
        scale_ref = min(board_w * fill / rw, board_h * fill / rh)
        want = Image.new("RGBA", (board_w, board_h))
        scaled = reference.crop((rx0, ry0, rx0 + rw, ry0 + rh)).resize(
            (round(rw * scale_ref), round(rh * scale_ref)), Image.LANCZOS
        )
        want.alpha_composite(
            scaled,
            (
                round((board_w - rw * scale_ref) / 2),
                round(board_h * baseline - rh * scale_ref),
            ),
        )
        got = Image.open(args.export).convert("RGBA")
        if got.size != want.size:
            got = got.resize(want.size, Image.LANCZOS)
    else:
        raise SystemExit("pass --composite or --export FILE")

    got_mask, want_mask = silhouette(got), silhouette(want)
    score = iou(got_mask, want_mask)
    gx, gy = centroid(got_mask)
    wx, wy = centroid(want_mask)
    drift = float(np.hypot(gx - wx, gy - wy))

    delta = colour_error(got, want, got_mask & want_mask)
    print(f"silhouette IoU  {score:.4f}   (gate >= {IOU_GATE})")
    print(f"centroid drift  {drift:.2f}px  (gate <= {CENTROID_GATE})")
    print(f"colour error    {delta:.2f}    (gate <= {COLOR_GATE})")

    if args.overlay:
        strip = Image.new("RGBA", (want.width * 3, want.height), (255, 255, 255, 255))
        strip.alpha_composite(want, (0, 0))
        strip.alpha_composite(got, (want.width, 0))
        diff = np.zeros((want.height, want.width, 4), dtype=np.uint8)
        diff[..., 0] = np.where(want_mask & ~got_mask, 255, 0)  # missing: red
        diff[..., 1] = np.where(got_mask & ~want_mask, 255, 0)  # extra: green
        diff[..., 3] = np.where(want_mask ^ got_mask, 255, 40)
        strip.alpha_composite(Image.fromarray(diff, "RGBA"), (want.width * 2, 0))
        strip.convert("RGB").save(args.overlay)
        print(f"overlay -> {args.overlay}  (reference | assembly | diff)")

    ok = score >= IOU_GATE and drift <= CENTROID_GATE and delta <= COLOR_GATE
    print("PASS" if ok else "FAIL -- fix the numbers in the manifest, not in the editor")
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
