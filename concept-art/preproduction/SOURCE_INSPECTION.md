# Source inspection and credits

November 9, 2026. Thirteen Poly Haven packages acquired with editable Blender files and 1K review textures; 77 files verified against the upstream MD5 manifest. Preserve the originals. [Poly Haven CC0 license](https://polyhaven.com/license). Each folder retains upstream author and file metadata. These packages are staged under this folder's Godot exclusion, not integrated into gameplay.

| Asset | Author | Whole-package bounds X/Y/Z (m) | Mesh objects | Armatures / actions |
| --- | --- | --- | --- | --- |
| [Bolt Action Rifle 7.62](https://polyhaven.com/a/bolt_action_rifle_7_62) | Mateusz Sadek | 1.231 × 0.067 × 0.205 | 7 | 0 / 0 |
| [Cassette Player](https://polyhaven.com/a/cassette_player) | Oday Abuzaeed | 0.129 × 0.049 × 0.237 | 2 | 0 / 0 |
| [Chemistry Set](https://polyhaven.com/a/chemistry_set) | Jiří Ptáček | 1.078 × 0.354 × 0.429 | 50 | 0 / 0 |
| [Dining Table](https://polyhaven.com/a/dining_table) | Aron Łyczek | 2.256 × 1.390 × 0.877 | 2 | 0 / 0 |
| [Electric Stove](https://polyhaven.com/a/electric_stove) | Kuutti Siitonen | 1.097 × 1.097 × 0.859 | 23 | 1 / 0 |
| [Industrial Microscope](https://polyhaven.com/a/industrial_microscope) | Lukas Walzer | 0.215 × 0.498 × 0.462 | 2 | 0 / 0 |
| [Metal Office Desk](https://polyhaven.com/a/metal_office_desk) | Ulan Cabanilla | 2.000 × 0.947 × 0.788 | 9 | 0 / 0 |
| [Old Bed Frame](https://polyhaven.com/a/old_bed_frame) | Luca B | 0.905 × 2.002 × 1.201 | 1 | 0 / 0 |
| [Painted Wooden Cabinet](https://polyhaven.com/a/painted_wooden_cabinet) | Kirill Sannikov | 1.195 × 0.617 × 1.182 | 5 | 0 / 0 |
| [Painted Wooden Chair 01](https://polyhaven.com/a/painted_wooden_chair_01) | Kuutti Siitonen | 0.432 × 0.540 × 0.956 | 1 | 0 / 0 |
| [Retro Multimeter](https://polyhaven.com/a/retro_multimeter) | elli moeller | 0.216 × 0.203 × 0.279 | 20 | 0 / 20 |
| [Service Pistol](https://polyhaven.com/a/service_pistol) | Mateusz Sadek | 0.302 × 0.032 × 0.281 | 11 | 0 / 0 |
| [Small Wooden Table 01](https://polyhaven.com/a/small_wooden_table_01) | Ulan Cabanilla | 0.916 × 0.440 × 0.533 | 1 | 0 / 0 |

Bounds include all objects, alternative versions, open parts and accessories. They are not necessarily the size of one assembled object. Blender Z is vertical. Unit scale is 1 for these inspected files. A reported action count is not proof of useful gameplay animation.

## Inspection conclusions

- Small wooden table is only 0.533 m tall: select for a side-table role, not dining.
- Dining table mesh is about 2.047 × 1.152 × 0.791 m; the cloth makes package bounds larger. It suits a larger household.
- Cupboard height is 1.182 m: pantry storage, not the kitchen preparation counter.
- Stove body is about 0.50 × 0.61 × 0.859 m; open/separate parts enlarge package bounds. One rig exists, but no action clips were found.
- Bed frame is about 0.905 × 2.002 m, 1.201 m high. Check local mattress fit during later production.
- Chemistry set contains 50 mesh objects; select only the needed vessels/racks.
- Pistol includes variants and magazines; aggregate bounds are not a single pistol dimension. Both weapon packages have no armature/actions.
- Multimeter contains 20 actions; their purpose and export behavior have not been certified.

## Compatibility limits

All thirteen files opened in Blender 4.5.3. Several produced newer-file warnings (5.1 data), so this is a structural inspection with limitations, not compatibility certification. No original file was resaved. No missing referenced images were found. Pistol, rifle and dining-table source renders were produced and visually inspected; they use 1K review textures. Reopen newer-authored files in a compatible Blender version before final exports. No Godot import, collider, animation or performance acceptance is implied. See [raw results](sources/inspection.json) and [log](sources/inspection.log).

## Farmhouse sink

[Innerscene farmhouse sink](https://www.innerscene.com/tools/library/3d-parts/apron-sink-farmhouse-sink-d48bb2ce): source listing identifies an original CC0 GLB, with embedded PBR materials and approximately 0.789 × 0.529 × 0.294 m dimensions. The acquired GLB is preserved. No native Blender source was established. [Local provenance and structural checks](sources/farmhouse-sink/provenance.json) record its hash and contents. The source-advertised measurements are not a fresh world-transform measurement. It has not been visually rendered or Godot-imported in this pass.

## Research decisions for remaining custom details

The [Grab3D toilet](https://grab3d.com/models/furniture/toilet/) is explicitly a stylized kit asset; the [Kenney-derived sink](https://www.innerscene.com/tools/library/3d-parts/bathroom-sink-fd93773e) is flat low-poly. Neither was adopted as a quality replacement. Bathroom fixture concepts therefore remain conventional original-design briefs after research, with final source/model decisions open. No purchases were made.

Curtains, padding, labels and cable terminations are adaptations to the existing fabric, cases, paper and utility families, not newly acquired complete kits. Keep the source-vs-original distinction visible in production.

Existing local materials and character credits remain in their original credit files. The generated concept images are not evidence of rights to an external asset or of exact model appearance.
