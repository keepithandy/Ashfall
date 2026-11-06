# Checkpoint atmosphere and first natural dressing pass

The checkpoint now uses cold dusk light, longer shadows, restrained amber lamps, low road mist, and quieter environmental audio. The flashlight and interior lamp still reveal the architecture and props. This is an atmosphere pass; it does not add enemies or scripted jump scares.

## Changes

- `game.gd`: existing environment settings adjusted for cold dusk; volumetric fog enabled; lamp emissive surfaces reduced; two ambient drone frequencies create a slow beat. Prop annotations on the sample and extraction terminal have been removed. The medical cross is now geometry that hides with the medical supplies.
- `atmosphere.gd`: a low mist volume over the road, a subtle edge vignette, infrequent spatial creaks around empty buildings and the service yard, and two lamps with occasional smooth power dips. Lamp dips are slower than rapid flicker. Cue scheduling and lamp animation stop when the game is paused. Sound clips are generated in code and stay below a fixed peak limit.
- `nature_dressing.gd`: deterministic grass, low stones, and dry leaves. Grass is patchy and moves gently in wind. MultiMesh batches group grass in small spatial regions and limit draw distance. The expanded layout and current counts are documented in `NATURAL_LIBRARY.md`.

Grass, stones, and leaves exclude the road, building footprints, the puddle, containers, the house approach, extraction area, and placed prop footprints. They have no collision. The player controller is unchanged. The new natural kit adds shrubs, reeds, ferns, trees, and deadwood; terrain transitions and more detailed surface textures remain future art passes.

## Text policy

The default prop scenes are text-free so they are ready to place in the world. Only preview variants and gallery furniture show lettering. All fitted preview lettering is measured against its physical panel size; the warning sign uses four shorter lines. Building lettering has now also been removed. HUD objectives remain visible.

## Verification

Checks cover all 32 prop scenes, preview text fit, zero Label3D nodes in world props and the placed prop group, mesh/material validity, collision, open shelf gaps, grass exclusion zones, absence of foliage collision, paused atmosphere, audio sample bounds, and the original expedition loop. Rendering checks use the actual Vulkan renderer. Screenshots are in `reviews/`; the expanded prop catalog is in `reviews/props/`.

## References

- [Godot volumetric fog](https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html): fog and light interaction.
- [Godot MultiMesh](https://docs.godotengine.org/en/stable/classes/class_multimesh.html): instancing repeated meshes for grass and ground dressing.
- [Prop library guide](PROP_LIBRARY.md): asset reuse, original material sources, and rebuild instructions.
