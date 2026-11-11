# Station 04 — Fixture Glow and Industrial Ground Staining

The existing Station 04 tripod work light had a physical lamp fixture and a recently introduced low-energy light, but lacked a corresponding bright lens visible from player height. A small warm emissive sphere is now placed at the authored fixture's lens (roughly world x30.952/y1.62/z7.088) without changing the prop library, light detection, or interaction system.

The ground shader adds localized, noise-broken dirt and oil-contact darkening beneath the service-yard's existing generator, metal drums and supply stack. This is a material-only mark: no decals casting large shadows, puddle collision, stamina penalties or NPC behavior changes. The staining strength is adjustable via `industrial_staining` on the walkable ground shader.

The dedicated lighting test now asserts the lens is emissive and near its fixture and that the contact-staining shader parameter exists. This is a structural/regression check, **not** a screenshot or visual acceptance. In Godot Forward+, inspect the fixture from the gate and service yard, verify the glowing lens doesn't look like a floating orb, and confirm the dark patches are subtle against the existing concrete and muddy shoulders. Use F5 and compare FPS before marking ready.
