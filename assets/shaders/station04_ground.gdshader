shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Station 04: physically grounded world-space soil / gravel / yard.
// Geometry and ground collision stay flat at y=0; DO NOT move authored objectives.
// Visual-only horizon relief is handled by station04_horizon.gd, outside the walls.
uniform sampler2D forest_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D forest_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D forest_roughness : filter_linear_mipmap, repeat_enable;
uniform sampler2D forest_ao : filter_linear_mipmap, repeat_enable;
uniform sampler2D concrete_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D concrete_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D concrete_roughness : filter_linear_mipmap, repeat_enable;
uniform sampler2D concrete_ao : filter_linear_mipmap, repeat_enable;

uniform vec3 soil_tint : source_color = vec3(0.65, 0.66, 0.59);
uniform vec3 road_tint : source_color = vec3(0.58, 0.58, 0.53);
uniform vec3 shoulder_tint : source_color = vec3(0.38, 0.36, 0.30);
uniform float forest_tex_scale : hint_range(0.02, 1.0) = 0.25;
uniform float pavement_tex_scale : hint_range(0.02, 1.0) = 0.34;
uniform float worn_edges : hint_range(0.15, 2.5) = 1.05;
uniform float normal_strength : hint_range(0.0, 1.5) = 0.62;
uniform float weather_wetness : hint_range(0.0, 1.0) = 0.20;
uniform float dirt_variation : hint_range(0.0, 0.5) = 0.16;
// Two-scale breakup avoids large uniform patches across the open yard.
uniform float patch_strength : hint_range(0.0, 0.5) = 0.12;
uniform float verge_grit : hint_range(0.0, 1.0) = 0.32;
uniform float foundation_weathering : hint_range(0.0, 0.5) = 0.18;

varying vec3 terrain_world;

void vertex() {
    terrain_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash21(vec2 p) {
    vec3 v = fract(vec3(p.xyx) * 0.1031);
    v += dot(v, v.yzx + 33.33);
    return fract((v.x + v.y) * v.z);
}

float value_noise(vec2 p) {
    vec2 c = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash21(c), hash21(c + vec2(1.0, 0.0)), f.x),
        mix(hash21(c + vec2(0.0, 1.0)), hash21(c + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

// Smooth signed-distance rectangle, exactly aligned to the legacy walkable road.
float region_mask(vec2 p, vec2 centre, vec2 half_size, float feather) {
    vec2 d = abs(p - centre) - half_size;
    float sd = length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
    return 1.0 - smoothstep(-feather, feather, sd);
}

void fragment() {
    vec2 ground = terrain_world.xz;
    vec2 soil_uv = ground * forest_tex_scale;
    vec2 road_uv = ground * pavement_tex_scale;
    float broad = value_noise(ground * 0.065);
    float fine = value_noise(ground * 0.68);
    float broken = value_noise(ground * 0.24);
    // Both edges of each track wander slightly; avoid straight, stamped rectangles.
    float edge_jitter = (fine - 0.5) * 0.42 + (broken - 0.5) * 0.55;
    vec2 irregular_ground = ground + vec2(edge_jitter, edge_jitter * 0.38);

    float shoulder = region_mask(irregular_ground, vec2(0.0, -7.0),
                                 vec2(4.55, 42.7), worn_edges * 1.45);
    float yard_shoulder = region_mask(irregular_ground, vec2(25.0, -8.0),
                                      vec2(17.3, 15.7), 2.0);
    float road = region_mask(irregular_ground, vec2(0.0, -7.0),
                             vec2(2.60, 40.65), worn_edges * 0.76);
    float yard = region_mask(irregular_ground, vec2(25.0, -8.0),
                             vec2(15.35, 13.75), 1.45);
    float compact_mask = clamp(max(road, yard), 0.0, 1.0);
    float shoulder_mask = max(shoulder, yard_shoulder);

    vec3 soil = texture(forest_albedo, soil_uv).rgb * soil_tint;
    soil *= 1.0 + dirt_variation * (broad * 2.0 - 1.0);
    soil *= mix(0.92, 1.06, fine);

    // Mud and fine grit collect around traffic, blending into undisturbed soil.
    vec3 verge = soil * shoulder_tint * 1.7;
    float verge_scatter = smoothstep(0.40, 0.75, fine) * shoulder_mask;
    soil = mix(soil, verge, shoulder_mask * 0.65);
    soil = mix(soil, soil * 0.72, verge_scatter * verge_grit);

    // Damp soil and tracked debris where existing house foundations meet
    // the flat ground; all coordinates match authored Station 04 house centres.
    // The ring is material-only: no moving foundations, doors, or collisions.
    float foundation = 0.0;
    foundation = max(foundation, region_mask(ground, vec2(-24.0, -2.0), vec2(4.6, 4.9), 1.8));
    foundation = max(foundation, region_mask(ground, vec2(-25.0, -29.0), vec2(4.6, 4.9), 1.8));
    foundation = max(foundation, region_mask(ground, vec2(-24.0, 44.0), vec2(4.15, 4.15), 1.8));
    foundation = max(foundation, region_mask(ground, vec2(0.0, 46.0), vec2(6.15, 3.65), 1.8));
    foundation = max(foundation, region_mask(ground, vec2(24.0, 44.0), vec2(4.65, 5.15), 1.8));
    soil *= 1.0 - foundation * foundation_weathering;
    vec3 compacted = texture(concrete_albedo, road_uv).rgb * road_tint;
    compacted *= mix(0.85, 1.13, broken);
    float patches = value_noise(ground * 0.105 + vec2(71.2, 9.7));
    compacted *= 1.0 - patch_strength * smoothstep(0.52, 0.78, patches);

    // Two subtle compacted wheel tracks; not a sharp painted pair of stripes.
    float tire_wander = (value_noise(vec2(ground.z * 0.12, 8.0)) - 0.5) * 0.26;
    float tire_pair = 1.0 - smoothstep(0.16, 0.45, abs(abs(ground.x + tire_wander) - 1.06));
    tire_pair *= road * (1.0 - yard);
    compacted *= 1.0 - tire_pair * 0.12;

    // Localized damp patches, with no fake raised water plane or collision.
    float damp_noise = value_noise(ground * 0.15 + vec2(13.3, -9.2));
    float damp = smoothstep(0.53, 0.79, damp_noise);
    damp *= weather_wetness * (0.7 + shoulder_mask * 0.3);
    vec3 color = mix(soil, compacted, compact_mask);
    color *= 1.0 - damp * 0.28;
    ALBEDO = clamp(color, vec3(0.0), vec3(1.0));

    // PBR normal, AO and roughness maps are existing, licensed project textures.
    vec3 soil_n = texture(forest_normal, soil_uv).rgb;
    vec3 compact_n = texture(concrete_normal, road_uv).rgb;
    NORMAL_MAP = mix(soil_n, compact_n, compact_mask);
    NORMAL_MAP_DEPTH = normal_strength;
    float soil_r = texture(forest_roughness, soil_uv).r;
    float road_r = texture(concrete_roughness, road_uv).r;
    ROUGHNESS = clamp(mix(soil_r, road_r, compact_mask) * (1.0 - damp * 0.40), 0.42, 1.0);
    AO = mix(texture(forest_ao, soil_uv).r, texture(concrete_ao, road_uv).r, compact_mask);
    SPECULAR = 0.22;
    METALLIC = 0.0;
}
