# Crossroads 2.3 — Second landscape pass: the country beyond the village

**Status:** Direct development on `main`, with verification in `Crossroads 2.3 Village Acceptance`. This document records what is implemented and the remaining *visual* acceptance criteria. It does not call an automated parser result a visual playtest.

## Artistic target

Crossroads is a fictional rural Ukrainian-inspired settlement in late autumn. The first 2.3 version succeeded at framing twelve fenced homesteads and roads but failed when the player faced *out* of the settlement: the 360 × 420 m lived-in core was surrounded by 1.4 × 1.5 km of almost empty ground, with only 125 isolated trees. The horizon looked like a smooth plane and the cloud sky had implausibly harsh high-contrast holes. Fences and house floor heights were repaired in the previous terrain pass; the work here keeps those corrections intact.

The new environment is deliberately assembled from recognisable agricultural patterns: modest broadleaf/conifer shelterbelts enclosing worked fields, scattered unthinned copses, field-side woody growth, scrub along the unfinished road verge, adjoining parcels with different harvest histories, subdued low hills and layered overcast clouds. This is **not** a precise reproduction of one named Ukrainian village, and no signs, military ruins, political imagery or gameplay content are added.

### External reference research

- [Encyclopedia of Ukraine — Shelterbelt](https://www.encyclopediaofukraine.com/display.asp?linkpath=pages%5CS%5CH%5CShelterbelt.htm): Ukraine's shelterbelts protect farmland from wind and soil loss, especially in steppe and forest-steppe landscapes. They can contain oak, pine, birch, poplar and other trees.
- [Agroforestry as a Resource for Resilience in the Technological Era: The Case of Ukraine (Resources, 2025)](https://www.mdpi.com/2079-9276/14/10/152): explains linear/curvilinear shelterbelt configurations, field parcels and the importance of mixed trees and shrubs in shelterbelts.
- [Agroforestry in Ukraine — SIANI 2024](https://www.siani.se/wp-content/uploads/2024/04/AgroforestryUkraina_2024-120324-final.pdf): agricultural plains use windbreaks/shelterbelts and mosaic land-use patterns.
- Reference photographs: [Yasnohorodka village aerial, Kyiv region](https://travels.in.ua/en-US/locality/23509), showing road, distinct plots, forest and farmland; Ukrainian autumn roadside/acacia fields viewed as weathered, not stylized alpine forests.

Only existing Ashfall-authored or licensed resources are rendered. No photographs or outside meshes are imported or baked into the game.

## Changes to the actual Godot scene

`scripts/crossroads/crossroads_background_dressing.gd` is an **additive** environment-only layer at `Landscape/CountryComposition`. It does not replace `crossroads_terrain.gd`, `crossroads_countryside.gd`, the primary village, or the walkabout player.

### Near, middle and distant compositions

**Village transition, 100–320 m out.** The bands between the homestead back fences and existing outer field edges are seeded with grass, low shrubs and brambles derived from the original Godot natural kit. All plants skip defined roads, farm tracks and house entrances. The greenery is deliberately intermittent; the country is not a dense woodland theme.

**Middle distance, 240–550 m.** Ten woodland clumps sit at asymmetrical locations. Planted tree belts have several offset rows, missing trunks and uneven spacing. This breaks the smooth sky silhouette into believable field-edge windbreaks instead of repeating small uniform trees across an infinite plain.

**Far distance, 500–700 m.** Outer shelterbelts frame the rim of the playable fields while allowing the original road to continue through them. Farmland height adds small low rises, not mountains, fading in outside the original 360 × 420 m terrain. The original scene's twelve house foundations and road profile are not altered.

The existing visual `FarTreeLine` remains, but heavier new groups are GPU-instanced by 170 m cells and reuse the already-bundled Pine, Bare Tree, Low Shrub, Dry Bramble and Dry Grass prefab meshes. MultiMesh batches do not instantiate physics objects and have no new collision layers. Each source prefab is loaded once when making shared mesh batches; there is no new image generation or huge reimported art pack.

### Roadside utility continuity

The village originally had only eight timber utility poles ending abruptly before the road disappeared into the fields. That line now continues on both approaches as **18 additional terrain-grounded poles**, using the existing bark material and the same dimensions as the previously authored posts. The 288 short hanging wire sections share a **single MultiMesh draw batch** rather than hundreds of independent mesh nodes. Poles have ordinary narrow physical trunk collisions; the wires are visual-only. The road lane remains unobstructed, and neither power generation nor interactive electricity is introduced.

### Field texture and material

Twelve parcels use the existing `forest_ground_05` CC0 albedo with `crossroads_field_rows.gdshader`. Three agricultural treatments represent dark turned soil, patchy cut stubble and green-brown fallow. Row markings and subtle broad noise are drawn in world space so nearby parcels can have different furrow directions without a common obvious tiling direction.

The new visual patch surfaces follow the same triangulated physical terrain sample as each of the four coarse existing outer fields. Their vertices sit slightly above the terrain to avoid z-fighting. All original ground collisions remain exactly where they were.

### Lighting and sky

Only **Crossroads** overrides the old `ashfall_overcast_clouds.gdshader` parameters. The new settings bring cloud contrast down, open the gray-blue horizon and increase the apparent scale of the low cloud deck, with a slightly brighter but still cold autumn atmosphere. The original Station 04 sky shader and all historic playtest scenes are unchanged.

Fog remains enabled to give depth but not wash out the entire 500–650 m background. Forward+ rendering and the user’s GPU are still needed to check actual appearances.

## Technical and gameplay guardrails

- The player, mouse capture, stamina/movement, scene entry, old inventory and legacy game logic are untouched.
- Generator, anomaly, extraction, loot, enemy AI and story objectives remain absent from the new Crossroads main scene.
- Terrain, house foundation meshes, fences, gates, cart tracks and original asset scenes are not replaced.
- No dynamic spawn system, environmental damage, resource drops, collectibles or game save mutation was added.
- All new vegetation is cosmetic, nonblocking and deterministic for consistent screenshots.
- The map remains finite; the outer countryside is more convincing but is **not** an infinite-streamed/open-world system.

## Acceptance passes

**Geometry and continuity:** Old 2.3 physical walking, entrances, house pads, fences, four outer collision fields and road-ground checks must remain green.

**Visual density:** Check ten shelterbelt runs, ten small groves, twelve rendered field parcels, five existing-asset vegetation sources, appropriate batches, and that the main road has no vegetation blocking it. The new automated assertion protects against a regression to the almost-empty outer country.

**GPU/performance:** Count total GPU batches and cap the acceptable range. F7 still displays FPS; F8 still cycles camera ranges. Batched foliage receives no per-tree physics, casts no expensive individual shadows and shares its existing mesh/material resources.

**Actual in-game screenshots required:** Capture (a) south road looking away from the village, (b) mid-village field edge toward a shelterbelt, (c) one outside country parcel looking back at Crossroads, and (d) sky above a dark tree line. Examine hard pop-in, field seams, over/under-exposed soil, floating flora and extreme GPU frame-time spikes.

## Known remaining limits

Godot headless CI cannot certify a final art direction or realistic physical scale in every camera angle. The native pine mesh is limited to one stylized evergreen and the bare deciduous tree has no leaf canopy; repeated silhouettes remain noticeable at close range. They have been grouped and scaled but **not** replaced with new licensed assets, because this pass prioritizes building out the existing original asset kit. There is no true LOD swap by distance within one MultiMesh cell, only cell-level culling/fog and no shadow burden. If full desktop rendering reveals CPU/GPU hitching or too much repetition, the next evidence-driven pass should tune those specific cells without resetting the village.
