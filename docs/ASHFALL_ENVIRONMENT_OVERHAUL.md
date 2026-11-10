# Station 04 — Cloud Sky and House Weathering (Review Build)

**Status:** Implemented on a feature branch; **not yet verified in the Godot editor or merged into `main`**.

## Scope

Station 04's existing `WorldEnvironment` now uses a sky `ShaderMaterial` backed by
`assets/shaders/ashfall_overcast_clouds.gdshader`. It **retains existing fog,
volumetric fog, sunlight, terrain, atmosphere, and gameplay code**.

All five existing Station 04 houses have an additive `ArchitecturalWeathering`
child powered by `scripts/authoring/house_weathering.gd`:

| House scene | New finishing details |
| --- | --- |
| `green_longhouse.tscn` | Broken-up timber fascia, roof gutters, corroded supports, downpipe and siding repair |
| `ochre_workers_house.tscn` | Rusted gutters, metal hangers, conduit, repaired plaster and repair seams |
| `white_garden_house.tscn` | Weathered fascia, rain gutters, gutter hooks, downpipe and elbow |
| `blue_porch_cottage.tscn` | Porch drip edge, replacement boards and metal repair straps |
| `cottage_detail.tscn` | Gutter repair bands, drainpipe and timber end-wall repairs |

New finish geometry is non-colliding and is generated at scene load. It is designed
as an *additional* architectural layer, not a destructive replacement for existing
authored house geometry, materials, openings, or physics. It is previewable in the
editor through the `@tool` script. Generated meshes have no `owner` assigned:
they are intentionally not saved into the PackedScene when editing.

## Sky architecture

The shader draws **two drifting cloud formations** with layered, smooth procedural
noise. Coverage, cloud-edge softness, frequency, wind direction, motion speed,
cloud detail and palette are adjustable from the sky `ShaderMaterial`.

- Cloud computations run in Godot's **half-resolution sky subpass** to reduce GPU cost.
- The full-resolution pass composites the clouds over a low-contrast
  horizon-to-zenith gradient; sun-facing edges get restrained highlighting.
- The environment's radiance/reflection cubemap uses a simplified overcast tint,
  not an expensive per-pixel cloud calculation on all six cube faces.
- The `Sky` is set to **Realtime** process mode and **256 px radiance**, because
  sky shaders using `TIME` can update the radiance cubemap every frame.
- Ground-level fog remains enabled, but its sky contribution has been deliberately
  reduced (`fog_sky_affect = 0.10`, `volumetric_fog_sky_affect = 0.12`) so
  distant overcast banks are legible while the ground stays threatening.

**Important limitation:** This is an atmospheric **procedural sky shader**, not
physically simulated 3D cloud volumes. It does not yet cast cloud shadows onto
buildings, dynamically change weather, generate rain, or synchronize its sky
luminance with the sun light energy. Those would require further, tested rendering
and weather-controller work.

### Tuning

Open `scenes/ashfall_station_main.tscn`, select the `WorldEnvironment`, then
expand `Environment > Sky > Sky Material > Shader Parameters`. Notable parameters:

| Parameter | Default | Meaning |
| --- | --- | --- |
| `cloud_coverage` | 0.63 | More coverage means more continuous overcast |
| `cloud_softness` | 0.095 | How diffuse the cloud boundaries are |
| `cloud_scale` | 2.15 | Apparent frequency of cloud formations |
| `cloud_detail` | 0.76 | High-frequency variation |
| `cloud_speed` | 0.065 | Animation speed in shader time |
| `wind_direction` | (0.93, 0.36) | Horizontal sky-plane wind direction |
| `sun_glow_strength` | 0.16 | Brightness around the directional sun |

To assess performance, compare the main scene against `main` under equal
resolution, camera position and GPU conditions. Keep the most fog-heavy viewpoints
in the comparison to ensure clouds are actually visible.


### Visibility and motion correction

Following the first on-device test, the initial clouds were reported **too faint
and apparently stationary**. This branch now:

- Reduces *both* non-volumetric and volumetric fog's influence on sky rendering,
  rather than reducing actual fog density around the buildings.
- Increases cloud-to-sky contrast and changes coverage thresholds so there are
  open-sky gaps and discernible cloud-bank edges, not a uniform gray ceiling.
- Changes drift from `0.005` to `0.065` shader-space units per second (13×),
  with the wispy secondary deck moving at a different speed and direction.
- Leaves `TIME` inside the sky shader, so movement advances continuously without
  adding a gameplay timer or script-side uniform updates.

**Animation test:** look about 45 degrees upward, keep the camera stationary for
15–20 seconds and watch a cloud edge against the darker sky gap. Then inspect
around the horizon. If the sky still appears completely uniform or still, check
Godot's shader compiler/output log and confirm `cloud_speed` in the active sky
material is not overridden to `0.005` or `0.0`. Restart the scene after pulling.

## Required validation (in Godot)

1. Open the project with Godot **4.7.2**, preferably in Forward+ mode. Let imports finish.
2. Check the Editor **Output** and **Debugger** tabs for `ERROR` messages,
   especially GDScript/shader compile failures and missing textures.
3. Open `scenes/ashfall_station_main.tscn` and verify the moving clouds
   are visible when looking up, including while clouds cross the sun.
4. Walk through the green longhouse, ochre workers house, white garden house,
   blue porch cottage and northern cottage: every doorway should remain usable,
   with no new invisible collision and no badly floating decorative parts.
5. Test at least 60 seconds of movement, a scene restart and a pause/resume.
   Confirm fog, sun shadowing, inventory, pickups, and objectives still work.
6. Check framerate and GPU usage while facing clear sky, buildings and fog.
   Record screenshots of all five houses from the exterior and of the cloud layer.
7. Optional source-loading smoke test in PowerShell (Godot executable location may
   differ on each PC):

   ```powershell
   & "..\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script "res://tests/check_environment_overhaul.gd"
   ```

**Do not merge until visual and performance checks pass.** If anything loads incorrectly,
switch back to `main` to restore the original scenes.

## Rollback

The original current playable build is preserved on `main`. This branch can
be reviewed or discarded without changing the established game.
