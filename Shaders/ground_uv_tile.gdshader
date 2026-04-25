shader_type canvas_item;
render_mode unshaded;

// Godot 的 fragment 里不能写 return，只能给 COLOR 赋值
uniform float tile_repeat: hint_range(1.0, 65536.0) = 32.0;
uniform float y_repeat_scale: hint_range(0.1, 4.0) = 1.0;
uniform vec4 back_color: source_color = vec4(0.42, 0.32, 0.24, 1.0);
uniform sampler2D albedo: source_color, filter_nearest, repeat_enable;

void fragment() {
	ivec2 d = textureSize(albedo, 0);
	vec2 t = vec2(UV.x * tile_repeat, UV.y * tile_repeat * y_repeat_scale);
	vec2 n = fract(t);
	n = min(n, vec2(0.9999994));
	ivec2 i = ivec2(floor(n * vec2(d)));
	i = min(i, d - ivec2(1, 1));
	i = max(i, ivec2(0, 0));
	vec4 texc = texelFetch(albedo, i, 0);
	vec3 rgb = mix(back_color.rgb, texc.rgb, texc.a);
	COLOR = vec4(rgb, 1.0);
}
