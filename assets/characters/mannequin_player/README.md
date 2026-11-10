# Current playable mannequin

The gameplay wrapper now loads assets/characters/hand_authoring/hand_authoring.glb
with editable Blender hand pose clips. See ../hand_authoring/README.md for the
current source/export workflow. The derived source in this folder is retained
as the earlier baseline, not the file to overwrite current pose edits from.

The game player now uses scenes/characters/mannequin_player.tscn: the approved
plain gray male mannequin with a fitted flashlight in its right hand. Clothing
remains separated in ../wardrobe/; the clean anatomy source in ../male_mannequin/
is preserved. No detached camera arms or replacement glove meshes are used.

The playable export has 58 bones: the anatomical rig, the retained item.R
authoring bone, and lower-forearm twist support. Nine in-place locomotion clips
drive the complete body. The flashlight is scaled to 84% for this hand and
exported independently, with no skeleton or skin in the prop. The body GLB
contains no baked equipment.

held_item_controller.gd attaches props to hand.R using per-item HandGripProfile
resources under assets/grips/. Each profile owns its attachment, finger pose,
contact guides, aim frame and optional light settings. player_profile.json
contains body calibration and fingertip lengths. See ../../../HAND_ITEM_SYSTEM.md
for the reusable item workflow. Movement, collision, stamina, battery consumption
and interactions remain with the existing controller.

full_body_character.gd shares the continuous body's original skinned vertex
arrays and normals, partitioning only triangle indices for first-person head
visibility. The source topology stays continuous. Head and eye shadow-only
skins retain the full silhouette. Head aiming avoids rotating the mannequin's
upper-chest-weighted neck bone into the camera. Foot contacts use the new rig's
actual ankle heights rather than the old boots' height.

Inspect Full Character.cmd opens the actual player visual for review. Keys 1–7
show front, back, side, face, first person, look down and grip. Movement/crouch
preview controls are listed on screen. Inspect Mannequin.cmd keeps the clean,
unposed anatomy study available; Inspect Dressed Character.cmd opens the old
outfit study. Stop and restart gameplay (F8 then F5) to load the new player.

Inspect Hand Grips.cmd opens the isolated hand workshop with flashlight/tin
switching, open/close fingers, hidden-item inspection and contact markers.

The movement clips and grip are draft poses and still need artistic refinement,
particularly knee/elbow deformation under deep bends. This integration does
not claim finished animation quality. The clean mannequin source and wardrobe
remain the basis for future anatomy, weight-painting and clothing work.

Rebuild with Blender 4.5 using tools/build_mannequin_player.py. The derived
editable source is source/mannequin_player.blend; the game loads the GLB.
