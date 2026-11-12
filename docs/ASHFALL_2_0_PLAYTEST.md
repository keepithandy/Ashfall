# Ashfall 2.0 — integrated playtest milestone

**Milestone:** 2.0 playtest · **Date:** 2026-11-11 · **Engine:** Godot 4.7.2 / Forward+  
**Status:** integrated playable test build; visual, performance and full expedition signoff still require in-editor testing on the target PC. **Not a finished/AAA production release.**

## Purpose

Ashfall 2.0 is a coherent, playable checkpoint that consolidates the work already merged into `main`, rather than starting a second incompatible map or rewriting gameplay. It centers on **grounded exploration, resource scavenging and curiosity-driven danger**, with original environmental horror and occasional pursuit. The game remains **level-based with an open-world feel**. Light, grounded and brutal area difficulty, with an optional Hardcore modifier for each, are intended future work and **are not presented as implemented features**.

## What is included

### Playable Station 04

- The original expedition's sample collection, extraction, supplies, inventory, hazards, stamina, flashlight, sound settings and linked Crossroads / North Relay area journey remain in place.
- Station 04's environment passes added grounded terrain and road/yard materials, wet-ground weathering, atmospheric fog/lighting and decorative field detail (PR #5).
- Multi-profile distant forest, supplementary near-tree canopies, saplings and a layered visible ridgeline improve depth (PRs #7 and #8).
- Distant hill mesh winding and skirts were corrected to address see-through geometry (PR #9). **The final silhouette needs visual confirmation**.
- Station 04 alone uses a 900 m camera far plane, paired with scene fog tuning; other areas keep their authored budgets (PR #10).

### Personal screen-space interface

- No intentional floating 3D information labels in Station 04. Prompts, objectives, hazard/readout information and equipment status use the anchored HUD (PR #10).
- The **Field Journal** finish is the default, with **Signal Receiver** and **Worn Amber** alternatives. Press **F10** to cycle them; the selected finish is stored as a local UI preference only (PR #11).
- Inventory, pause controls and supply-cache UI retain the journal's restrained, weathered identity. Data continues to come from game state, rather than decorative fictional numbers.
- The 2.0 milestone makes the Station 04 launch screen explicitly branded, adds a concise expedition briefing and fits the launch actions to desktop and laptop window sizes. The normal gameplay/menu flow is unchanged.

### Further environments and props

- The 2.4 × 2.0 km terrain, roads, junctions, bridge and river valley remain a **separate region preview** in `scenes/world/ashfall_region_roads.tscn`, **not** the playable Station 04 start scene (PR #6).
- Decorative prop packs and the prop showroom are integrated for inspection and dressing; presence in the repository does not mean every prop has been manually placed into Station 04 or art-approved (PR #4).

## Playtest entry and useful controls

Open `project.godot` in Godot 4.7.2 and press **F5**, or use `Play Ashfall.cmd` when the adjacent portable Godot directory is installed. The start scene is `res://scenes/ashfall_station_main.tscn`.

**WASD** move · **Mouse** look · **Shift** sprint · **Ctrl** crouch · **F** flashlight · **E** interact · **Tab** field pack · **Q** use carried item · **F10** cycle HUD finish · **Esc** pause.

Use the gallery and regional preview scenes directly in the editor. They do not replace the normal F5 start.

## Required playtest acceptance

1. Load Station 04 through F5 and confirm the 2.0 briefing is legible, buttons remain reachable at 1280×720 and 960×540, F10 cycles three finishes and the choice persists after restart.
2. Walk the road and village edges at eye level. Check the trees, forest depth, hill profiles and **front/back visibility of all hill surfaces**; compare against earlier see-through hillside issues.
3. Verify 900 m visibility is atmospheric but usable. Measure real FPS and frame timing on the target GPU and adjust scene-only far distance or fog if necessary.
4. Visit checkpoint, cottages, research sample and entry gate; complete extraction. Validate anomaly response, collision and that no world-space text floats in the play view.
5. Scavenge, open/close the field pack, use equipment and medical supplies, interact with a cache, pause and resume, check audio settings and test North Relay/area transitions with inventory continuity **within the same expedition**.
6. Open the separate regional road/terrain preview and decorative prop showroom independently; evaluate collision and art only within their intended review scopes.
7. Run the repository's Station 04 headless regression and relevant smoke tests. A green headless run is **not** proof of high-quality rendering or full gameplay completion.

## What 2.0 does not claim

Persistent game progress across process restarts, finalized encounter AI, multiple implemented difficulty tiers/Hardcore modifiers, all-original production-grade models, an unrestricted open world, and complete renderer/FPS QA are **not** certified by this milestone. Avoid changing combat math, enemy balance, saves, inventory schema, objectives or area transition logic as part of presentation work.

## Syncing to the integrated `main` without discarding local changes

A prior user worktree contained edits to `scenes/ashfall_station_main.tscn`; Git correctly refused to overwrite them. Inspect `git status` first. If the edits should be preserved, commit them locally, or temporarily use:

```powershell
git stash push -u -m "Ashfall local scene before 2.0 sync"
git pull --ff-only origin main
git stash pop
```

Resolve any stash conflicts manually. If changes are intentionally to be discarded, review the diff first—**do not use a force reset as the default update procedure**.

## Traceability

Consolidates merged repository work from PRs [#4](https://github.com/keepithandy/Ashfall/pull/4), [#5](https://github.com/keepithandy/Ashfall/pull/5), [#6](https://github.com/keepithandy/Ashfall/pull/6), [#7](https://github.com/keepithandy/Ashfall/pull/7), [#8](https://github.com/keepithandy/Ashfall/pull/8), [#9](https://github.com/keepithandy/Ashfall/pull/9), [#10](https://github.com/keepithandy/Ashfall/pull/10), and [#11](https://github.com/keepithandy/Ashfall/pull/11).
