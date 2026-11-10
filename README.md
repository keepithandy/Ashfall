# Ashfall

An original, early 3D expedition prototype inspired by the atmosphere of survival exploration games. Built with Godot 4.7.2 and GDScript. This is a small foundation for discussing and developing the larger game.

## Play

Double-click **Play Ashfall.cmd**, then choose **ENTER STATION 04**. To edit the project, double-click **Open Godot Editor.cmd**. Press **F5** in Godot to play. Keep the adjacent `Godot` folder alongside this project; the launchers use that portable editor. No separate installation, account, or paid assets are required.

## Your first expedition

The main scene is Station 04, including the evacuation area, northern isolation ward and new street lamps. Follow the road north, through the checkpoint. The research station is the large building on the left at the far end. Enter through its front doorway and collect the glowing sample from the table. Return south and interact with the entry gate terminal, beside the green lamp.

Give the blue-green anomaly rings plenty of space. Medical supplies are in the left checkpoint hut near the entrance. There is no time limit.

Choose **Audio** on the opening or pause screen to adjust master volume, wind,
footsteps, and creature/world sounds. Settings are saved between sessions.

| Control | Action |
| --- | --- |
| WASD / Mouse | Move / look |
| Shift | Sprint, using stamina |
| Space | Jump |
| Ctrl | Crouch, with reduced collision height |
| F | Toggle flashlight |
| E | Interact with an object under the crosshair within 3.5 metres |
| Tab | Open inventory and select, carry, or use items |
| Q | Use the carried item |
| Escape | Pause and release the mouse |

## Included

First-person movement and collision, stamina, a flashlight, a foggy industrial perimeter, procedural wind and footsteps, hazardous anomalies, medical supplies, an objective pickup, extraction, pause, failure, and restart. The left checkpoint house now has an editable detailed scene and CC0 scanned materials. No STALKER assets are included.

The surrounding environment is a blockout built by `game.gd` when you run the scene. The detailed house is saved separately as `scenes/checkpoint_house.tscn`; open that scene to edit its architecture, furniture, materials, or collisions. `house_builder.gd` and `bake_house.gd` preserve its rebuild procedure. Double-click **Inspect House.cmd** for a starting position beside it. See `HOUSE_NOTES.md` for references and the material sources.

## Current limits

No weapons, saved progress, or open-world simulation yet. Progress and the eight-item test loadout reset when you restart. The inventory shows item icons and quantities, with carry/use/stow actions; see [INVENTORY_NOTES.md](INVENTORY_NOTES.md), or run **Inspect Inventory.cmd**. Forward+ rendering is selected for material detail, contact shadows, indirect screen-space lighting, and subtle bloom; the project has been tested with Vulkan on this PC's RTX 4080 SUPER.

## Verification

Tested on Windows with Godot 4.7.2 and an NVIDIA RTX 4080 SUPER. The built-in smoke scenario checks movement, ground collision, walking through the house entrance, blocking at its wall, pause/resume, anomaly damage, healing, ray-based sample pickup, and extraction. It also saves `preview.png` from the actual renderer. Exterior and interior house review renders are in `reviews/`.

To rerun from this directory in PowerShell:

```powershell
$env:APPDATA = Join-Path (Get-Location) '..\Godot\userdata'
& '..\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . -- --smoke-test
```

## Files

- `game.gd`: environment, level, interaction, and expedition state.
- `player.gd`: movement, camera, torch, and footsteps.
- `hud.gd`: HUD, menus, and controls.
- `main.tscn`: entry scene.
- `project.godot`: project settings.

Official engine source and license: https://godotengine.org and https://godotengine.org/license/ . The editor executables were downloaded from the official Godot Windows download page and their Windows publisher signatures validated as Prehensile Tales B.V. The local launchers keep settings and user data inside the adjacent portable Godot folder.

## Connected survival slice

Crossroads now powers a service passage to North Relay. Retrieve the generator diagnostic, use the lit passage east of the starting road, recover the recorder behind the relay cottage, and return to the entry gate. Inventory, looted caches and objectives persist between area visits within the expedition. See [SURVIVAL_SLICE.md](SURVIVAL_SLICE.md) for the route, architecture, validation and remaining work.


## Project folders

- `scenes/ashfall_station_main.tscn`: current playable main scene.
- `scripts/runtime`: gameplay systems.
- `scripts/authoring`: asset builders and baking tools.
- `scripts/review` and `tools/launchers`: asset inspection tools.
- `assets`: models, textures and editable source assets.
- `docs/notes`: design notes, roadmaps and asset documentation.
- `concept-art/archive`: earlier reference images and previews.
- `scenes/legacy`: previous main scene, retained for reference.
- `reviews` and `tests`: development captures and checks.

Double-click **Play Ashfall.cmd** in this folder to enter the new scene.
