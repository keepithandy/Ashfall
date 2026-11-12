shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Crossroads harvest parcels. A restrained world-mapped treatment of
// existing CC0 forest-floor imagery, with static soil/stubble traces.
// Reuses the existing texture; no external assets or procedural gameplay.
uniform sampler2D soil_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform int plot_type : hint_range(0, 2) = 0;
uniform float furrow_angle : hint_range(-3.14, 3.14) = 0.24;

varying vec3 world_position;

float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f *= f * (3.0 - 2.0 * f);
    vec2 a = fract(sin(vec2(dot(i, vec2(127.1, 311.7)), dot(i, vec2(269.5, 183.3)))) * 43758.5453);
    vec2 b = fract(sin(vec2(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7)), dot(i + vec2(0.0, 1.0), vec2(269.5, 183.3)))) * 43758.5453);
    return mix(mix(a.x, b.x, f.x), mix(b.y, a.y, f.x), f.y);
}

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 uv = world_position.xz * 0.29;
    vec3 photographic_soil = texture(soil_albedo, uv).rgb;

    vec2 row_axis = vec2(cos(furrow_angle), sin(furrow_angle));
    float furrow = sin(dot(world_position.xz, row_axis) * 3.2);
    float sparse_stalk = noise2(world_position.xz * 0.91);
    float broad = noise2(world_position.xz * 0.035 + vec2(71.3, 18.7));
    float rill = (furrow + 1.0) * 0.5;
    vec3 tint = vec3(0.46, 0.40, 0.34);
    float rows_amount = 0.09;
    if (plot_type == 1) {
        // Weathered cut-stubble: understated straw rather than yellow grass.
        tint = vec3(0.55, 0.53, 0.44);
        rows_amount = 0.075;
    } else if (plot_type == 2) {
        // Fallow field that has begun to green at the edges.
        tint = vec3(0.44, 0.48, 0.40);
        rows_amount = 0.038;
    }
    float variation = mix(0.87, 1.10, broad) *
                      mix(0.94, 1.035, sparse_stalk) *
                      mix(1.0 - rows_amount, 1.0 + rows_amount, rill);
    ALBEDO = clamp(photographic_soil * tint * variation, vec3(0.045), vec3(0.72));
    ROUGHNESS = 0.97;
    METALLIC = 0.0;
    SPECULAR = 0.16;
}
