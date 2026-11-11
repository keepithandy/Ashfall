# Station 04 — Shallow wet-ground and drainage detail

Nine deliberately placed, noninteractive wet patches add restrained reflection/specular cues around the west/east road shoulders, service-yard edge, and outside selected house yards. Each is a small, UV-feathered transparent plane with broken organic edges, with no associated physics material or collider. This does **not** introduce water gameplay, slippery movement, standing-water hazards, liquid simulation, or rainfall.

Settings are on `EditableWorld/WetGround`: `show_wet_ground` and `wet_opacity`. Patch placement and size are kept in `scripts/runtime/station04_wet_ground.gd`; the shared shader is `assets/shaders/station04_wet_ground.gdshader`. Use the authored patch locations rather than broadly scattering transparent planes in front of every house.

Review requirements: run the included headless wet-ground check, then inspect in Godot Forward+ using the real overcast sun, fog, and PBR soil. Check transparency ordering, z-fighting, visual size, weak/strong reflection, and whether any patch looks like an obvious black shape. Check performance in the same station camera position with WetGround visibility enabled and disabled. Revise or remove patches that fail visual review. Existing collision, objectives, NPCs, enemy behavior and saves are not affected by source changes.
