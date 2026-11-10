# Ashfall — Asset Showroom (Update 002)

A separate **inspection-only Godot scene** for reviewing what Ashfall already has. It does not replace the main scene or modify gameplay.

## How to open

1. Open Ashfall in Godot and find `res://scenes/testing/ashfall_asset_showroom.tscn`.
2. Double-click it to inspect/edit the static display in the 3D editor.
3. Press **F6** while that scene is selected to run **only the showroom**. Do not press F5, which launches the normal game.
4. Use **WASD** to fly, mouse to look, **Q/E** to descend/ascend, **Shift** for faster movement, **Esc** to release the pointer. Click to capture it again.

## What this changes

- Displays **94 distinct existing scenes** grouped by use case.
- Instantiates source assets; does not copy or regenerate their models or materials.
- Provides simple plates, section labels, neutral lighting, a floor and a standalone fly camera.
- Excludes whole levels, combatants, and gameplay-driven galleries that would introduce unintended behavior.
- Does not touch `project.godot`, the default scene, save data, or any existing scene.

## Limits of the exported source

- The chat export excluded image textures, meshes, Blender files, and imported resources. The scene references the original local asset paths; it is intended for **your complete Ashfall project**, not to run from the lightweight ZIP alone.
- The snapshot shows two standalone house scenes and one Crossroads maintenance station building. **There is no separate warehouse scene confirmed in this source snapshot**; the maintenance station is presented as the closest existing industrial building, not renamed into a warehouse.
- This is a layout and reference check, not a Godot runtime-tested build: confirm the scene opens in Godot and inspect the Debugger for missing dependencies.

## What to review

Suggested simple status marks: **Keep**, **Improve**, **Replace**, **Unused**. Do not delete anything during the first pass. Mark the notes here when you decide what assets the game should use.

### Buildings — 3 scene(s)

| Asset | Source scene | Decision / notes |
|---|---|---|
| Checkpoint House | `scenes/checkpoint_house.tscn` | Not reviewed |
| Blue Porch Cottage | `scenes/houses/blue_porch_cottage.tscn` | Not reviewed |
| Maintenance Station V03 | `assets/crossroads_v03/scenes/maintenance_station_v03.tscn` | Not reviewed |

### Crossroads modular kit — 8 scene(s)

| Asset | Source scene | Decision / notes |
|---|---|---|
| Corner 1M | `scenes/crossroads_kit/corner_1m.tscn` | Not reviewed |
| Floor 4M | `scenes/crossroads_kit/floor_4m.tscn` | Not reviewed |
| Metal Door | `scenes/crossroads_kit/metal_door.tscn` | Not reviewed |
| Roof 4M | `scenes/crossroads_kit/roof_4m.tscn` | Not reviewed |
| Wall Door 4M | `scenes/crossroads_kit/wall_door_4m.tscn` | Not reviewed |
| Wall Solid 2M | `scenes/crossroads_kit/wall_solid_2m.tscn` | Not reviewed |
| Wall Solid 4M | `scenes/crossroads_kit/wall_solid_4m.tscn` | Not reviewed |
| Wall Window 4M | `scenes/crossroads_kit/wall_window_4m.tscn` | Not reviewed |

### Crossroads v03 modules — 8 scene(s)

| Asset | Source scene | Decision / notes |
|---|---|---|
| Electrical Cabinet | `assets/crossroads_v03/scenes/electrical_cabinet.tscn` | Not reviewed |
| Floor Slab 4M | `assets/crossroads_v03/scenes/floor_slab_4m.tscn` | Not reviewed |
| Industrial Workbench | `assets/crossroads_v03/scenes/industrial_workbench.tscn` | Not reviewed |
| Roof Panel 4M | `assets/crossroads_v03/scenes/roof_panel_4m.tscn` | Not reviewed |
| Wall Doorway 4M | `assets/crossroads_v03/scenes/wall_doorway_4m.tscn` | Not reviewed |
| Wall Garage 4M | `assets/crossroads_v03/scenes/wall_garage_4m.tscn` | Not reviewed |
| Wall Solid 4M | `assets/crossroads_v03/scenes/wall_solid_4m.tscn` | Not reviewed |
| Wall Window 4M | `assets/crossroads_v03/scenes/wall_window_4m.tscn` | Not reviewed |

### Other construction variants — 3 scene(s)

| Asset | Source scene | Decision / notes |
|---|---|---|
| Damaged Wall | `assets/crossroads_refined/damaged_wall.tscn` | Not reviewed |
| Damaged Wall V02 | `assets/crossroads_v02/scenes/damaged_wall_v02.tscn` | Not reviewed |
| Steel Door V02 | `assets/crossroads_v02/scenes/steel_door_v02.tscn` | Not reviewed |

### Industrial and household props — 32 scene(s)

| Asset | Source scene | Decision / notes |
|---|---|---|
| Cable Spool | `scenes/props/cable_spool.tscn` | Not reviewed |
| Concrete Barrier | `scenes/props/concrete_barrier.tscn` | Not reviewed |
| Damaged Fence | `scenes/props/damaged_fence.tscn` | Not reviewed |
| Desk Radio | `scenes/props/desk_radio.tscn` | Not reviewed |
| Electrical Cabinet | `scenes/props/electrical_cabinet.tscn` | Not reviewed |
| Enamel Mug | `scenes/props/enamel_mug.tscn` | Not reviewed |
| Equipment Case | `scenes/props/equipment_case.tscn` | Not reviewed |
| Field Cot | `scenes/props/field_cot.tscn` | Not reviewed |
| Filing Cabinet | `scenes/props/filing_cabinet.tscn` | Not reviewed |
| Gas Cylinder | `scenes/props/gas_cylinder.tscn` | Not reviewed |
| Hand Truck | `scenes/props/hand_truck.tscn` | Not reviewed |
| Jerrycan | `scenes/props/jerrycan.tscn` | Not reviewed |
| Metal Bucket | `scenes/props/metal_bucket.tscn` | Not reviewed |
| Pendant Light | `scenes/props/pendant_light.tscn` | Not reviewed |
| Pipe Bundle | `scenes/props/pipe_bundle.tscn` | Not reviewed |
| Portable Generator | `scenes/props/portable_generator.tscn` | Not reviewed |
| Radiator | `scenes/props/radiator.tscn` | Not reviewed |
| Rubble Pile | `scenes/props/rubble_pile.tscn` | Not reviewed |
| Rusted Drum | `scenes/props/rusted_drum.tscn` | Not reviewed |
| Sandbag Stack | `scenes/props/sandbag_stack.tscn` | Not reviewed |
| Shelving Unit | `scenes/props/shelving_unit.tscn` | Not reviewed |
| Shipping Crate | `scenes/props/shipping_crate.tscn` | Not reviewed |
| Steel Drum | `scenes/props/steel_drum.tscn` | Not reviewed |
| Tool Box | `scenes/props/tool_box.tscn` | Not reviewed |
| Traffic Cone | `scenes/props/traffic_cone.tscn` | Not reviewed |
| Valve Pipe | `scenes/props/valve_pipe.tscn` | Not reviewed |
| Wall Fusebox | `scenes/props/wall_fusebox.tscn` | Not reviewed |
| Warning Sign | `scenes/props/warning_sign.tscn` | Not reviewed |
| Wooden Bench | `scenes/props/wooden_bench.tscn` | Not reviewed |
| Wooden Pallet | `scenes/props/wooden_pallet.tscn` | Not reviewed |
| Work Light | `scenes/props/work_light.tscn` | Not reviewed |
| Worn Mattress | `scenes/props/worn_mattress.tscn` | Not reviewed |

### Workshop equipment — 8 scene(s)

| Asset | Source scene | Decision / notes |
|---|---|---|
| Coiled Hose | `scenes/workshop/coiled_hose.tscn` | Not reviewed |
| Discarded Tyre | `scenes/workshop/discarded_tyre.tscn` | Not reviewed |
| Fire Extinguisher | `scenes/workshop/fire_extinguisher.tscn` | Not reviewed |
| Metal Chair | `scenes/workshop/metal_chair.tscn` | Not reviewed |
| Open Wood Crate | `scenes/workshop/open_wood_crate.tscn` | Not reviewed |
| Steel Ladder | `scenes/workshop/steel_ladder.tscn` | Not reviewed |
| Wheelbarrow | `scenes/workshop/wheelbarrow.tscn` | Not reviewed |
| Workbench Vise | `scenes/workshop/workbench_vise.tscn` | Not reviewed |

### Crossroads field props — 4 scene(s)

| Asset | Source scene | Decision / notes |
|---|---|---|
| Exposed Roots | `scenes/crossroads_props/exposed_roots.tscn` | Not reviewed |
| Hydraulic Jack | `scenes/crossroads_props/hydraulic_jack.tscn` | Not reviewed |
| Mushroom Cluster | `scenes/crossroads_props/mushroom_cluster.tscn` | Not reviewed |
| Work Trestle | `scenes/crossroads_props/work_trestle.tscn` | Not reviewed |

### Extra environment dressing — 7 scene(s)

| Asset | Source scene | Decision / notes |
|---|---|---|
| Dry Grass Tuft | `scenes/extra_dressing/dry_grass_tuft.tscn` | Not reviewed |
| Firewood Stack | `scenes/extra_dressing/firewood_stack.tscn` | Not reviewed |
| Garden Shovel | `scenes/extra_dressing/garden_shovel.tscn` | Not reviewed |
| Mushroom Cluster | `scenes/extra_dressing/mushroom_cluster.tscn` | Not reviewed |
| Scrap Sheet | `scenes/extra_dressing/scrap_sheet.tscn` | Not reviewed |
| Stone Scatter | `scenes/extra_dressing/stone_scatter.tscn` | Not reviewed |
| Wood Sawhorse | `scenes/extra_dressing/wood_sawhorse.tscn` | Not reviewed |

### Nature — 10 scene(s)

| Asset | Source scene | Decision / notes |
|---|---|---|
| Bare Tree | `scenes/nature/bare_tree.tscn` | Not reviewed |
| Dead Branch Pile | `scenes/nature/dead_branch_pile.tscn` | Not reviewed |
| Dry Bramble | `scenes/nature/dry_bramble.tscn` | Not reviewed |
| Fallen Log | `scenes/nature/fallen_log.tscn` | Not reviewed |
| Fern Clump | `scenes/nature/fern_clump.tscn` | Not reviewed |
| Forest Pine | `scenes/nature/forest_pine.tscn` | Not reviewed |
| Low Shrub | `scenes/nature/low_shrub.tscn` | Not reviewed |
| Mossy Boulder | `scenes/nature/mossy_boulder.tscn` | Not reviewed |
| Reed Clump | `scenes/nature/reed_clump.tscn` | Not reviewed |
| Tree Stump | `scenes/nature/tree_stump.tscn` | Not reviewed |

### Field gear and pickups — 11 scene(s)

| Asset | Source scene | Decision / notes |
|---|---|---|
| Handheld Flashlight | `scenes/items/handheld_flashlight.tscn` | Not reviewed |
| Held Antiseptic | `scenes/items/held_antiseptic.tscn` | Not reviewed |
| Held Bandage | `scenes/items/held_bandage.tscn` | Not reviewed |
| Held Batteries | `scenes/items/held_batteries.tscn` | Not reviewed |
| Held Detector | `scenes/items/held_detector.tscn` | Not reviewed |
| Held Field Radio | `scenes/items/held_field_radio.tscn` | Not reviewed |
| Held Food Tin | `scenes/items/held_food_tin.tscn` | Not reviewed |
| Held Water Bottle | `scenes/items/held_water_bottle.tscn` | Not reviewed |
| Bandage | `scenes/loot/bandage.tscn` | Not reviewed |
| Batteries | `scenes/loot/batteries.tscn` | Not reviewed |
| Food Tin | `scenes/loot/food_tin.tscn` | Not reviewed |

## Proposed project organization (future discussion only)

- `scenes/testing/` — inspection stages and isolated tests.
- `scenes/houses/` — individual authored buildings.
- `scenes/props/` and `scenes/workshop/` — props, not entire environments.
- `assets/crossroads_v03/` and `scenes/crossroads_kit/` — modular building components.
- Keep full playable levels in their existing locations until a deliberate restructure.

**Do not move/rename assets now**: other scenes refer to their current paths. This catalogue is the starting point for a cleanup plan.
