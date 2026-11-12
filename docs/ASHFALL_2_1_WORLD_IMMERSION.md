# Ashfall 2.1 — World Immersion Playtest

**Status:** implementation and automated integration milestone, **not a completed art/gameplay overhaul**.  
**Target:** Godot 4.7.2, Forward+; playable entry remains `scenes/ashfall_station_main.tscn`.

## What changed since 2.0

### Environment and atmosphere

- Six seeded, naturally clustered **understory zones** use existing foliage meshes in the packaged project. The scatter stays in bounded periphery regions and clears the main road, service approach, cottages and objective doors. Decorative vegetation has collision disabled; substantial pre-authored story props retain their native colliders. Placement is deterministic and idempotent.
- Four additional original-packaged scenic props become landmarks: the quiet roadside memorial, snapped utility pole, collapsed bus shelter and abandoned mailbox.
- Distant tree canopy, stationary buildings, 900 m default camera and terrain remain as authored. **No false claim of new sculpted walkable terrain or production-level remodelling.**
- Mild weather modulation adds subtle shifts in existing fog density and light energy, without forcing a day/night cycle or changing player detection.
- Five intermittent localized forest-wind and industrial-creak emitters use the existing Effects mix. They play near their sites, not as non-stop jump scares.

### Exploration and encounters

- **J** opens an original screen-space **Personal Field Record** with nine location-linked entries and initial deployment notes. Entering an area once unlocks its record for the rest of the *current* expedition; records do not survive game restarts and do not modify save schemas, loot rewards or objective logic.
- The village creature's **search** state now investigates its actual last known player location with a small local sweep instead of snapping back to arbitrary patrol waypoints. The existing detection ranges, chase speed, damage, attack cooldown and encounter probability remain unchanged.
- Field pack selection now exposes the *actual* item catalog category, description, listed use effect and weight. Carry weight is informational only and does not add encumbrance rules.

### Presentation, diagnostics and safety

- **F8** cycles scene-local view budgets: **900 m Long View** (default), **650 m Balanced**, **400 m Performance**. The performance preset reduces the new decorative foliage draw range and disables volumetric fog; it is a manual tuning option, **not automatic performance optimization or benchmark certification**.
- **F7** toggles an optional live FPS/debug readout. Frame-rate conclusions must come from real target-hardware captures.
- The field record matches the selected Field Journal / Signal Receiver / Worn Amber palettes. All new explanatory text stays on-screen rather than reintroducing floating world text.
- Extended Godot checks cover foliage placement, collision boundaries, authored story objects, area discoveries, controller switches, ambient emitters, creature search behavior, startup and the existing terrain/HUD regressions.

## Playtest directions

Launch Station 04 from `project.godot` or the existing launcher. Try the new records near the worker cottages, northern ward, service yard, research approach and four new outer-path landmarks. Test **J** to open/close the journal, **F8** to compare draw budgets from the same view, **F7** to measure FPS live, and **F10** to compare the three UI finishes. The area connection and all inventory/medical interactions remain unchanged.

Visually inspect high-detail foliage placement from eye height, tree/ground intersections, landmark asset origins, real collider responses, and performance. Automated tests cannot establish that an asset is photorealistic or visually well positioned. Capture repeatable screenshots at the same viewpoint with each quality mode, and record FPS, GPU frame time, and any shader or clipping issues.

## The twenty-area overhaul: completion accounting

| Requested area | Verified scope in 2.1 | Still required for a major overhaul |
|---|---|---|
| 1. Terrain | Existing regional heightfield preview retained | Sculpted walkable Station 04 terrain, aligned road collision, erosion and grounded scenery |
| 2. Forest | Understory density and near/far vegetation already improved | Production trees, roots, branches, natural vegetation variety, wind movement and visual signoff |
| 3. Buildings | Existing three houses and kit preserved | Detailed geometry, interiors, unique weathering and hero architecture |
| 4. Lighting/weather | Restrained climate modulation | Full weather system, artistic lighting pass and performance budget |
| 5. World density | Four story landmarks, clustered foliage | Many more meaningful POIs, road debris and industrial infrastructure |
| 6. Sound | Five additional spatial sound emitters | Professional soundscape, room acoustics, mixing and recording |
| 7. Creature AI | Last-known-position sweep | Advanced pursuit/search, cover perception, reactions, creature animations |
| 8. Player movement | Existing responsive controller preserved | Animation and collision polish with real player-camera testing |
| 9. Scavenging | Existing systems preserved | More physically convincing interactions and contextual animation |
| 10. Survival | Existing survival values kept stable | Light/grounded/brutal per-area options, Hardcore variants, tuning and QA |
| 11. Exploration | Nine discoverable field notes | More route choices, optional secrets, meaningful returns and branching |
| 12. Transitions | Existing linked expedition remains | Seamless production area loading, persistent-save integration |
| 13. HUD | Discoverable screen-space personal journal | Full interaction redesign, original UI assets, accessibility |
| 14. Inventory | Real descriptions, use effects and informational mass | Inspection animations, custom art and layout/pad support |
| 15. Animation | Existing movement/creature animation preserved | Character, props, environmental and hand animation production pass |
| 16. Rendering | View budget presets and optional FPS readout | Recorded benchmarks, robust LOD, occlusion, scalable graphics presets |
| 17. Collision | Tests confirm new vegetation is not obstructive | Full traversal audit of all scenes and authored props |
| 18. Identity | Station-specific records and presentation | Cohesive original visual language, narrative, props and audio motifs |
| 19. Testing | Integration checks for new 2.1 changes | Repeatable screenshot/fps capture, continuous gameplay traversal tests |
| 20. First minutes | Original start screen with route clues and journal motivation | In-engine player funnel observation, pacing, encounter and discovery iteration |

**Release policy:** Do not mark the full 20-item brief complete or label Ashfall AAA/production-ready based solely on this release. Treat this as a measurable next build for playtesting and further work.

## Git-safe update

If your earlier local edit to `scenes/ashfall_station_main.tscn` is still uncommitted, preserve it before pulling. Run `git status`, then commit your local work or `git stash push -u -m "Ashfall local work before 2.1"`, followed by `git pull --ff-only origin main` and `git stash pop`. Resolve any conflict manually instead of discarding the edited scene.
