shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Ashfall regional terrain — multi-surface weathered soil, moss and stone.
// Procedural visual terrain is paired with the SAME physical triangle mesh.

uniform sampler2D forest_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 lowland_tint : source_color = vec3(0.48, 0.51, 0.43);
uniform vec3 mountain_tint : source_color = vec3(0.57, 0.55, 0.50);
uniform vec3 marsh_tint : source_color = vec3(0.32, 0.38, 0.33);
uniform float forest_scale : hint_range(0.01, 0.5) = 0.12;
uniform float rock_scale : hint_range(0.01, 0.5) = 0.095;
uniform float rock_elevation : hint_range(10.0, 90.0) = 32.0;
uniform float rock_slope : hint_range(0.1, 0.9) = 0.55;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
    vec3 normal = normalize(world_normal);
    float steep = 1.0 - clamp(normal.y, 0.0, 1.0);
    float altitude = smoothstep(rock_elevation - 12.0, rock_elevation + 22.0, world_position.y);
    float exposed = smoothstep(rock_slope * 0.45, rock_slope, steep);
    float rocky = clamp(max(altitude * 0.72, exposed), 0.0, 1.0);

    vec3 forest = texture(forest_albedo, world_position.xz * forest_scale).rgb * lowland_tint;
    vec3 rock = texture(rock_albedo, world_position.xz * rock_scale).rgb * mountain_tint;
    float wetland = 1.0 - smoothstep(-3.0, 6.0, world_position.y);
    forest = mix(forest, forest * marsh_tint * 1.8, wetland * 0.6);

    ALBEDO = mix(forest, rock, rocky);
    ROUGHNESS = mix(0.98, 0.88, rocky);
    SPECULAR = 0.21;
}
