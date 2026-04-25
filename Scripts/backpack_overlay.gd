extends Control

const UiTheme := preload("res://Scripts/ui_theme.gd")

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $CenterPanel
@onready var item_list: ItemList = $CenterPanel/Margin/VBox/ItemList
@onready var close_btn: Button = $CenterPanel/Margin/VBox/CloseBtn


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(22, 0.95))
	dim.gui_input.connect(_on_dim_gui)
	close_btn.pressed.connect(close_panel)
	PlayerInventory.inventory_changed.connect(_on_inv_changed)


func open_panel() -> void:
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	_refresh_list()


func close_panel() -> void:
	GameAudio.ui_click()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_dim_gui(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_panel()
	if event is InputEventScreenTouch and event.pressed:
		close_panel()


func _on_inv_changed() -> void:
	if visible:
		_refresh_list()


func _refresh_list() -> void:
	item_list.clear()
	for line in PlayerInventory.describe_lines():
		item_list.add_item(line)
	if item_list.item_count == 0:
		item_list.add_item("（空）拾取史莱姆掉落可收集材料")
