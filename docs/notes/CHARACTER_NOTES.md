# Full-body player character

Current hand workflow: assets/characters/hand_authoring/source/hand_authoring.blend
contains editable pose assets and a preview flashlight. tools/export_authored_hand.py
exports saved edits. A filtered AnimationTree layer plays the hand pose; the old
finger writer is bypassed for authored clips. See that asset folder's README.

The current playable character is the gray mannequin with a fitted flashlight:
player.gd loads scenes/characters/mannequin_player.tscn. Inspect Full Character.cmd
opens that same player visual in scenes/player_mannequin_review.tscn. The clean
anatomy source and all eight wardrobe parts remain separate. See
assets/characters/mannequin_player/README.md for the current implementation.
Hand grips and independent item models are documented in HAND_ITEM_SYSTEM.md.
Inspect Hand Grips.cmd opens the hand-only fitting workshop.

The dressed character study below is preserved for later clothing refitting.

The dressed study instantiates scenes/characters/scavenger.tscn, an editable Godot
wrapper around a complete humanoid GLB. The existing movement controller,
capsule, stamina, battery, loot and interaction code remain authoritative.
The previous procedural first_person_body.gd is preserved for reference.

Open scenes/character_review.tscn and run the current scene (F6), or run
Inspect Dressed Character.cmd. This review uses the same mesh, skin and adapter
as gameplay. Keys 1–6 show front, back, side, face, first person and downward
views. Right-drag orbits/aims; wheel zooms; Space previews walking, Shift
running, C crouched walking, and F toggles the hand-mounted light.

The anatomy-first study is separate: Inspect Mannequin.cmd opens the neutral
gray anatomy model, while Inspect Full Character.cmd opens its playable
flashlight-equipped derivative. See
MANNEQUIN_NOTES.md for the anatomy and separated wardrobe workflow.

## Architecture chosen after reviewing the game

One 57-bone skeleton controls the head, neck, spine, pelvis, complete arms,
individual fingers, legs and toes. The civilian field jacket, cargo trousers,
boots and shoulder bag follow the approved concept. The exposed anatomical
head uses CC0 MakeHuman topology and skin, eyes and short hair; see the asset
CREDITS.md and preserved licenses.

AnimationTree blends idle, forward/back/side walking, running, crouching and
airborne clips. Clips are in place: animation cannot move the collision body.
A SkeletonModifier3D runs after the clips and solves the right arm toward
the camera's aim, closes the finger grip, retracts/lowers the arm at walls,
adjusts head aim and fits the feet to nearby floor heights and normals.
The light uses a BoneAttachment3D on the same skeleton's item socket.
No separate camera-mounted replacement arms are used.

The controller keeps a stable camera at eye height. Looking down adds a small
forward head lean so the chest does not fill the entire viewport. Head, hair,
eyes and the neckline use a separate visibility layer excluded by the player
camera; shadow-only skins preserve the complete character silhouette.
Movement speeds and collision dimensions are unchanged. Eye height is now
1.69 m standing and 1.07 m crouched, matching the new body presentation.

## Remaining art and animation work

This is a functional full-body modeling draft, not the finished photoreal
character. It has approximately 287,000 source triangles before Godot's
generated LODs. Clothing silhouette, shoulder weights and crease placement
need more sculpting and a deliberate retopology/bake pass. Face identity,
skin wear, eyebrows, hair and material matching need artistic refinement.
The clips are authored test motions, not final motion-capture quality.

Foot IK adapts height and normal on small surfaces; it does not yet implement
world-space stance locking, stride warping, stair anticipation or pelvis
balancing on large height differences. The held arm has reach limits, but
the wrist/finger grip still needs pose refinement. Secondary bag movement is
bounded procedural motion, not cloth simulation. Jaw/eye bones exist; facial
expressions, lip sync, death/ragdoll and item-use/reach animations are not built.

The next quality pass should focus on the whole silhouette and deformation
in the inspection scene, then retopology and baked clothing detail, and then
authored locomotion/interaction clips. That improves what is visible instead
of adding complexity without an observable benefit.

## Source and validation

tools/build_scavenger.py rebuilds the Blender source and GLB using Blender
4.5. tools/scavenger_head.py adapts the licensed anatomical data. The source
images are packed in the blend file. tools/fetch_makehuman_assets.py is the
CRC-checked, selective upstream asset-fetch recipe; it does not install or
execute MakeHuman code. It uses only the needed ranges of the official ZIP.

tests/test_full_body_character.gd checks the real player's imported components,
rig and animations, first-person visibility/shadows, moving legs, crouched
joints, camera independence, hand/beam alignment, near-wall arm retraction,
raised-ground foot contact and pause behavior. Existing expedition and smoke
tests exercise gameplay with the new character.

Godot API references used:

- https://docs.godotengine.org/en/stable/classes/class_skeletonmodifier3d.html
- https://docs.godotengine.org/en/stable/classes/class_boneattachment3d.html
- https://docs.godotengine.org/en/stable/classes/class_animationnodeblendspace2d.html
