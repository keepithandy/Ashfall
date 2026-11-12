<div align="center">

# A S H F A L L

**SURVIVE THE SILENCE.**

*An original, first-person survival-horror expedition through abandoned roads, industrial ruins, and places best left undisturbed.*

![Godot](https://img.shields.io/badge/Godot-4.7.2-478CBF?logo=godot-engine&logoColor=white)
![Language](https://img.shields.io/badge/Language-GDScript-2D3748)
![Platform](https://img.shields.io/badge/Platform-Windows-363636)
![Status](https://img.shields.io/badge/Status-2.1%20Playtest-796044)

**[Play the current build](#getting-started) · [Explore Station 04](#your-first-expedition) · [Project structure](#project-structure)**

</div>

---

> **The road is quiet. The perimeter is not.**  
> Head north. Recover what remains. Find your way back.

## Ashfall 2.0 playtest

This milestone combines the playable Station 04 expedition with the recent environmental passes, repaired distant hills, layered forest, **900 m Station 04 view distance**, and a personal screen-space **Field Journal HUD**. Press **F10** to switch among Field Journal, Signal Receiver and Worn Amber. The start screen now has a 2.0 field briefing with accessible actions on laptop-sized windows.

The **expanded region road/terrain scene remains a separate preview**, not a replacement for the Station 04 gameplay start. Decorative props and galleries are included for inspection. This is an integrated **playtest**, not a completed release; terrain visuals, performance and end-to-end expedition behavior still need an in-game approval pass. See [Ashfall 2.0 playtest scope and QA](docs/ASHFALL_2_0_PLAYTEST.md).

## Ashfall 2.1 — World Immersion Playtest

The latest branch extends the 2.0 Station 04 build with near-ground foliage clusters, four narrative landmarks, nine discoverable field notes, localized ambient sounds, creature investigation around last-known positions, and more useful item inspection. **J** opens the Field Record, **F8** cycles draw-distance budgets, and **F7** toggles a live FPS display.

This is **a tested incremental build, not a finished twenty-system overhaul**: realistic building models, walkable terrain reconstruction, survival difficulty/Hardcore tiers and production animation are still future work. Read the [2.1 release scope and full 20-area progress accounting](docs/ASHFALL_2_1_WORLD_IMMERSION.md).

## Welcome to Ashfall

**Ashfall** is an independent Godot survival-horror project focused on vulnerable exploration, scavenging, environmental storytelling, and unease. Inspired by the *atmosphere* of survival-exploration games, it uses an original world, environments, and assets rather than assets taken from those games.

The current playable expedition is **Station 04**: a foggy industrial perimeter with an evacuation area, checkpoint, isolation ward, hazardous anomalies, and a research station. The project is a foundation in active development, **not a finished game**.

### What you can experience

- **Explore:** Traverse the station perimeter, checkpoint buildings, and surrounding environment.
- **Scavenge:** Find medical supplies, collect an objective sample, and interact with containers and items.
- **Survive:** Manage stamina, flashlight use, and dangerous anomaly zones.
- **Extract:** Return to the entry gate after completing the expedition objective.
- **Investigate:** Explore a connected survival slice linking Crossroads and North Relay, with area-to-area inventory and objective continuity during an expedition.
- **Listen:** Adjust master, wind, footsteps, and creature/world audio levels, with settings saved between sessions.

## Getting started

The project targets **Godot 4.7.2** with **Forward+** rendering and GDScript. It has been tested on Windows with an NVIDIA RTX 4080 SUPER; other hardware has not been verified here.

**Using the provided Windows launchers:** Keep the project's adjacent portable `Godot` folder in place, then launch **`Play Ashfall.cmd`** and choose **ENTER STATION 04**. Use **`Open Godot Editor.cmd`** to edit the project.

**Using your own Godot installation:** Open `project.godot` in a compatible Godot 4.7 editor and press **F5**. The configured main scene is `res://scenes/ashfall_station_main.tscn`. The adjacent portable editor is not part of this GitHub repository, so a fresh clone needs a compatible Godot installation.

## Your first expedition

The starting area is **Station 04**.

Follow the road north through the checkpoint. The research station sits on the left near the far end. Enter through the front doorway and recover the **glowing sample** from the table. Then head back south and interact with the entry-gate terminal near the green lamp.

Keep your distance from the **blue-green anomaly rings**. The left checkpoint hut has medical supplies. There is **no time limit**.

### Controls

| Input | Action |
| :--- | :--- |
| **WASD / Mouse** | Move / look |
| **Shift** | Sprint (uses stamina) |
| **Space** | Jump |
| **Ctrl** | Crouch |
| **F** | Toggle flashlight |
| **E** | Interact within reach, under the crosshair |
| **Tab** | Open inventory; select, carry, or use items |
| **Q** | Use carried item |
| **Escape** | Pause / release mouse |
| **F10** | Cycle the three saved field-journal HUD finishes |
| **J** | Open/close personal discovery Field Record |
| **F8** | Switch Station 04 viewing distance (900 m / 650 m / 400 m) |
| **F7** | Toggle live FPS/view diagnostic overlay |

## Under the hood

Ashfall includes first-person movement and collision, stamina, a flashlight, atmospheric fog, wind and footsteps, hazardous anomaly areas, item interaction, inventory, an expedition objective, extraction, pause, failure, and restart states.

The repository also contains **modular building kits, props, textures, editable source assets, development review scenes, tests, and documentation**. The current launch scene is distinct from earlier experiments retained under `scenes/legacy/`.

### Current development boundaries

This is an early build. **Weapons, persistent saved progress between launches, and an open-world simulation are not yet complete features.** The connected survival slice can preserve inventory, caches, and objectives across area visits *within an expedition*, but that should not be confused with a full save system.

Ashfall's intended direction is a level-based world with an open-world feel, grounded survival tension, original encounters, and multiple routes worth investigating. Those are **development goals**, not a claim that every system is already implemented.

## Project structure

| Location | Purpose |
| :--- | :--- |
| [`scenes/ashfall_station_main.tscn`](scenes/ashfall_station_main.tscn) | Current playable entry scene |
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
