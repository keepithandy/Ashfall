shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Crossroads 2.3: continuous textured village soil and surrounding fields.
// World-space mapping preserves scale over both 2m village triangles and
// larger outer-field triangles. Purely visual: no terrain height changes.
// Texture maps are already bundled, CC0 licensed Poly Haven 2K materials.
uniform sampler2D forest_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D forest_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D forest_roughness : filter_linear_mipmap, repeat_enable;
uniform sampler2D concrete_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D concrete_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D concrete_roughness : filter_linear_mipmap, repeat_enable;

uniform vec3 dry_soil_tint : source_color = vec3(0.62, 0.59, 0.51);
uniform vec3 roadside_mud_tint : source_color = vec3(0.50, 0.46, 0.39);
uniform vec3 dead_grass_tint : source_color = vec3(0.55, 0.64, 0.51);
uniform float soil_tile_scale : hint_range(0.03, 1.0) = 0.33;
uniform float grit_tile_scale : hint_range(0.03, 1.0) = 0.27;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.58;
uniform float wetness : hint_range(0.0, 1.0) = 0.20;

varying vec3 world_location;

void vertex() {
    world_location = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float ground_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float ground_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(ground_hash(cell), ground_hash(cell + vec2(1.0, 0.0)), f.x),
        mix(ground_hash(cell + vec2(0.0, 1.0)), ground_hash(cell + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

void fragment() {
    vec2 ground = world_location.xz;
    vec2 soil_uv = ground * soil_tile_scale;
    vec2 grit_uv = (ground + vec2(15.7, -11.3)) * grit_tile_scale;

    float broad = ground_noise(ground * 0.035 + vec2(24.3, 7.5));
    float local = ground_noise(ground * 0.17);
    float speckle = ground_noise(ground * 0.82 + vec2(9.0, 21.0));
    float patch = clamp(broad * 0.68 + local * 0.32, 0.0, 1.0);
    float vegetation = smoothstep(0.37, 0.67, patch);
    float roadside_axis = sin(ground.y * 0.015) * 2.8;
    float near_road = 1.0 - smoothstep(4.0, 14.0, abs(ground.x - roadside_axis));
    vegetation *= (1.0 - near_road * 0.62);

    vec3 forest = texture(forest_albedo, soil_uv).rgb;
    vec3 compacted = texture(concrete_albedo, grit_uv).rgb;
    // All variants have an earthy PBR color even where one imported texture
    // fails to resolve. The broad patch noise keeps areas from turning gray.
    vec3 earth = mix(forest * dry_soil_tint,
                     forest * dead_grass_tint, vegetation);
    vec3 mud = mix(compacted * roadside_mud_tint,
                   forest * dry_soil_tint * 0.79, 0.48);
    float gritty = clamp(near_road * 0.55 + (1.0 - vegetation) * 0.19, 0.0, 0.72);
    vec3 color = mix(earth, mud, gritty);
    color *= mix(0.88, 1.07, speckle);
    float damp = wetness * smoothstep(0.55, 0.78, local);
    color *= 1.0 - damp * 0.27;

    ALBEDO = clamp(color, vec3(0.045), vec3(0.78));
    NORMAL_MAP = mix(texture(forest_normal, soil_uv).rgb,
                     texture(concrete_normal, grit_uv).rgb, gritty);
    NORMAL_MAP_DEPTH = normal_strength;
    ROUGHNESS = clamp(mix(texture(forest_roughness, soil_uv).r,
                          texture(concrete_roughness, grit_uv).r, gritty) *
                      (1.0 - damp * 0.25), 0.58, 1.0);
    METALLIC = 0.0;
    SPECULAR = 0.19;
}
