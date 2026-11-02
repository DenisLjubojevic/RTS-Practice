shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_back, shadows_disabled;

uniform sampler2D memory_texture;
uniform sampler2D visible_texture;
uniform float explored_brightness : hint_range(0.0, 1.0) = 0.4;
uniform vec2 map_size = vec2(144.0, 144.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz / map_size;
	float explored = texture(memory_texture, uv).r;
	float vis = texture(visible_texture, uv).r;
	float level = max(vis, explored * explored_brightness);
	ALBEDO = vec3(level);
	ALPHA = 1.0;
}