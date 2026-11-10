shader_type sky;

uniform vec3 horizon_color : source_color = vec3(0.26, 0.30, 0.31);
uniform vec3 zenith_color : source_color = vec3(0.065, 0.095, 0.12);
uniform vec3 lower_cloud_color : source_color = vec3(0.16, 0.19, 0.20);
uniform vec3 upper_cloud_color : source_color = vec3(0.47, 0.50, 0.49);
uniform vec3 sun_glow_color : source_color = vec3(0.65, 0.67, 0.60);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.70;
uniform float cloud_softness : hint_range(0.05, 0.7) = 0.27;
uniform float cloud_scale : hint_range(0.5, 6.0) = 2.2;
uniform float cloud_detail : hint_range(0.1, 2.0) = 0.85;
uniform float cloud_speed : hint_range(0.0, 0.1) = 0.005;
uniform vec2 wind_direction = vec2(0.93, 0.36);
uniform float sun_glow_strength : hint_range(0.0, 1.0) = 0.18;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise2d(vec2 p) {
    vec2 cell = floor(p);
    vec2 local_pos = fract(p);
    vec2 fade = local_pos * local_pos * (3.0 - 2.0 * local_pos);
    return mix(
        mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), fade.x),
        mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0, 1.0)), fade.x),
        fade.y
    );
}

float cloud_fbm(vec2 p) {
    float sum = 0.0;
    float amplitude = 0.52;
    mat2 rotation = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
    for (int i = 0; i < 5; i++) {
        sum += amplitude * noise2d(p);
        p = rotation * p * 2.02 + vec2(4.8, 1.3);
        amplitude *= 0.49;
    }
    return sum;
}

void sky() {
    vec3 direction = normalize(EYEDIR);
    float altitude = max(direction.y, 0.0);
    float horizon = pow(1.0 - altitude, 2.2);
    vec3 color = mix(zenith_color, horizon_color, horizon);

    // Two windswept cloud decks: distinct altitude, scale, and motion.
    // Angular projection prevents cloud shapes stretching at the horizon.
    vec2 plane = direction.xz / max(direction.y + 0.17, 0.23);
    vec2 wind = normalize(wind_direction + vec2(0.0001)) * TIME * cloud_speed;
    vec2 p = plane * cloud_scale + wind;
    float main_noise = cloud_fbm(p);
    float fine_noise = cloud_fbm(p * 2.8 + vec2(13.1, 4.7) - wind * 0.55);
    float banks = main_noise * 0.86 + fine_noise * 0.14 * cloud_detail;
    float threshold = mix(0.67, 0.28, cloud_coverage);
    float bank = smoothstep(threshold - cloud_softness, threshold + cloud_softness, banks);
    float distant_deck = cloud_fbm(plane * (cloud_scale * 0.55) - wind * 0.62 + vec2(48.0, 17.0));
    float veil = smoothstep(0.32, 0.72, distant_deck) * cloud_coverage * 0.43;
    float cloud = max(bank, veil) * smoothstep(-0.04, 0.12, direction.y);
    float light_variation = clamp(bank * 0.57 + main_noise * 0.5 + altitude * 0.1, 0.0, 1.0);
    vec3 cloud_tint = mix(lower_cloud_color, upper_cloud_color, light_variation);

    // Brightening is restrained: most of Station 04 should remain overcast.
    if (!AT_CUBEMAP_PASS) {
        float sun_alignment = max(dot(direction, LIGHT0_DIRECTION), 0.0);
        float glow = pow(sun_alignment, 18.0) * sun_glow_strength;
        cloud_tint += sun_glow_color * glow * 0.22;
        color += sun_glow_color * glow * (1.0 - cloud) * 0.18;
    }

    COLOR = mix(color, cloud_tint, clamp(cloud, 0.0, 1.0));
}
