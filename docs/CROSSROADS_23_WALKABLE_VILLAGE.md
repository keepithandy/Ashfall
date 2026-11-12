# Ashfall 2.3: Crossroads — first full environment playtest

**Current main scene:** `res://scenes/crossroads_main.tscn`  
**Status:** static environment-only playtest; in-editor realism/FPS sign-off pending.  
**Godot target:** 4.7.2, Forward+.  
**Project identity:** Crossroads, a fictional Ukrainian-inspired rural settlement; not a recreation of a real community or specific war location.

## Design intent

The player should feel stranded on a real forgotten lane. Streets determine where houses stand. Gates lead somewhere. Farm plots have work areas, unkempt beds, shade trees, household leftovers and outbuildings; no house is a prop on a featureless lawn. Weather comes from overcast sky, softened indirect light, slight low-lying mist and wet roadside ruts, not supernatural effects.

Architecture and planning references: [Encyclopedia of Ukraine](https://www.encyclopediaofukraine.com/display.asp?linkpath=pages%5CF%5CO%5CFolkarchitecture.htm); [L. Hnes, 2025, rural homestead spatial planning](https://science.lpnu.ua/node/41548); [Gammalsvenskby/Zmijivka 2025 cultural environment](https://www.gotlandsmuseum.se/wp-content/uploads/2025/10/Cultural-Environment-Plan-GammalsvenskbyZmijivka-2025.pdf). These support one-storey plaster/brick homes, aged blue/green finishes, sloped corrugated roofing and practical garden/utility buildings, but differ by locality. Crossroads is a plausible composite rather than a geographically precise simulation.

## What was built — audit pass A, geometry and asset reuse

The `crossroads_profile.gd` defines a **360 × 420 m map** and twelve individually indexed homesteads. The `crossroads_terrain.gd` builds a **2 m physical heightfield mesh** with 37,800 cells; its collision uses that exact generated triangle topology. A smooth-grade road corridor is integrated into the terrain height function and household foundations each have a local blended flat pad. Roads, house positions, gate trails, scenery and tree trunks use the same triangle-interpolated elevation query.

`crossroads_roads.gd` builds an old village spine and two longer cart/farm tracks which reconnect at both ends. All three are foot-traversable. Their shoulders and small rainwater patches are visual only, so they cannot create raised invisible steps above the actual ground collision.

Only **two additional houses** were made: the *Blue Sill Cottage* (12 × 8 m) and *Lane Brick House* (8 × 12 m) from the original Crossroads kit and existing interior decorations. Each has a sloping corrugated roof, actual 3D wall openings, pitched roof gable ends, defined floor slab, several real furniture pieces and an open doorway. Both can be separately inspected at:
- `res://scenes/houses/blue_sill_crossroads.tscn`
- `res://scenes/houses/lane_brick_crossroads.tscn`

Existing White Garden, Green Longhouse and Ochre Workers homes are reused as the other residence types. No external GLBs, royalty-free downloads, texture collections, scripts that synthesize novel game items, or custom character art were added.

## What was built — audit pass B, spatial realism

Twelve residences no longer float in open meadows. Every property includes a street-facing privacy fence with a wide actual gate gap, matching collision boundaries, open road-to-threshold path, rear boundary, and occupied yard space.

Existing-asset yard groupings distinguish the homes: abandoned laundry, rotten timber, pots, vegetable beds, boards, crates, hoses, abandoned household furniture, tools, a neglected working area, wheelbarrows and tyre stacks. The countryside uses a seeded forest belt, leftover hedges, dry grasses and occasional rocks or dead branches. Rural overhead wiring, eight wooden poles and a neglected roadside shelter distinguish the road corridor from the private homesteads. These are static visual dressing, not pickups or interactable story objectives.

The goal is environmental storytelling without on-screen floating text, minimap icons or glow.

## What was built — audit pass C, system exclusion

The active `crossroads_playtest.gd` scene starts only a reused real first-person player controller. It does **not** attach `game.gd` or the original Station 04 gameplay runtime.

There are no generators or generator interactions, no anomaly rings or hazard damage, no sample or extraction gate, no loot inventory screen, no creature patrol/chase, and no Hardcore/difficulty menus in the new scene. The old systems are retained only as inactive legacy content in `scenes/ashfall_station_main.tscn` and its scripts. This allows restoration later without deleting historical work.

The new opening UI is a very simple cloth-colored menu. It hides entirely when you enter the world. A small optional FPS indicator is the only normal on-screen debug element.

## Walk the map in this order

**First, the initial view.** Start F5. Look straight down the road from its southern approach. You should see a gently curving lane with continuous ground; a few fences and rooflines must break the horizon rather than a row of identical houses. Check for floating props, flashing surfaces, severe clipping or default-mesh colors.

**Second, the southern properties.** Walk north, inspect the left first white house and the right *Blue Sill Cottage*. Enter through its open front gate. Follow the path to the painted entrance. Walk across the threshold into the furnished room. Verify that the pitched roof looks physically joined, its window openings have glazing and the player's head/body doesn't clip through furniture or the eaves.

**Third, the mid-village properties.** Continue past the aged green and ochre homes. Compare how each side sits behind fences and gardens. Examine the other new house, *Lane Brick House*, on the western side mid-way up the street. Its door is off-centre and there is a rear/side lean-to. The floor should be level with the front garden, and the interior partition should leave real walking clearance.

**Fourth, the rear tracks.** Take one of the thinner cart/farm lanes joining the main street at the village ends. Walk behind the properties. You should be able to distinguish house backs, utility areas and gardens rather than the same house façade from another angle. The terrain should roll gently without terrain/road intersections.

**Fifth, the outer borders.** Walk toward the pines and leafless trees to evaluate density, grounding, canopy profile and realistic line of sight. The edges remain a finite prototype area, not a genuinely continuous country.

**Sixth, diagnostic comparisons.** Press F7 for FPS. Press F8 to rotate the view distance between 650 m, 350 m and 500 m and walk through the most densely decorated section. Report approximate minimum and average FPS on the RTX 4080 SUPER, hitching when crossing house thresholds, and texture or shadow pop-in.

## Controls in this map

`WASD` move; mouse look; `Shift` sprint; `Ctrl` crouch; `Space` jump; `F` flashlight; `Escape` pause/resume; `F7` FPS and view distance; `F8` change view-distance budget.

The old `Tab` inventory, `J` field record, `E` interactions, `F6` tier, `F9` hardcore and `F10` finishes are intentionally inactive, not broken.

## Automated tests

`tests/check_crossroads_village.gd` verifies that Crossroads instantiates; its exact terrain collision exists; all three routes/puddles render; twelve plots, two new building variants and twelve open gates are available; new homes have furnishing and roofs; roadside utility poles, fences and foliage populate; legacy gameplay objects are absent; a player can start, walk, and pause; and a ray through the first open gate is unobstructed.

The GitHub Actions workflow additionally runs headless Godot 4.7.2 asset import, parser checks, this new test and first-frame main-scene startup.

## Risks not eliminated by CI

Godot's headless dummy renderer cannot certify the final visual look, accurate terrain color, believable model scale, interior furnishing collisions in every house, high-end lighting, the true render-distance behavior on Windows, or actual FPS under the selected Forward+ driver. A successful automated pass must be followed by screenshots and a local player route review. The repository contains older heavyweight mesh scenes; some may be expensive at highest detail. This is a serious environment prototype, not an art-final photogrammetry release.

## Safe local testing

On the local Windows project `C:\Users\quali\OneDrive\Desktop\source\Ashfall`, check `git status` before pulling. The previously restored local scene modifications and untracked generated asset import files may still be present. **Do not reset, clean, or overwrite them to force an update.** Commit or stash personal scene changes first, sync `main` once merged, then inspect/reapply your local scene edits separately. The new main scene lives at a **new path** and does not overwrite the old Station 04 scene.

`Play Ashfall.cmd` and Godot F5 use `project.godot`'s new Crossroads entry.
