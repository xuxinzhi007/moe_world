class_name GameplayPauseMenu
extends CanvasLayer

signal auto_lock_changed(enabled: bool)
signal menu_opened()
signal menu_closed()
signal back_hall_requested()
signal exit_game_requested()

const _ICON_SETTINGS_PATH := "res://Assets/ui/icons/topbar_settings.svg"
const _ICON_BACK_PATH := "res://Assets/ui/icons/topbar_map.svg"
const _ICON_BUTTON_SIZE := 24

var _dim: ColorRect
var _menu_panel: PanelContainer
var _settings_panel: PanelContainer
var _auto_lock_check: CheckButton
var _missing_icon_warned: Dictionary = {}


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	set_process_input(true)
	set_process_unhandled_input(true)


func _input(event: InputEvent) -> void:
	_try_toggle_by_escape(event)


func _unhandled_input(event: InputEvent) -> void:
	_try_toggle_by_escape(event)


func _try_toggle_by_escape(event: InputEvent) -> void:
	if not _is_pc_mode():
		return
	if event.is_action_pressed("ui_cancel"):
		_toggle_menu_and_consume()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE:
			_toggle_menu_and_consume()


func _toggle_menu_and_consume() -> void:
	if visible:
		close_menu()
	else:
		open_menu()
	get_viewport().set_input_as_handled()


func open_menu() -> void:
	visible = true
	_show_menu_root()
	get_tree().paused = true
	menu_opened.emit()


func close_menu() -> void:
	visible = false
	get_tree().paused = false
	menu_closed.emit()


func set_auto_lock_enabled(enabled: bool) -> void:
	if is_instance_valid(_auto_lock_check):
		_auto_lock_check.button_pressed = bool(enabled)


func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.0, 0.0, 0.0, 0.58)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_menu_panel = _build_menu_panel()
	_settings_panel = _build_settings_panel()
	add_child(_menu_panel)
	add_child(_settings_panel)
	_show_menu_root()


func _build_menu_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -210
	panel.offset_top = -130
	panel.offset_right = 210
	panel.offset_bottom = 130
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "游戏菜单"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vb.add_child(title)
	var resume_btn := Button.new()
	resume_btn.text = "继续游戏"
	resume_btn.pressed.connect(close_menu)
	vb.add_child(resume_btn)
	var setting_btn := Button.new()
	setting_btn.text = "设置"
	_apply_button_icon(setting_btn, _ICON_SETTINGS_PATH, "设置")
	setting_btn.pressed.connect(_show_settings)
	vb.add_child(setting_btn)
	var back_hall_btn := Button.new()
	back_hall_btn.text = "返回大厅"
	back_hall_btn.pressed.connect(_request_back_hall)
	vb.add_child(back_hall_btn)
	var exit_btn := Button.new()
	exit_btn.text = "退出游戏"
	exit_btn.pressed.connect(_request_exit_game)
	vb.add_child(exit_btn)
	return panel


func _build_settings_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -230
	panel.offset_top = -150
	panel.offset_right = 230
	panel.offset_bottom = 150
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "游戏设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vb.add_child(title)
	_auto_lock_check = CheckButton.new()
	_auto_lock_check.text = "自动索敌（远程职业）"
	_auto_lock_check.toggled.connect(func(pressed: bool) -> void:
		auto_lock_changed.emit(pressed)
	)
	vb.add_child(_auto_lock_check)
	var hint := Label.new()
	hint.text = "关闭后：攻击朝当前输入/鼠标方向，不自动吸附最近目标。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	vb.add_child(hint)
	var back_hall_btn := Button.new()
	back_hall_btn.text = "返回大厅"
	back_hall_btn.pressed.connect(_request_back_hall)
	vb.add_child(back_hall_btn)
	var exit_btn := Button.new()
	exit_btn.text = "退出游戏"
	exit_btn.pressed.connect(_request_exit_game)
	vb.add_child(exit_btn)
	var back_btn := Button.new()
	back_btn.text = "返回菜单"
	_apply_button_icon(back_btn, _ICON_BACK_PATH, "返回菜单")
	back_btn.pressed.connect(_show_menu_root)
	vb.add_child(back_btn)
	return panel


func _show_menu_root() -> void:
	if is_instance_valid(_menu_panel):
		_menu_panel.visible = true
	if is_instance_valid(_settings_panel):
		_settings_panel.visible = false


func _show_settings() -> void:
	if is_instance_valid(_menu_panel):
		_menu_panel.visible = false
	if is_instance_valid(_settings_panel):
		_settings_panel.visible = true


func _is_pc_mode() -> bool:
	return not OS.has_feature("mobile")


func _request_back_hall() -> void:
	close_menu()
	back_hall_requested.emit()


func _request_exit_game() -> void:
	close_menu()
	exit_game_requested.emit()


func _apply_button_icon(btn: Button, path: String, fallback_text: String) -> void:
	if not is_instance_valid(btn):
		return
	var icon_tex: Texture2D = _scaled_icon(_load_icon_safe(path), _ICON_BUTTON_SIZE)
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.tooltip_text = fallback_text
	if icon_tex != null:
		btn.icon = icon_tex
		btn.text = fallback_text
	else:
		btn.icon = null
		btn.text = fallback_text


func _load_icon_safe(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		_warn_missing_icon_once(path)
		return null
	var res: Resource = ResourceLoader.load(path)
	var tex: Texture2D = res as Texture2D
	if tex == null:
		_warn_missing_icon_once(path)
	return tex


func _scaled_icon(src: Texture2D, target_px: int) -> Texture2D:
	if src == null:
		return null
	var img: Image = src.get_image()
	if img == null or img.is_empty():
		return src
	var out: Image = img.duplicate()
	out.resize(target_px, target_px, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(out)


func _warn_missing_icon_once(path: String) -> void:
	if _missing_icon_warned.get(path, false):
		return
	_missing_icon_warned[path] = true
	push_warning("Pause menu icon missing: %s" % path)
