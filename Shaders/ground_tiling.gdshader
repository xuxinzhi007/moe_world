shader_type canvas_item;
render_mode unshaded;

/// 在整块地形的 UV 上横向/纵向各排多少格「整张贴图」；越大=单格在世界里越小
uniform float tile_repeat: hint_range(1.0, 256.0) = 32.0;
/// 高宽比：地面矩形不是正方形时，把 (size.x/size.y) 设进来，小格在世界里仍是方格
uniform float y_repeat_scale: hint_range(0.1, 4.0) = 1.0;
uniform vec4 back_color: source_color = vec4(0.42, 0.32, 0.24, 1.0);
uniform sampler2D albedo: source_color, filter_nearest, repeat_enable;

void fragment() {
	// 用 texelFetch 取整格像素，避免 texture() 在格缝处双线性/边界浮点 产生 1px 发暗或漏色
	ivec2 d = textureSize(albedo, 0);
	vec2 t = vec2(UV.x * tile_repeat, UV.y * tile_repeat * y_repeat_scale);
	vec2 n = fract(t);
	// 防止 n 在边界浮成 1.0，使 floor 落到宽/高
	n = min(n, vec2(0.9999994));
	ivec2 i = ivec2(floor(n * vec2(d)));
	i = min(i, d - ivec2(1, 1));
	i = max(i, ivec2(0, 0));
	vec4 texc = texelFetch(albedo, i, 0);
	vec3 rgb = mix(back_color.rgb, texc.rgb, texc.a);
	COLOR = vec4(rgb, 1.0);
}
