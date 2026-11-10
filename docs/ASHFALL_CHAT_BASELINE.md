# Ashfall source snapshot — first review

**Snapshot received:** November 9, 2026 (the ZIP's external timestamp is not proof of every file's edit time). 396 entries, approximately 28.3 MiB uncompressed; approximately 5.2 MiB compressed. This was a **source-only** review, not an engine playtest.

## Confirmed architecture

- `project.godot` starts `res://scenes/ashfall_editable.tscn` (Godot 4.7 feature set).
- `game.gd` orchestrates the existing expedition. `player.gd`, `hud.gd`, `inventory_screen.gd`, and `item_catalog.gd` implement first-person movement, HUD, inventory, and consumables.
- `expedition_areas.gd` + `area_link.gd` already connect the perimeter to North Relay. In-session state is retained by keeping areas resident, rather than by disk saving.
- `crossroads_encounter.gd` has the generator-related encounter and objective logic. `village_stalker.gd` and `pursuit_path.gd` implement threat perception, searching, chasing, and obstacle routing.
- `scenes/relay_yard.tscn`, `scenes/houses/*`, and Crossroads assets show substantial existing authored environment work. The scene files often refer to heavy GLB/model resources, which are absent from the source-only ZIP by design.
- `tests/test_area_journey.gd` and other GDScript tests are present; their existence does not prove they passed against this snapshot.

## Existing limitations / caution

- The project documentation says there is **no disk save** yet. A restart resets expedition progress.
- `README.md` still mentions `main.tscn` in its file index; the actual main scene in `project.godot` is `scenes/ashfall_editable.tscn`. Treat current project settings as authoritative.
- The broader late-1980s rural-district and art direction lives in `ASHFALL_MASTER_ROADMAP.md`; avoid introducing conflicting aesthetics.
- The source ZIP cannot render or playtest your real imported meshes/textures. No new art should be certified from this ZIP alone.
- Current player interaction, loot, generator, recording, and sample/extraction logic should not be replaced with a second competing system.

## Recommended first gameplay patch (not included in the bridge test)

**Disk-save design and audit** is a high-value next step, but it needs an inventory of stable state IDs first. Prefer a small verified save system that captures: active area, player location/condition, inventory/equipment, Crossroads stage, recovered/reported objectives, loot containers, and encounter rolls. It should not silently claim complete world persistence or overwrite existing in-session state. Add automated save/reload tests and check with Godot before enabling in the player's release build.

## Update-delivery approach

Use `Export-Ashfall.ps1` for new snapshots and `Install-AshfallUpdate.ps1` for checksum-verified, explicitly approved, no-delete patches. Every patch declares new and replaced files and refuses to overwrite a locally edited file unexpectedly. Keep version control or a full project backup in addition to patch-level backups.
