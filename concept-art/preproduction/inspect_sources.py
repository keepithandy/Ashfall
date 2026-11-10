import bpy, json, pathlib
from mathutils import Vector
root=pathlib.Path(__file__).parent/'sources'
reports=[]
for f in sorted(root.glob('*/*.blend')):
    try:
        bpy.ops.wm.open_mainfile(filepath=str(f), load_ui=False)
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        pts=[o.matrix_world @ Vector(v) for o in meshes for v in o.bound_box]
        dims=[max(p[i] for p in pts)-min(p[i] for p in pts) for i in range(3)] if pts else []
        missing=[im.filepath for im in bpy.data.images if im.source=='FILE' and not im.packed_file and not pathlib.Path(bpy.path.abspath(im.filepath)).exists()]
        reports.append(dict(asset=f.parent.name,source=f.name,dimensions_scene_units=dims,unit_scale=bpy.context.scene.unit_settings.scale_length,mesh_objects=len(meshes),polygons=sum(len(o.data.polygons) for o in meshes),armatures=sum(o.type=='ARMATURE' for o in bpy.context.scene.objects),actions=len(bpy.data.actions),missing_images=missing,objects=[dict(name=o.name,dimensions=list(o.dimensions)) for o in meshes]))
    except Exception as e: reports.append(dict(asset=f.parent.name,error=str(e)))
(root/'inspection.json').write_text(json.dumps(reports,indent=2))
print('INSPECTED',len(reports),'sources')
