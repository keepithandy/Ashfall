# Hand grips and held items

Item changes now use a short lower/exchange/raise transition with eased wrist
calibration and animation cross-fades. equip_item returning true accepts the
request; item_changed marks the actual exchange. See GRIP_SMOOTHING_NOTES.md
for timings, interruption behavior and the transition review/test workflow.

Current workflow: the player loads assets/characters/hand_authoring/hand_authoring.glb.
Editable Blender pose assets drive the right fingers through a filtered
AnimationTree layer. See assets/characters/hand_authoring/README.md and use
tools/export_authored_hand.py for saved Blender edits. The cylinder fitting and
older player rebuild scripts below are legacy authoring aids, not the routine
export workflow for the current hand poses.

The playable mannequin holds a separate flashlight model on its real right-hand
bone. Each item has its own attachment, finger pose and optional light settings.
The anatomy study and wardrobe remain separate.

The current flashlight uses the forward utility hold selected from the
[MecArmy MOT10 reference](https://www.walmart.com/ip/5109056472): thumb extended
to a forward side switch, with the shaft crossing the palm and fingers curling
underneath. The held scene has a ThumbSwitch marker for checking the imported
thumb against the switch independently of the authored fingertip guide.

## Hand workshop

Run **Inspect Hand Grips.cmd**, or open `scenes/hand_grip_review.tscn` in Godot
and run it with F6. This isolates the actual skinned player hand.

| Control | Action |
| --- | --- |
| 1 / 2 / 0 | Flashlight / food tin / empty hand |
| Space | Open or close the fingers |
| I | Hide the prop to inspect fingers |
| G | Show contact targets and actual fingertip guides |
| P | Cycle level, downward and upward aim |
| C / V / W | Preview crouch / wall retraction / walking |
| Right drag / wheel | Orbit / zoom |
| F | Toggle the beam when a flashlight is equipped |

The readout measures terminal bone tips against authored targets, which sit
inside the finger pads slightly outside the object surface. These are review
guides, not a runtime collision solver. The largest flashlight target error is
under 4 mm. Stop and restart gameplay (F8 then F5) to reload changed assets.

## Fit a new item

1. Create a visual-only Node3D scene. Keep world pickup physics separate.
   Examples: `scenes/items/handheld_flashlight.tscn` and `held_food_tin.tscn`.
2. Duplicate a resource under `assets/grips/`, give it a new `item_id` and
   `display_name`, and assign its `model_scene`.
3. Fit `attachment_transform` relative to `hand.R`. Author the 15
   `finger_rotations` quaternion offsets relative to the bones' rest rotations.
   The runtime composes rest rotation with each offset. Oppose the thumb and
   check all three joints of each digit.
4. Set `hand_offset` for wrist reach in camera coordinates, plus `aim_forward`
   and `aim_up` in the avatar's rest frame. Set item-local `contact_targets`
   for all five fingertip guides.
5. Light-emitting props use `emits_light`, an item-local `beam_transform`, and
   light parameters. Other items cannot activate the beam or drain batteries.
6. Add the profile as a workshop selection. Inspect multiple angles with the
   item hidden, fingers opening/closing, and contact guides enabled.

From the player's presentation adapter:

```gdscript
var grip: HandGripProfile = load("res://assets/grips/food_tin.tres")
body_model.equip_item(grip)
body_model.equip_item(null) # release item and relax fingers
```

The game defaults to the flashlight. The field pack now selects all eight usable
items and provides a live grip preview; see INVENTORY_NOTES.md. Physical dropping
and hand-based consumption animations are not added.
Profiles are shared authored data; each character owns its own blend state.
Invalid rig profiles return false and retain the current item. The current rig
ID is `mannequin_humanoid_v1`. This implementation supports authored right-hand
grips. Left-hand and two-handed holds require additional constraints. It does
not automatically infer a grip for an arbitrary object.

## Sources and regeneration

The derived source is
`assets/characters/mannequin_player/source/mannequin_player.blend`. Its
flashlight reference remains for authoring, while the body GLB exports only
the rig, body and eyes. The 58-bone rig includes the retained authoring item
bone and lower-forearm twist bone. The prop exports independently to
`assets/items/handheld_flashlight.glb`, with no skeleton or skin.

`tools/build_hand_grips.py` rebuilds the prop, profiles and player export.
`tools/hand_grip_fitter.py` fits cylindrical objects offline using joint limits,
contact targets and weighted skin clearance. More complex tools need authored
contacts and suitable geometry constraints. Runtime uses the saved pose.
The builder preserves thumb weights, smooths the thumb web through mesh
neighbors once per source build, and leaves clean anatomy and wardrobe intact.

`assets/grips/authoring_reference.json` keeps item calibration separate from
the avatar's `player_profile.json`. `fit_report.json` records target errors and
subdivided skin clearance against simplified cylinders, with the export's four
normalized weights per vertex. The finger fit attracts terminal skin pads to
the handle and checks the thumb skin against the switch. An item-specific
`elbow_offset` controls arm support without altering the finger pose.
These checks do not guarantee
zero intersections in every subdivided animation pose.

`tools/build_mannequin_player.py` calls the grip builder at the end of a full
player rebuild. Run with Blender 4.5:
`blender --background --python-exit-code 1 --python tools/build_hand_grips.py`.
The flashlight reuses the original Ashfall asset; the tin reuses existing loot.

## Checks

`tests/test_held_items.gd` checks imported contacts, aim alignment, item swaps,
independent instances, rig rejection, empty hands and non-light battery behavior.
The full-body, expedition and clean mannequin tests cover the existing game.
Review renders can be regenerated with the workshop's `--capture-grips` flag.

Godot references: [BoneAttachment3D](https://docs.godotengine.org/en/stable/classes/class_boneattachment3d.html),
[Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html),
[Skeleton3D pose/rest conventions](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html).
