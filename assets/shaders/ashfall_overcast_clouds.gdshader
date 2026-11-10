shader_type sky;
render_mode disable_fog;

// Ashfall Station 04 — visible, wind-driven layered overcast.
// The cloud shape is evaluated in the background pass instead of sampling
// a half-resolution intermediate texture. This deliberately prioritizes
// clear visual verification over the earlier subpass optimization.
//
// Fog is disabled FOR THE SKY ONLY. Existing ground / volumetric fog
// continues to render over the world without washing out cloud edges.

uniform vec3 high_sky_color : source_color = vec3(0.058, 0.084, 0.103);
uniform vec3 horizon_sky_color : source_color = vec3(0.23, 0.26, 0.27);
uniform vec3 cloud_shadow_color : source_color = vec3(0.17, 0.19, 0.20);
uniform vec3 cloud_light_color : source_color = vec3(0.72, 0.73, 0.69);
uniform vec3 cloud_silver_color : source_color = vec3(0.78, 0.76, 0.67);

// These are authoring controls, also inspectable on Station 04's sky material.
uniform float coverage : hint_range(0.0, 1.0) = 0.59;
uniform float edge_softness : hint_range(0.02, 0.25) = 0.077;
uniform float cloud_scale : hint_range(0.3, 5.0) = 1.42;
uniform float cloud_contrast : hint_range(0.5, 3.0) = 1.65;
// Darken cloud banks without crushing the blue-black gaps between them.
uniform float cloud_darkening : hint_range(0.0, 0.5) = 0.18;
uniform float wind_speed : hint_range(0.0, 0.25) = 0.075;
uniform vec2 wind_direction = vec2(0.84, 0.54);
uniform float high_layer_strength : hint_range(0.0, 0.8) = 0.30;
// Set 1 for high-contrast white-cloud diagnostics; 2 for motion stripes.
uniform int diagnostic_mode : hint_range(0, 2) = 0;

float hash_grid(vec2 p) {
    vec3 q = fract(vec3(p.x, p.y, p.x) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float noise_grid(vec2 p) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    local = local * local * (3.0 - 2.0 * local);
    float a = hash_grid(cell);
    float b = hash_grid(cell + vec2(1.0, 0.0));
    float c = hash_grid(cell + vec2(0.0, 1.0));
    float d = hash_grid(cell + vec2(1.0, 1.0));
    return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float layered_noise(vec2 p) {
    float result = 0.0;
    float weight = 0.53;
    // A rotation between octaves reduces repetitive square grid artifacts.
    mat2 rotation = mat2(vec2(0.82, 0.57), vec2(-0.57, 0.82));
    for (int i = 0; i < 4; i++) {
        result += weight * noise_grid(p);
        p = rotation * p * 2.12 + vec2(4.91, 3.73);
        weight *= 0.47;
    }
    return result;
}

float smaller_noise(vec2 p) {
    float result = 0.0;
    float weight = 0.56;
    for (int i = 0; i < 3; i++) {
        result += weight * noise_grid(p);
        p = p * 2.15 + vec2(8.14, 4.21);
        weight *= 0.45;
    }
    return result;
}

vec3 background_sky(vec3 direction) {
    float above = clamp(direction.y, 0.0, 1.0);
    float horizon = pow(1.0 - above, 1.7);
    vec3 sky = mix(high_sky_color, horizon_sky_color, horizon);
    // Haze on the horizon is authored here so disabling sky fog doesn't
    // leave a hard color discontinuity against the foggy terrain.
    return mix(vec3(0.19, 0.22, 0.225), sky, smoothstep(-0.08, 0.18, direction.y));
}

void sky() {
    vec3 direction = normalize(EYEDIR);
    vec3 sky_base = background_sky(direction);

    if (AT_CUBEMAP_PASS) {
        // Constant broad overcast radiance instead of a full dynamic cloud
        // evaluation in every cubemap face. Visible clouds move independently.
        float height_mask = smoothstep(-0.05, 0.38, direction.y);
        COLOR = mix(sky_base, mix(cloud_shadow_color, cloud_light_color, 0.40),
                    coverage * height_mask * 0.62);
    } else {
        // Camera-relative direction-based projection anchors clouds to the
        // sky dome. Their translation uses TIME (seconds), not frame count.
        vec2 plane = direction.xz / max(direction.y + 0.24, 0.29);
        vec2 wind = normalize(wind_direction + vec2(0.0001)) * TIME * wind_speed;
        vec2 uv = plane * cloud_scale;

        // Low deck uses two frequencies, with domain displacement for
        // irregular banks rather than uniformly blurred monochrome noise.
        float warp = smaller_noise(uv * 0.56 + wind * 0.37 + vec2(3.7, 6.8));
        vec2 warped_uv = uv + vec2(warp - 0.5, 0.5 - warp) * 1.20;
        float broad = layered_noise(warped_uv * 0.56 - wind);
        float broken = smaller_noise(warped_uv * 1.56 - wind * 1.34 + vec2(20.2, 3.7));
        float density = broad * 0.76 + broken * 0.24;

        float threshold = mix(0.70, 0.39, coverage);
        float opacity = smoothstep(threshold - edge_softness,
                                   threshold + edge_softness, density);
        opacity = clamp((opacity - 0.5) * cloud_contrast + 0.5, 0.0, 1.0);

        // Higher and finer clouds move independently so static camera views
        // still show parallax-like change over a few seconds.
        float high_noise = layered_noise(uv * 0.39 + wind * 0.61 + vec2(11.3, 32.2));
        float upper = smoothstep(0.53, 0.71, high_noise) * high_layer_strength;
        float cloud_alpha = max(opacity, upper);
        float altitude_fade = smoothstep(-0.035, 0.095, direction.y);
        cloud_alpha *= altitude_fade;

        // Different density zones are lit differently: hard dark underbellies,
        // cool gray faces and restrained silver edges for an industrial sky.
        float brightness = clamp(0.13 + 0.83 * broad + 0.18 * broken, 0.0, 1.0);
        brightness = smoothstep(0.34, 0.79, brightness);
        vec3 cloud_color = mix(cloud_shadow_color, cloud_light_color, brightness);
        float edge = clamp(opacity * (1.0 - opacity) * 4.0, 0.0, 1.0);
        if (LIGHT0_ENABLED) {
            float facing_sun = max(dot(direction, LIGHT0_DIRECTION), 0.0);
            cloud_color += cloud_silver_color * pow(facing_sun, 18.0) * edge * 0.10;
        }

        // Apply after the restrained sun rim so the whole cloud bank stays
        // moody, while open-sky contrast and animation remain unchanged.
        cloud_color *= 1.0 - cloud_darkening;
        vec3 final_color = mix(sky_base, cloud_color, cloud_alpha);

        if (diagnostic_mode == 1) {
            // If the shader works, this shows bright white moving banks
            // against blue-black openings, independent of the lighting palette.
            final_color = mix(vec3(0.025, 0.06, 0.15),
                              vec3(0.95, 0.95, 0.95), cloud_alpha);
        } else if (diagnostic_mode == 2) {
            // A full-frame moving signal to distinguish shader animation
            // failure from cloud-contrast or weather-design issues.
            float travel = fract(uv.x * 0.22 + TIME * wind_speed);
            float stripe = smoothstep(0.38, 0.42, travel)
                         * (1.0 - smoothstep(0.58, 0.62, travel));
            final_color = mix(vec3(0.04, 0.04, 0.10),
                              vec3(0.95, 0.15, 0.75), stripe);
        }
        COLOR = final_color;
    }
}
