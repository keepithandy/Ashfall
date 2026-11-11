shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Station 04 low-profile wet ground. Visual only: it supplies no depth,
// collision, physics material, hazard, reflection probe or gameplay signal.
// UV feathering prevents hard elliptical borders on top of the ground PBR.
uniform vec3 water_tint : source_color = vec3(0.12, 0.15, 0.145);
uniform float opacity : hint_range(0.0, 1.0) = 0.42;
uniform float edge_softness : hint_range(0.02, 0.50) = 0.20;
uniform float surface_roughness : hint_range(0.05, 0.85) = 0.23;

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 2.0;
    float eddy = sin(p.x * 9.0 + p.y * 4.0) * sin(p.y * 7.0 - p.x * 3.0);
    float distortion = 0.048 * eddy;
    float radial = length(p * vec2(1.0, 1.12)) + distortion;
    float feather = 1.0 - smoothstep(1.0 - edge_softness, 1.0, radial);

    ALBEDO = water_tint;
    ROUGHNESS = surface_roughness;
    METALLIC = 0.0;
    SPECULAR = 0.56;
    ALPHA = clamp(feather * opacity, 0.0, 0.68);
}
