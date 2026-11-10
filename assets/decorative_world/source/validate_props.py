"""Check that every Ashfall decorative prop is a valid glTF 2.0 GLB plus a static Godot scene."""
import json
import math
import struct
import sys
from pathlib import Path

NAMES = [
    "bent_guardrail", "collapsed_bus_shelter", "discarded_tire_pile", "fallen_utility_pole",
    "rusted_mailbox", "sagging_porch_chair", "cracked_plant_pots", "torn_clothesline",
    "crushed_ventilation_duct", "collapsed_cable_tray", "corroded_sheet_metal_stack",
    "broken_factory_window", "rotting_picnic_table", "damaged_footbridge_fragment",
    "roadside_memorial", "broken_drainage_culvert",
]
ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / "assets" / "decorative_world" / "models"
SCENES = ROOT / "scenes" / "decorative_world"


def check_glb(path):
    data = path.read_bytes()
    if len(data) < 28:
        raise ValueError("GLB too short")
    magic, version, file_length = struct.unpack_from("<III", data, 0)
    if (magic, version, file_length) != (0x46546C67, 2, len(data)):
        raise ValueError("Invalid glTF envelope")
    json_length, chunk_type = struct.unpack_from("<II", data, 12)
    if chunk_type != 0x4E4F534A or json_length % 4:
        raise ValueError("Invalid JSON chunk header")
    obj = json.loads(data[20:20 + json_length].decode("utf8").rstrip(" "))
    offset = 20 + json_length
    if offset + 8 > len(data):
        raise ValueError("Missing BIN chunk")
    binary_length, binary_type = struct.unpack_from("<II", data, offset)
    if binary_type != 0x004E4942 or binary_length % 4 or offset + 8 + binary_length != len(data):
        raise ValueError("Invalid BIN chunk")
    if obj.get("asset", {}).get("version") != "2.0":
        raise ValueError("glTF 2.0 required")
    if len(obj.get("buffers", [])) != 1 or obj["buffers"][0]["byteLength"] > binary_length:
        raise ValueError("Invalid buffer declaration")
    views = obj.get("bufferViews", [])
    for view in views:
        start, size = view.get("byteOffset", 0), view["byteLength"]
        if start < 0 or size <= 0 or start + size > binary_length or start % 4:
            raise ValueError("Invalid buffer view offset/size")
    accessors = obj.get("accessors", [])
    for acc in accessors:
        if acc["bufferView"] >= len(views):
            raise ValueError("Bad accessor buffer view reference")
        if acc.get("componentType") != 5126 or acc.get("type") != "VEC3" or acc["count"] <= 0:
            raise ValueError("Invalid position or normal accessor")
        if any(not math.isfinite(v) for v in acc.get("min", []) + acc.get("max", [])):
            raise ValueError("Non-finite bounds")
    if not obj.get("meshes") or not obj.get("materials"):
        raise ValueError("Missing mesh or material")
    triangles = 0
    for mesh in obj["meshes"]:
        for primitive in mesh["primitives"]:
            i = primitive["attributes"]["POSITION"]
            j = primitive["attributes"]["NORMAL"]
            if i >= len(accessors) or j >= len(accessors):
                raise ValueError("Missing primitive accessor")
            pa, na = accessors[i], accessors[j]
            if primitive.get("mode", 4) != 4 or pa["count"] != na["count"] or pa["count"] % 3:
                raise ValueError("Invalid primitive triangle count")
            if primitive.get("material", 0) >= len(obj["materials"]):
                raise ValueError("Material index out of range")
            triangles += pa["count"] // 3
    if not 20 <= triangles <= 20000:
        raise ValueError(f"Unexpected triangle count: {triangles}")
    return triangles


def validate():
    if {f.stem for f in ASSETS.glob("*.glb")} != set(NAMES):
        raise ValueError("The model set is incomplete or unexpected")
    total = 0
    for name in NAMES:
        scene_path = SCENES / f"{name}.tscn"
        if not scene_path.is_file():
            raise ValueError(f"Missing scene: {scene_path}")
        text = scene_path.read_text("utf8")
        if f"res://assets/decorative_world/models/{name}.glb" not in text:
            raise ValueError(f"Incorrect GLB reference: {scene_path}")
        if 'type="StaticBody3D"' not in text or 'type="CollisionShape3D"' not in text:
            raise ValueError(f"No static collider: {scene_path}")
        forbidden = ['type="Area3D"', 'type="RigidBody3D"', 'type="Script"', "script =", 'type="AnimationPlayer"']
        if any(fragment in text for fragment in forbidden):
            raise ValueError(f"Interactive content forbidden in {scene_path}")
        triangles = check_glb(ASSETS / f"{name}.glb")
        total += triangles
        print(f"OK {name}: {triangles} triangles")
    gallery = (SCENES / "gallery_all_16.tscn").read_text("utf8")
    if gallery.count('type="Label3D"') != 16:
        raise ValueError("Gallery labels missing")
    for name in NAMES:
        if f"res://scenes/decorative_world/{name}.tscn" not in gallery:
            raise ValueError(f"Gallery missing prop: {name}")
    print(f"PASS: {len(NAMES)} static decorative props; {total} triangles")


if __name__ == "__main__":
    try:
        validate()
    except (OSError, ValueError, KeyError, IndexError, UnicodeError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        sys.exit(1)
