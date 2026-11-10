# Ashfall — extra dressing, revision 2

Seven improved, reusable assets are available in `res://scenes/extra_dressing/`. They have ground-level origins, metre scale, shared materials, and no attached names or viewing equipment.

| World scene | Display name | Features |
| --- | --- | --- |
| `wood_sawhorse.tscn` | Weathered timber sawhorse | Splayed legs, diagonal brace, straps, washers and hex bolts; open collision between legs |
| `garden_shovel.tscn` | Worn garden shovel | Curved pointed blade, worn lip, socket and rivets, wooden shaft and open D handle |
| `scrap_sheet.tscn` | Bent corrugated steel | Continuous corrugated surface, edge curl, thin cut edges and roofing fasteners |
| `firewood_stack.tscn` | Split firewood stack | Irregular log sections, exposed split faces, growth rings and checks |
| `mushroom_cluster.tscn` | Woodland mushrooms | Varied curved caps, rolled lips, underside gills and stems |
| `dry_grass_tuft.tscn` | Dry meadow grass | Curved tapered blades, seed stalks and subtle wind |
| `stone_scatter.tscn` | Weathered stone scatter | Irregular grounded stones, varied tones and dirt near ground contact |

## View the named gallery

Double-click `Inspect Extra Props.cmd` in the Ashfall project folder, or open `res://scenes/extra_dressing_gallery.tscn` in Godot and press **F6**.

- The overview arranges all seven props on numbered display plinths, with names and measured dimensions.
- Press **1–7** or click a bottom button to inspect one prop.
- Drag the left mouse button to orbit; use the mouse wheel to zoom.
- Use the left/right arrow keys to browse and **H** for the overview.

The gallery instances the ordinary world scenes at their original scale. All name labels, size captions, display plinths, camera controls and lighting belong to the gallery. For placement, drag an individual `.tscn` from `scenes/extra_dressing/` into your world. Use the normal world scenes rather than copying a display group.

## Materials and collision

The four larger props have simplified static collision. The small natural decorations have none. All seven are decorative; they do not provide tool, harvesting or storage interactions.

Materials for the extension are shared external resources in `res://assets/extra_dressing/`. These original procedural materials provide oxidation, steel, bark, endgrain, cap/stem variation, dry grass and stone surfaces. Timber reuses the project's existing scanned wood resource; its credits remain in `PROP_LIBRARY.md` and `HOUSE_NOTES.md`. No newly downloaded imagery is used.

## Edit and regenerate

`extra_dressing_builder.gd` contains the editable geometry/material source. `bake_extra_dressing.gd` generates only these seven scene files, the extra material resources, the gallery and `assets/extra_dressing/catalog.json`. Preserve manual edits to those generated files before rebaking.

Run Godot with `--headless --path . --script res://scripts/authoring/bake_extra_dressing.gd` to regenerate, and `--headless --path . --script res://tests/test_extra_dressing.gd` to validate.

Validation covers all seven world scenes, their labels and cameras being absent, finite mesh geometry and bounds, normals, triangle counts, simplified collision, physical sawhorse clearance, gallery references to the same world assets, names, keyboard focus, zoom and overview controls. Visual review uses the project's Forward+ renderer.
