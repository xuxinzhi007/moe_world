extends Control

## 世界地图覆盖层：示意分区与玩家位置。M / 地图按钮 / Esc 关闭。

const UiTheme := preload("res://Scripts/meta/ui_theme.gd")

@onready var _drawer: Control = %MinimapDrawer
@onready var _close_btn: Button = %CloseBtn
@onready var _dim: ColorRect = $Dim


func _ready() -> void:
	set_process_unhandled_input(true)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	if is_instance_valid(_close_btn):
		_close_btn.pressed.connect(close_map)
	if is_instance_valid(_dim):
		_dim.gui_input.connect(_on_dim_gui_input)
	_apply_card_style()


func _apply_card_style() -> void:
	var card: PanelContainer = get_node_or_null("Center/MapCard") as PanelContainer
	if card:
		card.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(26, 0.96))


func setup(world: Node2D) -> void:
	if is_instance_valid(_drawer):
		_drawer.set("world_root", world)


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			close_map()
			accept_event()


func open_map() -> void:
	if not is_in_group("world_map_open"):
		add_to_group("world_map_open")
	visible = true
	if is_instance_valid(_close_btn):
		_close_btn.grab_focus()


func close_map() -> void:
	if is_in_group("world_map_open"):
		remove_from_group("world_map_open")
	visible = false


func toggle_map() -> void:
	if visible:
		close_map()
	else:
		open_map()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_world_map"):
		close_map()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			close_map()
			accept_event()
