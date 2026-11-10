# Workshop prop extension

Eight new text-free scenes are saved in `scenes/workshop/`: discarded tyre, workbench with vise, wheelbarrow, steel ladder, fire extinguisher, open wooden crate, coiled hose, and metal chair. These original assets share the existing kit's wood, paint, metal, and rubber materials. They have metre-scale, bottom-centred origins and simplified static collision.

Open `scenes/workshop_gallery.tscn` and press F6 to browse them with the existing controls. Drag individual scenes from `scenes/workshop/` into a level. Gallery captions are separate from the assets. The crate has separate wall and floor collision; its interior is open. These are set dressing: the ladder cannot yet be climbed, the vise does not operate, and the extinguisher cannot yet be discharged.

`scenes/workshop_dressing.tscn` contains twelve new placements: a small workshop arrangement beside the containers, tyres in the yard, a wheelbarrow and stored ladder at the checkpoint, extinguishers, storage, and hoses near service areas. Grass excludes their footprints. The existing layout scenes, natural props, revised mossy boulder, and player controller were not rebuilt by this pass.

`workshop_prop_builder.gd` defines the new assets; `bake_workshop_props.gd` regenerates only these eight assets, their gallery, and their new placement group. Preserve any manual edits to these generated files before rebaking. `assets/workshop/catalog.json` records their scene paths and sizes. The existing 32-prop library and ten natural props remain in their original directories.

The review contact sheet is `reviews/workshop/prop-catalog.png`. Review renders use the actual engine. Validation includes scene loading, visual inspection, no attached world text, protected vegetation regions, and the original expedition smoke scenario. The player's source hash remained unchanged.

Workshop and wheelbarrow image searches informed the silhouettes, including tubular frames, hollow trays, thick bench tops, and visible vise hardware. Reference photographs were not incorporated as game textures. Material credits remain in `PROP_LIBRARY.md`.
