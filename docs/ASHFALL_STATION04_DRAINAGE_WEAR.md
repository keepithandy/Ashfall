# Station 04 — Roadside drainage wear

A low-contrast drainage-grit pass adds interrupted, weathered discoloration near both road shoulders. It uses the existing world-space ground shader and terrain masks, so there are no new meshes, draw calls, physics bodies, collisions, routes, or third-party assets.

The `drainage_grit` shader uniform controls strength (default 0.16, clamp 0–0.45). This effect is intentionally restrained and spatially broken up; it is not a functioning drainage system. Inspect the north/south road at player height in Forward+ and verify that the shoulders remain irregular rather than looking like painted stripes. This commit is source-level only pending Godot visual acceptance.
