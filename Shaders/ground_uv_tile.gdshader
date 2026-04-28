shader_type canvas_item;
render_mode unshaded;

uniform float tile_repeat: hint_range(1.0, 65536.0) = 32.0;
uniform float y_repeat_scale: hint_range(0.1, 4.0) = 1.0;
uniform vec4 back_color: source_color = vec4(0.42, 0.32, 0.24, 1.0);
uniform sampler2D albedo: source_color, filter_linear_mipmap, repeat_enable;

void fragment() {
	vec2 t = vec2(UV.x * tile_repeat, UV.y * tile_repeat * y_repeat_scale);
	vec4 texc = texture(albedo, t);
	vec3 rgb = mix(back_color.rgb, texc.rgb, texc.a);
	COLOR = vec4(rgb, 1.0);
}
