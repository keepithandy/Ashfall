import bpy, math, os
import numpy as np
from mathutils import Vector
from mathutils.geometry import intersect_point_line

OUT=os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT,exist_ok=True)
import tempfile
tempfile.tempdir=os.path.join(OUT,'export_temp')
os.makedirs(tempfile.tempdir,exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def texture(name, base, grain, weave=False):
    n=1024
    rng=np.random.default_rng(428 if weave else 731)
    y,x=np.mgrid[0:n,0:n]
    detail=rng.random((n,n)).astype(np.float32)-.5
    broad=(np.sin(x*.023)*np.cos(y*.017)+np.sin((x+y)*.008))*.035
    threads=(np.sin(x*math.pi)*0 if not weave else (np.sin(x*2.1)*np.sin(y*2.1)*.025))
    value=np.clip(1+detail*grain+broad+threads,.45,1.4)
    pixels=np.ones((n,n,4),dtype=np.float32)
    pixels[:,:,:3]=np.array(base)[None,None,:]*value[:,:,None]
    im=bpy.data.images.new(name,n,n)
    im.pixels.foreach_set(pixels.ravel())
    im.filepath_raw=os.path.join(OUT,name+'.png'); im.file_format='PNG'; im.save()
    return im

def mat(name,color,rough=.65,metal=0, image=None):
    m=bpy.data.materials.new(name); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Roughness'].default_value=rough
    p.inputs['Metallic'].default_value=metal
    if image:
        tex=m.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=image
        m.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
    return m

def surface_maps(material,name,cloth=False):
    n=1024
    y,x=np.mgrid[0:n,0:n]
    rng=np.random.default_rng(912 if cloth else 317)
    if cloth:
        height=.08*np.sin(x*1.4)+.08*np.sin(y*1.4)+.025*np.sin((x+y)*2.8)
        height+=rng.normal(0,.018,(n,n))
    else:
        height=rng.normal(0,.08,(n,n))+.045*np.sin(x*.18+np.sin(y*.07)*2)
    gy,gx=np.gradient(height)
    normal=np.stack([-gx*1.8,-gy*1.8,np.ones_like(gx)],axis=-1)
    normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
    pixels=np.ones((n,n,4),dtype=np.float32);pixels[:,:,:3]=normal*.5+.5
    im=bpy.data.images.new(name+'_normal',n,n)
    im.colorspace_settings.name='Non-Color';im.pixels.foreach_set(pixels.ravel())
    im.filepath_raw=os.path.join(OUT,name+'_normal.png');im.file_format='PNG';im.save()
    nodes=material.node_tree.nodes;links=material.node_tree.links
    tex=nodes.new('ShaderNodeTexImage');tex.image=im
    normalnode=nodes.new('ShaderNodeNormalMap');normalnode.inputs['Strength'].default_value=.55
    links.new(tex.outputs['Color'],normalnode.inputs['Color'])
    links.new(normalnode.outputs['Normal'],nodes.get('Principled BSDF').inputs['Normal'])
    rough=np.ones((n,n,4),dtype=np.float32)
    values=np.clip((.88 if cloth else .68)+rng.normal(0,.055,(n,n))+.055*np.sin(x*.028)*np.sin(y*.018),.38,.98)
    rough[:,:,:3]=values[:,:,None]
    rim=bpy.data.images.new(name+'_roughness',n,n)
    rim.colorspace_settings.name='Non-Color';rim.pixels.foreach_set(rough.ravel())
    rim.filepath_raw=os.path.join(OUT,name+'_roughness.png');rim.file_format='PNG';rim.save()
    rtex=nodes.new('ShaderNodeTexImage');rtex.image=rim
    links.new(rtex.outputs['Color'],nodes.get('Principled BSDF').inputs['Roughness'])

cloth=mat('Faded olive canvas',(.22,.25,.17),.93,image=texture('olive_canvas',(.20,.225,.165),.24,True))
leather=mat('Worn brown glove leather',(.12,.10,.075),.75,image=texture('glove_leather',(.21,.165,.115),.28))
seam=mat('Dark linen stitching',(.025,.023,.018),.93)
cuffmat=mat('Ribbed cuff',(.025,.032,.018),.96)
steel=mat('Patinated flashlight steel',(.035,.042,.036),.55,.65)
edge=mat('Exposed worn metal',(.3,.32,.29),.32,.85)
rubber=mat('Switch rubber',(.024,.03,.026),.9)
lensmat=mat('Flashlight lens',(.32,.39,.34),.17,.45)
reinforcement=mat('Reinforced glove panels',(.031,.024,.017),.86)
surface_maps(cloth,'canvas',True)
surface_maps(leather,'leather',False)

def finish(obj,material):
    obj.data.materials.append(material)
    for p in obj.data.polygons:p.use_smooth=True
    return obj

def ellipsoid(name,center,scale,material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=center)
    o=bpy.context.object;o.name=name;o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,material)

def tube(name,points,radii,material,sides=20,steps=4,folds=0):
    pts=[Vector(p) for p in points]
    centers=[]; rs=[]
    for i in range(len(pts)-1):
        for j in range(steps):
            t=j/steps
            centers.append(pts[i].lerp(pts[i+1],t))
            rs.append(radii[i]*(1-t)+radii[i+1]*t)
    centers.append(pts[-1]);rs.append(radii[-1])
    vertices=[];faces=[]
    for i,p in enumerate(centers):
        tangent=(centers[min(i+1,len(centers)-1)]-centers[max(i-1,0)]).normalized()
        reference=Vector((0,0,1)) if abs(tangent.z)<.85 else Vector((1,0,0))
        a=tangent.cross(reference).normalized(); b=tangent.cross(a).normalized()
        for j in range(sides):
            angle=j*2*math.pi/sides
            r=rs[i]*(1+folds*(math.sin(i*.83+angle*3)*.6+math.sin(i*1.6-angle*2)*.4))
            if name.startswith('Canvas sleeve'):
                t=i/max(1,len(centers)-1)
                for crease in [.56,.72,.84]:
                    diagonal=crease+.022*math.sin(angle*2+.4)
                    r-=.0035*math.exp(-((t-diagonal)/.017)**2)*(0.7+.3*math.cos(angle))
            vertices.append(p+(a*math.cos(angle)+b*math.sin(angle))*r)
    for i in range(len(centers)-1):
        for j in range(sides):
            nj=(j+1)%sides
            faces.append((i*sides+j,i*sides+nj,(i+1)*sides+nj,(i+1)*sides+j))
    faces.append(tuple(reversed(range(sides))))
    faces.append(tuple((len(centers)-1)*sides+j for j in range(sides)))
    me=bpy.data.meshes.new(name);me.from_pydata(vertices,[],faces);me.update()
    ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob)
    finish(ob,material)
    # A predictable UV strip for real exported texture images.
    uv=me.uv_layers.new(name='UVMap')
    for poly in me.polygons:
        for li in poly.loop_indices:
            vi=me.loops[li].vertex_index
            uv.data[li].uv=((vi%sides)/sides,(vi//sides)/max(1,len(centers)-1))
    return ob

def join_meshes(objects,name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join();o=bpy.context.object;o.name=name
    return o

chains=[]
def build_hand(side):
    right=side==1
    if right:
        wrist=Vector((.30,.36,.105)); palm=Vector((.283,.455,.155))
        parts=[ellipsoid('Glove palm',palm,(.033,.065,.037),leather)]
        parts.append(tube('Wrist',[wrist,(.288,.41,.14),palm],[.029,.032,.032],leather,24))
        chains.append(('wrist.R',wrist,palm,None))
        for k,name in enumerate(['index','middle','ring','pinky']):
            y=.535-k*.022
            radius=.0105-k*.0006
            pts=[]
            for j in range(5):
                theta=-.1-j*.79
                pts.append(Vector((.235+math.cos(theta)*.042,y,.181+math.sin(theta)*.042)))
            parts.append(tube(name+' metacarpal',[(.290,y-.025,.159),pts[0]],[.014,radius],leather,20,3))
            parts.append(tube(name,pts,[radius,radius*.98,radius*.9,radius*.84,radius*.65],leather,20,3))
            for j in range(len(pts)-1):
                chains.append((name+'.R.'+str(j),pts[j],pts[j+1],('wrist.R' if j==0 else name+'.R.'+str(j-1))))
        thumb=[Vector((.292,.446,.18)),Vector((.285,.461,.205)),Vector((.265,.480,.220)),Vector((.249,.496,.215))]
        parts.append(tube('Thumb',thumb,[.016,.014,.0125,.009],leather,24,4))
        for j in range(3):chains.append(('thumb.R.'+str(j),thumb[j],thumb[j+1],'wrist.R' if j==0 else 'thumb.R.'+str(j-1)))
    else:
        wrist=Vector((-.32,.31,.045));palm=Vector((-.29,.405,.065))
        parts=[ellipsoid('Left glove palm',palm,(.039,.057,.025),leather),tube('Left wrist',[wrist,palm],[.029,.031],leather,24)]
        chains.append(('wrist.L',wrist,palm,None))
        for k,name in enumerate(['pinky','ring','middle','index']):
            x=-.323+k*.022
            length=[.065,.079,.085,.077][k]
            points=[Vector((x,.44,.065)),Vector((x,.44+length*.5,.055)),Vector((x,.44+length*.85,.035)),Vector((x,.44+length,.018))]
            parts.append(tube('Left '+name,points,[.011,.010,.009,.0065],leather,20,4))
            for j in range(3):chains.append((name+'.L.'+str(j),points[j],points[j+1],'wrist.L' if j==0 else name+'.L.'+str(j-1)))
        thumb=[Vector((-.26,.40,.06)),Vector((-.232,.425,.055)),Vector((-.217,.454,.032))]
        parts.append(tube('Left thumb',thumb,[.016,.014,.009],leather,24,4))
        for j in range(2):chains.append(('thumb.L.'+str(j),thumb[j],thumb[j+1],'wrist.L' if j==0 else 'thumb.L.'+str(j-1)))
    glove=join_meshes(parts,'Right glove' if right else 'Left glove')
    bpy.context.view_layer.objects.active=glove
    remesh=glove.modifiers.new('Continuous glove surface','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.0017;remesh.use_smooth_shade=True
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth=glove.modifiers.new('Relax joined forms','SMOOTH');smooth.factor=.45;smooth.iterations=3
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.015);bpy.ops.object.mode_set(mode='OBJECT')
    for p in glove.data.polygons:p.use_smooth=True
    glove.data.materials.append(reinforcement)
    panel_index=len(glove.data.materials)-1
    for face in glove.data.polygons:
        p=glove.matrix_world@face.center
        in_panel=(p.x>.302 and .416<p.y<.513 and .141<p.z<.19) if right else (-.325<p.x<-.253 and .373<p.y<.441 and p.z>.08)
        if in_panel:face.material_index=panel_index
    # Creases and scuff variation follow the actual knuckles, not random noise.
    joints=[entry[1] for entry in chains if ('.R.' if right else '.L.') in entry[0]]
    for v in glove.data.vertices:
        world=glove.matrix_world@v.co
        distance=min((world-j).length for j in joints)
        if .009<distance<.015:
            v.co-=v.normal*(.00055*math.sin((distance-.009)/.006*math.pi))
    colors=glove.data.color_attributes.new(name='Leather wear',type='FLOAT_COLOR',domain='CORNER')
    for loop in glove.data.loops:
        world=glove.matrix_world@glove.data.vertices[loop.vertex_index].co
        distance=min((world-j).length for j in joints)
        wear=.69+.27*math.exp(-((distance-.018)/.014)**2)
        wear+=.035*math.sin(world.x*340)*math.sin(world.y*280)
        colors.data[loop.index].color=(wear,wear*.98,wear*.94,1)
    # Separately modeled raised seams over the back of the glove.
    return glove

right=build_hand(1);left=build_hand(-1)
sleeves=[]
for side in [1,-1]:
    if side==1:
        points=[(.48,-.03,-.05),(.395,.12,.015),(.345,.25,.075),(.30,.365,.108)]
        radii=[.085,.073,.055,.038]
        cuff=[(.307,.346,.101),(.30,.377,.112)]
    else:
        points=[(-.49,-.03,-.09),(-.42,.1,-.025),(-.36,.23,.02),(-.32,.325,.05)]
        radii=[.081,.069,.051,.037]
        cuff=[(-.325,.309,.045),(-.318,.34,.055)]
    ob=tube('Canvas sleeve '+str(side),points,radii,cloth,48,14,.035)
    sleeves.append(ob)
    seam_points=[Vector(p)+Vector((.002*side,0,.88*r)) for p,r in zip(points,radii)]
    tube('Sleeve panel stitching '+str(side),seam_points,[.0011]*len(points),seam,8,14)
    tube('Ribbed cuff '+str(side),cuff,[.043,.040],cuffmat,48,8,.015)
    center=(.301,.361,.153) if side==1 else (-.321,.324,.097)
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    tab=bpy.context.object;tab.name='Cuff closure tab '+str(side);tab.dimensions=(.025,.036,.004)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    tab.data.materials.append(cuffmat)
    bevel=tab.modifiers.new('Soft tab edges','BEVEL');bevel.width=.002;bevel.segments=3
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=.004,depth=.002,location=(center[0],center[1],center[2]+.003))
    stud=bpy.context.object;stud.name='Cuff press stud '+str(side);finish(stud,steel)
    # A narrow bound edge gives the cuff a sewn construction.
    a,b=map(Vector,cuff)
    tangent=(b-a).normalized()
    tube('Cuff bound edge '+str(side),[b-tangent*.001,b+tangent*.001],[.0406,.0406],seam,48,1)

def lathe(name,profile,material,segments=96,knurl=False):
    verts=[];faces=[]
    for i,(y,r) in enumerate(profile):
        for j in range(segments):
            angle=2*math.pi*j/segments
            rr=r
            if knurl:rr+=.00055*math.sin(j*math.pi/2+i*math.pi/2)
            verts.append((.235+rr*math.cos(angle),y,.181+rr*math.sin(angle)))
    for i in range(len(profile)-1):
        for j in range(segments):
            k=(j+1)%segments
            faces.append((i*segments+j,(i+1)*segments+j,(i+1)*segments+k,i*segments+k))
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);finish(ob,material)
    uv=me.uv_layers.new(name='UVMap')
    for p in me.polygons:
        for li in p.loop_indices:
            vi=me.loops[li].vertex_index;uv.data[li].uv=((vi%segments)/segments,(vi//segments)/max(1,len(profile)-1))
    return ob

lathe('Machined flashlight shell',[(.388,0),(.388,.024),(.391,.028),(.405,.028),(.41,.026),(.592,.026),(.605,.029),(.616,.041),(.622,.045),(.66,.048),(.671,.048),(.674,.044),(.665,.038),(.63,.008)],steel,128)
lathe('Diamond knurled grip',[(.414+i*.0024,.027) for i in range(68)],steel,128,True)
for y in [.398,.406,.59,.606,.625,.645,.662]:
    r=.029 if y<.61 else (.045 if y<.64 else .049)
    lathe('Machined band',[(y-.001,r-.001),(y,r),(y+.002,r),(y+.003,r-.001)],edge,96)
lathe('Reflector bezel',[(.674,.043),(.678,.043),(.68,.039),(.677,.038)],edge,128)
lathe('Front glass',[(.678,0),(.678,.039),(.68,.039),(.68,0)],lensmat,96)
switch=ellipsoid('Rubber thumb switch',(.235,.501,.209),(.014,.023,.006),rubber)
marker=bpy.data.objects.new('BeamOrigin',None);bpy.context.collection.objects.link(marker);marker.location=(.235,.685,.181)

# A real armature with weighted glove vertices and a subtle inspection animation.
arm_data=bpy.data.armatures.new('First person hand rig')
rig=bpy.data.objects.new('HandRig',arm_data);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
rootbone=arm_data.edit_bones.new('root');rootbone.head=(0,0,0);rootbone.tail=(0,.1,0)
for name,a,b,parent in chains:
    bone=arm_data.edit_bones.new(name);bone.head=a;bone.tail=b
    bone.parent=arm_data.edit_bones.get(parent or 'root')
bpy.ops.object.mode_set(mode='OBJECT')
for glove,suffix in [(right,'.R'),(left,'.L')]:
    relevant=[entry for entry in chains if suffix in entry[0]]
    groups={name:glove.vertex_groups.new(name=name) for name,_,_,_ in relevant}
    for v in glove.data.vertices:
        p=glove.matrix_world@v.co
        distances=[]
        for name,a,b,_ in relevant:
            closest,factor=intersect_point_line(p,a,b)
            q=a.lerp(b,max(0,min(1,factor)))
            distances.append(((p-q).length,name))
        distances.sort()
        chosen=distances[:2];weights=[1/max(.003,d)**3 for d,_ in chosen];total=sum(weights)
        for weight,(_,name) in zip(weights,chosen):groups[name].add([v.index],weight/total,'REPLACE')
    mod=glove.modifiers.new('Glove deformation rig','ARMATURE');mod.object=rig
    glove.parent=rig

rootpose=rig.pose.bones['root'];rootpose.rotation_mode='XYZ'
for obj in list(bpy.context.scene.objects):
    if obj==rig or obj.parent is not None:continue
    if obj.type in {'MESH','EMPTY'}:
        transform=obj.matrix_world.copy()
        obj.parent=rig;obj.parent_type='BONE';obj.parent_bone='root'
        obj.matrix_world=transform
for frame,angle in [(1,0),(45,.007),(90,0)]:
    rootpose.rotation_euler=(0,0,angle);rootpose.keyframe_insert('rotation_euler',frame=frame)
if rig.animation_data and rig.animation_data.action:rig.animation_data.action.name='SubtleHandMotion'
bpy.context.scene.frame_set(1)

for ob in bpy.context.scene.objects:
    if ob.type=='MESH':
        for poly in ob.data.polygons:poly.use_smooth=True

bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'ashfall_hands_flashlight.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'ashfall_hands_flashlight.glb'),export_format='GLB',export_animations=True,export_yup=True,export_apply=False)
print('PLAYER_ASSET_EXPORTED',sum(len(o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH'),'polygons')
