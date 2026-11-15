# Ashfall — Briar Creek (Area 02) foundation

Status: **isolated walkabout candidate; 3D runtime acceptance pending**, 14 November 2026. Area name is approved; geometry, dimensions and asset placements remain tentative. This is **not a finished, playable district**.

## Intent and continuity

Briar Creek is an abandoned logging district with dense woodland, large irregular clearings, a functioning geographical relationship between an upstream ridge and western creek, and a road back to Crossroads. The game remains level-based with open-world-feeling exploration. Survival/scavenging comes first, with intermittent danger instead of permanent combat or pursuit.

Crossroads 2.3 is currently the Godot 4.7 / Forward+ environment-only main scene at `res://scenes/crossroads_main.tscn`. It does not run the older expedition loot/objective/area runtime. The reusable `scripts/runtime/expedition_areas.gd` uses session-resident state, **not proven persistent disk saves**. Therefore there is intentionally **no area travel, save migration, inventory, creature or gameplay integration** in this foundation. Do not change `project.godot` or the Crossroads 2.3 scene to showcase Briar Creek.

## Research applied to the environment

1. U.S. Forest Service, *Low-Volume Roads Engineering, Best Management Practices*, Chapters 3–4. Forest roads need stable placement, moderate grades and runoff control; minimize road-stream crossings and protect drainage. Source: https://www.fs.usda.gov/t-d/programs/forest_mgmt/projects/lowvolroads/ch3.pdf and https://www.fs.usda.gov/t-d/programs/forest_mgmt/projects/lowvolroads/ch4.pdf .
2. Penn State Extension, *From the Woods: Hardwood Lumber*. The physical production flow involves incoming logs, log yard sorting, sawing, byproducts, grading and stacked drying lumber. This is a process reference, not proof of a specific 1980s local mill design: https://extension.psu.edu/from-the-woods-hardwood-lumber .
3. Ukraine State Forest Resources Agency, *General characteristic of Ukrainian forests*. Scots pine, spruce, oak, beech, birch, alder and fir are plausible species in different regions: https://forest.gov.ua/en/areas-activity/forests-ukraine/general-characteristic-ukrainian-forests . Briar Creek is fictional and inherits Crossroads' Ukrainian-inspired rural environment; favor local species mixtures rather than American-only conifer forests.
4. Godot Engine, *Visibility ranges (HLOD)* and *Optimizing 3D performance*. Use LOD/visibility ranges and measured vegetation batching; do not assume every individual tree should have a node and collision at 600m scale: https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html and https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html .
5. Godot Engine, *Large world coordinates*. An independently loaded 600m level does not justify switching Ashfall to double precision: https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html .

No sourced imagery or third-party meshes have been imported into the repository.

## Coordinate contract

Design-plan coordinates: southeast/east X **0–600**, north N **0–600**, elevation Y in meters. The southwestern corner is (0,0) in design X/N.

Godot local scene coordinates: `Vector3(X - 300, Y, 300 - N)`. This preserves Godot's existing **north = negative Z** convention while keeping the independent Briar Creek scene centered about the origin. Do not place raw positive-N design coordinates into Godot Z.

A 600 × 600m initial heightfield with 4m grid spacing contains **151 × 151 vertices (22,801)** and **45,000 triangles**. The render mesh and static triangle collision use identical indices. Road skins sample that same triangulated terrain; they are **not raised collidable slabs**.

### Seven reserved zones

| Site ID | Center X/N | Target Y | Landscape envelope | Role |
|---|---|---:|---|---|
| checkpoint | 305/65 | +5m | 40 × 35m | Crossroads-facing southern entry |
| mill | 350/305 | +18m | 125 × 105m | Mill hall, log deck, office, finished timber staging |
| cabins | 145/390 | +23m | 100 × 75m | Four worker cabins on shared lane |
| depot | 470/445 | +32m | 75 × 65m | Workshop, fuel store, equipment shelter |
| lookout | 335/550 | +60m | 30 × 30m | Pedestrian-access lookout |
| creek | 110/245 | +8m provisional | 55 × 35m | Stream-side path and former crossing |
| clearing | 220/460 | +30m provisional | 65 × 55m | Logged cut with stumps, brash and regrowth |

Targets at the creek and clearing are **labels** until the drainage and relief surfaces are accepted. The overhead scene places one noncolliding marker per site. The independent walkthrough additionally places early collision-capable building and shed shells, not the final production asset set.

### Road network

| ID | Use | Width | Approximate polyline length | Max straight-segment rise |
|---|---|---:|---:|---:|
| R01 | Southern road to mill | 5.5m | 317m | 6.3% |
| R02 | Mill to depot | 4.5m | 222m | 7.7% |
| R03 | Cabin access lane | 3.7m | 305m | 4.9% |
| P01 | Depot–lookout footpath | 1.6m | 348m | 11.1% |
| P02 | Cabins–creek-side footpath | 1.6m | ~194m | 8.7% |
| P03 | Mill–logged clearing footpath | 1.5m | ~231m | 7.1% |

Calculated control-point grades are planning checks, **not** sampled terrain-grade certification. Smooth the vehicle-road turn radii and verify physical slopes and truck clearance before adding detailed roadside assets. P01 is pedestrian-only: an attempt to drive directly to the +60m lookout was too steep for the small site.

### Forest boundaries and clearings

The deliberately irregular perimeter should not present a square visible edge. The low western creek, northern ridge and east-facing hills will shape the enclosing sightlines; a southern road leads toward Crossroads, but **do not currently attach an interactive exit**.

Clear the mill's ~125 × 105m working area with 10–25m of staggered edge regrowth. Cabin housing gets a ~100 × 75m shared footprint with 8–18m transition; depot ~75 × 65m with 10–20m transition; logging clearcut ~65 × 55m with 5–15m edge transition. Avoid rectangular tree deletion masks and uniform tree spacing. Use windfall, stumps, isolated mature trees, brush and partial glimpses of the mill/lookout to help orientation.

Existing assets for later review: `scenes/nature/forest_pine.tscn`, `bare_tree.tscn`, `fallen_log.tscn`, `tree_stump.tscn`, `fern_clump.tscn`, `reed_clump.tscn`, `mossy_boulder.tscn`, `dry_bramble.tscn`. Current `assets/nature/catalog.json` reports an 8.6m-tall pine, so a believable mature woodland will require scaled/variant trees and additional side-profile review before population. Do not import unverified third-party sources.

## Files in this isolated foundation

- `scripts/briar_creek/briar_creek_profile.gd`: map geometry, sites, terrain formula and road/path waypoints.
- `scripts/briar_creek/briar_creek_blockout.gd`: editor/runtime generation of 4m terrain mesh, shared collision, visible road skins and rough site center markers.
- `scenes/briar_creek/briar_creek_blockout.tscn`: independently opened plan-camera environment scene (not a first-person playtest).
- `scripts/briar_creek/briar_creek_forest.gd`: seeded, 100m-cell GPU-instanced visual forest with physical tree trunk proxies.
- `scripts/briar_creek/briar_creek_structures.gd`: first collidable logging operation architecture and house shells.
- `scripts/briar_creek/briar_creek_walkthrough.gd`: independent walker and HUD, no inherited objective/save wiring.
- `scenes/briar_creek/briar_creek_walkthrough.tscn`: dedicated first-person experimental scene; leave project main set to Crossroads.
- `tests/check_briar_creek_foundation.gd`: terrain and planning scene regression.
- `tests/check_briar_creek_walkthrough.gd`: composed runtime scene, forest counts, physical structures, south-entry terrain ray (excluding the spawned player), and physical building-road clearance checks.
- `.github/workflows/briar-creek.yml`: Godot 4.7.2 parse and headless checks for both Briar Creek scenes and a Crossroads regression.

The overhead blockout remains a planning scene. A second scene, `briar_creek_walkthrough.tscn`, adds the existing Ashfall first-person controller, HUD/pause UI, multi-mesh pine/bare tree/shrub population with trunk colliders, several collidable structural shells (sawmill, office, four cabins, depot, shelters, checkpoint, unfinished tower), the shared Ashfall dirt/gravel materials, and a **visual-only creek ribbon**. These are physical development shells, **not accepted game-ready architectural models**. There is no inventory, persistent save, enemy, AI, loot, scripted objective, functioning Crossroads exit, finished climbing access or deep-water mechanics.

## Building 01 — wooden logging maintenance workshop (incremental pass)

The first small follow-up to the Area 02 foundation keeps the existing `MaintenanceWorkshop` at the depot's (450,465) design position with the **same 16 × 12m footprint, collidable shell and front repair-bay opening**. The generator now adds visual-only dark timber corner posts, side supports, a front lintel, bracing, a rear sill, a discreet metal ridge cap and a weathered wooden equipment door shown parked on a sliding track beside the opening.

The door **does not close or interact**. The detail meshes have no separate collision, so the existing vehicle/pedestrian opening remains unobstructed. The automatic walkthrough test checks the required visual parts, verifies the parked door's position outside the entry span, and confirms the original eight workshop collision shapes are unchanged. The sawmill, cabins, woodland, roads, area travel and Crossroads are not modified by this pass.

This is a clear exterior readability improvement using lightweight primitives, not a Blender production model or a finished interior. It does not require a manual playtest for acceptance; a detailed realistic workshop is a later milestone.

### Building 01 — small exterior follow-up: siding and roof edges

The maintenance workshop receives a second constrained visual pass: ten thin battens distributed across the two outside side walls, six across the back, and four raked timber fascia boards across both gable roof ends. These make the existing low-poly wooden workshop read more clearly from side and rear viewpoints without adding detailed interiors or new systems. The new trim meshes are noncolliding and sit outside the original 16 × 12m shell. The repair-bay entrance, parked sliding door, original eight shell collision shapes, footprint and site remain unchanged. The headless walkthrough regression now verifies the visual detail count, outside-wall placement, roof trim elevation and unchanged collision shape count.

## Automated foundation acceptance (no user playtest required)

This foundation is delivered and validated through the repository, without asking the user to open Godot or manually test. The scene lives at `scenes/briar_creek/briar_creek_walkthrough.tscn` **on the `feature/briar-creek-foundation` branch** until merged into `main`; it will not appear in a local `main` checkout until that branch has been merged and local files synced.

The foundation acceptance checks are:
1. Godot 4.7.2 resource import and parser checks.
2. The headless 600 × 600m terrain/road construction check and associated continuity assertions.
3. The headless independent first-person scene construction test, including tree colliders and building-to-road clearances, and a non-interactive launch smoke run.
4. Crossroads main-scene and regression checks to establish the existing playable scene is unaffected.
5. Confirm the PR changes are limited to the isolated Briar Creek environment, tests, docs and workflow; `project.godot`, existing saves and existing Crossroads files remain unchanged.

The GitHub Actions run `43665085963` passed the above pipeline on commit `67bf7004c7462f7a1ab7bfd3929d4796b7280e76`. Automated results validate the **foundation scope**, not photorealism, actual graphics performance or production gameplay quality. No manual user activity is required for the foundation merge.

**Not part of foundation acceptance:** realistic finished models/interiors, connected area travel with persistent inventory, finished lookout access, creek bridge and water physics, full survival gameplay, and high-fidelity performance tuning. Those are subsequent development milestones; they must not be represented as completed work. Automated gameplay, rendering and performance checks should be expanded as those features are implemented.

### Revision v0.3: technical improvement pass

The first CI run (Godot 4.7.2) parsed Briar Creek scripts and passed the 600m terrain foundation test; the full walkthrough test reported its south-spawn terrain ray had struck a non-terrain collider. The new test excludes the player capsule from that ground-only ray. Recheck the latest CI run before claiming resolution.

The original sawmill, depot workshop and checkpoint were located on top of the road network. Sawmill hall is now at design (325,320), workshop at (450,465), equipment shelter at (500,451), and checkpoint booth at (315,72); each is physically terrain-snapped, and the headless walkthrough regression checks eleven primary building footprints against the 6-route access network. Existing mill service props were adjusted to follow those moved structures. Road surface generation now shares mitered vertices across bends, minimizing disconnected cards at the corners.

Additional woodland routes P02 and P03 connect the cabin terrace to the east bank of the creek and the mill yard to the logged clearing. **P02 reaches a creek-side stopping point, not a traversable bridge or opposite-bank connection.** The forestry forest-mask generator excludes these access paths. The rest of the primary road and lookout route retain their planned grading.

### Route engineering concerns identified in independent geometry calculations

Original P01 footpath grading did not affect terrain and produced an untenable ~60% slope in sample calculations; the profile now grades the footpath into the heightfield. A second calculation sampling the proposed 4m physical grid returned approximately **17% peak** for the walking path and **up to 12%** on short vehicle road segments at junctions. These are independent numerical estimates, not measured Godot results. Vehicle junction and road crossfall smoothing remain required before any claim of truck traversability. Do not add more forest shortcut paths without checking intersecting road grades.

### Scene location and status

Briar Creek's walkabout scene is at `scenes/briar_creek/briar_creek_walkthrough.tscn`. This file is only on the development branch until the foundation merges. The project continues to open Crossroads by default. User-side playtesting is not a requested step or acceptance requirement. Future visual refinements should be undertaken by automated/headless checks, screenshots generated in the development environment where supported, and professional review when those tools become available.
