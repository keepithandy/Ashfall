# Crossroads maintenance station kit — first art pass

## Main-world integration

The playable scene `scenes/ashfall_editable.tscn` now contains the 12 × 8 m
`CrossroadsMaintenanceStation` east of the starting area inside the perimeter.
The instance is saved in the scene and can be selected or moved in the editor.
It has been moved and raised in the editor since the first placement. The
textured entrance ramp is a child of the instance and provides a walkable
approach to the raised floor. The previous automatic-placement bridge is no longer registered
as an autoload, so it cannot add a second station during play.

The assembled v0.3 station uses its concrete floor, walls, framed windows,
garage shutter, corrugated roof, workbench and electrical cabinet, plus the
v0.2 damaged wall and animated steel door. The door uses the normal E-key
interaction. The hydraulic jack and trestle from Crossroads props 02 furnish
the interior. `scenes/crossroads_kit/maintenance_dressing.tscn` adds workshop
equipment, a dim lamp, and yard props as an editable scene instance. The
original v0.1 kit and its Blender source remain available
separately. The supplied v0.2/v0.3 source generators are preserved in their
respective `source` folders; no Blender files for those versions were supplied.

The in-world station now uses Blender-refined wall exports and a continuous
roof, guttering, downpipes, canopy and trim. The editable assembled Blender
source (including the original modules as references) is
`assets/crossroads_refined/source/crossroads_station_refined.blend`. Its builder
script exports the selected architectural pieces and revised wall modules;
the original v0.2/v0.3 GLBs remain intact. The original roof visuals are hidden
in the station while their simple collision is retained. Godot reuses the
project's shared plaster and roof textures via the refinement import script.

The newer GLBs were supplied without vertex normals. Their import settings use
`assets/crossroads_integration/fix_import_normals.gd` to generate face normals
and tangent space without modifying the source GLBs. Four saved vegetation
overrides clear the station and entrance apron while preserving surrounding
grass, stones, and leaves. If the station is moved, revisit those local
overrides for its new footprint. Run
`tests/test_crossroads_integration.gd` after importing to check the saved
placement, terrain contact, door interaction, and player passage. Run
`tests/test_crossroads_dressing.gd` with a rendering driver to verify the
vegetation changes.

This is an original modular industrial building kit for Godot 4, made in Blender 4.5. Open `scenes/crossroads_kit/demo.tscn` to review the 8 × 8 m example. It is a separate scene and does not replace the existing world or main scene. The roof is deliberately incomplete in the demo to expose the interior.

## Modules and dimensions

All dimensions are metres; Godot Y is up. Set the editor translation snap to 1 m and rotation snap to 90°. Walls are 3.2 m high and 0.24 m thick, measured on the centreline. Straight wall pivots are at their left end at floor level; their local +X direction runs along the wall. The floor and roof pivots are at the grid corner, with their area extending +X and -Z. The roof pivot sits at wall-top height. Both have a 4 × 4 m footprint.

- `floor_4m`: slab with its top at Y=0.
- `wall_solid_4m`, `wall_solid_2m`, `wall_window_4m`, `wall_door_4m`: wall sections; the window is open and framed. The door opening is 1.30 m wide and 2.40 m high before its frame.
- `corner_1m`: L-shaped return with 1 m centreline legs in local +X and -Z. Rotate in 90° increments. A side made from corner + 4 m wall + 2 m wall + corner spans 8 m.
- `roof_4m`: flat structural deck with a corrugated steel covering. Its origin is at the wall top.
- `metal_door`: separate door leaf, with hinge origin at floor level. Position the pivot near the left frame; rotate Y to set its open angle. The door is a static scene with collision; an interaction/animation system is not included.

Instancing the `.tscn` scenes supplies simple collision and shared Godot materials. The GLBs are the visual source exports, and have no standalone collision or shared material override. Use the scene wrappers in a level. Windows and doorway have separate collision sections so the openings are clear; small decorative details are intentionally omitted from collision.

## Editable sources and materials

`assets/crossroads_kit/source/crossroads_kit.blend` contains all meshes in named collections, with packed textures. `build_crossroads_kit.py` can regenerate the source and GLBs with Blender 4.5; running it replaces those generated files. `.gdignore` prevents Godot treating the source `.blend` as an importable game asset. The five shared Godot materials live in `assets/crossroads_kit/materials`; the wrapper script applies them to the imported surfaces at runtime and in the editor. Godot uses the existing project's `assets/materials` texture sets. Exports also embed fallback PBR textures, which makes them portable but increases their size and duplicates image data on disk.

Concrete floor, grey plaster, and rusty corrugated iron textures are existing CC0 Poly Haven sets; authors and source links are documented in `assets/materials/sources.json` and the project's `HOUSE_NOTES.md`. The painted and dark steel materials are original simple PBR materials. The window is unglazed. This is a first art pass: bespoke localized wear, damaged variants, a proper door interaction, LODs, texture memory optimization, and a gameplay-scale art review remain for production polish.

## Verification

Import the project once in Godot, then run the demo scene or execute:

```
godot --headless --path . --script res://tests/test_crossroads_kit.gd
```

The test loads each module, checks collision sections and material overrides, assembles the demo, and uses physics rays to check the open doorway and window and the solid wall. The example is a review scene, not integrated into the current playable map.

## Installation into another Godot 4 project

Copy `assets/crossroads_kit`, `scenes/crossroads_kit`, and `tests/test_crossroads_kit.gd` to the matching locations under that project's root. Also copy the `concrete_floor_worn_001`, `grey_plaster`, and `rusty_corrugated_iron` folders from `assets/materials` if absent. Preserve `assets/materials/sources.json` for attribution without replacing another project's existing credits file. Open the project in Godot and allow imports to finish. Paths in the scenes assume these exact locations.

## Crossroads encounter — November 8

The main editable scene now includes a station side objective, independent of the existing research sample mission.
- At the station east of the entry gate, use E on the existing generator. A 12-second warmup lights the workshop and attracts a station creature using the existing stalker model/controller.
- Use E again to recover the relay diagnostic, then E at the entry gate to report it. One spare battery is awarded once per expedition. The research mission remains available.
- The creature approaches the entrance yard, investigates, searches for 16 seconds after losing contact, and withdraws. Sight and noisy movement can cause pursuit. Crouching reduces visibility range; solid geometry blocks sight. Cover markers in the editor identify the rear interior and west exterior corner; they do not grant invisibility.
- Generator, creature footsteps, and breathing use the Effects volume control. Warmup and sound pause with gameplay.
- The station's saved placement, collision, Blender assets, and original village creature are preserved. A separate saved StationThreat instance reuses that creature's implementation.

Validation: tests/test_crossroads_encounter.gd covers real generator ray targeting, warmup, pause, cover occlusion, physical approach and withdrawal, retrieval, gate delivery and duplicate-reward prevention. The test repositions the player between checkpoints; it is not a manual end-to-end walk. Native Vulkan Forward+ run passed. Existing Crossroads doorway/floor traversal and expedition feature regression tests passed. Headless shutdown can still report transient AudioStream ObjectDB leaks; the final rendered encounter run did not report them.

First-pass limitations: synthesized sound cues and the existing prototype creature art; simple obstacle steering rather than a navigation mesh. Longer freeform chase routes need further playtesting. Encounter progress resets with a new expedition, matching the current game.
