# Crossroads 2.3 — Homestead design freeze (before construction)

**Design-only milestone. No other new prop types are authorized.**

## Place, era and reference discipline

Set Crossroads in a fictional rural settlement in north-central/eastern Ukraine during a wet, overcast autumn. This is an *informed composite*, not a named real village or an exact historical reconstruction. No flags, military staging, war debris, folk-costume clichés or invented Ukrainian signage are necessary to make the place recognisable.

Reference study:
- Encyclopedia of Ukraine, [folk architecture](https://www.encyclopediaofukraine.com/display.asp?linkpath=pages%5CF%5CO%5CFolkarchitecture.htm): whitewashed homes, practical wooden homestead fencing, changes in farmyard arrangements by region.
- Ukrainian Journal of Architectural research, [Hnes, 2025](https://science.lpnu.ua/node/41548): houses, outbuildings, yards and street setbacks vary; not uniform detached lawn-islands.
- Gotland Museum, [Gammalsvenskby/Zmijivka cultural environment](https://www.gotlandsmuseum.se/wp-content/uploads/2025/10/Cultural-Environment-Plan-GammalsvenskbyZmijivka-2025.pdf): weathered white-rendered one-storey walls, grey corrugated roofing, aged blue/turquoise/green joinery and painted gates.
- Observed contemporary rural road reference from Kharkiv oblast: narrow asphalt or dirt lanes, imperfect shoulders, roadside rainwater, utility poles, and mismatched fences.

## New building design A: The Blue Sill (single-storey 12 × 8 m)

An old plastered 3-bay residence; low concrete foundation; front elevation with two windows, central open door, small covered threshold, raised step and dark, pitched grey roof. Low glazed window panes and faded blue wooden-looking trim give it a modest, lived-in scale. Floor plan: central room connecting two lived-in corners, a bed, a chair, shelves and a stove-related storage impression without adding new interactive systems.

Construction uses only existing Crossroads 4 m wall/window/door/floor modules, existing worn concrete, plaster, timber and corrugated textures, and already-packaged interior furnishings. No new GLBs, downloads or new item mechanics.

## New building design B: The Lane Brick House (single-storey 8 × 12 m)

Narrower red-brown, repaired masonry home, facing the same road but with its entrance off-centre. Different longitudinal gable roof, slightly deeper roof, narrow rear store room and short built-in side lean-to. Green-grey painted trim and rough timber cladding near the threshold distinguish it from A, not just a color swap. The rear room is accessed through the original door opening geometry, not an invisible wall.

Construction uses exactly the same existing modular meshes, colliders and textures as A. Different bay count, door location, roof orientation and interior plan make it a genuinely distinct building.

## How they enter the street

The two new models are *houses only*, not prefabricated levels. Crossroads reuses these alongside its existing white, green and ochre houses. Each is placed on a terrain-graded homestead with a plausible setback, front gate gap, irregular garden, side/rear privacy fence, outbuilding/utility props from the existing catalog, a real path from gate to door, and natural verge. The environment does not make houses hover or block the walking route.

## Architectural acceptance

1. Doors remain visibly traversable; windows have believable proportions; collision follows physical wall, floor and roof geometry.
2. Roof edges overlap wall tops without daylight gaps; their slope is not a flat industrial slab. Keep visual-only roof collision where inaccessible.
3. The building's foundation does not float above its prepared terrain pad.
4. Furniture doesn't block all circulation. Interiors feel inhabited but remain usable.
5. Runtime and editor opening are deterministic; each model can be inspected independently.
6. No additions to old sample, generator, anomaly, inventory, AI or extraction systems.
