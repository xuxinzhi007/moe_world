shader_type canvas_item;

uniform sampler2D albedo : source_color;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.98);
uniform float tile_repeat = 3.0;
uniform float y_repeat_scale = 1.0;
uniform float fade_width = 0.16;
uniform float fade_left = 0.0;
uniform float fade_right = 0.0;
uniform float fade_top = 0.0;
uniform float fade_bottom = 0.0;

void fragment() {
	vec2 tile_uv = vec2(UV.x * tile_repeat, UV.y * tile_repeat * y_repeat_scale);
	vec4 c = texture(albedo, tile_uv) * tint;

	float edge = 1.0;
	float fw = clamp(fade_width, 0.001, 0.49);
	if (fade_left > 0.5) {
		edge *= smoothstep(0.0, fw, UV.x);
	}
	if (fade_right > 0.5) {
		edge *= smoothstep(0.0, fw, 1.0 - UV.x);
	}
	if (fade_top > 0.5) {
		edge *= smoothstep(0.0, fw, UV.y);
	}
	if (fade_bottom > 0.5) {
		edge *= smoothstep(0.0, fw, 1.0 - UV.y);
	}

	COLOR = vec4(c.rgb, c.a * edge);
}
