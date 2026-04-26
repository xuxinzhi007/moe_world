extends Node2D

## 世界坐标飘字：上浮 + 放大弹出 + 淡出后自毁。
## 使用 Node2D + 极高的 Z-index 确保不被遮挡！

func begin(text: String, color: Color, font_size: int, rise_px: float) -> void:
	# 设置极高的 Z-index，确保在所有物体之上
	z_as_relative = false
	z_index = 100000
	
	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(220, 44)
	lbl.position = Vector2(-110, -22)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.1, 0.92))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.pivot_offset = Vector2(110, 22)
	add_child(lbl)
	
	var start_y := global_position.y
	var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "global_position:y", start_y - rise_px, 0.88)
	tw.tween_property(lbl, "scale", Vector2(1.06, 1.06), 0.16).from(Vector2(0.38, 0.38))
	tw.tween_property(lbl, "modulate:a", 0.0, 0.55).set_delay(0.38)
	tw.finished.connect(_queue_free_self, CONNECT_ONE_SHOT)


func _queue_free_self() -> void:
	if is_instance_valid(self):
		queue_free()
