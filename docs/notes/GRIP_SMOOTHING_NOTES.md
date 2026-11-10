# Smooth held-item transitions

The approved inward-facing flashlight and tin poses remain the settled poses.
This change addresses snapping between poses and items, not new skin weights.

## Research applied

Godot's AnimationNodeTransition can cross-fade permanent animation inputs;
replacing the animation on a single AnimationNodeAnimation is not an equivalent
transition. The hand layer now contains the imported Hand_* clips as separate
inputs with a 0.16-second eased cross-fade. Only right-finger tracks are filtered
into locomotion. Source clips are not modified at runtime.

Reference: https://docs.godotengine.org/en/stable/classes/class_animationnodetransition.html
AnimationTree filters/blending: https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
Editable pose assets: https://docs.blender.org/manual/en/3.6/animation/armatures/posing/editing/pose_library.html

## Runtime behavior

An equip request first validates and instantiates the pending prop. The hand
lowers and releases, the prop exchanges at the bottom of that motion, and the
hand raises and closes. The wrist's aim calibration interpolates rather than
switching to the next item's orientation in one frame. Swaps normally use the
profile's lower_time (0.16 seconds) and raise_time (0.24 seconds). Reaching from
or releasing to an empty hand uses at least 0.40 seconds for the larger arm arc.
Startup equips immediately to avoid moving the hand during initial scene load.

equip_item(profile) returning true means the request was accepted; item_changed
fires when the actual prop exchanges. A later valid request replaces the pending
one. Invalid requests preserve both current and pending equipment. Reversing a
raising motion starts lowering from its current amount, with a full ease duration
to avoid a fast reversal. Pending unparented props are freed on replacement or exit.

The persistent light survives swapping. Battery state is checked again at the
actual exchange, so a queued flashlight cannot turn on with an empty battery.
Pause freezes the equip phase, aim calibration, animation fade and wall easing.
Empty-hand transitions blend the real arm back into locomotion. No camera arms
or replacement hand mesh are added.

Wall-retraction input is eased in presentation updates, independently of how
often the movement controller supplies the target. Physics/camera collision
remain with the existing controller. The diagonal safety ray can still retract
the arm immediately to avoid penetration.

During opening and exchanges, fingertips are not expected to remain on the
settled item's contact guides. The props are visual held representations;
physical dropping is not added. The field pack equipment selector and independent
live preview are documented in INVENTORY_NOTES.md.

## Verification and review

tests/test_grip_transitions.gd samples actual post-animation/post-IK bone output
at fixed 60 Hz. It checks wrist displacement, wrist/finger angular steps, delayed
exchange, rapid interruptions, reversal, pause/resume, empty-hand relaxation,
pending-request validation, prop cleanup and an empty battery at delayed equip.
The authored-hand test continues to check inward curl and final contacts through
steep aim, walking, crouch and wall retraction. Existing full-body, item and village
smoke checks remain relevant.

Inspect Hand Grips.cmd previews the same runtime behavior with 1/2/0 and Space.
P/C/V/W preview aim, crouch, wall retraction and walking. --capture-transitions
records a reproducible offline render at fixed 60 Hz; every third frame forms a
20 fps review animation. This is an engine-rendered review, not a claim of measured
real-time game performance. See Godot's offline capture documentation:
https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html

Finger anatomy, joint bulges and authored motion quality still need artistic
refinement. These transitions preserve the approved poses; they do not solve
arbitrary-object grasping, two-handed holds, or all possible mesh intersections.

For the next surface-refinement pass, compare deformation in Blender and Godot
with the same skinning assumptions. Blender's Preserve Volume option changes
armature deformation; glTF 2.0 specifies linear blend skinning. A nicer Blender
preview alone does not establish the result after export. Weight changes and
any corrective shapes need their own imported visual comparison.
Primary references:
https://docs.blender.org/manual/en/3.6/modeling/modifiers/deform/armature.html
https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html
