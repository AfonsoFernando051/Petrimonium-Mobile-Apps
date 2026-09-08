#!/usr/bin/env python3
"""Fit the dog rig sprite layers to the assembled reference image.

The atlas is a sprite sheet, not a composition.  This script measures one
uniform scale and one translation per layer against ``generated_dog.png`` and
stores the resulting content boxes in ``rig_manifest.json``.  It also emits
the exact Rive inspector values and a verification bundle.

OpenCV is intentionally used for the masked normalized correlation requested
by the rig specification.  Install ``opencv-python-headless`` when ``cv2`` is
not already available in the active Python environment.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

try:
    import cv2
except ImportError as exc:  # pragma: no cover - exercised only without OpenCV
    raise SystemExit(
        "OpenCV is required. Install opencv-python-headless and run again."
    ) from exc

import numpy as np
from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "apps/academy/assets/images/generated_dog.png"
RIG_DIR = ROOT / "apps/academy/assets/images/pet/dog_rig_v1"
LAYERS_DIR = RIG_DIR / "layers"
MANIFEST_PATH = RIG_DIR / "rig_manifest.json"
VERIFY_DIR = RIG_DIR / "verification"

REF_ALPHA_BBOX = (12.0, 12.0, 321.0, 398.0)
REF_SCALE = 1.25
ARTBOARD_OFFSET = (16.9, 57.5)
ALPHA_PADDING = 8.0
LOW_CONFIDENCE_THRESHOLD = 0.60
OCCLUDED_LAYERS = {"torso", "rear_haunch", "collar"}
SEARCH_PADDING = 128

# Broad semantic windows keep repeated fur/metal textures from matching the
# wrong anatomical region.  They are search constraints, not final placements;
# scale and translation are still selected by the masked correlation sweep.
# Radii deliberately allow tens of pixels of movement around each feature.
FIT_HINTS = {
    "ground_shadow": ((165.0, 405.0), (38.0, 24.0)),
    "tail": ((67.0, 326.5), (32.0, 55.0)),
    "rear_haunch": ((102.5, 343.0), (28.0, 52.0)),
    "torso": ((166.0, 321.0), (52.0, 65.0)),
    "front_leg_right": ((224.0, 332.0), (42.0, 65.0)),
    "front_leg_left": ((155.5, 339.0), (46.0, 70.0)),
    "collar": ((182.0, 249.5), (28.0, 22.0)),
    "head": ((189.0, 131.5), (52.0, 48.0)),
    "ear_right": ((295.0, 92.0), (42.0, 48.0)),
    "ear_left": ((65.0, 82.0), (48.0, 55.0)),
    "muzzle": ((192.5, 194.0), (42.0, 32.0)),
    "eye_right": ((256.5, 142.0), (30.0, 30.0)),
    "eye_left": ((142.5, 136.0), (34.0, 32.0)),
    "eyebrow_right": ((260.5, 77.5), (22.0, 10.0)),
    "eyebrow_left": ((145.5, 69.5), (22.0, 11.0)),
    "medallion": ((203.5, 273.5), (35.0, 35.0)),
}

# Approximate scale centres come from comparing each padding-free sprite extent
# with its anatomical extent in the reference.  They are a weak regularizer,
# not fixed output: every scale in the required [0.30, 1.20] sweep is scored.
SCALE_HINTS = {
    "ground_shadow": (0.72, 0.16),
    "tail": (0.40, 0.12),
    "rear_haunch": (0.50, 0.13),
    "torso": (0.575, 0.13),
    "front_leg_right": (0.55, 0.13),
    "front_leg_left": (0.63, 0.15),
    "collar": (0.44, 0.13),
    "head": (0.765, 0.15),
    "ear_right": (0.44, 0.13),
    "ear_left": (0.595, 0.14),
    "muzzle": (0.65, 0.12),
    "eye_right": (0.52, 0.10),
    "eye_left": (0.55, 0.10),
    "eyebrow_right": (0.42, 0.11),
    "eyebrow_left": (0.405, 0.11),
    "medallion": (0.405, 0.10),
}

SILHOUETTE_LAYERS = (
    "ground_shadow",
    "tail",
    "rear_haunch",
    "torso",
    "front_leg_right",
    "front_leg_left",
    "head",
    "ear_right",
    "ear_left",
)

# Silhouette refinement must not trade anatomical registration for a slightly
# larger union score. These bounds are measured in reference pixels around the
# RGB-derived placement. The shadow is diffuse and therefore gets more room.
SILHOUETTE_MAX_TRANSLATION = {
    "ground_shadow": (52.0, 28.0),
    "tail": (12.0, 12.0),
    "rear_haunch": (15.0, 15.0),
    "torso": (12.0, 12.0),
    "front_leg_right": (12.0, 12.0),
    "front_leg_left": (12.0, 12.0),
    "head": (8.0, 8.0),
    "ear_right": (10.0, 10.0),
    "ear_left": (10.0, 10.0),
}

SILHOUETTE_MAX_SCALE_DELTA = {
    "ground_shadow": 0.07,
    "tail": 0.04,
    "rear_haunch": 0.04,
    "torso": 0.04,
    "front_leg_right": 0.04,
    "front_leg_left": 0.04,
    "head": 0.04,
    "ear_right": 0.04,
    "ear_left": 0.04,
}


@dataclass(frozen=True)
class Match:
    scale: float
    tx: int
    ty: int
    score: float
    raw_score: float
    outside_fraction: float


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path, default=REFERENCE)
    parser.add_argument("--layers", type=Path, default=LAYERS_DIR)
    parser.add_argument("--manifest", type=Path, default=MANIFEST_PATH)
    parser.add_argument("--output-dir", type=Path, default=VERIFY_DIR)
    parser.add_argument(
        "--write-manifest",
        action="store_true",
        help="write the measured placements block into rig_manifest.json",
    )
    parser.add_argument(
        "--coarse-step", type=float, default=0.02, help="coarse scale step"
    )
    parser.add_argument(
        "--refine-step", type=float, default=0.005, help="refined scale step"
    )
    return parser.parse_args()


def load_rgba(path: Path) -> np.ndarray:
    with Image.open(path) as image:
        return np.asarray(image.convert("RGBA"), dtype=np.uint8)


def resize_rgba(rgba: np.ndarray, scale: float) -> np.ndarray:
    height, width = rgba.shape[:2]
    size = (max(1, round(width * scale)), max(1, round(height * scale)))
    interpolation = cv2.INTER_AREA if scale < 1.0 else cv2.INTER_LANCZOS4
    return cv2.resize(rgba, size, interpolation=interpolation)


def inclusive_range(start: float, stop: float, step: float) -> list[float]:
    count = int(math.floor((stop - start) / step + 1e-9))
    values = [start + index * step for index in range(count + 1)]
    if not values or values[-1] < stop - 1e-9:
        values.append(stop)
    return values


def normalized_mask(alpha: np.ndarray) -> np.ndarray:
    # A binary mask is more stable with TM_CCOEFF_NORMED than a soft mask and
    # still excludes the eight-pixel transparent padding from correlation.
    return np.where(alpha >= 16, 255, 0).astype(np.uint8)


def score_scale(
    search_reference: np.ndarray,
    layer: np.ndarray,
    scale: float,
    hint: tuple[tuple[float, float], tuple[float, float]],
    scale_hint: tuple[float, float],
    native_visible_mask: np.ndarray | None = None,
) -> Match | None:
    resized = resize_rgba(layer, scale)
    ref_height, ref_width = search_reference.shape[:2]
    height, width = resized.shape[:2]
    if width > ref_width or height > ref_height:
        return None

    if native_visible_mask is None:
        mask = normalized_mask(resized[:, :, 3])
    else:
        mask = cv2.resize(
            native_visible_mask,
            (width, height),
            interpolation=cv2.INTER_NEAREST,
        )
        mask = np.where((mask > 0) & (resized[:, :, 3] >= 16), 255, 0).astype(
            np.uint8
        )

    mask_count = int(np.count_nonzero(mask))
    if mask_count < 32:
        return None

    # OpenCV accepts an 8-bit single-channel mask for a three-channel template.
    correlation = cv2.matchTemplate(
        search_reference[:, :, :3],
        resized[:, :, :3],
        cv2.TM_CCOEFF_NORMED,
        mask=mask,
    )
    correlation = np.nan_to_num(correlation, nan=-1.0, posinf=-1.0, neginf=-1.0)

    reference_silhouette = (search_reference[:, :, 3] >= 16).astype(np.float32)
    template_silhouette = (mask > 0).astype(np.float32)
    overlap = cv2.matchTemplate(
        reference_silhouette,
        template_silhouette,
        cv2.TM_CCORR,
    )
    outside_fraction = np.clip(1.0 - overlap / float(mask_count), 0.0, 1.0)
    adjusted = correlation - 0.35 * outside_fraction
    expected_scale, scale_tolerance = scale_hint
    scale_distance = (scale - expected_scale) / scale_tolerance
    adjusted = adjusted - 0.22 * scale_distance * scale_distance

    # Convert each result-cell location back from the padded search canvas and
    # keep only candidates whose full-image center is in the anatomical window.
    (center_x, center_y), (radius_x, radius_y) = hint
    grid_y, grid_x = np.indices(adjusted.shape, dtype=np.float32)
    candidate_center_x = grid_x - SEARCH_PADDING + width / 2.0
    candidate_center_y = grid_y - SEARCH_PADDING + height / 2.0
    in_window = (
        (np.abs(candidate_center_x - center_x) <= radius_x)
        & (np.abs(candidate_center_y - center_y) <= radius_y)
    )
    adjusted = np.where(in_window, adjusted, -np.inf)
    if not np.isfinite(adjusted).any():
        return None

    _, best_adjusted, _, location = cv2.minMaxLoc(adjusted)
    padded_tx, padded_ty = location
    tx = padded_tx - SEARCH_PADDING
    ty = padded_ty - SEARCH_PADDING
    raw_score = float(correlation[padded_ty, padded_tx])
    outside = float(outside_fraction[padded_ty, padded_tx])
    return Match(
        scale=scale,
        tx=int(tx),
        ty=int(ty),
        score=float(best_adjusted),
        raw_score=raw_score,
        outside_fraction=outside,
    )


def derive_visible_mask(
    search_reference: np.ndarray, layer: np.ndarray, match: Match
) -> np.ndarray | None:
    """Estimate the actually visible template pixels for an occluded layer."""

    resized = resize_rgba(layer, match.scale)
    height, width = resized.shape[:2]
    padded_x = match.tx + SEARCH_PADDING
    padded_y = match.ty + SEARCH_PADDING
    region = search_reference[
        padded_y : padded_y + height, padded_x : padded_x + width
    ]
    if region.shape[:2] != resized.shape[:2]:
        return None

    base = resized[:, :, 3] >= 16
    color_error = np.mean(
        np.abs(resized[:, :, :3].astype(np.int16) - region[:, :, :3].astype(np.int16)),
        axis=2,
    )
    visible = base & (region[:, :, 3] >= 16) & (color_error <= 58.0)
    if np.count_nonzero(visible) < max(64, int(np.count_nonzero(base) * 0.08)):
        return None

    visible_u8 = np.where(visible, 255, 0).astype(np.uint8)
    kernel = np.ones((3, 3), dtype=np.uint8)
    visible_u8 = cv2.morphologyEx(visible_u8, cv2.MORPH_OPEN, kernel)
    visible_u8 = cv2.dilate(visible_u8, kernel, iterations=1)
    native_height, native_width = layer.shape[:2]
    return cv2.resize(
        visible_u8,
        (native_width, native_height),
        interpolation=cv2.INTER_NEAREST,
    )


def best_match_for_scales(
    search_reference: np.ndarray,
    layer: np.ndarray,
    scales: Iterable[float],
    hint: tuple[tuple[float, float], tuple[float, float]],
    scale_hint: tuple[float, float],
    native_visible_mask: np.ndarray | None = None,
) -> Match:
    best: Match | None = None
    for scale in scales:
        candidate = score_scale(
            search_reference,
            layer,
            scale,
            hint,
            scale_hint,
            native_visible_mask,
        )
        if candidate is not None and (best is None or candidate.score > best.score):
            best = candidate
    if best is None:
        raise RuntimeError("no valid template scale fits inside the reference")
    return best


def fit_layer(
    name: str,
    search_reference: np.ndarray,
    layer: np.ndarray,
    coarse_step: float,
    refine_step: float,
) -> Match:
    coarse = inclusive_range(0.30, 1.20, coarse_step)
    hint = FIT_HINTS[name]
    scale_hint = SCALE_HINTS[name]
    first = best_match_for_scales(
        search_reference, layer, coarse, hint, scale_hint
    )

    visible_mask = None
    if name in OCCLUDED_LAYERS:
        visible_mask = derive_visible_mask(search_reference, layer, first)

    refine_start = max(0.30, first.scale - coarse_step)
    refine_stop = min(1.20, first.scale + coarse_step)
    refined_scales = inclusive_range(refine_start, refine_stop, refine_step)
    refined = best_match_for_scales(
        search_reference,
        layer,
        refined_scales,
        hint,
        scale_hint,
        native_visible_mask=visible_mask,
    )
    return refined


def content_box(layer: np.ndarray, match: Match) -> list[float]:
    height, width = layer.shape[:2]
    content_width = width - 2.0 * ALPHA_PADDING
    content_height = height - 2.0 * ALPHA_PADDING
    return [
        match.tx + ALPHA_PADDING * match.scale,
        match.ty + ALPHA_PADDING * match.scale,
        content_width * match.scale,
        content_height * match.scale,
    ]


def render_search_mask(
    layer: np.ndarray, match: Match, shape: tuple[int, int]
) -> np.ndarray:
    resized = resize_rgba(layer, match.scale)
    source = resized[:, :, 3] >= 16
    canvas = np.zeros(shape, dtype=bool)
    left = match.tx + SEARCH_PADDING
    top = match.ty + SEARCH_PADDING
    right = left + source.shape[1]
    bottom = top + source.shape[0]
    clip_left = max(0, left)
    clip_top = max(0, top)
    clip_right = min(shape[1], right)
    clip_bottom = min(shape[0], bottom)
    if clip_left >= clip_right or clip_top >= clip_bottom:
        return canvas
    source_left = clip_left - left
    source_top = clip_top - top
    canvas[clip_top:clip_bottom, clip_left:clip_right] = source[
        source_top : source_top + (clip_bottom - clip_top),
        source_left : source_left + (clip_right - clip_left),
    ]
    return canvas


def refine_one_silhouette_layer(
    name: str,
    search_reference: np.ndarray,
    layers: dict[str, np.ndarray],
    matches: dict[str, Match],
    anchor: Match,
) -> Match:
    target = search_reference[:, :, 3] >= 16
    other_union = np.zeros(target.shape, dtype=bool)
    for other_name, other_match in matches.items():
        if other_name == name:
            continue
        other_union |= render_search_mask(
            layers[other_name], other_match, target.shape
        )

    residual = target & ~other_union
    target_float = target.astype(np.float32)
    residual_float = residual.astype(np.float32)
    other_float = other_union.astype(np.float32)
    target_area = float(np.count_nonzero(target))
    other_area = float(np.count_nonzero(other_union))
    other_intersection = float(np.count_nonzero(other_union & target))

    base = matches[name]
    max_scale_delta = SILHOUETTE_MAX_SCALE_DELTA[name]
    scale_start = max(0.30, anchor.scale - max_scale_delta)
    scale_stop = min(1.20, anchor.scale + max_scale_delta)
    scales = inclusive_range(scale_start, scale_stop, 0.01)
    hint = FIT_HINTS[name]
    (center_x, center_y), (radius_x, radius_y) = hint

    best_objective = -math.inf
    best_iou = -math.inf
    best_scale = base.scale
    best_location = (base.tx + SEARCH_PADDING, base.ty + SEARCH_PADDING)

    for scale in scales:
        resized = resize_rgba(layers[name], scale)
        template = (resized[:, :, 3] >= 16).astype(np.float32)
        area = float(np.count_nonzero(template))
        if area < 32:
            continue
        overlap_residual = cv2.matchTemplate(
            residual_float, template, cv2.TM_CCORR
        )
        overlap_other = cv2.matchTemplate(other_float, template, cv2.TM_CCORR)
        intersection = other_intersection + overlap_residual
        candidate_area = other_area + area - overlap_other
        union = target_area + candidate_area - intersection
        iou = np.divide(
            intersection,
            union,
            out=np.zeros_like(intersection, dtype=np.float32),
            where=union > 0,
        )

        grid_y, grid_x = np.indices(iou.shape, dtype=np.float32)
        candidate_center_x = grid_x - SEARCH_PADDING + template.shape[1] / 2.0
        candidate_center_y = grid_y - SEARCH_PADDING + template.shape[0] / 2.0
        in_window = (
            (np.abs(candidate_center_x - center_x) <= radius_x)
            & (np.abs(candidate_center_y - center_y) <= radius_y)
        )
        candidate_tx = grid_x - SEARCH_PADDING
        candidate_ty = grid_y - SEARCH_PADDING
        max_dx, max_dy = SILHOUETTE_MAX_TRANSLATION[name]
        near_anchor = (
            (np.abs(candidate_tx - anchor.tx) <= max_dx)
            & (np.abs(candidate_ty - anchor.ty) <= max_dy)
        )
        # Prefer the RGB-derived placement when silhouettes are effectively
        # tied, and never let a part migrate into a neighbor's region.
        scale_penalty = 0.0018 * (
            (scale - anchor.scale) / max(max_scale_delta, 0.005)
        ) ** 2
        translation_penalty = 0.0012 * (
            ((candidate_tx - anchor.tx) / max(max_dx, 1.0)) ** 2
            + ((candidate_ty - anchor.ty) / max(max_dy, 1.0)) ** 2
        )
        objective = np.where(
            in_window & near_anchor,
            iou - scale_penalty - translation_penalty,
            -np.inf,
        )
        if not np.isfinite(objective).any():
            continue
        _, maximum, _, location = cv2.minMaxLoc(objective)
        if maximum > best_objective:
            best_objective = float(maximum)
            best_iou = float(iou[location[1], location[0]])
            best_scale = scale
            best_location = location

    return Match(
        scale=best_scale,
        tx=int(best_location[0] - SEARCH_PADDING),
        ty=int(best_location[1] - SEARCH_PADDING),
        score=best_iou,
        raw_score=base.raw_score,
        outside_fraction=base.outside_fraction,
    )


def refine_silhouettes(
    search_reference: np.ndarray,
    layers: dict[str, np.ndarray],
    matches: dict[str, Match],
) -> dict[str, Match]:
    refined = dict(matches)
    anchors = dict(matches)
    # Two coordinate-descent passes let neighboring outer parts settle against
    # one another while keeping the measured RGB fits as tie-breakers.
    for _ in range(2):
        for name in SILHOUETTE_LAYERS:
            previous = refined[name]
            candidate = refine_one_silhouette_layer(
                name, search_reference, layers, refined, anchors[name]
            )
            refined[name] = candidate
            print(
                f"silhouette {name:13s} "
                f"s={previous.scale:.3f}->{candidate.scale:.3f} "
                f"xy=({previous.tx},{previous.ty})->({candidate.tx},{candidate.ty}) "
                f"global_iou={candidate.score:.5f}"
            )
    return refined


def rounded(values: Iterable[float], digits: int = 3) -> list[float]:
    return [round(float(value), digits) for value in values]


def rive_values(
    name: str,
    layer: np.ndarray,
    placement: dict[str, object],
    pivots: dict[str, list[float]],
) -> dict[str, float | str]:
    height, width = layer.shape[:2]
    content_width = width - 2.0 * ALPHA_PADDING
    content_height = height - 2.0 * ALPHA_PADDING
    pivot_x, pivot_y = pivots[name]
    x0, y0, ref_width, ref_height = placement["refBox"]

    origin_x = (ALPHA_PADDING + pivot_x * content_width) / width * 100.0
    origin_y = (ALPHA_PADDING + pivot_y * content_height) / height * 100.0
    scale = ref_width * REF_SCALE / content_width * 100.0
    position_x = ARTBOARD_OFFSET[0] + (
        x0 + pivot_x * ref_width - REF_ALPHA_BBOX[0]
    ) * REF_SCALE
    position_y = ARTBOARD_OFFSET[1] + (
        y0 + pivot_y * ref_height - REF_ALPHA_BBOX[1]
    ) * REF_SCALE
    return {
        "layer": name,
        "originX": round(origin_x, 3),
        "originY": round(origin_y, 3),
        "positionX": round(position_x, 3),
        "positionY": round(position_y, 3),
        "scaleX": round(scale, 3),
        "scaleY": round(scale, 3),
        "rotation": round(float(placement.get("rotation", 0.0)), 3),
    }


def alpha_composite_at(
    canvas: Image.Image, layer: np.ndarray, match: Match
) -> None:
    resized = Image.fromarray(resize_rgba(layer, match.scale), mode="RGBA")
    canvas.alpha_composite(resized, dest=(match.tx, match.ty))


def warp_reference_to_artboard(image: np.ndarray) -> np.ndarray:
    matrix = np.asarray(
        [
            [REF_SCALE, 0.0, ARTBOARD_OFFSET[0] - REF_ALPHA_BBOX[0] * REF_SCALE],
            [0.0, REF_SCALE, ARTBOARD_OFFSET[1] - REF_ALPHA_BBOX[1] * REF_SCALE],
        ],
        dtype=np.float32,
    )
    return cv2.warpAffine(
        image,
        matrix,
        (420, 560),
        flags=cv2.INTER_LANCZOS4,
        borderMode=cv2.BORDER_CONSTANT,
        borderValue=(0, 0, 0, 0),
    )


def silhouette_iou(first: np.ndarray, second: np.ndarray) -> float:
    first_mask = first[:, :, 3] >= 16
    second_mask = second[:, :, 3] >= 16
    union = np.count_nonzero(first_mask | second_mask)
    if union == 0:
        return 1.0
    return float(np.count_nonzero(first_mask & second_mask) / union)


def centroid(mask: np.ndarray) -> tuple[float, float]:
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return (math.nan, math.nan)
    return (float(xs.mean()), float(ys.mean()))


def centroid_error(first: np.ndarray, second: np.ndarray) -> float:
    first_center = centroid(first[:, :, 3] >= 16)
    second_center = centroid(second[:, :, 3] >= 16)
    return math.dist(first_center, second_center)


def make_diff(reference: Image.Image, fitted: Image.Image) -> Image.Image:
    reference_rgba = reference.convert("RGBA")
    fitted_rgba = fitted.convert("RGBA")
    difference = ImageChops.difference(reference_rgba, fitted_rgba)
    alpha = difference.getchannel("A")
    rgb_difference = difference.convert("RGB")
    luminance = rgb_difference.convert("L")
    alpha = ImageChops.lighter(alpha, luminance)
    red = Image.new("RGBA", reference_rgba.size, (255, 45, 45, 0))
    red.putalpha(alpha)
    return red


def make_silhouette_error(reference: np.ndarray, fitted: np.ndarray) -> Image.Image:
    """Show silhouette agreement (gray), excess (red), and missing (cyan)."""

    reference_mask = reference[:, :, 3] >= 16
    fitted_mask = fitted[:, :, 3] >= 16
    output = np.zeros((*reference_mask.shape, 4), dtype=np.uint8)
    output[reference_mask & fitted_mask] = (82, 82, 88, 255)
    output[fitted_mask & ~reference_mask] = (255, 52, 52, 255)
    output[reference_mask & ~fitted_mask] = (40, 210, 255, 255)
    return Image.fromarray(output, mode="RGBA")


def make_overlay_strip(
    reference: Image.Image, fitted: Image.Image, difference: Image.Image, iou: float
) -> Image.Image:
    panel_width, panel_height = reference.size
    header_height = 42
    strip = Image.new(
        "RGBA", (panel_width * 3, panel_height + header_height), (28, 28, 30, 255)
    )
    strip.alpha_composite(reference, dest=(0, header_height))
    strip.alpha_composite(fitted, dest=(panel_width, header_height))
    strip.alpha_composite(difference, dest=(panel_width * 2, header_height))
    draw = ImageDraw.Draw(strip)
    draw.text((12, 12), "REFERENCE", fill=(255, 255, 255, 255))
    draw.text((panel_width + 12, 12), "FITTED", fill=(255, 255, 255, 255))
    draw.text(
        (panel_width * 2 + 12, 12),
        f"DIFF  IoU={iou:.5f}",
        fill=(255, 255, 255, 255),
    )
    return strip


def write_markdown_table(rows: list[dict[str, float | str]], path: Path) -> None:
    lines = [
        "# DogCompanion Rive transform table",
        "",
        "All scales are uniform: `Scale X == Scale Y`.",
        "",
        "| Layer | Origin X | Origin Y | Position X | Position Y | Scale X | Scale Y | Rotation |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in rows:
        lines.append(
            "| {layer} | {originX:.3f}% | {originY:.3f}% | "
            "{positionX:.3f} | {positionY:.3f} | {scaleX:.3f}% | "
            "{scaleY:.3f}% | {rotation:.3f}° |".format(**row)
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    reference = load_rgba(args.reference)
    search_reference = np.pad(
        reference,
        ((SEARCH_PADDING, SEARCH_PADDING), (SEARCH_PADDING, SEARCH_PADDING), (0, 0)),
        mode="constant",
        constant_values=0,
    )
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    draw_order = manifest["drawOrderBackToFront"]
    pivots = manifest["pivots"]

    placements: dict[str, dict[str, object]] = {}
    matches: dict[str, Match] = {}
    layers: dict[str, np.ndarray] = {}

    for name in draw_order:
        path = args.layers / f"{name}.png"
        layer = load_rgba(path)
        match = fit_layer(
            name,
            search_reference,
            layer,
            coarse_step=args.coarse_step,
            refine_step=args.refine_step,
        )
        matches[name] = match
        layers[name] = layer
        confidence = (
            " LOW_CONFIDENCE"
            if match.raw_score < LOW_CONFIDENCE_THRESHOLD
            else ""
        )
        print(
            f"{name:18s} s={match.scale:.3f} xy=({match.tx:3d},{match.ty:3d}) "
            f"score={match.raw_score:.4f} outside={match.outside_fraction:.3f}{confidence}"
        )

    matches = refine_silhouettes(search_reference, layers, matches)
    for name in draw_order:
        match = matches[name]
        box = content_box(layers[name], match)
        placement: dict[str, object] = {
            "refBox": rounded(box),
            "score": round(match.raw_score, 5),
            "rotation": 0.0,
        }
        if match.raw_score < LOW_CONFIDENCE_THRESHOLD:
            placement["low_confidence"] = True
        placements[name] = placement

    # Preserve every pre-existing contract field and replace/add only placements.
    manifest["placements"] = placements
    if args.write_manifest:
        args.manifest.write_text(
            json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    rows = [rive_values(name, layers[name], placements[name], pivots) for name in draw_order]
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "rive_transform_table.json").write_text(
        json.dumps(rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    write_markdown_table(rows, args.output_dir / "rive_transform_table.md")

    fitted_reference_canvas = Image.new(
        "RGBA", (reference.shape[1], reference.shape[0]), (0, 0, 0, 0)
    )
    for name in draw_order:
        alpha_composite_at(fitted_reference_canvas, layers[name], matches[name])

    fitted_artboard_array = warp_reference_to_artboard(
        np.asarray(fitted_reference_canvas, dtype=np.uint8)
    )
    reference_artboard_array = warp_reference_to_artboard(reference)
    fitted_artboard = Image.fromarray(fitted_artboard_array, mode="RGBA")
    reference_artboard = Image.fromarray(reference_artboard_array, mode="RGBA")
    difference = make_diff(reference_artboard, fitted_artboard)
    silhouette_error = make_silhouette_error(
        reference_artboard_array, fitted_artboard_array
    )
    iou = silhouette_iou(reference_artboard_array, fitted_artboard_array)
    global_centroid_error = centroid_error(reference_artboard_array, fitted_artboard_array)
    overlay = make_overlay_strip(reference_artboard, fitted_artboard, difference, iou)

    reference_artboard.save(args.output_dir / "reference_420x560.png", optimize=True)
    fitted_artboard.save(args.output_dir / "fitted_420x560.png", optimize=True)
    difference.save(args.output_dir / "diff_420x560.png", optimize=True)
    silhouette_error.save(
        args.output_dir / "silhouette_error_420x560.png", optimize=True
    )
    overlay.save(args.output_dir / "overlay_reference_fitted_diff.png", optimize=True)
    verification = {
        "silhouetteIoU": round(iou, 6),
        "globalCentroidErrorPx": round(global_centroid_error, 6),
        "thresholds": {"silhouetteIoU": 0.95, "centroidErrorPx": 2.0},
        "passes": {
            "silhouetteIoU": iou >= 0.95,
            "globalCentroidError": global_centroid_error <= 2.0,
        },
    }
    (args.output_dir / "verification.json").write_text(
        json.dumps(verification, indent=2) + "\n", encoding="utf-8"
    )

    print("\nRive values")
    for row in rows:
        print(
            "{layer:18s} origin=({originX:7.3f},{originY:7.3f}) "
            "position=({positionX:8.3f},{positionY:8.3f}) "
            "scale={scaleX:7.3f} rotation={rotation:.3f}".format(**row)
        )
    print(f"\nSilhouette IoU: {iou:.6f}")
    print(f"Global centroid error: {global_centroid_error:.3f}px")
    return 0


if __name__ == "__main__":
    sys.exit(main())
