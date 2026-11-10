# Crossroads / North Relay slice

Implemented directly in the existing project, November 8, 2026. No content was deleted, no source assets were regenerated, and nothing was pushed or published.

## Review and direction

The strongest existing work is the editable Crossroads station and yard, the detailed checkpoint/cottage assets, the inventory and authored item grips, and the generator's noise-driven encounter. These remain the foundation. The original sample/extraction mission, movement, consumables, anomaly behavior, sound controls and starter loadout remain available.

The main gaps were area connections, progress across visits, and village enemies dropping immediately back to patrol after losing contact. Pursuit previously relied on turning sideways when a short ray hit a wall. This pass adds a connected exploration loop and collision-sampled route planning while retaining the existing creature model, animation and perception rules.

## Play the new loop

1. Start normally. Visit Crossroads, east of the entry gate, and interact with its generator. Wait for warmup behind solid cover and retrieve the diagnostic.
2. Find the lit SERVICE PASSAGE cabinet east of the starting road (world position 8, 0, 24). Press E to travel to North Relay. Before diagnostic retrieval it reports that power is unavailable.
3. Explore either side of the cottage. The west lane passes an anomaly; the east yard contains supplies. The recorder sits on the rear workbench beneath an amber lamp. E recovers it. The field receiver points toward it, then toward the return passage.
4. Return through the cabinet at the south fence. Report at the original entry gate. If both reports are carried, interact twice: Crossroads awards a battery, North Relay awards a bandage. Each reward is granted once.
5. Continue the original research sample mission and extract. Tab and Q retain the existing inventory/item controls.

The village has an 80% presence roll and North Relay a 70% roll, resolved once at expedition creation. Revisiting never rerolls or respawns a creature. Crossroads keeps its authored generator encounter. Enemies hear movement, see within a forward cone with solid-wall occlusion, chase, search and eventually disengage. Footsteps now sound for all creatures. Crouching behind solid cover is the hiding mechanic; bushes do not grant invisibility.

## Structure and editing

- `scenes/relay_yard.tscn`: separately editable cottage, ground, recorder, workbench, cover and boundaries, using existing project assets.
- `expedition_areas.gd`: area registration, authored prop placement, presence rolls, reports and transition state.
- `area_link.gd`: exported destination, arrival, heading and power requirement for connections.
- `pursuit_path.gd`: collision-sampled local routing with capsule clearance and no diagonal corner cutting.

The small slice keeps areas resident, geographically separated in the same world. The same player and inventory cross between them, and doors, caches, records and threats retain their real state. Inactive-area creatures and the station encounter suspend. Add packed areas and links through the coordinator. This is not streaming and it does not provide disk saves; restarting resets the expedition. The passages currently use an immediate transition rather than a loading corridor or travel animation.

## Verification

The existing Crossroads encounter test passed before changes. Godot 4.7.2 import completed successfully using the installed portable editor. The rendered smoke test passed movement, ground/house collision, pause, anomaly damage, healing, sample pickup and extraction.

All 18 existing `test_*.gd` scripts were run. The vegetation/dressing test requires a graphics driver and passed when rerun with Vulkan. The editable-world check was updated to expect the fourth anomaly and to retain its text-free check on the original editable world; it passed. The other 16 passed, covering items, inventory, grips, character assets, station integration/collision, audio settings, cottage surfaces and expedition sight/sound/attacks.

`tests/test_area_journey.gd` checks passage lock/unlock, ground at arrival, retained health/inventory, walking both flanks using movement input, real interaction rays, recorder recovery, rewards, revisits, search expiry, physical pursuit around a solid wall, and suspension outside the active area. It deliberately positions actors for individual scenarios and forces the present encounter branch; this is an automated integration test, not an uninterrupted manual playthrough. `--capture` saves actual renderer images under `reviews/survival-slice/`.

Manual review: launched the graphical game, entered through the opening menu and inspected the starting scene. Desktop keyboard inputs did not reliably produce observable game actions, so inventory, traversal and encounters are validated by automated gameplay checks, not claimed as manually completed. Rendered North Relay views were inspected separately.

## Remaining work

- North Relay is an initial asset-reuse layout. Terrain edges, gate architecture, vegetation density and bespoke environmental storytelling need an art pass; its boundary collision extends beyond the visible damaged fencing.
- Replace the existing procedural creature with a fully authored original rig and richer search/attack animation and sound. No monster art was replaced in this pass.
- Navigation currently samples a local flat grid on demand. Multi-floor routes, stairs, moving obstacles, performance at scale and every doorway need further coverage; a baked navigation solution is appropriate for larger levels.
- Add disk saves and area streaming when the world grows; retain stable area/object IDs during that change.
- Complete a human end-to-end pacing and difficulty playthrough with headphones. The starter pack remains intentionally generous for the existing item review workflow.
- Some headless tests report ObjectDB objects at exit. No runtime script errors were observed in the successful rendered journey and smoke runs.

The smoke test regenerates `preview.png`; test logs and additional review images are local outputs.
