# Station 04 environment — third pass: distant vegetation silhouettes

The station's square collision perimeter still defines the accessible map. A deterministic pair of low-poly MultiMesh layers creates 128 distant conifer silhouettes outside the perimeter. Trunks and crowns are separate meshes with low radial segment counts, no shadows, and no collision. The layer is optional via `DistantTreeLine.show_tree_line`.

This pass does not alter the player, missions, navigation, world height, procedural ground shader, roads, or the separate regional preview. It adds a scene reference and automated procedural batch-instantiation checks to `tests/check_station_grounding.gd`. Its purpose is to reduce the abrupt empty horizon visible beyond the station wall, not to claim a final forest asset pass.

Before merging, open the real Station 04 scene in Godot 4.7.2 Forward+, inspect silhouettes against the existing fog and distant relief, and measure frame times with the layer on and off. Adjust average_height and tree_count only after inspecting the real render. Check for obvious geometric repetition and ensure the skyline does not look like a solid ring. Existing PR #4 art-quality gates and PR #6 heightfield checks remain independently outstanding.
