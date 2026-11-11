# Ashfall — Abandoned Interiors Pack

This is an original, **non-interactive** environmental dressing set for buildings across Ashfall. All models are static decoration; they are NOT usable equipment, loot containers, crafting resources, or physics pickup items.

## 16 asset families plus 1 damage variant

**Living rooms:** sagging sofa, battered armchair, cracked CRT television, crooked wall mirror.

**Kitchens/dining rooms:** splintered dining table, damaged kitchen cupboard, broken crockery scatter, rusted enamel kettle.

**Bedrooms/occupied spaces:** tilted wooden dresser, torn interior curtains, threadbare area rug, faded photo frame cluster.

**Structural decay:** fallen ceiling tile pile, broken ceiling fan, peeling wallpaper panels, dusty cardboard box stack.

**Variant:** `sagging_sofa_torn.glb` and `sagging_sofa_torn.tscn` have exposed cushion foam and spring detail.

## Directory layout

- `assets/decorative_interiors/models/*.glb`: all original geometry, self-contained glTF 2.0 binaries with basic PBR factors
- `scenes/decorative_interiors/*.tscn`: reusable non-interactive `StaticBody3D` scenes, with basic box collision or disabled collision for flat clutter
- `scenes/decorative_interiors/gallery_all_16.tscn`: inspection scene, including the additional sofa damage variant
- `assets/decorative_interiors/source/generate.cjs`: source authoring generator (Node.js 18+)
- `assets/decorative_interiors/source/validate_interiors.py`: offline structural integrity validation

Run from project root:

```powershell
node assets/decorative_interiors/source/generate.cjs
python assets/decorative_interiors/source/validate_interiors.py
```

## Placement rules

- Decorate interiors **only after reviewing** each prefab in its inspection gallery. Do not spawn these automatically in existing rooms.
- Keep doorways, stairs, escape routes, and player navigation clear.
- Group furniture logically with signs of abandonment (dirt, wear, inconsistent alignment).
- Wall mirrors and wallpaper panels should be mounted to walls via scene placements; curtain mesh hangs from its own rail. No opening or closing interactions.
- The large sofa, chair, dresser, cupboard and table use basic blockout collision pending editor refinement.
- Thin decoration (rug, plate debris, ceiling tile debris) has collision disabled so it doesn't catch player movement.

## Validation / merge gates

- [x] Original GLB mesh files and reusable scene wrappers generated
- [x] No item pickups, interactions, inventory edits, gameplay scripts or main-scene changes
- [ ] Godot 4.7 headless import and gallery load pass
- [ ] Visual inspection in Godot and art refinement: materials, damage, scale, pivots, collision
- [ ] Add convincing texture/normal/roughness maps as needed; current GLBs have baked procedural albedo, normal, and roughness maps
- [ ] Verify repeated props and variants under Ashfall's dark lighting
- [ ] User approval before merge

**Status:** The models are a first-pass procedurally authored art pack, not yet production-art finished. Keep draft PR #4 unmerged. The 16 exterior decorative props in `assets/decorative_world` also await in-editor visual art review.

## Latest technical-art pass (November 10, 2026)

All 33 GLBs have been processed with an original, reproducible procedural PBR surface pass (`assets/decorative_world/source/upgrade_pbr_surfaces.py`). Maps are embedded in the GLB files with UVs. **This improves surface variation but does not establish photorealistic or production-ready art.** The geometry still needs in-editor art review and refinement. See `assets/decorative_world/ART_REVIEW_2026-11-10.md` and PR #4 for outstanding gates.
