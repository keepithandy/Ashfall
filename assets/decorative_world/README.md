# Decorative world props — 16-asset draft pack

**Scope:** Static, non-interactive 3D scenery only. These are environmental dressing assets, **not** inventory objects, loot, usable containers, quests, or gameplay systems. The work is isolated to a feature branch and draft pull request. Nothing is added to the main station scene.

## Current assets (16 of 16 requested unique items modeled)

### Roads and checkpoints
1. Bent guardrail — `bent_guardrail`
2. Abandoned/collapsed bus shelter — `collapsed_bus_shelter`
3. Tire pile — `discarded_tire_pile`
4. Fallen utility pole with dead cables — `fallen_utility_pole`

### Residential and abandoned settlements
5. Rusted roadside mailbox — `rusted_mailbox`
6. Sagging porch chair — `sagging_porch_chair`
7. Cracked clay plant pots with dead branches — `cracked_plant_pots`
8. Torn clothesline with faded cloth — `torn_clothesline`

### Industrial and maintenance
9. Crushed ventilation duct — `crushed_ventilation_duct`
10. Collapsed cable tray — `collapsed_cable_tray`
11. Corroded sheet-metal stack — `corroded_sheet_metal_stack`
12. Broken industrial window frame — `broken_factory_window`

### Wilderness and outskirts
13. Rotting picnic table — `rotting_picnic_table`
14. Damaged footbridge fragment — `damaged_footbridge_fragment`
15. Roadside memorial — `roadside_memorial`
16. Cracked concrete drainage culvert — `broken_drainage_culvert`

## Directory structure

- `models/<prop>.glb`: self-contained, original glTF 2.0 binary geometry with PBR factors and visible weathering geometry
- `../../scenes/decorative_world/<prop>.tscn`: reusable Godot 4 `StaticBody3D` scene with simple collision
- `../../scenes/decorative_world/gallery_roadside.tscn`: original first-four gallery
- `../../scenes/decorative_world/gallery_all_16.tscn`: overview of all sixteen models in four thematic rows
- `source/generate_props.cjs`: reproducible Node.js 18+ procedural authoring source for the twelve new props (first four were authored in the first PR commit)
- `source/.gdignore`: keep source code out of Godot's asset importer

To rebuild the 12 new model files, from the project root run:

```powershell
node assets/decorative_world/source/generate_props.cjs
```

Node.js is required to execute the source generator; exported GLBs are already included in this PR.

## Placement guidance

**Roads:** Combine guardrails, shelter, tires, utility poles, and scattered roadside debris irregularly. Avoid overly symmetrical repetition.

**Residential:** Mailboxes, chairs, planters and clotheslines at roadsides or homes, with different rotations and small offset variation.

**Industrial:** Use duct, cable tray, oxidized sheet-metal and shattered window with existing cabinets, drums and workbenches. Keep silhouette clear for gameplay navigation.

**Wilderness:** Place the old picnic table, broken bridge fragment, memorial and culvert in convincing edge-of-settlement or drainage sites. These are scenery only; no crossing, activation or search mechanic.

## Quality / test gates before merge

- [ ] Import all 16 GLBs in target Godot version and confirm no errors.
- [ ] Open `gallery_all_16.tscn`, verify orientation, scale, pivot and geometry for each prop.
- [ ] Inspect PBR material colors/transparency under dark and neutral lighting; improve realism with authored textures/normal maps where needed.
- [ ] Confirm normals/winding, no gaps or floating geometry, and acceptable triangle counts.
- [ ] Verify static collision alignment in Godot's debug collision view; correct overly broad box collisions on irregular props.
- [ ] Add purposeful intact/weathered/heavily damaged variants for common reusable props as art quality requires.
- [ ] Confirm props are not scripted, interactive, pickupable or persisted in save data.
- [ ] Check imported gallery and PR changes in CI or locally; no unrelated project modifications.
- [ ] Place approved props into level scenes only in a separate deliberate dressing pass.
- [ ] Review visually in-game before promotion from draft to ready-for-merge.

**Honest state:** All sixteen distinct asset definitions are present, but this is still a **procedurally modeled first pass** with baked tileable procedural albedo, normal, and metallic/roughness maps. It is NOT Godot-playtested or approved as final realistic production art. Keep this PR a draft and DO NOT MERGE until the gates above pass.

## Latest technical-art pass (November 10, 2026)

All 33 GLBs have been processed with an original, reproducible procedural PBR surface pass (`assets/decorative_world/source/upgrade_pbr_surfaces.py`). Maps are embedded in the GLB files with UVs. **This improves surface variation but does not establish photorealistic or production-ready art.** The geometry still needs in-editor art review and refinement. See `assets/decorative_world/ART_REVIEW_2026-11-10.md` and PR #4 for outstanding gates.
