# Ashfall prop library

32 reusable props are saved under `scenes/props/`. Open `scenes/prop_gallery.tscn` and press **F6** to browse the whole set. Click the gallery window to capture the mouse, then use the existing WASD/mouse controls. Escape releases the mouse; F toggles the inspector's torch.

**World-placement rule:** all default scenes in `scenes/props/` have no attached text. The gallery uses `scenes/props_preview/` variants with fitted preview lettering. Gallery captions are display furniture, separate from the prop itself. Use the default scenes when placing objects in a level. The warning sign's preview wording now wraps over four lines, and all preview text is measured against its panel dimensions before baking.

To use an asset, drag its `.tscn` from Godot's FileSystem panel into your scene. Assets use metres, with their origin at the bottom centre and their front facing local +Z. Keep scale at `(1, 1, 1)` for the intended proportions. The editable mesh and collision nodes remain inside each scene. Shared materials live in `assets/props/`.

| Category | Scenes |
| --- | --- |
| Storage | `steel_drum`, `rusted_drum`, `wooden_pallet`, `shipping_crate`, `equipment_case` |
| Utilities | `jerrycan`, `gas_cylinder`, `cable_spool`, `portable_generator`, `electrical_cabinet`, `wall_fusebox`, `valve_pipe` |
| Checkpoint | `traffic_cone`, `concrete_barrier`, `warning_sign`, `damaged_fence`, `sandbag_stack` |
| Workshop | `work_light`, `hand_truck`, `tool_box`, `pipe_bundle` |
| Interiors | `shelving_unit`, `filing_cabinet`, `wooden_bench`, `radiator`, `field_cot`, `worn_mattress`, `pendant_light` |
| Small objects | `desk_radio`, `metal_bucket`, `enamel_mug` |
| Ground dressing | `rubble_pile` |

These are original static environment props. Large objects have simplified static collision. Small rubble intentionally has none so it does not catch the character's capsule. Shelves use separate shelf and upright colliders, keeping the spaces between shelves open. The bucket and mug use simple solid collision rather than simulated hollow containers. The generator, radio, toolboxes, and cabinets are visual props; they do not yet have sounds, moving parts, inventory, or interactions. The tripod light includes an `OptionalWorkLight` child that is off by default; enable its visibility in the Inspector when needed.

## Current placement

`scenes/checkpoint_props.tscn` groups 32 text-free prop instances around the checkpoint. `game.gd` instantiates that group beside the existing house. Storage and fuel equipment sit outside; the interior gets shelving, tools, a filing cabinet, a radio, a mug, and a radiator. A cot and mattress sit in the opposite checkpoint hut. The entrance, medical-supply sight line, main road, and extraction terminal remain accessible. The existing player controller was not modified for this prop pass.

## Materials and reference

The kit reuses CC0 wood, concrete, and masonry scans listed in `assets/materials/sources.json` and `HOUSE_NOTES.md`. Reclaimed wood uses a desaturated, reduced-contrast derivative of the existing scanned wood albedo, saved as `assets/props/reclaimed_wood.res`; the original house material remains separate. Painted steel uses original procedural paint wear. Shared material files avoid duplicating texture sets for every instance.

- [EPAL Euro pallet dimensions and construction](https://www.epal-pallets.org/eu-en/load-carriers/epal-euro-pallet): the pallet uses the reference 1.2 × 0.8 × 0.144 metre envelope. It does not reproduce EPAL logos or certification stamps.
- [DDR generator reference photographs](https://www.chemnitz-auktionshaus.de/feuerwehrtechnik/ddr-notstromaggregat--id-1740-item.html): tubular frame, fuel tank, engine block, and control panel informed the generator silhouette. The model is an original composite design; no reference photograph is included as a game texture.
- [House reference notes](HOUSE_NOTES.md): weathering palette and existing CC0 material credits.

## Rebuild and review

`prop_builder.gd` defines the assets; `bake_props.gd` writes their native Godot scenes, catalog, gallery, and checkpoint dressing group. Rebuilding **replaces these generated scenes**, so preserve any manual scene edits first. Shared materials are retained by default; pass `--refresh-prop-materials` after the script separator to deliberately regenerate them.

From the project root, run your Godot console executable with:

```text
--headless --path . --script res://scripts/authoring/bake_props.gd
--path . res://scenes/prop_gallery.tscn -- --prop-review
--path . -- --smoke-test
```

`assets/props/catalog.json` records the scene paths, preview paths, approximate sizes, categories, and collision shape counts. `reviews/props/prop-catalog.png` shows all 32 assets rendered by the actual engine. The gallery and selected individual render captures are in the same folder.

Validation includes loading every asset, checking geometry and collision, verifying no Label3D nodes in world props, checking preview text bounds, rendering the gallery and all 32 assets, and running the expedition's walking-entry, wall-collision, healing, sample-pickup, and extraction checks. Props share the current prototype's art direction and can receive more bespoke wear, damage, and texture variations in later passes.
