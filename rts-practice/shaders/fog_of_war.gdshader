shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D memory_texture;
uniform sampler2D visible_texture;
uniform float explored_brightness : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    float explored = texture(memory_texture, UV).r;
	float visible = texture(visible_texture, UV).r;
	float level = max(visible, explored * explored_brightness);
	ALBEDO = vec3(level);
	ALPHA = 1.0;
}