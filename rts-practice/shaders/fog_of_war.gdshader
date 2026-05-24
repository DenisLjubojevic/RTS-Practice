shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D source_texture_fow : source_color;

void fragment() {
    vec3 fow = texture(source_texture_fow, UV).rgb;
    ALBEDO = fow;
    ALPHA = 1.0 - fow.r;
}