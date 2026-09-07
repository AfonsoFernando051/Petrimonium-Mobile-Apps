#!/usr/bin/env python3
"""Split and clean the generated dog rig atlas into transparent PNG layers."""

from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


ROOT = Path(__file__).resolve().parents[2]
ATLAS = ROOT / "apps/academy/assets/images/pet/dog_rig_v1/dog_rig_atlas.png"
OUTPUT = ATLAS.parent / "layers"

# Coordinates are deliberately explicit: the source atlas is a versioned art asset.
CROPS = {
    "head": (35, 35, 375, 360),
    "ear_left": (380, 35, 635, 365),
    "ear_right": (685, 35, 925, 365),
    "muzzle": (925, 150, 1235, 350),
    "eye_left": (120, 385, 310, 575),
    "eye_right": (405, 385, 565, 575),
    "eyebrow_left": (690, 420, 855, 540),
    "eyebrow_right": (985, 420, 1130, 540),
    "torso": (45, 595, 395, 945),
    "front_leg_left": (395, 600, 655, 950),
    "front_leg_right": (685, 600, 900, 950),
    "rear_haunch": (925, 600, 1160, 950),
    "tail": (55, 940, 295, 1195),
    "collar": (315, 970, 660, 1190),
    "medallion": (675, 975, 875, 1190),
    "ground_shadow": (885, 1020, 1235, 1185),
}


def keep_largest_alpha_component(image: Image.Image) -> Image.Image:
    pixels = np.asarray(image.convert("RGBA")).copy()
    alpha = pixels[:, :, 3]
    labels, count = ndimage.label(alpha >= 12)
    if count == 0:
        return image.convert("RGBA")

    sizes = ndimage.sum(alpha, labels, range(1, count + 1))
    chosen = int(np.argmax(sizes)) + 1
    selected = labels == chosen
    # Include adjacent antialiased pixels while excluding detached extraction noise.
    selected = ndimage.binary_dilation(selected, iterations=2)
    pixels[:, :, 3] = np.where(selected, alpha, 0)
    return Image.fromarray(pixels, "RGBA")


def trim_with_padding(image: Image.Image, padding: int = 8) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(image.width, right + padding)
    bottom = min(image.height, bottom + padding)
    return image.crop((left, top, right, bottom))


def main() -> None:
    atlas = Image.open(ATLAS).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, box in CROPS.items():
        layer = keep_largest_alpha_component(atlas.crop(box))
        layer = trim_with_padding(layer)
        layer.save(OUTPUT / f"{name}.png", optimize=True)
        print(f"{name}: {layer.width}x{layer.height}")


if __name__ == "__main__":
    main()
