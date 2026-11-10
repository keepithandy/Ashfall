import bpy, pathlib, math
from mathutils import Vector
root=pathlib.Path(__file__).parent
for ident in ['service_pistol']:
    f=next((root/'sources'/ident).glob('*.blend'))
    bpy.ops.wm.open_mainfile(filepath=str(f),load_ui=False)
    sc=bpy.context.scene
    objects=[o for o in sc.objects if o.type=='MESH']
    pts=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
    low=Vector([min(v[i] for v in pts) for i in range(3)])
    high=Vector([max(v[i] for v in pts) for i in range(3)])
    center=(low+high)/2; span=max(high-low)
    for o in list(sc.objects):
        if o.type in ['CAMERA','LIGHT']: bpy.data.objects.remove(o,do_unlink=True)
    bpy.ops.object.camera_add(location=center+Vector((span*.2,-span*2,span*.8)))
    cam=bpy.context.object; cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO';cam.data.ortho_scale=span*2.1;sc.camera=cam
    for pos,power in [((1,-2,3),700),((-2,-1,1),450)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(pos)*span)
        light=bpy.context.object;light.data.energy=power*span*span;light.data.shape='DISK';light.data.size=span*3;light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
    sc.world=bpy.data.worlds.new('ReviewWorld');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.18,.19,.20,1)
    sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=16
    sc.render.resolution_x=1200;sc.render.resolution_y=700;sc.render.resolution_percentage=100
    sc.render.filepath=str(root/(ident+'-source-review.png'));sc.render.image_settings.file_format='PNG'
    bpy.ops.render.render(write_still=True)
