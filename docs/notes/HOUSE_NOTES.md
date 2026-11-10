# Checkpoint house — first realism pass

The left house at the entry checkpoint is the first environment asset to move beyond the blockout. The visual direction is an abandoned perimeter office with plaster over masonry, worn green timber joinery, a corrugated pitched roof, and a simple administrative interior. It is an original composite design rather than a reconstruction of a specific real building.

## Reference study

- [Old Pripyat checkpoint photographs, Forgotten Chernobyl](https://www.forgottenchernobyl.net/old-pripyat-checkpoint-and-lead-glass-windows): utilitarian building proportions, corrugated roof, pale walls, runoff staining, and vegetation at the foundation. The photographs are reference only and are not used as game textures.
- [Weathered village facade photograph](https://www.mediakatalogas.lt/nuotrauka/484339/senas-pastatas-Kaimas-nemokamos-nuotraukos-nemokami-vaizdai): recessed multi-pane timber windows, broken plaster edges, masonry showing underneath, and damp near ground level. Reference only.
- [Godot material documentation](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html): normal, roughness, occlusion, transparent glazing, and triplanar material setup.

## What changed

The house has a 7 × 6 metre footprint, 34 cm masonry walls, a roughly 2.3 metre doorway, and a pitched roof rising to approximately 4.2 metres. The windows are physical openings with inset frames, mullions, sills, and separate intact and broken glass pieces. An open planked door has braces and a latch. The roof has overhangs, fascia, ridge cap, gutters, drainpipe, and a chimney.

The lower facade exposes masonry beneath irregular plaster patches, with runoff and damp staining at separate scales. Small rubble and weeds connect the foundation to the ground. Interior additions include a worn concrete floor, painted plaster wall, desk, chair, locker, notices, and a warm wall lamp. The medical supplies now sit on the desk.

Scanned materials include albedo, OpenGL normal, roughness, and ambient occlusion maps. Mipmaps, anisotropic filtering, and normal-map import settings reduce shimmer. Forward+ lighting adds contact shading and indirect screen-space light. Separate transparent glass panes leave the interior visible through the windows.

## Asset credits

All five downloaded material sets are [CC0 from Poly Haven](https://polyhaven.com/license). Each source URL, author credit, map URL, dimensions, and verified MD5 download checksum is recorded in `assets/materials/sources.json`.

- [Rough Plaster Brick 02](https://polyhaven.com/a/rough_plaster_brick_02) — Rob Tuytel.
- [Concrete Floor Worn 001](https://polyhaven.com/a/concrete_floor_worn_001) — Dimitrios Savva and Rico Cilliers.
- [Wood Peeling Paint Weathered](https://polyhaven.com/a/wood_peeling_paint_weathered) — Dimitrios Savva and Rob Tuytel.
- [Rusty Corrugated Iron](https://polyhaven.com/a/rusty_corrugated_iron) — Charlotte Baglioni.
- [Grey Plaster](https://polyhaven.com/a/grey_plaster) — Rob Tuytel.

## Edit, rebuild, and review

Open `scenes/checkpoint_house.tscn` in Godot to edit the saved scene normally. Rebuilding overwrites that scene, so preserve any manual edits before running the builder.

From the project directory in PowerShell:

```powershell
$env:APPDATA = Join-Path (Get-Location) '..\Godot\userdata'
& '..\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://scripts/authoring/bake_house.gd
& '..\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . -- --house-review
& '..\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . -- --smoke-test
```

The smoke scenario verifies walking through the entrance without jumping, wall collision, access to medical supplies, and the existing expedition loop. Review captures use the actual game renderer rather than an offline illustration. The fixed close-up view retains a matching `house-detail-before.png` for comparison.

## Remaining art work

This is the first detailed asset pass. More irregular plaster damage, subtle edge bevels, bespoke dirt masks, furniture wear, higher quality foliage, and a matching terrain treatment would improve realism further. The other buildings, road, perimeter wall, and forest remain blockouts, so the new house is currently more detailed than its surroundings.
