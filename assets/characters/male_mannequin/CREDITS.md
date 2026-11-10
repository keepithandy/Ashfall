# Male mannequin anatomy source

The continuous body mesh and adult male target are adapted from the MakeHuman
core graphical assets, released under CC0 1.0 Universal. The source data and
complete license are preserved in ../scavenger/source/makehuman/.

Sources:

- https://www.makehumancommunity.org/about/license.html
- https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.ASSETS.md
- https://github.com/makehumancommunity/makehuman/blob/master/makehuman/data/3dobjs/base.obj
- https://github.com/makehumancommunity/makehuman/blob/master/makehuman/data/targets/macrodetails/caucasian-male-young.target

Ashfall adaptations: consistent orientation, normalization to 1.80 m with soles
at ground level, smooth neutral mannequin groin, matte unpainted materials,
anatomically positioned 56-bone rig, region-aware normalized skin weights,
editable subdivision and a bounded joint-inspection animation. The head,
neck, torso, arms, fingers, legs and feet remain one continuous anatomical mesh.

The mannequin contains no clothing, hair, facial paint, equipment or flashlight.
Its separate eyes use the same unpainted mannequin finish. The source blend
keeps the original editable cage with two subdivision levels; the Godot GLB
uses one subdivision level and at most four normalized weights per vertex.
