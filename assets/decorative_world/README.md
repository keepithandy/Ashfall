# Ashfall — Decorative World Props (roadside first pass)

This is an **original, static, non-interactive prop set** for environmental dressing across Ashfall. No loot, inventory, crafting, script, quest, interaction or gameplay hooks.

## Assets and size (metres)

| Prop | Visual | Godot scene | Approx. footprint |
| --- | --- | --- | --- |
| Bent guardrail | `assets/decorative_world/models/bent_guardrail.glb` | `scenes/decorative_world/bent_guardrail.tscn` | 4.2 × 0.3 × 1.0 |
| Abandoned bus shelter | `assets/decorative_world/models/collapsed_bus_shelter.glb` | `scenes/decorative_world/collapsed_bus_shelter.tscn` | 3.4 × 1.6 × 2.5 |
| Tire pile | `assets/decorative_world/models/discarded_tire_pile.glb` | `scenes/decorative_world/discarded_tire_pile.tscn` | 1.2 × 1.2 × 2.0 |
| Fallen utility pole | `assets/decorative_world/models/fallen_utility_pole.glb` | `scenes/decorative_world/fallen_utility_pole.tscn` | 4.5 × 1.9 × 3.2 |

Open `scenes/decorative_world/gallery_roadside.tscn` to inspect all four side-by-side. They are **not placed** in the main level.

Each scene has simple static collision, no scripts, and references its original glTF 2.0 binary model. Models contain roughness/metallic PBR material factors and several weathered/rusted detail surfaces. The models were procedurally authored specifically for Ashfall, not imported from third-party asset packs.

## Validation status

- Generated meshes are self-contained glTF 2.0 assets with explicit positions/normals, material definitions, and binary buffer chunks.
- No Godot editor is available in the authoring environment, so **Godot import, appearance, collision, and performance are not yet playtested**.
- Consider this a **first asset pass**, not a production-art sign-off. It needs editor inspection and art refinement (including texture work and alternate damage variants) before merge.

## Scope guardrails

Do not turn these props into pickups or usable items. Do not add signals, animations, rigidbody interactions, or new scripts to these scene assets. Preserve main scene, station lighting, gameplay and save files. Issue #3 tracks the broader 16-prop expansion.
