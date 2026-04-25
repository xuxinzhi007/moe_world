shader_type spatial;
## 用世界 XZ 采样，配合轻微杂色消弱规则砖缝
render_mode cull_back, depth_draw_opaque, diffuse_burley;

uniform sampler2D albedo_texture : source_color, filter_linear, repeat_enable;
uniform vec3 albedo_tint : source_color = vec3(1.0, 0.95, 0.9);
uniform float uv_scale = 0.1;
uniform float roughness : hint_range(0.0, 1.0) = 0.92;
uniform float micro_variation = 0.11;

varying vec3 w_pos;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = w_pos.xz * uv_scale;
	vec3 col = texture(albedo_texture, uv).rgb * albedo_tint;
	float n = hash2(floor(w_pos.xz * 0.35)) * 0.5 + hash2(floor(w_pos.xz * 0.12)) * 0.5;
	n = n * 2.0 - 1.0;
	col *= 1.0 + n * micro_variation;
	ALBEDO = col;
	ROUGHNESS = roughness;
}
