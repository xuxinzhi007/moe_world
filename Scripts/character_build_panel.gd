extends Control

const UiTheme := preload("res://Scripts/ui_theme.gd")

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $CenterPanel
@onready var points_label: Label = $CenterPanel/Margin/VBox/PointsLabel
@onready var atk_label: Label = $CenterPanel/Margin/VBox/AtkHBox/AtkLabel
@onready var move_label: Label = $CenterPanel/Margin/VBox/MoveHBox/MoveLabel
@onready var surge_btn: Button = $CenterPanel/Margin/VBox/SurgeBtn
@onready var close_btn: Button = $CenterPanel/Margin/VBox/CloseBtn
@onready var atk_plus: Button = $CenterPanel/Margin/VBox/AtkHBox/AtkPlus
@onready var move_plus: Button = $CenterPanel/Margin/VBox/MoveHBox/MovePlus


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(24, 0.95))
	dim.gui_input.connect(_on_dim_gui)
	close_btn.pressed.connect(close_panel)
	atk_plus.pressed.connect(_on_atk_plus)
	move_plus.pressed.connect(_on_move_plus)
	surge_btn.pressed.connect(_on_surge)
	CharacterBuild.build_changed.connect(_refresh)
	_refresh()


func open_panel() -> void:
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	_refresh()


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


func _refresh() -> void:
	points_label.text = "未分配点数：%d" % CharacterBuild.unspent_points
	atk_label.text = "攻速训练 Lv.%d（缩短近战冷却）" % CharacterBuild.atk_speed_level
	move_label.text = "体能训练 Lv.%d（提升移动速度）" % CharacterBuild.move_level
	var cd: float = CharacterBuild.surge_cooldown_remaining()
	surge_btn.text = "强击：下一击伤害 +38%%" if cd <= 0.01 else "强击冷却中 %.1fs" % cd
	surge_btn.disabled = not CharacterBuild.can_activate_surge()
	atk_plus.disabled = CharacterBuild.unspent_points <= 0
	move_plus.disabled = CharacterBuild.unspent_points <= 0


func _on_atk_plus() -> void:
	if CharacterBuild.try_spend_attack_speed():
		GameAudio.ui_confirm()
	_refresh()


func _on_move_plus() -> void:
	if CharacterBuild.try_spend_move_speed():
		GameAudio.ui_confirm()
	_refresh()


func _on_surge() -> void:
	if CharacterBuild.activate_surge():
		GameAudio.ui_confirm()
	_refresh()
