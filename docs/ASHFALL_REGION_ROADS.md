# Ashfall — Expanded Region Road Network (First Blockout)

**Status:** Visual/procedural road first-pass on a feature branch. Do not confuse
this with a playable world or a replacement for Station 04's F5 scene.

## Intended map

The expanded Ashfall region follows the top-down concept at approximately
**2,400 × 2,000 metres**. Coordinates are in Godot metres (X increases east,
negative Z is north, Y is height). The **Station 04 hub** occupies the centre
at `(0,0,0)`. The new scene contains an overview camera, continuous ground,
a road network and markers; the playable Station 04 remains separate.

### Road assets built

All models are saved in `scenes/roads/` and share assets under
`assets/roads/`. They are editable, procedural `@tool` prefabs:
- `road_straight.tscn`: a 24 m straight, 5.8 m worn surface, compacted shoulders
- `road_bend.tscn`: an irregular multi-point bend, with mitered joins
- `road_t_junction.tscn`: T intersection cap (rotate to orient)
- `road_crossroads.tscn`: four-way intersection cap
- `road_service_bridge.tscn`: a variable-length steel-railed bridge with deck collision
- `road_model_gallery.tscn`: separate gallery where all pieces are laid out

The shared `scripts/roads/road_strip.gd` script builds road strips from
editable `PackedVector3Array` centre-line points. Asphalt and shoulders are
separate material surfaces with tiled existing textures. Surface height is
only **3.6 cm** above the reference terrain to prevent z-fighting: these are
**not floating collision platforms**. The ground underneath handles ordinary
road walking, while the bridge prefab has its own deck collision. Road
models are reusable and can be integrated into playable areas later.

### Complete concept road connectivity

The draft network presently has **15 road routes**, **10 area anchors**, and
one river/bridge connection. Route names are stable in
`scripts/roads/region_road_layout.gd`. Destinations and positions:

| Site | X | Z | First-pass connections |
| --- | ---: | ---: | --- |
| Station 04 hub | 0 | 0 | North access, south access |
| Industrial plant | -720 | -700 | Northern industrial route, forest loop |
| Anomaly field | -170 | -820 | North-fork dirt track |
| North Relay | 320 | -490 | Northern junction, signal ridge, riverbank |
| Signal ridge/comms | 800 | -780 | Relay climb |
| Marsh outpost | -920 | -150 | Western access, forest loop |
| Farmsteads | -760 | 650 | Southern lane |
| Crash clearing | 350 | 700 | South approach, riverside loop |
| River crossing bridge | 845 | 70 | West approach, east tunnel road |
| East tunnel | 1080 | 290 | Bridge road and river-mill spur |

The **east river corridor is a visual-only placeholder**, not water simulation
or a gameplay hazard. The bridge spans approximately x=760 to x=930, crossing
the river at z=70. Areas beyond the roads are identified by ground markers
and readable labels, **not by constructed buildings or functioning gameplay**.

Station 04's exits are visual road anchors at z=±130. They deliberately stop
outside the existing playable compound; **the game still needs proper gate,
area loading, save/inventory continuity and collision-boundary adjustments**
before the entire region can be traversed as one world.

## How to preview in Godot

First, switch to the branch with the road network.

**To inspect road models:**
Open `res://scenes/roads/road_model_gallery.tscn` in Godot and press **F6**.
This shows straight, curved, junction and bridge models.

**To view the full road plan:**
Open `res://scenes/world/ashfall_region_roads.tscn` and press **F6**.

The scene uses a top-down orthographic camera. Press **W/A/S/D** or arrow
keys to pan, and use the **mouse wheel** to zoom. Roads are generated both
for the editor preview and when you run that scene. Press **F5** to return
to the unchanged playable Station 04 entry point.

To change routes, edit the named `ROUTES` waypoint arrays in
`scripts/roads/region_road_layout.gd`. To change the look of a road kit
piece, open one of the prefabs and adjust road width, shoulder width,
waypoints or assigned materials in Inspector.

## Checks before merge

This work was authored through GitHub source edits. **It has not been
rendered or run inside the user's Godot editor.** The new script
`tests/check_region_road_network.gd` provides a headless load/smoke check:

```powershell
& "..\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script "res://tests/check_region_road_network.gd"
```

After that, inspect both new F6 scenes, ensure terrain and roads load
without errors, verify road shoulders have no visible gaps, look for
junction/bridge alignment problems and note performance when zooming/panning.
The region is only a **road-layout prototype**, so do not merge it on the
assumption that full-area traversal or new buildings already work.

## Integration guardrails

`project.godot`, `scenes/ashfall_station_main.tscn`, scripts under
`scripts/runtime/`, existing houses, prop assets and combat/survival state
are left unchanged. This branch is independent of the currently open
terrain-grounding PR; it avoids overwriting earlier local scene changes.
