#!/usr/bin/env python3
"""Pose timelines and the Companion state machine, shared by every pet.

Two things make companion motion read well at the size it is actually shown
(~220px in a header) rather than looking frantic:

**Pivots.** A Rive image rotates about its own centre, so rotating an ear swings
it off the skull. Each rotating part is therefore parented to a `node` placed at
its anatomical joint, with the image offset underneath; the node is what the
timelines rotate.

**Restraint.** Amplitudes here are single-digit pixels and single-digit degrees.
A companion sitting beside study and budgeting screens should read as calm and
alive, not as a performance competing with the content. Idle in particular is
meant to be almost subliminal — you notice it stopped, not that it started.
"""

from __future__ import annotations

import math

FPS = 60

# state input value per pose -- fixed by PetAnimationState's declaration order.
POSES = ["idle", "celebrate", "think", "sleep", "victory", "happy"]

# Persistent states hold until the app changes `state`; the rest are momentary
# reactions that settle back to idle.
LOOPING = {"idle", "think", "sleep"}

# Where each part rotates from, as a fraction of its own box. Ears hinge near the
# top where they meet the skull, the tail at its base, the head at the neck.
JOINTS = {
    "ear_left": (0.62, 0.14),
    "ear_right": (0.38, 0.14),
    "tail": (0.76, 0.86),
    "head": (0.50, 0.90),
}

REST = "rest"


def joint_children(
    layers: list[dict], sizes: dict[str, tuple[int, int]]
) -> tuple[list[dict], dict[str, tuple[float, float]]]:
    """Wrap rotating layers in a node at their joint; pass the rest through.

    `layers` are dicts of name/x/y in artboard space, front-to-back. `sizes` maps
    a layer to its on-artboard pixel size. Returns the children and where each
    joint node ended up -- timelines that move a joint must key it from that
    position, since a keyframe on `y` replaces the node's own y rather than
    offsetting it.
    """
    out: list[dict] = []
    joints: dict[str, tuple[float, float]] = {}
    for layer in layers:
        name = layer["name"]
        image = {"type": "image", "name": name, "asset": layer.get("asset", f"{name}_a")}
        joint = JOINTS.get(name)
        if not joint:
            out.append({**image, "x": layer["x"], "y": layer["y"]})
            continue
        width, height = sizes[name]
        # Joint position in artboard space, then the image offset that puts its
        # centre back where it was.
        jx = layer["x"] + (joint[0] - 0.5) * width
        jy = layer["y"] + (joint[1] - 0.5) * height
        joints[name] = (jx, jy)
        out.append(
            {
                "type": "node",
                "name": f"{name}_joint",
                "x": jx,
                "y": jy,
                "children": [{**image, "x": layer["x"] - jx, "y": layer["y"] - jy}],
            }
        )
    return out, joints


def _track(target: str, prop: str, frames: list[tuple[int, float]]) -> dict:
    return {"object": target, "property": prop, "frames": [{"frame": f, "value": v} for f, v in frames]}


def build_animations(
    pos: dict[str, tuple[float, float]],
    present: set[str],
    joints: dict[str, tuple[float, float]] | None = None,
) -> list[dict]:
    """The six poses plus a motionless `rest` for reducedMotion."""

    def rotates(name: str) -> str | None:
        return f"{name}_joint" if name in present and name in JOINTS else None

    anchors = joints or {}

    def shift(name: str, dy: float, frames: list[int], curve: list[float]) -> list[dict]:
        if name not in present:
            return []
        target = rotates(name)
        # A keyframe on `y` sets the value outright, so the baseline has to be
        # whatever that object already sits at -- the joint node's own y when the
        # part is wrapped, the image's otherwise.
        base = anchors[name][1] if target else pos[name][1]
        return [_track(target or name, "y", [(f, base + dy * c) for f, c in zip(frames, curve)])]

    def turn(name: str, deg: float, frames: list[int], curve: list[float]) -> list[dict]:
        # Rive stores rotation in radians. Authoring in degrees and converting
        # here is the difference between a 2 degree head tilt and a 2 radian one,
        # which is what made an early pass of these poses look unusable.
        target = rotates(name)
        if not target:
            return []
        rad = math.radians(deg)
        return [_track(target, "rotation", [(f, rad * c) for f, c in zip(frames, curve)])]

    def breathe(span: int, amount: float) -> list[dict]:
        if "torso" not in present:
            return []
        return [_track("torso", "scale_y", [(0, 1.0), (span // 2, 1.0 + amount), (span - 1, 1.0)])]

    def eyes_shut() -> list[dict]:
        out = []
        for eye in ("eye_left", "eye_right"):
            if eye in present:
                out.append(_track(eye, "scale_y", [(0, 1.0), (12, 0.08), (168, 0.08), (179, 1.0)]))
        return out

    specs: dict[str, tuple[int, list[dict]]] = {}

    # Idle: two-second breath. Deliberately almost subliminal.
    f = [0, 60, 119]
    specs["idle"] = (
        120,
        breathe(120, 0.008)
        + shift("head", 1.5, f, [0, 1, 0])
        + turn("ear_left", 1.5, f, [0, 1, 0])
        + turn("ear_right", -1.5, f, [0, 1, 0])
        + turn("tail", 2.0, [0, 30, 60, 90, 119], [0, 1, 0, -1, 0]),
    )

    # Happy: a quick, small acknowledgement of a tap.
    f = [0, 12, 30, 44]
    specs["happy"] = (
        45,
        shift("head", -4.0, f, [0, 1, 0.3, 0])
        + turn("tail", 8.0, [0, 11, 22, 33, 44], [0, 1, -1, 1, 0])
        + turn("ear_left", -2.5, f, [0, 1, 0.3, 0])
        + turn("ear_right", 2.5, f, [0, 1, 0.3, 0]),
    )

    # Celebrate: a settled double bounce, still modest.
    f = [0, 16, 34, 50, 74]
    specs["celebrate"] = (
        75,
        shift("head", -6.0, f, [0, 1, 0.35, 0.7, 0])
        + turn("tail", 10.0, [0, 14, 28, 42, 56, 74], [0, 1, -1, 1, -0.5, 0])
        + turn("ear_left", -3.0, f, [0, 1, 0.4, 0.7, 0])
        + turn("ear_right", 3.0, f, [0, 1, 0.4, 0.7, 0]),
    )

    # Victory: the largest of the reactions, and still under ten pixels.
    f = [0, 18, 38, 56, 89]
    specs["victory"] = (
        90,
        shift("head", -8.0, f, [0, 1, 0.3, 0.75, 0])
        + turn("tail", 12.0, [0, 15, 30, 45, 60, 89], [0, 1, -1, 1, -0.6, 0])
        + turn("ear_left", -4.0, f, [0, 1, 0.35, 0.75, 0])
        + turn("ear_right", 4.0, f, [0, 1, 0.35, 0.75, 0]),
    )

    # Think: a slow head tilt that holds, for loading and deliberation.
    f = [0, 30, 60, 89]
    specs["think"] = (
        90,
        turn("head", 2.5, f, [0, 1, 1, 0])
        + shift("head", 1.5, f, [0, 1, 1, 0])
        + turn("ear_left", 5.0, f, [0, 1, 1, 0])
        + breathe(90, 0.006),
    )

    # Sleep: eyes shut, head lowered, a slower breath. Persistent.
    f = [0, 40, 140, 179]
    specs["sleep"] = (
        180,
        eyes_shut()
        + shift("head", 5.0, f, [0, 1, 1, 0])
        + turn("ear_left", 3.0, f, [0, 1, 1, 0])
        + turn("ear_right", -3.0, f, [0, 1, 1, 0])
        + breathe(180, 0.010),
    )

    animations = [
        {
            "name": name,
            "fps": FPS,
            "duration": span,
            "loop_type": "loop" if name in LOOPING else "oneshot",
            "keyframes": tracks,
        }
        for name, (span, tracks) in ((p, specs[p]) for p in POSES)
    ]
    # A single motionless frame. reducedMotion parks here rather than playing a
    # slower version of anything.
    animations.append(
        {"name": REST, "fps": FPS, "duration": 1, "loop_type": "loop", "keyframes": []}
    )
    return animations


def build_state_machine() -> dict:
    """`state` selects a pose; `reducedMotion` overrides everything to `rest`."""
    idle_at = 2
    rest_at = idle_at + len(POSES)
    states = [{"type": "entry"}, {"type": "exit"}]
    states += [{"type": "animation", "animation": p} for p in POSES]
    states += [{"type": "animation", "animation": REST}]

    still = {"input": "reducedMotion", "op": "==", "value": False}
    transitions = [{"from": 0, "to": idle_at}]
    for index, pose in enumerate(POSES[1:], start=1):
        node = idle_at + index
        transitions.append(
            {
                "from": idle_at,
                "to": node,
                "conditions": [{"input": "state", "op": "==", "value": float(index)}, still],
            }
        )
        transitions.append(
            {"from": node, "to": idle_at, "conditions": [{"input": "state", "op": "==", "value": 0.0}]}
        )
        # Anything in motion yields immediately when accessibility asks it to.
        transitions.append(
            {
                "from": node,
                "to": rest_at,
                "conditions": [{"input": "reducedMotion", "op": "==", "value": True}],
            }
        )
    transitions.append(
        {
            "from": idle_at,
            "to": rest_at,
            "conditions": [{"input": "reducedMotion", "op": "==", "value": True}],
        }
    )
    transitions.append({"from": rest_at, "to": idle_at, "conditions": [still]})

    return {
        "name": "Companion",
        "inputs": [
            {"type": "number", "name": "state", "value": 0.0},
            {"type": "bool", "name": "reducedMotion", "value": False},
            {"type": "bool", "name": "interacting", "value": False},
        ],
        "layers": [{"states": states, "transitions": transitions}],
    }
