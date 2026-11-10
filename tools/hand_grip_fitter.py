"""Constrained, reproducible cylindrical hand-grip authoring for the current rig.

Uses anatomical finger hinges and explicit contact/clearance objectives. This is
an offline fitting tool: runtime uses the saved pose, never an unstable solver.
"""
import math
import numpy as np
from mathutils import Vector, Matrix, Quaternion


def unit(v):
    return v.normalized()


def cylinder_distance(p, radius, half_length):
    radial=math.hypot(p.x,p.z)-radius
    axial=abs(p.y)-half_length
    return min(max(radial,axial),0)+math.hypot(max(radial,0),max(axial,0))


def fit_grip(rig, item_world, radius, half_length, palm_normal, fingers=None, target_overrides=None, body=None):
    fingers=fingers or ['index','middle','ring','pinky','thumb']
    target_overrides=target_overrides or {}
    inverse=item_world.inverted()
    poses={}; targets={}; report={}
    hand=rig.data.bones['hand.R'].matrix_local.copy()
    for finger in fingers:
        names=[finger+str(j)+'.R' for j in range(1,4)]
        bones=[rig.data.bones[n] for n in names]
        lengths=[bone.length for bone in bones]
        relatives=[]
        parent=hand
        for bone in bones:
            relatives.append(parent.inverted()@bone.matrix_local)
            parent=bone.matrix_local
        hinges=[]
        for bone in bones:
            direction=unit(bone.tail_local-bone.head_local)
            axis=unit(direction.cross(palm_normal))
            hinges.append(unit(bone.matrix_local.to_3x3().inverted()@axis))
        root_basis=bones[0].matrix_local.to_3x3()
        spread_axis=unit(root_basis.inverted()@palm_normal)
        roll_axis=Vector((0,1,0))
        root=inverse@bones[0].head_local
        first_direction=inverse.to_3x3()@(bones[0].tail_local-bones[0].head_local)
        theta=math.atan2(root.z,root.x)
        sign=1 if root.x*first_direction.z-root.z*first_direction.x>=0 else -1
        clearance=.0055 if finger!='pinky' else .0045
        contact_radius=radius+clearance
        wrap=min(2.10,sum(lengths)*.88/contact_radius)
        if finger=='thumb':wrap=min(wrap,1.45)
        theta+=sign*wrap
        along=max(-half_length+.008,min(half_length-.008,root.y+.025))
        target=Vector((contact_radius*math.cos(theta),along,contact_radius*math.sin(theta)))
        spread=.75 if finger=='pinky' else .65
        limits=[(0,1.6),(0,1.92),(0,1.45),(-spread,spread)]
        initial=[.45,.90,.65,0]
        if finger=='thumb':
            limits=[(-.6,1.2),(0,1.3),(0,1.2),(-1.1,1.1),(-1.6,1.6)]
            initial=[.3,.6,.4,0,0]

        # Fit the volume of the weighted skin, not only the joint centerlines.
        # Cache each vertex in its influencing bone's rest frame for fast FK.
        skin_samples=[]
        if body is not None:
            for vertex in body.data.vertices:
                weights={body.vertex_groups[g.group].name:g.weight for g in vertex.groups}
                if sum(weights.get(n,0) for n in names)<.55:continue
                skin_samples.append((vertex.co.copy(),weights))
        skin_fixed=np.zeros((len(skin_samples),3))
        skin_local=[np.zeros((len(skin_samples),4)) for _ in names]
        pad_indices=[]
        for i,(point,weights) in enumerate(skin_samples):
            skin_fixed[i]=np.array(point)*sum(w for n,w in weights.items() if n not in names)
            for j,name in enumerate(names):
                local=bones[j].matrix_local.inverted()@point
                weight=weights.get(name,0)
                skin_local[j][i]=[local.x*weight,local.y*weight,local.z*weight,weight]
            if weights.get(names[-1],0)>.55:
                local=bones[-1].matrix_local.inverted()@point
                if local.y>lengths[-1]*.35:pad_indices.append(i)
        inverse_basis=np.array(inverse.to_3x3())
        inverse_origin=np.array(inverse.translation)

        def skin_penalty(chain):
            if not skin_samples:return 0
            points=skin_fixed.copy()
            for j,(matrix,_) in enumerate(chain):
                points+=skin_local[j]@np.array(matrix)[:3,:].T
            points=points@inverse_basis.T+inverse_origin
            def distances(p,r,h):
                radial=np.hypot(p[:,0],p[:,2])-r
                axial=np.abs(p[:,1])-h
                return np.minimum(np.maximum(radial,axial),0)+np.hypot(np.maximum(radial,0),np.maximum(axial,0))
            distance=distances(points,radius,half_length)
            if radius<.03:
                head=points.copy();head[:,1]-=.100
                distance=np.minimum(distance,distances(head,.0395,.025))
            depths=np.maximum(.0004-distance,0)
            score=(float(np.max(depths))**2+float(np.mean(depths*depths)))*1100
            # Pads should rest on the surface, not merely avoid penetrating it.
            # Use the terminal skin rather than the internal bone-tip guide.
            if pad_indices:
                if finger in target_overrides:
                    surface=Vector(target_overrides[finger])-Vector((0,0,.00208))
                    contact=float(np.min(np.linalg.norm(points[pad_indices]-np.array(surface),axis=1)))
                else:
                    contact=float(np.min(np.abs(distance[pad_indices])))
                score+=max(0,contact-.0005)**2*350
            return score

        def transforms(values):
            result=[];matrix=hand
            for j in range(3):
                q=Quaternion(hinges[j],values[j])
                if j==0:
                    q=Quaternion(spread_axis,values[3])@q
                    if finger=='thumb':q=Quaternion(roll_axis,values[4])@q
                matrix=matrix@relatives[j]@q.to_matrix().to_4x4()
                result.append((matrix,q))
            return result

        def evaluate(values, goal):
            chain=transforms(values)
            tip=inverse@(chain[-1][0]@Vector((0,lengths[-1],0)))
            error=(tip-goal).length_squared*200
            # A finger pad has volume. Centerlines may not cut through the item.
            for j,(matrix,_) in enumerate(chain):
                for t in [.25,.5,.75,1.0]:
                    p=inverse@(matrix@Vector((0,lengths[j]*t,0)))
                    distance=cylinder_distance(p,radius,half_length)
                    if radius<.03:
                        head_point=p-Vector((0,.100,0))
                        distance=min(distance,cylinder_distance(head_point,.0395,.025))
                    depth=max(0,clearance-distance)
                    error+=depth*depth*700
            # Prefer moderate bends and avoid solving contact with extreme splay.
            error+=sum(v*v for v in values)*.000015+values[3]**2*.00025
            if finger!='thumb':
                # Couple the distal and middle joints to discourage hooked tips.
                error+=(values[2]-values[1]*.65)**2*.0015
            error+=skin_penalty(chain)
            return error

        best=None
        # Contact targets follow a shorter arc for small fingers or broad objects.
        for arc_scale,along_delta in [(a,d) for a in [.45,.60,.72,.90,1.0] for d in ([0,.010,.025,.040] if finger!='thumb' else [-.015,.005,.020])]:
            angle=math.atan2(root.z,root.x)+sign*wrap*arc_scale
            along=max(-half_length+.003,min(half_length-.008,root.y+along_delta))
            goal=Vector((contact_radius*math.cos(angle),along,contact_radius*math.sin(angle)))
            if finger in target_overrides:goal=Vector(target_overrides[finger])
            values=list(initial)
            score=evaluate(values,goal)
            for step in [.34,.17,.08,.035,.015,.006]:
                for _ in range(9):
                    improved=False
                    for k,(minimum,maximum) in enumerate(limits):
                        for delta in [-step,step]:
                            candidate=values.copy();candidate[k]=max(minimum,min(maximum,values[k]+delta))
                            value=evaluate(candidate,goal)
                            if value<score:
                                values=candidate;score=value;improved=True
                    if not improved:break
            if best is None or score<best[0]:best=(score,values,goal)
        score,values,target=best
        chain=transforms(values)
        tip=inverse@(chain[-1][0]@Vector((0,lengths[-1],0)))
        minimum=1
        for j,(matrix,q) in enumerate(chain):
            poses[names[j]]=q.normalized()
            for t in [.25,.5,.75,1.0]:
                p=inverse@(matrix@Vector((0,lengths[j]*t,0)))
                minimum=min(minimum,cylinder_distance(p,radius,half_length))
        targets[finger]=target
        report[finger]={'target_error_mm':round((tip-target).length*1000,2),
                        'root_mm':[round(v*1000,1) for v in root],
                        'tip_mm':[round(v*1000,1) for v in tip],
                        'target_mm':[round(v*1000,1) for v in target],
                        'pad_clearance_mm':round(cylinder_distance(tip,radius,half_length)*1000,2),
                        'minimum_centerline_clearance_mm':round(minimum*1000,2),
                        'angles_degrees':[round(math.degrees(v),1) for v in values]}
    return poses,targets,report
