# Ashfall 2.3 — Lost & Weathered

**Status:** new playable development milestone, pending in-engine visual and target-machine performance acceptance.  
**Date:** November 2026  
**Engine:** Godot 4.7.2 / Forward+

## Creative identity: alone in the abandoned country

Ashfall should look as if its interface was assembled from the survivor's actual possessions. Every accessible control follows physical references: frayed work canvas, weather-stained paper, oxidized tin, battered leather, pencil and soot. There are no luminous tactical indicators, holographic surfaces, bright colored technology accents or futuristic framing.

Readability is a hard requirement. Damage to materials stays away from critical text. The on-screen panels remain quiet and restrained while still showing the real health, stamina, meter and objective state. The field notebook and pack can carry more visual texture because the player deliberately opens them.

## Completed implementation

### One coherent Godot interface skin

- Shared GDScript style functions for flat canvas/paper/metal surfaces, visible keyboard focus, disabled buttons, hover and press states.
- Deterministic, low-cost grime and scuffed binding strokes painted into Control nodes. No additional image downloads, shaders to animate every frame, or external art licensing.
- Three comparison finishes remain available through **F10**, now **Worn Canvas**, **Damp Paper**, and **Rusted Iron**, each within the same realistic material family.
- Notebook becomes a dark leather cover with actual paper-colored content, binding holes and aged margins; place discoveries are the same gameplay-backed notes.
- Pack keeps all **27 slots and eight catalog items** with the same use/equip/stow behavior, now using battered compartments, legible selection edges, description/effect/mass and grounded text.
- Supply-cache and sound menus share the material direction; supply contents are populated from actual items present rather than fixed hardcoded labels. Audio sliders reflow to fit 960×540 windows without lost buttons.
- Small original synthesized paper, cloth and latch handling noises on opening screens; no artificial videogame pings or musical cues.

### World and discovery

- Sixteen additional packaged, noninteractive environmental props in five authored narrative groups: bus stop, evacuated cottage row, abandoned maintenance yard, damaged roadside utility works, and forest-edge leftovers.
- All new scenic objects deliberately disable collision and have bounded placement, preventing new invisible barriers in the mission routes.
- Three added location-triggered observations expand the current Field Record from nine to **twelve**.
- Previous terrain horizon/skirt fixes, multi-profile trees, canopies, fog, wet ground, wind, hills and the regional heightfield preview remain intact.

### Selectable survival intensity

- The current existing areas, **Station 04 perimeter** and **North Relay**, each store an independent *playtest preference* of **Light**, **Grounded**, or **Brutal**.
- **F6** changes the mode of the currently occupied area. **F9** toggles optional **Hardcore** independently for that area.
- Profiles modify **incoming creature/anomaly damage, sprint exertion, stamina recovery, and movement-hearing radius**. A separate tuning readout shows the chosen mode.
- Grounded with Hardcore off deliberately uses the exact old multipliers of 1.0. No hidden adjustment to loot, creature spawn probabilities, attack cooldown, stamina maximum, physics, or player health maximum.
- Modes persist in `user://ashfall_23_survival.cfg` as player settings; this is **not cross-session saved player world progress** or a save-schema migration.
- These settings are **playtest tunables**, not a claim of complete three-tier content or fully balanced Hardcore design.

## Playtest walkthrough

Start Station 04 from the normal scene. On the opening page check **ASHFALL 2.3**, the restrained canvas wear and the readable expedition briefing. Enter the road; compare the worn default HUD against the two alternative subdued finishes with **F10**.

Use **Tab** to inspect the worn pack. Confirm each actual owned item is visible, and inventory use/equip/stow work unchanged. Search caches and verify only items actually in the cache are listed. Use **J** to read the stained notebook; find the broken shelter, the memorial, the washing, the northern cable repair and roadside table for discovery entries. Close the notebook and check mouse capture and movement resume correctly.

Open sound settings at 1280×720 and 960×540. Compare text legibility and slider access without clipping. Listen for subdued handling noises, not high-pitched bleeps.

Change **F6** while in Station 04 and in North Relay; check distinct settings. Turn Hardcore on/off with **F9**, then return both areas to **Grounded** for a baseline run. Watch stamina, nearby creature reactions and hazard damage. The player should be able to opt out of every new balance modification immediately.

Compare **F8** view modes and **F7** FPS diagnostics on the actual target GPU. Automated headless validation cannot measure visual quality, stuttering, occlusion, readability at all screen sizes, whether new prop origins sit correctly on textured ground, or immersion.

## Acceptance and known limitations

The new automated Godot check verifies themed UI existence, original inventory slot count, content/caches, sound panel bounds, world dressing counts and collision state, profile multipliers, and the opening scene. Earlier terrain/HUD/atmosphere tests continue to run in CI, including original 27-slot interaction tests.

This **does not certify the full twenty-category improvement backlog complete**. Production-quality original 3D tree and building models, authored interiors, physically sculpted Station 04 walkable terrain with corresponding navigation and road transitions, realistic character/creature animations, full player-interaction animation, balanced multi-area gameplay, a robust save system, full occlusion and LOD work, advanced AI, formal audio mixing, and target-PC art/FPS validation remain separate substantial tasks.

This release prioritizes high-quality interface consistency, safer environmental storytelling and testable opt-in mechanics over introducing unvalidated map replacement or asset downloads.

## Local update safety

The Godot repository lives in your local working copy. Before pulling, run `git status`. If you've modified `scenes/ashfall_station_main.tscn` locally, commit or stash those changes first; do not hard-reset or overwrite them blindly. Then pull `main`, and restore/reconcile your own changes.

**QA gate:** merge only after the GitHub Godot pipeline passes the exact head commit. Headless CI is not an in-editor visual playtest.
