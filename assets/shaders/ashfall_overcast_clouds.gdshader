shader_type sky;
render_mode use_half_res_pass;

// Station 04 - procedurally animated, overcast cloud banks.
// Cloud detail runs at half screen resolution. Ambient radiance uses a cheaper
// approximation so the dynamic cloud cover does not dominate the frame budget.
uniform vec3 horizon_color : source_color = vec3(0.24, 0.27, 0.29);
uniform vec3 zenith_color : source_color = vec3(0.049, 0.073, 0.089);
uniform vec3 undercloud_color : source_color = vec3(0.19, 0.22, 0.23);
uniform vec3 sunlit_cloud_color : source_color = vec3(0.64, 0.66, 0.63);
uniform vec3 sun_glow_color : source_color = vec3(0.64, 0.65, 0.59);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.63;
uniform float cloud_softness : hint_range(0.05, 0.7) = 0.095;
uniform float cloud_scale : hint_range(0.5, 6.0) = 2.15;
uniform float cloud_detail : hint_range(0.0, 2.0) = 0.76;
uniform float cloud_speed : hint_range(0.0, 0.1) = 0.005;
uniform vec2 wind_direction = vec2(0.93, 0.36);
uniform float sun_glow_strength : hint_range(0.0, 1.0) = 0.16;

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float smooth_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float sum = 0.0;
    float weight = 0.52;
    mat2 rotate2d = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
    for (int layer = 0; layer < 5; layer++) {
        sum += smooth_noise(p) * weight;
        p = rotate2d * p * 2.03 + vec2(3.91, 1.37);
        weight *= 0.49;
    }
    return sum;
}

vec3 atmosphere(vec3 dir) {
    float above = clamp(dir.y, 0.0, 1.0);
    float horizon = pow(1.0 - above, 2.1);
    vec3 sky_tint = mix(zenith_color, horizon_color, horizon);
    return mix(vec3(0.12, 0.15, 0.15), sky_tint, smoothstep(-0.12, 0.08, dir.y));
}

vec4 cloud_banks(vec3 dir) {
    if (dir.y < -0.07) {
        return vec4(undercloud_color, 0.0);
    }

    // Project two cloud decks from the hemisphere to an overhead wind plane.
    vec2 plane = dir.xz / max(dir.y + 0.20, 0.25);
    vec2 wind = normalize(wind_direction + vec2(0.0001)) * TIME * cloud_speed;
    vec2 uv = plane * cloud_scale;
    float primary = fbm(uv + wind);
    float wisps = fbm(uv * 2.72 - wind * 0.55 + vec2(15.2, 9.7));
    float distant = fbm(uv * 0.61 + wind * 0.34 + vec2(37.6, 15.9));

    float density = primary * 0.88 + wisps * 0.12 * cloud_detail;
    // Keep breakup between cloud banks even in stormy conditions.
    // Earlier low cutoff made nearly the entire sky opaque, with no edges.
    float cutoff = mix(0.78, 0.44, cloud_coverage);
    float main_bank = smoothstep(cutoff - cloud_softness, cutoff + cloud_softness, density);
    float high_veil = smoothstep(0.40, 0.77, distant) * cloud_coverage * 0.28;
    float cloud_alpha = max(main_bank, high_veil) * smoothstep(-0.06, 0.18, dir.y);

    float lit = clamp(0.07 + 0.94 * density + 0.13 * dir.y, 0.0, 1.0);
    vec3 cloud_tint = mix(undercloud_color, sunlit_cloud_color, lit);
    if (LIGHT0_ENABLED) {
        float alignment = max(dot(dir, LIGHT0_DIRECTION), 0.0);
        float silver_edge = pow(alignment, 24.0) * sun_glow_strength;
        cloud_tint += sun_glow_color * silver_edge * (1.0 - main_bank * 0.45) * 0.28;
    }
    return vec4(cloud_tint, clamp(cloud_alpha, 0.0, 1.0));
}

void sky() {
    vec3 dir = normalize(EYEDIR);
    vec3 base = atmosphere(dir);

    if (AT_CUBEMAP_PASS) {
        // Reflection/ambient cubemap: approximate broad cloud occlusion.
        // TIME in the background demands REALTIME sky mode; keeping the cubemap
        // simple prevents six extra full procedural cloud evaluations per frame.
        COLOR = mix(base, mix(undercloud_color, sunlit_cloud_color, 0.37),
                    cloud_coverage * smoothstep(-0.02, 0.3, dir.y) * 0.86);
    } else if (AT_HALF_RES_PASS) {
        vec4 clouds = cloud_banks(dir);
        COLOR = clouds.rgb;
        ALPHA = clouds.a;
    } else {
        if (LIGHT0_ENABLED) {
            float alignment = max(dot(dir, LIGHT0_DIRECTION), 0.0);
            base += sun_glow_color * pow(alignment, 28.0) * sun_glow_strength * 0.14;
        }
        // Preserve dark open-sky gaps so individual banks remain legible.
        COLOR = mix(base, HALF_RES_COLOR.rgb, clamp(HALF_RES_COLOR.a, 0.0, 1.0));
    }
}
