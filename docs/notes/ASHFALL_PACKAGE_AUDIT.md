# Ashfall package audit — in progress

The existing Godot project is the working package. Preserve its scenes, gameplay scripts, editable assets and uncommitted work. This is an audit index, not a claim that a new district is complete.

## Playable foundation

- `scenes/ashfall_editable.tscn` is the main scene; `game.gd` coordinates the current expedition.
- The checkpoint, village cottage, Crossroads station, research mission and North Relay are represented in the current project. `SURVIVAL_SLICE.md` describes the existing journey and test limitations.
- `scenes/relay_yard.tscn` includes a small service-yard dressing pass using existing props. It retains the recorder and flank routes.
- State persists between area visits during a session, but there is no disk save. A complete uninterrupted human playthrough remains outstanding.

## Asset groups

- `scenes/props`, `scenes/workshop`, `scenes/extra_dressing` and `scenes/nature`: existing usable Godot scene assets. Their placement, collision and appearance need review in context.
- `scenes/houses`, `scenes/crossroads_kit` and `assets/crossroads_v03`: existing building and station resources.
- `scenes/items`, `scenes/loot`, `assets/items` and `assets/grips`: existing item, loot and hand-fit work.
- `concept-art/preproduction/REVIEW.html`: concept boards and source review, not completed playable environments.
- `concept-art/preproduction/sources`: acquired editable source packages. See `SOURCE_INSPECTION.md` and `VERIFICATION.md` there for compatibility and provenance; these have not all been adapted or accepted in Godot.
- `concept-art/preproduction/Q1_DISTRICT_PLAN.html`: conceptual proposed district and checklist; its dashed links are not verified playable paths.

## Remaining work

Audit physical locations and available assets in the live scene; plan and implement a coherent decorated map without blocking existing interactions; integrate compatible sources selectively; review visually in the intended renderer; test all objectives and traversal; document the result. The map and consolidated package are not yet complete.
