"""Validate static decorative-interior models and their Godot scenes.

No Godot editor needed for this structural check. The CI workflow separately imports
and instantiates the pack in Godot.
"""
import runpy
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
NAMES = (
    "sagging_sofa", "battered_armchair", "cracked_crt_television",
    "crooked_wall_mirror", "splintered_dining_table", "damaged_kitchen_cupboard",
    "broken_crockery_scatter", "rusted_enamel_kettle", "tilted_wooden_dresser",
    "torn_interior_curtains", "threadbare_area_rug", "faded_photo_frames",
    "fallen_ceiling_tile_pile", "broken_ceiling_fan",
    "peeling_wallpaper_panels", "dusty_cardboard_box_stack",
    "sagging_sofa_torn",
)
MODEL_DIR = ROOT / "assets" / "decorative_interiors" / "models"
SCENE_DIR = ROOT / "scenes" / "decorative_interiors"
OLD_CHECKER = ROOT / "assets" / "decorative_world" / "source" / "validate_props.py"


def check() -> None:
    checker = runpy.run_path(str(OLD_CHECKER))["check_glb"]
    glbs = {p.stem for p in MODEL_DIR.glob("*.glb")}
    if glbs != set(NAMES):
        raise ValueError(f"Unexpected model set; missing={set(NAMES)-glbs}; extra={glbs-set(NAMES)}")

    total = 0
    for name in NAMES:
        model = MODEL_DIR / f"{name}.glb"
        scene = SCENE_DIR / f"{name}.tscn"
        if not scene.exists():
            raise ValueError(f"Missing Godot scene: {name}")
        text = scene.read_text(encoding="utf-8")
        if f"res://assets/decorative_interiors/models/{name}.glb" not in text:
            raise ValueError(f"Incorrect GLB ref: {name}")
        if 'type="StaticBody3D"' not in text or 'type="CollisionShape3D"' not in text:
            raise ValueError(f"Static-body or collision definition missing: {name}")
        forbidden = ('type="Area3D"', 'type="RigidBody3D"', 'type="Script"', 'script =', 'type="AnimationPlayer"')
        if any(value in text for value in forbidden):
            raise ValueError(f"Interactive element forbidden: {name}")
        tris = checker(model)
        print(f"PASS: {name} — {tris} triangles")
        total += tris

    gallery = (SCENE_DIR / "gallery_all_16.tscn").read_text(encoding="utf-8")
    if gallery.count('type="Label3D"') != len(NAMES):
        raise ValueError("Gallery should label 16 props plus the sofa damage variant")
    for name in NAMES:
        if f"res://scenes/decorative_interiors/{name}.tscn" not in gallery:
            raise ValueError(f"Gallery missing {name}")
    print(f"PASS: 16 unique interior assets + 1 variant; {total} triangles")


if __name__ == "__main__":
    try:
        check()
    except Exception as err:
        print(f"FAIL: {err}", file=sys.stderr)
        sys.exit(1)
