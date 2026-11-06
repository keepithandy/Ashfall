# Ashfall

An original, early 3D expedition prototype inspired by the atmosphere of survival exploration games. Built with Godot 4.7.2 and GDScript. This is a small foundation for discussing and developing the larger game.

## Play

Double-click **Play Ashfall.cmd**, then choose **Enter the perimeter**. To edit the project, double-click **Open Godot Editor.cmd**. Press **F5** in Godot to play. Keep the adjacent `Godot` folder alongside this project; the launchers use that portable editor. No separate installation, account, or paid assets are required.

## Your first expedition

Follow the road north, through the checkpoint. The research station is the large building on the left at the far end. Enter through its front doorway and collect the glowing sample from the table. Return south and interact with the entry gate terminal, beside the green lamp.

Give the blue-green anomaly rings plenty of space. Medical supplies are in the left checkpoint hut near the entrance. There is no time limit.

| Control | Action |
| --- | --- |
| WASD / Mouse | Move / look |
| Shift | Sprint, using stamina |
| Space | Jump |
| Ctrl | Lower viewpoint (collision height remains standing) |
| F | Toggle flashlight |
| E | Interact with an object under the crosshair within 3.5 metres |
| Escape | Pause and release the mouse |

## Included

First-person movement and collision, stamina, a flashlight, a foggy industrial perimeter, procedural wind and footsteps, hazardous anomalies, medical supplies, an objective pickup, extraction, pause, failure, and restart. The left checkpoint house now has an editable detailed scene and CC0 scanned materials. No STALKER assets are included.

The surrounding environment is a blockout built by `game.gd` when you run the scene. The detailed house is saved separately as `scenes/checkpoint_house.tscn`; open that scene to edit its architecture, furniture, materials, or collisions. `house_builder.gd` and `bake_house.gd` preserve its rebuild procedure. Double-click **Inspect House.cmd** for a starting position beside it. See `HOUSE_NOTES.md` for references and the material sources.

## Current limits

No enemies, weapons, inventory screen, saved progress, or open-world simulation yet. Progress resets when you restart. The surrounding level is still a simple blockout. Forward+ rendering is selected for material detail, contact shadows, indirect screen-space lighting, and subtle bloom; the project has been tested with Vulkan on this PC's RTX 4080 SUPER.

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
