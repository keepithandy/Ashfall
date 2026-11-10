# Crossroads prop set 02

Four original static props for Ashfall's maintenance station and its wooded surroundings. They are separate from the playable world, so the level layout and existing prop libraries are unchanged. The scenes use metres with the origin at ground level, and contain no in-world text.

| Scene | Design | Approximate extent (m) | Collision |
| --- | --- | --- | --- |
| `hydraulic_jack` | Wheeled low-profile workshop jack with pump, lifting arm, saddle, and handle | 1.13 × 1.05 high × 0.34 | Simplified chassis box; handle and wheels are visual |
| `work_trestle` | Weathered wooden work trestle, splayed legs, cross-bracing, and steel end straps | 1.12 × 0.83 high × 0.54 | Table and side-frame boxes |
| `exposed_roots` | Broken root crown, exposed branching roots and small moss patches | 1.39 × 0.45 high × 1.28 | None, to avoid snagging movement |
| `mushroom_cluster` | Seven small brown-capped mushrooms in different sizes | 0.46 × 0.23 high × 0.36 | None, to avoid snagging movement |

The jack and trestle are set dressing: the jack does not lift, roll, or respond to interaction. The refinement adds bent and forked roots, broken wood, small clinging soil and moss forms, irregular mushroom caps, curved stems, and radial underside gills. The workshop props have extra fasteners, linkage and bracing, with more subdued steel and rust finishes. These are still an art pass and need further close-up texture work and variation to meet a photoreal benchmark. The mushrooms are fictional set dressing, not a species identification or indication of edibility.

## Use and review

Open `scenes/crossroads_props/gallery.tscn` and run the current scene to view all four. The mushrooms are enlarged 2.5× **only in the gallery** for visibility. Drag the individual `.tscn` files from the same folder into a level at scale `(1,1,1)`. In the gallery, the jack and trestle sit in front; roots and mushrooms sit behind.

`assets/crossroads_props/source/crossroads_props.blend` contains the editable geometry grouped by prop. `build_props.py` regenerates the blend and the four GLBs using Blender 4.5. Regeneration overwrites those files. A `.gdignore` keeps the Blender source out of Godot's import pipeline. The exported meshes merge the modelling parts into a single mesh with material surfaces per prop; the editable Blender collections retain individual parts.

The scene wrappers apply shared Ashfall iron, wood, rubber and end-grain materials, plus kit-specific procedural painted steel, rust, and natural materials in `assets/crossroads_props/materials`. The wood material depends on the existing CC0 texture credited in `HOUSE_NOTES.md` and `assets/materials/sources.json`. GLB fallback materials use simple colours; use the wrapper scenes in Godot to get the shared materials and intended collision.

Validation: open the project in Godot 4.7 to import, then run `godot --headless --path . --script res://tests/test_crossroads_props.gd`. The check loads each asset, verifies mesh surfaces and shared materials, checks actual vertex bounds and ground alignment, and tests collision with physics rays. Visual review uses `gallery.tscn` in the engine. The current four meshes contain approximately 2,648, 2,168, 3,576, and 5,544 triangles respectively; the detailed mushroom cluster should be evaluated before dense placement. LODs, bespoke close-up wear, animation, and gameplay interaction remain future work.

