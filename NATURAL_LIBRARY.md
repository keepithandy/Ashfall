# Natural prop library and perimeter decoration

Ten reusable scenes are available under `scenes/nature/`: fern clump, dry bramble, reed clump, mossy boulder, fallen log, tree stump, dead branch pile, forest pine, bare tree, and low shrub. They use metre scale, bottom-centred origins, original geometry, and no attached text.

Open `scenes/natural_gallery.tscn` and press F6 to browse them. The gallery uses the existing player controls. Its two trees are displayed at 24% size; the reusable tree scenes retain their full scale. Drag scenes from `scenes/nature/` into a level to place them normally. The existing industrial kit remains in `scenes/props/`.

## Whole-level placement

- `scenes/natural_landmarks.tscn`: 234 placed natural instances, including the forest beyond the wall. The original cone trees have been replaced with branched pine and bare-tree geometry. Natural clusters appear around the perimeter, near the research area, and around the water's edge.
- `scenes/perimeter_dressing.tscn`: 33 additional equipment and debris instances spread through the research service area, container yard, tower service enclosure, opposite checkpoint hut exterior, and boundary corners.
- `scenes/checkpoint_props.tscn`: the existing checkpoint prop group remains separate and editable.
- `nature_dressing.gd`: grass and small ground dressing now exclude footprints from all three groups. The current layout has 3,903 grass clumps, 110 low stones, and 420 loose leaves. These counts change if the fixed layout or seed changes.

Ferns and shrubs have light wind movement. Reeds sit at the puddle margins. Logs, stumps, large boulders, and tree trunks have simplified static collision; small foliage and branch litter do not. Natural meshes are merged by material into one to three mesh nodes per asset, keeping repeated tree and foliage instances relatively inexpensive. These are initial art assets; the surrounding architecture and terrain still include blockout geometry.

## Building lettering

The house's two lettering nodes were removed directly from its existing saved scene, preserving its architecture and other edits. Their creation calls were also removed from `house_builder.gd`. Runtime lettering on the entry arch and research station was removed from `game.gd`. The running game now has zero Label3D nodes. HUD objectives and menus still work normally. Prop-gallery captions and preview lettering remain confined to the galleries.

## Rebuild

`natural_prop_builder.gd` defines geometry and materials. `bake_natural_props.gd` generates the ten natural scenes, material manifest, landscaping group, service-yard group, and natural gallery. Running the baker replaces its generated scenes, so preserve any manual edits before rebuilding. Existing natural materials are retained unless `--refresh-natural-materials` is explicitly passed after the argument separator.

```text
--headless --path . --script res://bake_natural_props.gd
--path . res://scenes/natural_gallery.tscn -- --prop-review
--path . -- --house-review
--path . -- --smoke-test
```

Review captures include the checkpoint house, research approach, container service yard, wetland edge, and water tower under `reviews/`. The ten-asset contact sheet is in `reviews/nature/prop-catalog.png`.

## Visual references

[Cairngorms Connect's woodland restoration photographs](https://cairngormsconnect.org.uk/news/1/37/Deadwood-Beetle-Monitoring-with-Cairngorms-Connect) and [Skogforsk's conservation forestry photographs](https://www.skogforsk.se/kunskapsbanken/kunskapsartiklar/2023/skordarens-prestation-i-ns-huggningar-i-manga-fall-likvardig-eller-hogre-an-i-gallring/) informed the grouping of deadwood, trunks, and understory. They are study references only; their photographs are not used as game textures. Existing material sources remain documented in `HOUSE_NOTES.md` and `PROP_LIBRARY.md`.
