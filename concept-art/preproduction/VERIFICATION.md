# Preproduction verification — November 9, 2026

This report covers art documents, concept images and research sources. It does not count earlier game tests as validation of the art package.

## Automated checks

Run `node concept-art/preproduction/verify_package.mjs` from the project root. Exact results, image dimensions and hashes are saved in [verification.json](verification.json).

Checks cover all 71 indexed local asset paths, local Markdown/HTML references, PNG signatures/dimensions, 77 acquired package-file MD5 values, the existing `.gdignore`, and the sink GLB header/declared size/JSON structure. Blender inspection records 13 source files and missing texture references. These are file and structural checks, not render parity or gameplay acceptance.

## Visual review

The ten generated concept images, three actual source renders and eight historical item review captures were inspected in the conversation. The pistol source-render camera crop was corrected. Concepts are assessed for readable composition and continuity, with geometry deviations documented in the six-workstream review. No claim of pixel-identical preservation is made.

The local HTML index and coordinate diagram were rendered in a headless browser and visually inspected. [Index preview](review-index-preview.png) and [diagram preview](layout-preview.png) are retained. No desktop screen-capture session was used. The index opens with readable navigation and loaded local art; the coordinate diagram displays the saved points and legend. Individual artwork was reviewed separately rather than treating the opening-page screenshot as proof of every image's quality.

## Production holds

- Bathroom fixture source/model decisions and exact room fit remain open; the concepts are not fabricated asset acquisitions.
- Newer Blender source data requires a compatible version before final export; original files are untouched.
- Generated partitions, window details, signs, route labels and anomaly radii do not authorize gameplay/geometry changes.
- Weapon rigs, animation, grips and carrying fit remain unverified.
- The Listener is a first design candidate, not an approved final creature.

No new Godot import, gameplay, collision, pursuit, item-use, objective or manual playthrough test was run during this art-only work. Those tests belong to the later approved integration pass.
