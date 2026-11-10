"""Read-only check that saved anatomy and wardrobe Blender files open as scenes."""
import bpy
import os

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
anatomy=os.path.join(ROOT,'assets','characters','male_mannequin','source','male_mannequin.blend')
bpy.ops.wm.open_mainfile(filepath=anatomy)
body=bpy.data.objects['MaleMannequinBody']
assert len(body.data.vertices)==13380
assert any(mod.type=='SUBSURF' and mod.levels==2 for mod in body.modifiers)
assert set(o.name for o in bpy.context.scene.objects)=={'MaleMannequinBody','MannequinRig','MannequinEye.R','MannequinEye.L'}
assert all(im.type=='RENDER_RESULT' or im.users==0 for im in bpy.data.images)
items={'field_jacket':'Jacket','collar_and_underlayer':'Neckwear','cargo_trousers':'Trousers','boots':'Boots','gloves':'Gloves','belt_and_strap':'Equipment','shoulder_bag':'Satchel','flashlight':'Flashlight'}
for filename,object_name in items.items():
    bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,'assets','characters','wardrobe','source',filename+'.blend'))
    assert set(o.name for o in bpy.context.scene.objects)=={'ScavengerRig',object_name},filename
    obj=bpy.data.objects[object_name]
    assert obj.type=='MESH' and any(m.type=='ARMATURE' for m in obj.modifiers)
print('SEPARATED_BLENDER_SOURCES_CHECK: continuous anatomy and eight standalone garment scenes passed')
