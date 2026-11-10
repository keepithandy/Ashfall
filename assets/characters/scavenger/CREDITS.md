# Ashfall full character — graphical asset sources

The head uses MakeHuman's CC0 graphical assets: hm08 base mesh, the adult male
macro target, middleage_caucasian_male skin, low-poly eyes with the brown eye
material, and short02 hair with its texture/normal map. The head was cropped,
rescaled, reweighted and fitted to the Ashfall skeleton. Hair and eyes were
fitted from their MHCLO barycentric mappings. Eyebrow strands were added.

These are graphical data, not MakeHuman application or add-on source code.
MakeHuman's core graphical asset license is CC0 1.0 Universal:

- https://www.makehumancommunity.org/about/license.html
- https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.ASSETS.md
- https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html

The upstream graphical asset copyright notices identify Data Collection AB,
Joel Palmius and Jonas Hauquier; the adult target also credits Manuel Bastioni.
The original notices and complete CC0 license remain in source/makehuman/.

Original data sources retrieved 2026-11-06:

- https://raw.githubusercontent.com/makehumancommunity/makehuman/master/makehuman/data/3dobjs/base.obj
- https://raw.githubusercontent.com/makehumancommunity/makehuman/master/makehuman/data/targets/macrodetails/caucasian-male-young.target
- https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip

The jacket, trousers, boots, gloves, satchel, strap, flashlight, synthesized
fabric/leather textures, 57-bone rig and nine draft clips were authored for
Ashfall. The approved player concept in the project informed the outfit.

source/ashfall_scavenger.blend contains the editable meshes, rig, clips and
packed images. The GLB is the runtime export. source/.gdignore keeps Blender
source and upstream files out of Godot's game asset import.
