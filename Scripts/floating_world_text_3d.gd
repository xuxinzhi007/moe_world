extends Node3D

## 3D 世界飘字：沿 +Y 上浮并淡出，供 Label3D 使用

func begin(text: String, color: Color, font_size: int, rise_m: float) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = font_size
	lbl.modulate = color
	lbl.outline_size = 5
	lbl.outline_modulate = Color(0.08, 0.05, 0.1, 0.9)
	lbl.position = Vector3(0, 0, 0)
	add_child(lbl)
	var start_y: float = global_position.y
	var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "global_position:y", start_y + rise_m, 0.88)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.55).set_delay(0.38)
	await tw.finished
	if is_instance_valid(self):
		queue_free()
