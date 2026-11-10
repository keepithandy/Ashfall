# Source shortlist and reuse decisions

> Current status: the late-1980s setting is user-selected. See [six-workstream review](SIX_WORKSTREAM_REVIEW.md) and [source inspection](SOURCE_INSPECTION.md) for completed boards, acquired packages and remaining production holds. Earlier research statements below are historical and may be superseded.

Checked November 8–9, 2026. Links are primary asset listings and official documentation. Suitability judgments below are our assessment; listing claims have not been verified by downloading or importing the assets. Prices that could not be read reliably are left unconfirmed.

## First choices: fill real gaps

Domestic continuation: [Small Wooden Table 01](https://polyhaven.com/a/small_wooden_table_01) by Ulan Cabanilla (~3K triangles, 0.9 m wide, 1K–4K textures) and [Painted Wooden Chair 01](https://polyhaven.com/a/painted_wooden_chair_01) by Kuutti Siitonen (724 triangles, 1 m tall, 1K–8K textures) are named candidates. Both list CC0 and Blender/glTF/FBX. Neither has been acquired or tested; the table is classified as side/end furniture, so dining height/clearance must be confirmed. See the [cottage source map](COTTAGE_REVIEW.md). Ordinary bed and bathroom sourcing remain open.

| Candidate | Intended place / use | What the source establishes | Decision / unresolved work |
| --- | --- | --- | --- |
| [Painted Wooden Cabinet — Kirill Sannikov](https://polyhaven.com/a/painted_wooden_cabinet) | Cottage kitchen or living space | CC0; Blender, glTF and FBX listed; approximately 2K triangles; weathered timber | Strong first candidate for domestic identity. Check actual doors/pivots before promising interaction. |
| [Painted Wooden Cabinet 02](https://polyhaven.com/a/painted_wooden_cabinet_02) | Tall cottage storage | CC0; listed at 966 triangles and 2.6 m tall | Useful variation; verify ceiling clearance and package formats. |
| [Metal Office Desk — Ulan Cabanilla](https://polyhaven.com/a/metal_office_desk) | Checkpoint administration, relay desk, research office | CC0; Blender/glTF/FBX; approximately 7K triangles and 2 m wide | Strong office-family candidate. Distinguish uses through documents and equipment, not a different desk model in every room. |
| [Tool Cart — Savva Zakharov](https://polyhaven.com/a/tool_cart) | Crossroads repair bay | CC0; Blender/glTF/FBX; approximately 29K triangles, 1.3 m wide | Good gap-filler if it earns a prominent location. More expensive than a background prop; assess reduced detail later. |
| [Portable Generator — James Ray Cock](https://polyhaven.com/a/portable_generator) | Comparison against existing generator | CC0; Blender/glTF/FBX; detailed controls and frame | Benchmark only for now. Ashfall already has a working generator prop and encounter, so replacement must show a clear gain. |
| [Workshop HDRI](https://polyhaven.com/a/workshop) | Real workshop lighting, spatial density and equipment relationships | CC0 downloadable HDR/EXR, with photography and processing credits | Study its practical work surfaces and lighting. It does not supply a ready-made playable workshop. |
| [Pine Forest collection](https://polyhaven.com/collections/pine_forest) | Landscape palette and coherent vegetation family | Collection includes trees/nature assets and a downloadable scene | Investigate individual trees and ground assets; avoid importing the whole scene by default. Inspect wind, geometry and texture budgets later. |
| [ambientCG materials](https://ambientcg.com/) | Missing flooring, wall and surface variations | Official license covers downloadable assets and material preview renders under CC0 | Supplement the existing material palette only after identifying a missing surface. No replacement library needed yet. |
| [Service Pistol — Mateusz Sadek](https://polyhaven.com/a/service_pistol) | First firearm appearance study | CC0; Blender/glTF/FBX; wood/tape grip variants, separate magazines; approximately 28K triangles | Best verified reuse lead for weapon art in this pass. Inspect moving parts, rig, markings and first-person appearance later. No firing/reloading animation or game functionality is assumed. |

The listing's rounded triangle counts are screening information, not measured Godot costs. Weapon selection here concerns visual assets only; it does not add combat or decide the final roster.

## Building candidates: inspect before adopting

| Candidate | Evidence | Assessment |
| --- | --- | --- |
| [Abandoned Countryside House — 3D SHOP](https://www.fab.com/listings/ed0757d9-7b7f-46f0-826e-69aa755db6bd) | Listed free; description advertises FBX and BLEND, while the formats field shows FBX; includes rural yard elements | Plausible style fit, but duplicates some existing cottage work. Inspect actual source delivery, playable interior, dimensions and license before using. Not yet cleared for acquisition. |
| [Abandoned House Modular — Horror Interior Kit](https://www.fab.com/listings/d962dc06-a697-4e38-9c3b-afddbb647af2) | 27 modules plus 16 props; GLB/glTF/FBX and Blender 5.2 listed; separate hinged pieces; 87,491 total triangles advertised | Potentially useful for missing domestic interiors. More ornate than the current rural cottage in places. Price and selected license unconfirmed; installed Blender compatibility and actual files need checking. |
| [Abandoned building modular — 32cm](https://www.fab.com/listings/046f1740-a9d1-457e-ab99-4cf13699c748) | 11 configurable industrial modules; FBX and converted glTF/GLB listed; 134K triangles advertised | A possible future warehouse source, not a reason to replace Crossroads. Editable native source not established. |
| [Modular Bunker — PStudio](https://www.fab.com/listings/ee887294-a2b7-4f5e-b784-dc0699909471) | Description advertises FBX/Blend and 139 assets, alongside Unreal content | Conditional research-facility lead. Confirm actual files and source availability. Blueprint doors, particles and other Unreal behavior do not transfer automatically. |

## Leads not selected

- [Abandoned Village](https://www.fab.com/listings/facc7678-4e63-476f-b657-93886f7a1474): listing supplies Unreal format and is tagged stylized. Too much conversion/style uncertainty to recommend over the local village now.
- [Survival Props Pack](https://www.fab.com/listings/e72c1bb7-75b7-4787-ba5d-8ba15c73dadd): extensive overlap with our inventory and tool library; Unreal demonstration and format. No current reason to replace working item assets and grips.
- [Survival Props Pack — 116](https://www.fab.com/listings/7a4db0ce-385e-4811-ad04-30d4c7fbd314): description says planned delivery and advertises Blender, while listed formats differ; marked generated with AI. Hold for actual file/source verification rather than trusting the broad coverage claim.
- [Post Apocalyptic Modular Building Pack](https://www.fab.com/listings/0932eb01-d712-4573-b99f-8e0ebb0d9ca3): advertised 2.56 million triangles across 29 objects and broad architectural styles. Likely more art-direction and optimization work than this slice needs.
- The bolt-action rifle's individual listing was verified in the November 9 pass below. Shotgun sourcing remains open; first establish whether a shotgun belongs in the art roster.

## November 9: domestic, research and relay selections

These candidates are **listed**, not acquired, inspected in Blender, or tested in Godot. Every Poly Haven entry below lists CC0 and Blender/glTF/FBX delivery. Sizes and geometry counts are rounded listing values. Native sources are advertised, not locally verified. Texture choices are availability, not a recommendation to use the highest resolution.

| Candidate / author | Listing evidence | Ashfall decision |
| --- | --- | --- |
| [Electric Stove](https://polyhaven.com/a/electric_stove) — Kuutti Siitonen | 0.9 m tall, ~14K triangles, 1K–8K textures, rigged tag | Select for cottage kitchen review. Reuse worn enamel and simple controls; do not promise the rig will transfer or the oven will function. |
| [Chemistry Set](https://polyhaven.com/a/chemistry_set) — Jiří Ptáček | ~42K triangles for the set, 1.1 m extent, 1K–4K textures | Select a few sample containers/racks for research. Do not scatter the whole set or imply chemical procedures. Glass transparency and separable objects need inspection. |
| [Industrial Microscope](https://polyhaven.com/a/industrial_microscope) — Lukas Walzer | ~17K triangles, 0.5 m wide, 1K–4K textures | Preferred examination-bench candidate; one purposeful instrument. Fits utility equipment better than ornamental antique brass. |
| [Retro Multimeter](https://polyhaven.com/a/retro_multimeter) — elli moeller | ~13K triangles, 0.3 m tall, 1K–4K textures | Select for relay servicing; optional shared workshop prop. This is electrical test equipment, not a replacement for the anomaly meter. |
| [Cassette Player](https://polyhaven.com/a/cassette_player) — Oday Abuzaeed | ~5K triangles, 0.2 m tall, 1K–4K textures, tape variants | Preferred lead for the existing relay recording objective's visual identity. Inspect before replacing any current prop. Presence of a built-in mic in listing imagery does not establish working recording controls or animation. |
| [Vintage Radio Transceiver](https://polyhaven.com/a/vintage_radio_transceiver) — Mateusz Sadek | ~42K triangles, 0.6 m wide, 1K–4K textures; military/WW2 tags | Conditional alternative only: current desk radio already exists; this could impose too much military/period specificity. Do not adopt solely because it is detailed. |
| [Vintage Electric Kettle](https://polyhaven.com/a/vintage_electric_kettle) — SV Garip | ~15K triangles, 0.3 m wide, 1K–4K textures | Hold. Antique brass/wood character is a poor universal kitchen baseline. A cottage-specific inherited object is possible after the setting is settled. |
| [Bolt Action Rifle 7.62](https://polyhaven.com/a/bolt_action_rifle_7_62) — Mateusz Sadek | ~20K triangles, 1.2 m extent, 1K–8K textures, wood/cloth/metal | Select alongside the existing pistol lead for weapon appearance review. Scope/accessories are optional visual choices. Rig, reload clips and hand fit remain unverified. No combat implementation. |

### Human movement and character foundations

The existing [scavenger credits](../../assets/characters/scavenger/CREDITS.md) and bundled [MakeHuman graphical asset license](../../assets/characters/scavenger/source/makehuman/LICENSE.ASSETS.md) document the local body/skin foundation. Keep the authored clothing, hands and rig. This does not automatically license unrelated community clothing packs.

[CMU's motion-capture database](https://mocap.cs.cmu.edu/) permits use in commercial products but prohibits selling the motion data itself, including converted data. It offers locomotion and environment-interaction categories. Its guidance flags noisy hand/toe joints and uncaptured finger motion. Use selected human walk/run/turn trials as a future baseline, then inspect, retarget and edit deliberately. **No individual clip has been selected, downloaded or tested.** It is a movement source, not an Ashfall creature design or a promised drop-in animation pack. The site requests no crawling; no bulk crawl was performed.

### Gaps retained rather than filled with mismatched assets

The [Gothic Bed](https://polyhaven.com/a/GothicBed_01) is available but its carved four-poster silhouette does not fit the ordinary cottage brief. Keep the existing mattress and seek a plain domestic frame. The current field cot suits checkpoint/temporary accommodation, not every household. Searches did not establish a suitably worn, licensed bathroom fixture package in this pass. Do not substitute flat-colour placeholder furniture or an entire ornate house kit just to mark these gaps complete.

## Reuse conditions

[Poly Haven's license](https://polyhaven.com/license) allows commercial use and modification of its CC0 assets. It explicitly distinguishes those assets from protected site content such as example/user renders and logos. Link to those references; do not assume every website image can be copied into a shipped art book or supplied to a generator. [ambientCG's license](https://docs.ambientcg.com/license/) explicitly includes its material previews as well as downloadable files.

[Fab's Standard License summary](https://www.fab.com/eula) permits compatible tools beyond Unreal, modification, and distribution within projects, while restricting standalone redistribution. That does not establish that every listing has that license or grants native source access. Confirm each selected product's actual terms, tier and file contents; Reference-Only is not source access. Keep account-specific pricing unconfirmed until visible. No purchases or library claims have been made.

[Godot's import documentation](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html) recommends glTF 2.0, supports Blender through conversion, and supports FBX through ufbx. These are format paths, not guarantees that a downloaded pack is game-ready. Later acceptance must check scale, normals, materials, pivots, colliders, animations, draw calls and hand fit in a separate review before integration.

## What is still missing from the research

Kitchen stove, selected laboratory equipment, relay recorder/test meter and a rifle now have named candidates. Still open: bathroom fittings, plain domestic bed/table/seating, curtains, sample-case inserts and PPE details, relay racks/connectors, period-consistent signage, clothing variants, specific creature movement clips, anomaly-effect and audio sources, and any additional weapon family justified by the game. The setting's region/era needs a clear decision before mixing manufacturers and architectural traditions. No claim is made that the whole game's sourcing is complete.
