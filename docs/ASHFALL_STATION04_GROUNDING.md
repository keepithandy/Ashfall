# Station 04 — Grounding and Terrain Visual Fix

## Why this change exists

In the November 11 in-game screenshot, distant trees, road edges and nearby props appeared disconnected from the surrounding landscape. Source inspection confirmed three concrete problems:

1. **Ground coverage:** the only playable floor was a 180 × 170 m box, ending just behind outer perimeter trees; the player's camera can see much farther than the terrain extends.
2. **Raised platform look:** the `ApproachRoad` and `ServiceYardSurface` were thin dark boxes whose top surface sat approximately 4 cm above the terrain, with stark square edges.
3. **Gigantic woodland mushroom:** the saved `MushroomCluster` was scaled **50×**, despite the asset itself being a normal-sized woodland cluster.

## Changes

- Ground visual and collision footprint both expand to **460 × 460 m**, retaining **world surface y = 0** and the original world origin.
- The original `StaticBody3D` ground physics remains intact; the existing perimeter barriers still restrict the playable area.
- The raised road and service-yard visual boxes remain in the scene, but are hidden. Their exact footprint is represented through a shader blended onto the ground itself, without extra road collision or an elevated lip.
- The new `assets/shaders/station04_ground.gdshader` samples the **already included** forest-ground and worn-concrete albedo textures at world scale. It combines rough forest soil, dusty verge transition, worn compacted path, subtle road ruts and a service-yard material region.
- The woodland `MushroomCluster` is restored from **50× to 1×**, with its original x/z placement and natural mesh size. It no longer towers above buildings.
- No gameplay scripts, main-scene wiring, objectives, house architecture, cloud shader, player movement, or sky parameters change.

### Coordinates and gameplay compatibility

The ground top stays at `y=0` (body center `y=-0.5`, thickness 1 m), so existing houses, props, trees, spawned actors, pickup positions, and movement thresholds are not shifted.

The legacy road ran along x=0, z=-7 with width 5.5 m and length 82 m. The service yard was centred on (x=25, z=-8), at 32 × 29 m. New material masks match those regions and soften their edges instead of changing the routes or physics.

Ground material can be edited in the Godot Inspector at `EditableWorld/Terrain/WalkableGround/VisibleGround > Material Override > Shader Parameters`, including soil/road/shoulder colors, forest and road texture scale, and edge blending.

## Validation

**Source changes committed; not visually tested in Godot yet.**

1. Open the scene in Godot 4.7.2 Forward+ and let textures import.
2. Press F5 and look down the starting road: it should appear **flush with the surrounding ground**, with softer soil/verge transitions.
3. Look toward the distant tree line from the entrance. The ground should continue *behind* the trees, rather than ending and exposing pale sky below their trunks.
4. Check that the blue porch cottage, isolation ward and maintenance station still sit on the same collision plane. Walk through house thresholds and run the existing sample/extraction objectives.
5. Check the mushroom cluster at x=-30.95, z=16.77; it should now be normal-sized, not a giant structure.
6. Monitor the debug log for shader compilation warnings and the framerate during a camera pan. Procedural material noise is new GPU work; report a measurable regression.
7. Optional resource/geometry test:
   ```powershell
   & "..\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script "res://tests/check_station_grounding.gd"
   ```

The test checks scene resources, the horizontal ground footprint, surface alignment and hidden legacy geometry. It does **not** measure framerate or replace a visual playtest.

## Rollback

This change is isolated to the Station 04 main scene and its new terrain shader. Review it on the feature branch and keep `main` as the known rollback baseline until the visual check passes.
