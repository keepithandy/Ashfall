shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Station 04 ground surface: the road and service yard are MATERIAL REGIONS,
// not raised platforms. All positions are in metres in the existing world.
// Geometry/collision stays flat at y=0 so the existing interiors and scripted
// spawn/interaction locations remain physically grounded.

uniform sampler2D forest_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D concrete_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform vec3 soil_tint : source_color = vec3(0.58, 0.59, 0.53);
uniform vec3 road_tint : source_color = vec3(0.47, 0.48, 0.45);
uniform vec3 shoulder_tint : source_color = vec3(0.34, 0.33, 0.29);
uniform float forest_tex_scale : hint_range(0.02, 1.0) = 0.23;
uniform float pavement_tex_scale : hint_range(0.02, 1.0) = 0.32;
uniform float worn_edges : hint_range(0.05, 2.5) = 0.90;

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

// Smooth, finite rectangles; these match the old visual mesh footprints.
float region_mask(vec2 p, vec2 centre, vec2 half_size, float feather) {
    vec2 d = abs(p - centre) - half_size;
    float signed_distance = length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
    return 1.0 - smoothstep(-feather, feather, signed_distance);
}

void fragment() {
    vec2 ground = terrain_world.xz;
    float broad = value_noise(ground * 0.071);
    float small = value_noise(ground * 0.74);
    float breakup = value_noise(ground * 0.23);

    vec3 forest = texture(forest_albedo, ground * forest_tex_scale).rgb * soil_tint;
    forest *= mix(0.82, 1.06, broad);
    forest *= mix(0.91, 1.04, small);

    // Dried, irregular gravel verges make the road look embedded in the soil.
    float verge = region_mask(ground, vec2(0.0, -7.0), vec2(4.5, 42.6), worn_edges);
    float yard_verge = region_mask(ground, vec2(25.0, -8.0), vec2(17.2, 15.8), 1.55);
    float verge_mask = max(verge, yard_verge);
    vec3 roadside = mix(forest, forest * shoulder_tint * 1.68, verge_mask * 0.68);

    float road = region_mask(ground, vec2(0.0, -7.0), vec2(2.60, 40.65), worn_edges * 0.7);
    float yard = region_mask(ground, vec2(25.0, -8.0), vec2(15.35, 13.75), 1.15);
    float road_mask = max(road, yard);

    vec3 compacted = texture(concrete_albedo, ground * pavement_tex_scale).rgb * road_tint;
    compacted *= mix(0.84, 1.13, breakup);
    // A faint wear track only inside the access road, never on the yard.
    float rut = 1.0 - smoothstep(0.20, 0.53, abs(abs(ground.x) - 1.08));
    compacted *= 1.0 - 0.12 * rut * road * (1.0 - yard);
    float irregular_edge = clamp(road_mask + (small - 0.5) * 0.12 * road_mask * (1.0 - road_mask), 0.0, 1.0);

    ALBEDO = clamp(mix(roadside, compacted, irregular_edge), vec3(0.0), vec3(1.0));
    ROUGHNESS = mix(0.98, 0.91, irregular_edge);
    SPECULAR = 0.21;
    METALLIC = 0.0;
}
