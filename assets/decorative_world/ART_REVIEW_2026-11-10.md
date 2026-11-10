# Ashfall decorative assets — real render quality audit (2026-11-10)

## Actual evidence

Godot **4.7.2** imported and instantiated both asset packs in CI. A subsequent run used **Xvfb and Godot's OpenGL compatibility renderer** to render every one of the 32 distinct assets as standalone previews with a neutral backdrop and darker Ashfall-style lighting. The output comprises 32 PNG images and two labeled contact sheets; these are uploaded as the **ashfall-prop-render-review** artifact from workflow run **42889787382**.

Visual evidence: https://github.com/keepithandy/Ashfall/actions/runs/42889787382

## Review findings (based on the actual 32 renders)

**Blocking production-art findings:**
- Several interior props, notably the sofa, armchair, cupboards and dresser, have box-like silhouettes with little believable fabric, joinery, sag or surface variation.
- Real-world small-detail textures are not implemented. Materials use basic glTF PBR factors, and most close surfaces appear smooth and uniformly colored.
- The ceiling fan and several scattered props read as stylized/prototype shapes rather than realistically abandoned objects.
- The tire stack appears too bright and uniform for weathered rubber in the demonstrated lighting.
- Damage/rust on some outdoor props is geometric and highly repetitive, rather than convincing localized wear.
- One fixed camera view cannot assess every side, material seam, hidden face, or deformation. Multiple angled renders and in-level test placement are still required.

**Integration checks passed:**
- Static glTF 2.0 envelope, normal and reference checks passed.
- Godot headless imports and scene instantiation passed for both original packs.
- Current feature branch adds collision refinement for the hollow culvert, window mullions, bridge side rails, tire stack, sofa/armchair and furniture.
- Separate dressing-set scenes are *examples*, not modifications to playable levels.

## Gate accounting (the six remaining requirements from PR #4)

1. **Visual QA:** PARTIAL. Thirty-two actual neutral/dark renders obtained; still need in-editor multiple-angle and in-level evaluation.
2. **Production materials:** NOT COMPLETE. Textures, realistic wear, roughness/normal detail and model silhouette refinement are required.
3. **Collision quality:** IN PROGRESS. Replaced nine problematic approximate colliders, including culvert (opening remains hollow); debug-physics/in-game testing still required.
4. **Wear/damage variants:** IN PROGRESS. Sofa torn variant plus four static variants added, but additional custom damage geometry and artistic review remain.
5. **Level placement and navigation:** IN PROGRESS. Three separate reusable dressing example scenes added without touching the current station or game levels; safe placement and route clearance have not been tested in the player's levels.
6. **Final approval:** NOT MET. User has authorized merging when complete; real art standards are not yet met, so do not merge prematurely.

## Merge policy

**DO NOT MERGE** until each of the six gates is demonstrably completed. Automated Godot import success is not evidence of visually finished production assets.

The intended direction is grounded, realistic, weathered, performance-aware post-apocalyptic scenery. The current models are a functioning first pass, not that final standard.
