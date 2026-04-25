extends Control

## 玩家进入新区域时顶部横幅提示，风格与 UiTheme 一致。

const UiTheme := preload("res://Scripts/ui_theme.gd")

var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _run_tween: Tween
var _show_seq: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	add_to_group("world_region_toast")

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 88)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	add_child(margin)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(cc)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(24, 0.94))
	cc.add_child(_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_panel.add_child(v)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", UiTheme.FontSizes.TITLE_MEDIUM)
	_title.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MAIN)
	_title.text = "区域"
	v.add_child(_title)

	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", UiTheme.FontSizes.BODY_SMALL)
	_subtitle.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MUTED)
	_subtitle.visible = false
	v.add_child(_subtitle)

	modulate.a = 0.0
	_panel.visible = false


func show_region(title: String, subtitle: String = "") -> void:
	if not is_instance_valid(_title):
		return
	_show_seq += 1
	var token: int = _show_seq
	_title.text = title
	if subtitle.strip_edges().is_empty():
		_subtitle.visible = false
	else:
		_subtitle.visible = true
		_subtitle.text = subtitle

	if _run_tween and _run_tween.is_valid():
		_run_tween.kill()

	await get_tree().process_frame
	if token != _show_seq or not is_instance_valid(_panel):
		return

	_panel.visible = true
	_panel.pivot_offset = _panel.size * 0.5
	modulate.a = 0.0
	_panel.scale = Vector2(0.94, 0.94)

	_run_tween = create_tween()
	_run_tween.set_parallel(true)
	_run_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_run_tween.tween_property(self, "modulate:a", 1.0, 0.38)
	_run_tween.tween_property(_panel, "scale", Vector2.ONE, 0.42)

	await get_tree().create_timer(2.65, false, false, true).timeout
	if token != _show_seq or not is_instance_valid(self):
		return
	if _run_tween and _run_tween.is_valid():
		_run_tween.kill()
	_run_tween = create_tween()
	_run_tween.set_parallel(true)
	_run_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_run_tween.tween_property(self, "modulate:a", 0.0, 0.45)
	_run_tween.tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.45)
	await _run_tween.finished
	if token != _show_seq:
		return
	if is_instance_valid(_panel):
		_panel.visible = false
