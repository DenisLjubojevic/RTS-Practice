shader_type spatial;
render_mode blend_mix, diffuse_toon, specular_disabled, shadows_disabled, ambient_light_disabled;

instance uniform vec4 insatance_color_1 : source_color;

void fragment() {
	ALBEDO = insatance_color_1.rgb;
	ALPHA = insatance_color_1.a;
}