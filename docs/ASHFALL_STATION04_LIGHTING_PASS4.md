# Station 04 — Lighting, Fog Depth and Foundation Integration

**Status:** implemented on the environment PR, awaiting Godot Forward+ real-render and gameplay acceptance. This pass is source-level work and does not establish a captured screenshot, measured FPS, or a human expedition traversal.

## Changes

The authored `WorldEnvironment` keeps the existing moving-cloud sky, filmic tonemapping, volumetric fog, and shadow-casting directional light. A controlled change to ambient brightness and overcast key-light strength aims to preserve readable house materials without turning the level into daylight. Global fog is slightly reduced so distant tree and hill silhouettes have depth instead of being lost in a uniform gray wall. SSAO intensity is reduced to avoid crushing recessed building surfaces.

Three **static visual-only FogVolume regions** add a restrained depth gradient around the research approach, service-yard perimeter, and behind the southern cottages. They complement, rather than replace, the existing procedurally created road and village mist in `scripts/runtime/atmosphere.gd`. The latter script is **unchanged**.

The existing work-light prop at approximately (31, 0, 7) has an optional lamp light disabled in the prop scene. This pass adds a low-power, localized SpotLight at the lens position in Station 04 only, keeping the reusable prop definition unchanged. No gameplay or stealth visibility rules are changed.

The flat ground's PBR shader now has subtle material-only weathering around the actual five authored house locations, using their approximately known footprint dimensions. Roads, house heights, entrances and physics remain unchanged. Exposed foundation edges require visual confirmation because authored mesh foundations may deviate from the approximate mask.

## How to inspect

In the Godot Forward+ editor, run `scenes/ashfall_station_main.tscn` (F5). From the entrance and each exterior house threshold, examine light/dark contrast and ground texture contact. Check both sides of the research approach (including the anomaly), walk around the service yard and the work light, and look south toward the three houses and rising skyline. Watch for harsh warm spots, milky overexposure, hard-edged fog volumes, and unnaturally dark rectangles around houses.

For A/B review, toggle `EditableWorld/AtmosphericVolumes` visibility, `EditableWorld/Props/WorkLampThrow` visibility, and `WorldEnvironment` values in the Inspector. Tweak `foundation_weathering` on the WalkableGround material if house contact looks too dark. Do not modify player visibility/detection, hazard logic, or quest routes as a substitute for tuning environmental appearance.

## Checks

The environment GitHub workflow includes a headless Godot import, Station 04 grounding regression, **new** `tests/check_station_lighting.gd` assertion script, and scene-start smoke check. All these must execute successfully before QA approval. Separate manual Forward+ screenshots (entrance, service yard, cottage row, research approach), actual FPS/frametime comparison and fresh-to-extraction playthrough are still necessary. Source inspection alone is not evidence of final visual quality or production readiness.

## Compatibility

Changes are limited to Station 04 scene, existing station ground shader, new targeted headless lighting test, this document, and the environment CI workflow. No expansion into the draft regional map (PR #6) and no new third-party assets or edits to the decorative asset pack (PR #4). `main` stays unchanged until review gates are met.
