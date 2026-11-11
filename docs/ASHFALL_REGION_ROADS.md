# Ashfall — Expanded Region Road Network (First Blockout)

**Status:** Visual/procedural road first-pass on a feature branch. Do not confuse
this with a playable world or a replacement for Station 04's F5 scene.

## Intended map

The expanded Ashfall region follows the top-down concept at approximately
**2,400 × 2,000 metres**. Coordinates are in Godot metres (X increases east,
negative Z is north, Y is height). The **Station 04 hub** occupies the centre
at `(0,0,0)`. The new scene contains an overview camera, an actual **heightfield
terrain with matching collision**, a river channel, a road network and markers.
The playable Station 04 remains a separate F5 scene.

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


### Heightfield / regional topography (second pass)

The flat preview plane has been replaced with a deterministic terrain system:

- **`scripts/roads/region_height_profile.gd`** is the single shared
  elevation function for the landscape, roads, destination pads and bridge
  landings. It combines seeded multi-octave noise with broad landforms.
- **`scripts/roads/region_terrain.gd`** generates one indexed
  **201 × 169 vertex** terrain mesh across 2.4 × 2.0 km, with smoothed
  normals and an attached `ConcavePolygonShape3D` collision generated from
  exactly the same mesh. The static collision is appropriate for the terrain
  and is not used for dynamic physics objects.
- **`assets/shaders/ashfall_region_terrain.gdshader`** blends the existing
  forest-ground albedo with a rough rock/plaster texture by slope, altitude and
  wetland elevation, retaining a weathered rural palette.
- Natural relief includes a prominent **northeastern communications ridge**,
  **northwestern rocky highlands**, rolling southern farmland, a **low western
  marsh basin**, and an **eastern carved river valley** with its river surface
  at **y = -9 m**.
- The Station 04 reserve remains approximately **y = 0** within its central
  footprint so the existing Station 04 level can be integrated later without
  moving its buildings or player start.
- Regional route waypoints now tessellate to approximately **6 m segments**.
  Each road surface and gravel shoulder samples the **same triangulated
  terrain grid** as the rendered landscape, including across the road width,
  preventing the floating/slab effect seen in the earlier station test.
- Markers follow the terrain; junction caps are triangulated over the
  terrain; the eastern service bridge sits at **y = 7.5 m** above the river,
  with matching-height abutment grading at its two road endpoints.

These are height changes to the **separate expanded-region scene** only.
They're not sculpting or replacing the existing Station 04 gameplay map.
The river, areas and regional roads remain first-pass visuals; the bridge has
deck collision, but the rest of the regional gameplay has not been implemented.

**Performance:** The single region mesh has about **33,969 vertices** and
**67,200 triangles** before collision processing. Generated terrain and the
draped road strips are built when the scene opens or runs, not every frame.
This is a baseline mesh rather than an optimized streamed terrain system.
Check editor startup/loading time and frame rate; future phases should add
LOD/terrain chunking before populating the entire region with dense assets.

### Complete concept road connectivity

The draft network presently has **16 road routes**, **10 area anchors**, and
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

Station 04 has a conceptual internal north-south road spine at x=0, and its
exits are visual anchors at z=±130. **The game still needs proper gate,
area loading, save/inventory continuity and collision-boundary adjustments**
before the entire region can be traversed as one world.

## How to preview in Godot

First, switch to the branch with the road network.

**To inspect road models:**
Open `res://scenes/roads/road_model_gallery.tscn` in Godot and press **F6**.
This shows straight, curved, junction and bridge models.

**To view the full road plan:**
Open `res://scenes/world/ashfall_region_roads.tscn` and press **F6**.

The scene now uses a slightly **angled orthographic overview camera** to
make the hills and valleys visible in 3D. Press **W/A/S/D** or arrow keys to
pan, and use the **mouse wheel** to zoom. Roads and terrain are generated
for both editor preview and when the scene runs. Press **F5** to return to
the unchanged playable Station 04 entry point.

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
without errors, check that the **hills are visibly elevated**, the **river runs
inside a lowered channel**, and the **road shoulders track hills without floating**.
Inspect the bridge ends, intersections, Station 04 reserve and marsh marker.
The region is still only a **terrain/road-layout prototype**, so do not merge
it on the assumption that full-area traversal or new buildings already work.

## Integration guardrails

`project.godot`, `scenes/ashfall_station_main.tscn`, scripts under
`scripts/runtime/`, existing houses, prop assets and combat/survival state
are left unchanged. This branch is independent of the currently open
terrain-grounding PR; it avoids overwriting earlier local scene changes.
