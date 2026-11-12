<div align="center">

# A S H F A L L

**SURVIVE THE SILENCE.**

*An original, first-person survival-horror expedition through abandoned roads, industrial ruins, and places best left undisturbed.*

![Godot](https://img.shields.io/badge/Godot-4.7.2-478CBF?logo=godot-engine&logoColor=white)
![Language](https://img.shields.io/badge/Language-GDScript-2D3748)
![Platform](https://img.shields.io/badge/Platform-Windows-363636)
![Status](https://img.shields.io/badge/Status-Crossroads%202.3-796044)

**[Play Crossroads](#getting-started) · [Walk the village](#your-first-walk-through-crossroads) · [Project structure](#project-structure)**

</div>

---

> **An old rural road. Empty houses. Nobody to tell you where to go.**  
> Crossroads is an environment-first walkabout, not an objective-driven game yet.

## Crossroads 2.3 — The First Walkable Village

**Crossroads is now the actual F5 main scene**: `scenes/crossroads_main.tscn`. This is a **360 × 420 m** fictional rural Ukrainian-inspired settlement on physically graded, collision-matched ground. There are three connected walking routes, twelve differently furnished and fenced homes, open gates and footpaths, two new house designs assembled only from existing Crossroads kits, real floor/wall geometry, weathered roofs, older utility lines, gardens, wet verges and surrounding forest.

**No generator, anomaly, extraction, sample, quests, enemy AI, survival tier system, pickup economy or floating objective text** is active. The old Station 04 systems and scene remain in the repository, not in the new playtest. You are here to walk and judge whether the village seems believable.

Read the [Crossroads environment playtest guide](docs/CROSSROADS_23_WALKABLE_VILLAGE.md) and [two-house design freeze](docs/CROSSROADS_HOMESTEAD_DESIGN.md). We still require actual visual inspection of house entrances, yard surfaces, road blending, collision edges and target-machine FPS before calling this art-final.

## Archived Station 04 milestones

## Ashfall 2.0 playtest

This milestone combines the playable Station 04 expedition with the recent environmental passes, repaired distant hills, layered forest, **900 m Station 04 view distance**, and a personal screen-space **Field Journal HUD**. Press **F10** to switch among Field Journal, Signal Receiver and Worn Amber. The start screen now has a 2.0 field briefing with accessible actions on laptop-sized windows.

The **expanded region road/terrain scene remains a separate preview**, not a replacement for the Station 04 gameplay start. Decorative props and galleries are included for inspection. This is an integrated **playtest**, not a completed release; terrain visuals, performance and end-to-end expedition behavior still need an in-game approval pass. See [Ashfall 2.0 playtest scope and QA](docs/ASHFALL_2_0_PLAYTEST.md).

## Ashfall 2.3 — Lost & Weathered Playtest

The earlier Station 04 build gave Ashfall a **grounded old-survivor identity**: worn field canvas, stained handwritten-style notebook pages, muted rust and paper, repaired-looking controls, physical paper/cloth handling sounds, consistent supply and inventory screens, and no futuristic HUD language. Existing information still comes from real gameplay state and 27 field-pack slots work as before.

That legacy Station 04 scene has **16 additional traces of abandonment** and **12 location-triggered notes**. The perimeter and North Relay each support optional **Light / Grounded / Brutal** survival profiles (**F6**) and independent **Hardcore** modifiers (**F9**). **Grounded with Hardcore off keeps the original balance.** The settings do not rewrite player saves.

This is a playtest foundation, **not completion of all major world, 3D art, animation and performance improvements**. Read the [2.3 technical scope and playtest guide](docs/ASHFALL_2_3_LOST_WEATHERED.md).

## Ashfall 2.1 — World Immersion Playtest

The 2.1 branch extended the 2.0 Station 04 build with near-ground foliage clusters, four narrative landmarks, nine discoverable field notes, localized ambient sounds, creature investigation around last-known positions, and more useful item inspection. **J** opens the Field Record, **F8** cycles draw-distance budgets, and **F7** toggles a live FPS display.

This is **a tested incremental build, not a finished twenty-system overhaul**: realistic building models, walkable terrain reconstruction, survival difficulty/Hardcore tiers and production animation are still future work. Read the [2.1 release scope and full 20-area progress accounting](docs/ASHFALL_2_1_WORLD_IMMERSION.md).

## Welcome to Ashfall

**Ashfall** is an independent Godot survival-horror project. The active main scene is now **Crossroads**, a quiet playable environment test of rural settlement density, everyday abandonment, physical walking, credible architecture and the visual composition of neglected homes.

The world uses an original fictional settlement informed by rural Ukrainian architecture, not a reconstruction of any real address or a claim of photorealism. Prior scavenging, anomaly, generator and extraction systems remain isolated in the older Station 04 scene for later reconsideration.

### What you can experience now

- **Walk:** First-person, collision-tested 360 × 420 m sloping ground and connected roads; sprint, crouch and jump.
- **Explore:** Twelve differently laid-out homesteads with actual open gate gaps and varied personal yards.
- **Enter:** Two new modular, furnished and openly accessible homes and the existing house variants.
- **Observe:** Garden rows, washed-out fences, utility poles and wires, rural roadside clutter, woodland and fog.
- **Inspect performance:** Optional F7 FPS diagnostic and F8 view-range cycle; no permanent HUD.


## Getting started

The project targets **Godot 4.7.2** with **Forward+** rendering and GDScript. It has been tested on Windows with an NVIDIA RTX 4080 SUPER; other hardware has not been verified here.

**Using the provided Windows launchers:** Keep the project's adjacent portable `Godot` folder in place, then launch **`Play Ashfall.cmd`** and choose **TAKE THE ROAD**. Use **`Open Godot Editor.cmd`** to edit the project.

**Using your own Godot installation:** Open `project.godot` in a compatible Godot 4.7 editor and press **F5**. The configured main scene is `res://scenes/crossroads_main.tscn`. The adjacent portable editor is not part of this GitHub repository, so a fresh clone needs a compatible Godot installation.

## Your first walk through Crossroads

Start on the village's southern road and walk north. The road curves through twelve inhabited-looking but deserted homesteads. Explore the gates, gardens, front steps, existing homes and the two new accessible house designs. At the north and south ends, narrower farm tracks loop around both sides of the village so you can see the buildings from the rear.

The goal is **observation**: believable scale, seamless ground, usable gates, lighting, prop density, FPS, and whether the environment feels like a real place. There is **no objective, creature, sample, generator or anomaly** to complete or evade.

### Current Crossroads controls

| Input | Action |
| :--- | :--- |
| **WASD / Mouse** | Walk / look |
| **Shift** | Sprint |
| **Ctrl** | Crouch |
| **Space** | Jump |
| **F** | Torch |
| **Escape** | Pause / release mouse |
| **F7** | Toggle FPS and view-distance diagnostic |
| **F8** | Cycle 650 m / 350 m / 500 m draw-distance budget |

The **Tab pack, J journal, F6 difficulty, F9 Hardcore, F10 finishes and E interactions** belong to the *archived Station 04 gameplay scene*, and are intentionally not present in the new Crossroads environment-only main scene.

## Under the hood

The Crossroads launch includes first-person physical traversal, slope/collision-tested terrain, a torch, footsteps, overcast weather and static environmental storytelling. The repository still contains the previous Station 04 systems—including stamina, anomaly damage, loot, extraction and enemy logic—but does not instantiate those systems here.

The repository also contains **modular building kits, props, textures, editable source assets, development review scenes, tests, and documentation**. The new launch scene is distinct from the older `scenes/ashfall_station_main.tscn`, which remains directly loadable in the Godot editor.

### Current development boundaries

This is an environment-first **playtest**: it is not a completed survival game, photorealistic AAA world, or cross-session save system. The new village has no quests, pickups, save state, dynamic enemies, or generator/anomaly encounters.

Ashfall's intended direction is a level-based world with an open-world feel, grounded survival tension, original encounters, and multiple routes worth investigating. Those are **development goals**, not a claim that every system is already implemented.

## Project structure

| Location | Purpose |
| :--- | :--- |
| [`scenes/crossroads_main.tscn`](scenes/crossroads_main.tscn) | Current world-only main scene and first walkable village |
| [`scenes/ashfall_station_main.tscn`](scenes/ashfall_station_main.tscn) | Previous Station 04 gameplay scene, preserved for reference |
| [`scripts/crossroads/`](scripts/crossroads/) | Twelve-lot settlement, pitched prefab houses, roads, physical terrain and walkabout controller |
| [`scripts/runtime/`](scripts/runtime/) | Gameplay and expedition systems |
| [`scripts/authoring/`](scripts/authoring/) | Asset-building and baking scripts |
| [`scripts/review/`](scripts/review/) | Review and inspection helpers |
| [`tools/`](tools/) | Development and launcher tooling |
| [`assets/`](assets/) | Models, materials, textures, and source assets |
| [`concept-art/`](concept-art/) | Visual exploration and archived concepts |
| [`docs/notes/`](docs/notes/) | Design, construction, and development notes |
| [`reviews/`](reviews/) | Development captures and checks |
| [`tests/`](tests/) | Automated and inspection tests |
| [`scenes/legacy/`](scenes/legacy/) | Earlier scene versions retained for reference |

For deeper technical details, see the [survival slice notes](docs/notes/SURVIVAL_SLICE.md), [inventory notes](docs/notes/INVENTORY_NOTES.md), [modular kit notes](docs/notes/CROSSROADS_KIT.md), and [master roadmap](docs/notes/ASHFALL_MASTER_ROADMAP.md).

## Development and verification

The project has been tested on Windows using **Godot 4.7.2** and an **RTX 4080 SUPER**. Development includes smoke and inspection tests covering movement, collision, interactions, hazards, inventory, and expedition behavior. The repository's `reviews/` directory contains development evidence; not every environment or machine has been tested.

For local validation, open the project in Godot and run the configured main scene. Refer to the scripts under `tests/` and the documentation in `docs/notes/` for targeted checks.

## Screenshots

*Screenshots and gameplay captures will be added as the project develops.*

---

<div align="center">

### ASHFALL

*Every expedition begins with a choice to go further.*

**Built with [Godot](https://godotengine.org/)** · [Engine license](https://godotengine.org/license/)

</div>
