# Anatomy-first character workflow

The new working model is a plain adult male display mannequin: bald, matte
gray, unpainted eyes, a smooth neutral groin, and no clothing or equipment.
Its head, neck, torso, arms, hands, legs and feet form a continuous mesh.
It is 1.80 m tall, with a 56-bone anatomical rig and editable subdivision.

Open scenes/mannequin_review.tscn in Godot and press F6, or run
Inspect Mannequin.cmd in the Ashfall folder.
Inspect Full Character.cmd opens the playable mannequin with its held flashlight.
Inspect Hand Grips.cmd isolates its hand for fitting reusable item profiles.
See HAND_ITEM_SYSTEM.md for that workflow; the clean anatomy stays equipment-free.
Inspect Dressed Character.cmd preserves the previous dressed review.
Keys 1–7 show front, back, side,
three-quarter, head, hand and feet. Right-drag orbits, the wheel zooms, O
switches orthographic/perspective and P toggles the joint-inspection motion.
Orthographic front/back/side views are the baseline for proportion review.

Edit assets/characters/male_mannequin/source/male_mannequin.blend for anatomy.
The low cage retains face and joint topology under a subdivision modifier.
The neutral display groin keeps this an anatomy/fit mannequin. Rendered
previews are saved under reviews/mannequin/.

The old outfit is separated into eight editable assets under
assets/characters/wardrobe/. Each has a standalone Blender scene, GLB, and
Godot wrapper scene under scenes/characters/wardrobe/. The original dressed
character, face/hair work and playable game are preserved. The new anatomy
study stays free of equipment. Its playable derivative now replaces the dressed
player in gameplay and holds the flashlight with the same full-body skeleton.

Current wardrobe fitting still targets the previous dressed rig. After body
proportions are agreed, refit and refine the jacket, trousers, boots, gloves
and equipment individually. Do not treat the current clothing as already
fitted to this new body.

The continuous anatomical source uses MakeHuman core CC0 data already in the
project. See assets/characters/male_mannequin/CREDITS.md. Rebuild with Blender
4.5 using tools/build_male_mannequin.py. tools/separate_character_wardrobe.py
reproduces the independent clothing exports without overwriting the original.
