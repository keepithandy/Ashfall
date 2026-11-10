#!/usr/bin/env python3
"""Upgrade Ashfall GLBs with original, tileable procedural PBR surface maps.

Does not change geometry or any Godot game scripts. UVs and 128px color,
normal, metallic/roughness textures are embedded in each self-contained GLB.
Deterministic and idempotent; no third-party materials or external licensing.
These maps are technical art prototypes and still require human art sign-off.
"""
import hashlib
import io
import json
import math
import random
import struct
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
PACKS = ("decorative_world", "decorative_interiors")
SIZE = 128


def align(data):
    while len(data) % 4:
        data.append(0)


def noise(seed, edge):
    rnd = random.Random(seed ^ (edge * 26717))
    base = Image.new("L", (edge, edge))
    base.putdata([rnd.randint(0, 255) for _ in range(edge * edge)])
    return list(base.resize((SIZE, SIZE), Image.Resampling.BICUBIC).getdata())


def images_for(material, base_factor, original_roughness, original_metal):
    key = material.lower()
    seed = int.from_bytes(hashlib.sha256(key.encode()).digest()[:8], "little")
    layers = [noise(seed, size) for size in (4, 12, 32, 64)]
    wood = any(k in key for k in ("wood", "splinter", "bark", "rott", "cardboard"))
    metal = any(k in key for k in ("rust", "iron", "steel", "galvan", "metal", "bolt", "brass", "copper", "oxid", "paint"))
    cloth = any(k in key for k in ("cloth", "canvas", "fabric", "fray", "worn", "faded"))
    concrete = any(k in key for k in ("concrete", "stone", "plaster", "damp", "grime", "dirt", "moss"))
    base_rgb = [int(255.0 * (max(.0, min(1.0, float(v))) ** (1.0 / 2.2))) for v in base_factor[:3]]
    rnd = random.Random(seed + 109)
    stripe_shift = [rnd.uniform(-3, 3) for _ in range(SIZE)]
    heights = []
    albedo = bytearray()
    rm = bytearray()
    for y in range(SIZE):
        for x in range(SIZE):
            i = y * SIZE + x
            cloud = (.42 * layers[0][i] + .27 * layers[1][i] + .22 * layers[2][i] + .09 * layers[3][i]) / 255.0
            grit = (layers[3][i] - 127.5) / 127.5
            value = cloud - .5
            if wood:
                grain = math.sin((y + stripe_shift[x] + .7 * layers[1][i] / 255) * 1.20)
                variation = value * .30 + grain * .09 + grit * .024
                h = cloud * .35 + grain * .12 + grit * .05
            elif metal:
                scratch = math.sin(x * 2.31 + y * .09)
                corrode = max(0, cloud - .52) if ("rust" in key or "oxid" in key) else 0
                variation = value * .28 - corrode * .20 + scratch * .022
                h = cloud * .42 + scratch * .03
            elif cloth:
                weave = (math.sin(x * 1.72) + math.sin(y * 1.77)) * .038
                variation = value * .18 + weave
                h = cloud * .19 + weave * .4
            elif concrete:
                speck = grit * .055
                variation = value * .27 + speck
                h = cloud * .42 + speck
            else:
                variation = value * .18 + grit * .015
                h = cloud * .22 + grit * .03
            heights.append(h)
            tint = [1.0, 1.0, 1.0]
            if metal and ("rust" in key or "oxid" in key):
                tint = [1.08 + value * .17, .91 - value * .08, .83 - value * .14]
            if concrete and cloud < .33:
                tint = [.88, .92, .87]
            for c in range(3):
                q = base_rgb[c] * (1.0 + variation) * tint[c]
                albedo.append(int(max(0, min(255, q))))
            roughness = max(.12, min(1.0, original_roughness * (0.9 + .15 * cloud)))
            metallness = max(0.0, min(1.0, original_metal * (0.93 + .10 * cloud)))
            rm.extend((255, int(roughness * 255), int(metallness * 255)))
    normals = bytearray()
    for y in range(SIZE):
        for x in range(SIZE):
            h_l = heights[y * SIZE + (x - 1) % SIZE]
            h_r = heights[y * SIZE + (x + 1) % SIZE]
            h_u = heights[((y - 1) % SIZE) * SIZE + x]
            h_d = heights[((y + 1) % SIZE) * SIZE + x]
            dx, dy = (h_l - h_r) * 1.6, (h_u - h_d) * 1.6
            nx, ny, nz = dx, dy, 1.
            length = math.sqrt(nx*nx + ny*ny + nz*nz)
            normals.extend(int(max(0,min(255, 127.5 * (v / length + 1.)))) for v in (nx, ny, nz))
    def png_bytes(raw):
        image = Image.frombytes("RGB", (SIZE, SIZE), bytes(raw))
        out = io.BytesIO()
        image.save(out, format="PNG", optimize=True)
        return out.getvalue()
    return png_bytes(albedo), png_bytes(normals), png_bytes(rm)


def transform(path):
    data = path.read_bytes()
    if len(data) < 28 or data[:4] != b"glTF":
        raise ValueError(f"Invalid GLB {path}")
    json_len, json_type = struct.unpack_from("<II", data, 12)
    if json_type != 0x4E4F534A:
        raise ValueError(f"No JSON chunk: {path}")
    doc = json.loads(data[20:20+json_len].decode("utf8").rstrip(" "))
    if doc.get("asset", {}).get("extras", {}).get("ashfall_surface_revision") == 1:
        return False
    oldoffset = 20+json_len
    binlen, bintype = struct.unpack_from("<II", data, oldoffset)
    if bintype != 0x004E4942:
        raise ValueError(f"No BIN chunk: {path}")
    oldbin = bytes(data[oldoffset+8:oldoffset+8+binlen])
    binary = bytearray(oldbin)
    views = doc["bufferViews"]
    accessors = doc["accessors"]
    images = doc.setdefault("images", [])
    textures = doc.setdefault("textures", [])
    samplers = doc.setdefault("samplers", [])
    sample_index = len(samplers)
    samplers.append({"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497})
    def append_bytes(content, target=None):
        align(binary)
        off = len(binary)
        binary.extend(content)
        entry = {"buffer": 0, "byteOffset": off, "byteLength": len(content)}
        if target is not None:
            entry["target"] = target
        index = len(views)
        views.append(entry)
        return index
    def png_texture(blob):
        index = len(images)
        images.append({"bufferView": append_bytes(blob), "mimeType": "image/png"})
        tindex = len(textures)
        textures.append({"sampler": sample_index, "source": index})
        return tindex
    for material in doc["materials"]:
        if material.get("alphaMode", "OPAQUE") != "OPAQUE":
            continue  # Preserve existing transparent glass.
        pbr = material["pbrMetallicRoughness"]
        color = list(pbr.get("baseColorFactor", [1.,1.,1.,1.]))
        roughness = float(pbr.get("roughnessFactor", 1.0))
        metal = float(pbr.get("metallicFactor", 0.0))
        c, n, mr = images_for(material.get("name", "surface"), color, roughness, metal)
        pbr["baseColorTexture"] = {"index": png_texture(c), "texCoord": 0}
        material["normalTexture"] = {"index": png_texture(n), "texCoord": 0, "scale": 0.65}
        pbr["metallicRoughnessTexture"] = {"index": png_texture(mr), "texCoord": 0}
        pbr["baseColorFactor"] = [1.,1.,1., color[3]]
        pbr["roughnessFactor"] = 1.0
        pbr["metallicFactor"] = 1.0
        material.setdefault("extras", {})["originalPBR"] = {"color": color, "roughness": roughness, "metallic": metal}
    for mesh in doc["meshes"]:
        for primitive in mesh["primitives"]:
            attrs = primitive["attributes"]
            if "TEXCOORD_0" in attrs:
                continue
            pacc = accessors[attrs["POSITION"]]
            nacc = accessors[attrs["NORMAL"]]
            if pacc["componentType"] != 5126 or nacc["componentType"] != 5126:
                raise ValueError(f"Expected float32 positions/normals in {path}")
            pv = views[pacc["bufferView"]]
            nv = views[nacc["bufferView"]]
            po = pv.get("byteOffset", 0) + pacc.get("byteOffset", 0)
            no = nv.get("byteOffset", 0) + nacc.get("byteOffset", 0)
            count = pacc["count"]
            uvbytes = bytearray()
            for i in range(count):
                x,y,z = struct.unpack_from("<fff", oldbin, po + i*12)
                nx,ny,nz = struct.unpack_from("<fff", oldbin, no + i*12)
                ax,ay,az = abs(nx),abs(ny),abs(nz)
                if ay >= ax and ay >= az:
                    u,v=x*1.7,z*1.7
                elif ax >= az:
                    u,v=z*1.7,y*1.7
                else:
                    u,v=x*1.7,y*1.7
                uvbytes.extend(struct.pack("<ff", u,v))
            offset_idx = append_bytes(uvbytes, target=34962)
            uv_idx = len(accessors)
            accessors.append({"bufferView":offset_idx,"componentType":5126,"count":count,"type":"VEC2"})
            attrs["TEXCOORD_0"] = uv_idx
    doc["buffers"][0]["byteLength"] = len(binary)
    doc["asset"].setdefault("extras", {})["ashfall_surface_revision"] = 1
    text=json.dumps(doc,separators=(",",":")).encode("utf8")
    jsonpad = b" " * ((4-len(text)%4)%4)
    align(binary)
    final=bytearray(12+8+len(text)+len(jsonpad)+8+len(binary))
    struct.pack_into("<III",final,0,0x46546C67,2,len(final))
    struct.pack_into("<II",final,12,len(text)+len(jsonpad),0x4E4F534A)
    final[20:20+len(text)] = text
    final[20+len(text):20+len(text)+len(jsonpad)] = jsonpad
    offset=20+len(text)+len(jsonpad)
    struct.pack_into("<II",final,offset,len(binary),0x004E4942)
    final[offset+8:] = binary
    path.write_bytes(final)
    print(f"TEXTURED {path.relative_to(ROOT)} {len(oldbin)} -> {len(binary)} binary bytes")
    return True


if __name__ == "__main__":
    count=0
    for pack in PACKS:
        for path in sorted((ROOT/"assets"/pack/"models").glob("*.glb")):
            count += int(transform(path))
    print(f"Upgraded {count} GLBs. Original assets preserved on previous Git commit.")
