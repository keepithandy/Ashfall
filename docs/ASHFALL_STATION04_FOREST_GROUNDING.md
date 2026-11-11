# Station 04 — Terrain-aligned distant woodland

The distant conifer layer now samples the same deterministic horizon height profile as the visual-only relief mesh, instead of positioning every tree at the original flat terrain's y=0. This aims to prevent floating trunks and deeply buried conifers around the hill silhouettes.

HorizonRelief exposes its shared FastNoiseLite configuration for deterministic sampling, while DistantTreeLine uses that source for each trunk's root position. Draw bounds are supplied for the two MultiMesh batches to avoid unexpected disappearance during camera pans. Existing ground collision, original vegetation, areas, interactions, navigation and authored house placements are unchanged.

The headless Station 04 grounding test now checks that the shared profile returns finite elevations and that tree geometry is instantiated. Visual acceptance still requires actual Godot Forward+ captures from the east, west, and station gate, checking that trees sit naturally on hills and do not create a repetitive geometric ring. Performance and real walkthrough checks remain open.
