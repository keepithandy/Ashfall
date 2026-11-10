# Ashfall — consolidated roadmap and phase prompts

November 9, 2026. Working revision 2 — itch.io release goal.

## Product goal: a complete game for itch.io

The owner intends Ashfall to become a real, publishable game on itch.io. Treat every phase as production toward that goal. The playable district and vertical slice are intermediate milestones; the final deliverable is a complete, downloadable game that an unfamiliar player can install, understand, play through and finish without developer assistance.

Proposed initial delivery target: a Windows desktop build, matching the current development environment. Confirm supported systems and target hardware during Phase 1; do not assume browser, Linux or macOS support. Price, release date and whether to offer a separate demo remain open decisions.

Release requirements to carry through every phase:

- A clear opening, coherent objectives, satisfying ending and enough guidance for a first-time player.
- Dependable saving/loading, new game/continue, pause, menus, controls, audio/display settings and agreed accessibility features.
- A consistent visual and sound standard, readable hazards and fair encounters across the complete game.
- Reproducible exported builds tested independently of the Godot editor; begin export smoke checks in Phase 1 and repeat at meaningful milestones.
- Retained editable sources and credits, traceable asset permissions, and an organized development package distinct from the player download.
- A tested release archive containing the files players need, version information, controls, known issues and credits. Keep raw source libraries, research and development tools out of the player download unless deliberately included.
- An itch.io page prepared with accurate screenshots, description, controls, supported systems, measured requirements and relevant content information; review current platform guidance when preparing the page and upload.
- Independent full-game playtests, clean-install checks, a prioritized defect list and a plan for updates and support.

Add this requirement to every phase prompt below: "Treat Ashfall as a complete game being developed for itch.io. Connect this phase to the player's finished experience and keep the exported build working. Distinguish production-complete work from prototypes, concepts and untested integrations."

## Audit conclusion

Ashfall has a working expedition foundation and a substantial art/source library. It does not yet have the newly consolidated, fully decorated district requested in this conversation. Five existing props were added to North Relay; that is a small dressing pass, not completion of the package. The next priority is to verify the physical district and integrate suitable art into a coherent playable journey.

This is a reconciliation of the planning records and evidence reviewed in this chat, not a fresh certification of every asset, screenshot, license or gameplay system. Earlier test results retain their original scope. No new gameplay tests were run to produce this roadmap.

## Document audit and precedence

| Record | Finding and how to use it now |
|---|---|
| Two-year roadmap (`concept-art/preproduction/ROADMAP_2026_2028.html`) | Retain its broad stages and conditional release target. Calendar dates are planning targets; capacity is still unknown. Do not delay already-authorized district work merely to follow a month label. |
| Q1 district plan (`concept-art/preproduction/Q1_DISTRICT_PLAN.html`) | Useful concept and checklist. Its geography is illustrative, not a verified scene map. One checked draft task does not mean the district has been built or approved. Browser checklist state is local, not shared project evidence. |
| Art roadmap (`concept-art/preproduction/ART_ROADMAP.md`) | Earlier ordered work contains stale gaps: household comparisons, yard studies and several source acquisitions subsequently happened. Keep its reuse principles; use the six-workstream review for actual completed review deliverables. |
| Package audit (`ASHFALL_PACKAGE_AUDIT.md`) | An unfinished index, not a comprehensive audit. Its source-directory paragraph incorrectly suggests SOURCE_INSPECTION.md and VERIFICATION.md live inside sources; both are in the parent preproduction directory. |
| Six-workstream review (`concept-art/preproduction/SIX_WORKSTREAM_REVIEW.md`) | Best consolidated art handoff. Reviewed concepts and inspected sources remain distinct from production-ready models. Its no-gameplay-changes statement describes that art pass only. |
| Visual review (`concept-art/preproduction/REVIEW.html`) | Navigation to boards and renders, not evidence that every pictured prop exists in the game. |
| Source inspection (`concept-art/preproduction/SOURCE_INSPECTION.md`) | Acquisition, dimensions, credits and compatibility evidence. Thirteen Blender packages plus the separately retained sink do not imply fourteen accepted game assets. Newer-file warnings and missing animations still matter. |
| Verification (`concept-art/preproduction/VERIFICATION.md`, `verification.json`) | Historical file/link/image/hash checks, not gameplay or renderer acceptance. Counts describe that package snapshot, not every Ashfall file today. |
| Crossroads concept review (`concept-art/preproduction/CONCEPT_REVIEW.md`) | Useful visual criticism; its missing-yard/layout statements were superseded by the six-workstream review. Generated glazing, trim and lighting are not measured construction data. |
| Cottage review (`concept-art/preproduction/COTTAGE_REVIEW.md`) | Useful room and circulation critique. Its not-downloaded claims and pending household comparison are historical. Actual furniture measurements supersede the picture. |
| Production checkpoint (`PRODUCTION_CHECKPOINT.md`) | Outdated blanket production pause: the user subsequently explicitly requested a playable decorated map and continued that work. Preserve its asset safeguards, not the stale pause. It predates the five-prop relay pass. |
| Survival slice (`SURVIVAL_SLICE.md`) | Primary written description of the existing journey and its original verification. Session retention is not disk persistence. It explicitly does not establish a full human playthrough. |
| Building briefs (`concept-art/preproduction/BUILDING_BRIEFS.md`) | Useful location purposes and composition. Era-open and unsourced-furniture statements are superseded by the late-1980s decision and source inspection. Three household studies do not authorize three finished houses. |
| Item/threat briefs (`concept-art/preproduction/ITEM_AND_THREAT_BRIEFS.md`) | Preserve eight item identities and hand fit. Weapon art does not establish a combat system; Listener remains a candidate. |
| Source shortlist (`concept-art/preproduction/SOURCE_SHORTLIST.md`) | Historical candidate research. Later acquisition/inspection supersedes listed-only claims for selected assets. Unselected vendor listings are not owned assets or confirmed current offers. |
| Existing asset inventory (`concept-art/preproduction/existing_assets.json`) | A selected local index, not a complete repository manifest. Expand through discovery rather than interpreting its 71 paths as all project assets. |
| Earlier checkpoint (`concept-art/preproduction/checkpoint-before-six-part-review.md`) | Historical only: three-board state, undecided era and no-acquisitions statements are obsolete. Do not use it as the resume instruction. |

## Current facts and constraints

- Keep the fictional temperate rural district in the late 1980s, level-based exploration, understandable threats and simple inventory.
- Preserve the existing main scene, Crossroads generator encounter, relay recorder on its rear workbench, sample/extraction mission and authored sources.
- Existing areas retain state within a session. Disk saves, larger-scale navigation validation and a complete human journey remain unfinished.
- The recent automated area journey passed after the relay dressing change. The compatibility-renderer run also passed behavior checks, but its dark capture and unsupported fog are not intended-renderer visual approval.
- Acquired art is staged outside normal Godot imports. Inspect/export suitable copies and test them individually. Keep unused or incompatible originals in the source library rather than forcing every asset onto the map.
- Do not infer combat, additional districts, purchases or publication from this roadmap. These remain separate scope decisions.

## How to use the prompts

Run one phase at a time. Every prompt below includes this common working contract: work in `C:\Users\quali\OneDrive\Desktop\source\Ashfall`; inspect current files and local instructions before editing; preserve user changes, editable originals and working gameplay; use the existing project; do not delete, purchase, push, merge or publish. Explain creative decisions plainly. Record changed files, exact checks, observed results and unresolved issues. Never mark a phase complete from file existence alone. Read this document and the prior phase report before starting.

Dates below retain the original two-year planning envelope. Re-estimate after Phase 1 when hours, budget and actual production pace are known. A failed exit check means fix or rescope before advancing.

## Phase 1 — Verified district baseline (start now / Q1)

**Outcome:** one accurate map and asset register that the next implementation can trust.

- [ ] Trace saved scenes and runtime-created areas, links, objectives and collision boundaries.
- [ ] Produce a coordinate-based map with entrances, interaction points, route widths and current/proposed distinctions.
- [ ] Inventory models, textures, sources, concepts, prompts, credits, scripts and tests; flag duplicates and staging status.
- [ ] Record available weekly time, budget and first-release scope assumptions.

**Prompt:**
> Apply the common working contract. Audit the actual main scene and runtime construction, including game.gd, expedition_areas.gd, area_link.gd, village_layout.tscn, relay_yard.tscn and Crossroads integration. Reconcile each location against the Q1 concept map. Build a source-linked asset register with stable IDs, actual paths, intended location, license-record location, native source, import status and unresolved compatibility. Include historical variants without deleting them. Produce a measured district map and a prioritized discrepancy list. Run the available baseline checks using the intended renderer where graphics matter; report automated traversal separately from human playthrough. Deliver a baseline report, map and register; do not invent completed places or current asset approval.

**Exit:** every mapped existing connection is traceable to code/scene evidence; gaps and untested claims are explicit.

## Phase 2 — Decorated playable district and organized package (Q1–Q2)

**Outcome:** the user's requested integrated district pass, with useful assets placed intentionally.

- [ ] Select and validate assets by location; preserve original sources.
- [ ] Dress checkpoint, cottage, Crossroads, relay and research approach in reviewable batches.
- [ ] Keep interactions, hiding opportunities and alternate paths clear.
- [ ] Create a package entry document with play instructions, map, asset register, credits and remaining issues.

**Prompt:**
> Apply the common working contract and use Phase 1's measured map. Implement a coherent decorated district directly in the current Godot project. Begin with existing Godot props, then inspect compatible copies of the acquired furniture, laboratory and relay sources before exporting selected assets. Check scale, materials, pivots, collisions and room fit; do not stretch furniture to fit or scatter all assets everywhere. Preserve Crossroads' shell and generator function and the rear-workbench relay objective. Give each place a plausible activity and distinct arrangement. Implement only routes supported by the audited layout; label future links in documentation. Review player-eye views in the intended renderer, test objectives and pursuit after each meaningful batch, and resolve blockers. Organize navigation through a package index rather than moving resource paths indiscriminately. Retain unused source assets and concept history in the library. Deliver the playable pass, before/after evidence, complete asset register and honest acceptance report; a few added props do not complete this phase.

**Exit:** a player can complete the current expedition through the dressed areas; no blocked interaction or traversal; all included sources are traceable. Human pacing review remains a distinct required result.

## Phase 3 — Reliable saves and area foundations (Q2)

**Outcome:** progress survives quitting and revisiting safely.

**Prompt:**
> Apply the common working contract. Inventory persistent state across inventory, health, doors, caches, reports, rewards, encounters and area position. Design stable object/area IDs and versioned saves before implementation. Implement new game and continue, atomic writes, validation and safe recovery. Preserve existing session behavior. Test restart in both areas, interrupted/corrupt saves, duplicate rewards, looted containers and encounter rolls. Profile area costs before deciding whether streaming is necessary; do not introduce streaming solely because it appears in older notes. Deliver save-format documentation, recovery behavior and passing persistence/regression results.

**Exit:** reload preserves the tested journey without duplicated rewards or lost required objectives; failure recovery is demonstrated.

## Phase 4 — Prove the horror experience (Q3)

**Outcome:** a representative polished journey with readable danger.

**Prompt:**
> Apply the common working contract. Use the existing pursuit, search, anomaly and generator systems to build a representative beginning-to-return experience. Refine the Listener direction through a concrete silhouette/movement review, then implement the selected original creature with editable rig, animation and audio sources. Preserve fair sight and sound rules; verify occlusion, ordinary doorways, search expiry, disengagement and inactive-area suspension. Improve anomaly cues without silently changing hazard radius or inventing safe phases. Tune supplies and objectives through observed play. Measure actual duration rather than promising 20–30 minutes. Deliver rendered evidence, behavior checks and an independent player-feedback report, with any missing human test clearly open.

**Exit:** a fresh player can understand the objective, read danger and escape or hide fairly; save and return behavior remain intact.

## Phase 5 — Finish the first district (Q4)

**Outcome:** a complete first-district experience at a consistent quality level.

**Prompt:**
> Apply the common working contract. Compare every location against the Phase 4 quality standard. Finish selected household stories, checkpoint details, relay service identity and research/extraction approach using the approved asset register. Complete useful alternate routes and return reasons without padding travel. Review terrain edges, boundary readability, lighting, audio, collisions and item use across the full route. Fix visual or gameplay defects before adding buildings. Deliver a fresh-save-to-extraction playthrough report, performance measurements and an updated remaining-work estimate.

**Exit:** first district is complete, revisitable and measured against agreed performance and readability goals.

## Phase 6 — Decide expansion and complete the game (Q5–Q6)

**Outcome:** an achievable beginning, middle and ending; additional area only if capacity supports it.

**Prompt:**
> Apply the common working contract. Review actual time spent, defects and performance from the first district. Present a concrete scope comparison: complete the game within this district, or add one purposeful area with explicit asset, narrative and testing costs. Obtain the owner's creative scope choice before committing to expansion or combat. Then implement the chosen objective/story chain, optional discoveries and ending. If another area is chosen, establish its blockout and persisted transitions before art production. Ensure essential information does not depend on finding every optional note. Reach a fresh-save-to-ending build and freeze major new features. Deliver a content-complete checklist and full defect backlog.

**Exit:** an independent player can reach the ending without developer intervention; all promised required content is present.

## Phase 7 — External testing and optimization (Q7)

**Outcome:** stable, understandable, accessible game and evidence-based launch preparation.

**Prompt:**
> Apply the common working contract. Prepare structured fresh-save playtests and collect observations of confusion, route choices, difficulty, save failures and motion/audio comfort. Prioritize progression blockers. Profile representative scenes on agreed hardware and optimize measured bottlenecks. Review subtitles, controls, settings, low-setting readability, loading and save compatibility. Prepare an optional demo/beta scope and honest store/trailer drafts, but do not publish them. Deliver reproducible defect reports, fixes, performance comparison and a regression matrix showing tested versus untested configurations.

**Exit:** no known progression blockers in the tested scope; performance/accessibility targets met or deviations explicitly resolved with the owner.

## Phase 8 — Release candidate and support (Q8)

**Outcome:** a reviewable release candidate; publication is a separate decision.

**Prompt:**
> Apply the common working contract. Prepare Ashfall's itch.io release candidate and player download for the agreed operating systems. Check current itch.io guidance when preparing delivery. Test the exported build from a clean installation outside the editor, including menus, settings, new game, continue, save upgrades, recovery and the full journey to the ending. Verify credits and distribution permissions from retained records. Prepare accurate page copy, real gameplay screenshots, controls, supported systems, measured requirements and relevant content information. Keep development sources and research separate from the player archive. Retest fixed blockers and prepare versioning, backup/rollback, known issues, support and patch procedures. Produce an explicit go/no-go report with unresolved defects and evidence. Prepare the package and page materials completely for owner review; do not upload or publish without explicit authorization. Move the release target if exit criteria fail.

**Exit:** clean-install and full-journey checks pass, release blockers are resolved, and the owner makes the release decision.

## First action

Start with Phase 1. Preserve the existing creative studies and recent relay changes; verify the whole playable layout once, then use that evidence to complete Phase 2 rather than repeatedly restarting broad art research. Record each phase's completion in a durable report linked from this roadmap. Until those reports exist, the phase remains open.
