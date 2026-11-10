# Editable hand poses — current player source

Open source/hand_authoring.blend. The full body and existing 58-bone rig remain
intact. Blender Actions Hand_flashlight, Hand_food_tin and Hand_open are pose
assets. They contain finger animation only. Select the rig, choose the action
and edit the fingers in Pose Mode; update the action's two identical keys.
The Godot AnimationTree filters these clips to right-hand fingers, independently
of locomotion and arm aiming. The runtime finger quaternion writer is skipped
while an authored animation is active. Existing profiles remain a fallback for
characters without those clips.

Save Blender edits, then run tools/export_authored_hand.py in a separate Blender
background process using --python-exit-code 1. This exports the saved source
without recreating the weights or poses. It never saves over the Blender file.
The authoring source is excluded from Godot scanning by source/.gdignore; Godot
imports the explicit GLB. Restart the game after export/import.

tools/author_hand_rig.py is a ONE-TIME bootstrap/comparison tool. Rerunning it
recreates the candidate from the older player source and discards edits in the
candidate file. Do not use it for routine exports. The original anatomy,
wardrobe and earlier player files remain available.

The initial actions preserve the previous fitted pose as an editable starting
point; they are not newly handcrafted final animation. Finger anatomy and
weight painting still need artistic work. The arm/foot correction code is still
present; this migration removes direct finger overrides for the new clips.
The source opens in Pose Mode with the flashlight action and a separate
PREVIEW_ONLY_HeldFlashlight helper. The export excludes that preview prop.
tools/prepare_hand_workspace.py is a one-time viewport/preview setup tool;
do not rerun it on a manually edited source without reviewing its changes.

An original-weight transfer was tested on 1,682 vertices. The source rig has
metacarpals absent from our simplified rig; the direct remap produced a worse
wrist transition. It was NOT promoted. The current export retains the previous
weights. --transfer-source-weights is only for reproducing that experiment.

default_weights.mhw is CC0 MakeHuman data, preserved for research:
https://github.com/makehumancommunity/makehuman/blob/master/makehuman/data/rigs/default_weights.mhw
Its checksum is in authoring_report.json. No new mesh or texture asset is added.

Validation: tests/test_authored_hand.gd checks imported pose contacts, swapping,
release, and operation with the legacy quaternion data removed. Existing held
item, full-body and game smoke tests remain applicable. These checks establish
functional behavior and import fidelity, not finished artistic quality.

The flashlight's earlier palm direction was reversed: the barrel was placed
on the dorsal side and the fingers bent backward. Its saved Blender action,
item attachment and fallback pose have been corrected to the palmar side.
Thumb opposition is fitted separately. The authored-hand test now also checks
that the four long fingers curl toward the anatomical palm, independent of
whether their tips happen to reach the prop's contact guides.
The food-tin action now uses the same palmar curl, with the can upright at
level aim. Both items are checked through steep aiming, walking, crouching
and wall retraction. Workshop P/C/V/W controls expose those cases visually.

Item swaps now use animation cross-fades and a lower/exchange/raise motion.
The approved Blender hold actions remain the settled poses. See
../../../GRIP_SMOOTHING_NOTES.md for the runtime transition and research details.
