# Crossroads 2.3 — Phase 1 homestead individuality and street-life pass

## Objective

Make Crossroads worth exploring even without enemies, loot, quests or objective labels. This pass builds on the existing twelve-house village and its physically validated terrain, rather than replacing the main scene or changing player movement. No new standalone house model or external art package was introduced.

## Research

Ukrainian rural homestead placement varies by region and history; front setbacks are not uniformly identical. Farm and household buildings may stand near the road, alongside the home or deeper in the plot. Source: [L. Hnes, 2025, *Architectural Canons and Folk Traditions of Spatial Organization of the Rural Homestead in Ukraine*](https://science.lpnu.ua/node/41548). The [Encyclopedia of Ukraine, *Folk architecture*](https://www.encyclopediaofukraine.com/display.asp?linkpath=pages%5CF%5CO%5CFolkarchitecture.htm) records regional differences in courtyard fences and gates, traditional gardens and the arrangements of utility buildings. Contemporary rural photographs depict modest corrugated roofs, yard trees, low timber fences and lanes marked by utility poles.

Crossroads is an original fictional composite and is **not** claimed to reconstruct a specific real village. Additive scene dressing uses authored existing Ashfall assets, rather than copying any reference photograph or building model.

## Already existing before this pass

- Twelve fenced homesteads with five home types and two new modular houses.
- Physical 2-m-grid ground, graded rotated house pads, roads, foundations, functioning gate gaps and player controller.
- Existing house interiors have cot, shelves, bench and radiator or analogous furnishings; new Blue Sill / Lane Brick buildings also have rooms and furniture.
- Field-edge vegetation, ordinary utility poles, walkable farmland and ambient overcast sky.

## New character for each property

Each homestead has a `HomesteadIdentity` node, preserving the original authored `Residence`, `PrivacyFence_*`, open gates and garden geometry. The added `PersonalCourtyard` creates a purposeful composition of **at least five** existing prop scenes per household, not a copy of one repeating master set. The `StreetVerge` adds small roadside plant/stone detail away from the actual roadway and entrance throat. The new `Residence/RoomTraces` adds exactly three existing everyday interior details per house, around its wall edges rather than obstructing the central circulation.

| Site | Distinct purpose and environmental cues |
| --- | --- |
| SouthWhiteYard | Family residence, garden seating, abandoned meal-related household fragments |
| BlueSillSouth | Blue-trim garden cottage, planting pots and tools |
| LonghouseNorthGarden | Woodcutter's shed-like work area, sawhorse and fuel |
| OchreOrchard | Orchard/planting household, tools, barrow and pots |
| BrickAndLeanTo | **Landmark: repair courtyard**, workbench, hoses, tyres, spare timber |
| GreenWellsYard | Water and washing yard, buckets, washing and firewood |
| WornWhiteHouse | Laundry house, empty chair, pots and ordinary wash remains |
| BluePorchNorth | Working vegetable patch, worn out tools and garden containers |
| OchreCollapsedFence | **Landmark: overgrown home**, brambles, branches, roots and neglect |
| TheOldBrick | Equipment storage, stacked sheet metal, pallets and tools |
| LastGreenCottage | Last-maintained garden, surviving bench and old pots |
| NorthernWhiteResidence | Woodpile and old rural repairs toward the northern exit |

**Third landmark:** SouthWhiteYard (a recognizable family home). The three landmarks are deliberately grounded household properties rather than quest destinations or map markers. No floating text or in-game collectible system is added.

## Subtle street variation

The pre-existing lot widths and gate positions remain unchanged to protect collision, terrain grading and existing player routes. However, every property's weathered fence material is individually toned, instead of cycling through three exact copies. The three terrace garden beds per yard are now distinct in length, offset, spacing and planting position, while still draping over the same physical terrain used by the player's feet.

The new courtyards keep visual objects several metres to either side of the gate-to-door centerline. Added interior traces are nonblocking and sit near perimeter walls. Existing structural collision, fences, rooms and doors remain physical, as they were before.

## Test plan

Run `res://tests/check_crossroads_village.gd` with Godot 4.7.2. Preserve all old collision/gate checks. New regression tests must verify:
- All twelve identity nodes load and advertise twelve unique household titles.
- Exactly three major landmark houses and at least five new yard details per home.
- Three new domestic traces per residence, and the twelve original homes still instantiate.
- Decorative props are nonblocking and don't appear in the walking lane to the front door.
- Original physical terrain, house foundations, 60 fences, 36 garden beds, road surface elevations, outdoor foliage and first-person movement still pass.
- Old generator, anomaly, enemy and extraction content remains unloaded in this scene.

### Required human visual acceptance

Walk the first eight yards and the last four. In particular enter SouthWhiteYard, BrickAndLeanTo, OchreCollapsedFence. Verify that each has a recognizable silhouette without game UI and that additions look naturally placed rather than floating, clipping, or perfectly aligned.

From each gate, walk to the house door and across the existing floor; photograph floor-to-ground height, front fence, porch, three room traces and adjacent garden rows. Recheck any prop origin that makes an asset hover or bury itself. The CI test protects structural placement, but does **not** prove the final aesthetic is photorealistic or that every furnished room looks good on the user's GPU.

## Local sync safety

The user previously had an uncommitted change to `scenes/crossroads_main.tscn`. **This Phase 1 update does not modify that scene path**; it modifies scripts loaded by the scene, extends the regression and CI, and adds this document. Do not use `git reset --hard` or `git clean` to apply the update.

On Windows, run `git status -sb` before any pull. A normal `git pull --ff-only origin main` may work when local modifications don't overlap; if Git blocks the pull, retain the work via a uniquely named stash or commit and reconcile it before reapplying changes. Don't automatically pop an older stash onto a new scene.
