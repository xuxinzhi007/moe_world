shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(1.0, 0.95, 0.77, 1.0);
uniform vec4 color_bottom : source_color = vec4(1.0, 0.90, 0.94, 1.0);

void fragment() {
    float t = UV.y;
    COLOR = mix(color_top, color_bottom, t);
}
