# Station 04 — Environment quality pass (draft review)

## Scope

This expands the existing grounding work in PR #5 **in the playable Station 04 scene**, not the separate regional preview from PR #6. The goal is to replace obvious prototype ground presentation while keeping the currently working expedition intact.

### Implemented in source

- Keep Station 04 ground/collider at 460 × 460 m, top y = 0, with unchanged player and objective placement.
- Blend road, service-yard, dirt shoulders, ruts, and environmental weathering in **world-space**, rather than showing floating rectangular platforms.
- Reuse the already licensed Poly Haven forest-ground and worn-concrete **albedo, tangent-space normal, roughness, and AO maps** in the spatial material. No new asset download or license.
- Add a deterministic, low-cost procedural **horizon relief** beyond the existing x = ±86 m and z = ±81 m collision limits. The near skirt stays below the world floor to avoid a hard seam; the inner gameplay surface remains completely flat.
- Add seven intentionally located **leaf-and-gravel microdressing zones** using only two collision-free MultiMesh instances. The central access road, house thresholds, objective table and generator access are not deliberately obstructed.
- Keep the existing overcast sky, environmental fog, lighting, architecture, character, AI, and mission scripts unchanged. The separate region-road experiment stays separate.
- Preserve hidden old road and yard meshes for rollback; keep mushroom display size at its original 1×.

## Edit controls

- Surface: `EditableWorld/Terrain/WalkableGround/VisibleGround` shader parameters, including soil/road color, normal strength, edge wear and wetness.
- Distant visual relief: `EditableWorld/Terrain/HorizonRelief` export controls for angular detail, silhouette height and visibility.
- Surface fragments: `EditableWorld/GroundLitter` enable/disable; authored zone extents and counts live in `scripts/runtime/station04_surface_dressing.gd`.

**Non-goals:** this is not heightmap collision, new playable land, streaming, weather gameplay, combat, new POIs, or the 2.4 km terrain project.

## Verification

Static integration/source checks are possible from the repository. **No Godot renderer execution, visual inspection or FPS profiling was performed by this change.** Do not mark visually approved or merge solely on static checks.

Suggested local command from the repo root (with a compatible Godot 4.7 editor):

```powershell
& "..\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script "res://tests/check_station_grounding.gd"
```

Then **F5** the actual Station 04 main scene using Forward+. Inspect from the gate, the road north, both road shoulders, the service yard, the cottages, the sample, and the outer tree line. Check that roads are flush, the horizon rises outside the fence, that leaves and gravel look subtle rather than patterned, and that nothing floats or disappears into the ground. Turn the relief off in the inspector to compare before/after; then disable the ground litter separately.

Required manual regression: walk and sprint on the road; enter every previously reachable house and the maintenance station; start the generator; use the service passage; return, recover the research sample and extract. Verify existing health/stamina, flashlight, loot and threat behavior. Watch Output for shader/GDScript errors.

Performance review: collect GPU/CPU frame times and FPS from the same camera position with `show_relief` and `draw_surface_detail` both enabled/disabled, on the same intended renderer and hardware. Disable or optimize these visual systems if they cause material regression. Record a real render capture of the gate/road and a second capture from the service yard before deciding merge.

## Rollback and compatibility

Only the Station 04 scene, the station ground material, two new optional visual scripts, this documentation, and the existing ground assertion test change. Current gameplay code, props, active area links, collisions, and save behavior remain unchanged. The previous road/yard meshes are still available but hidden. The main branch is untouched until review.
