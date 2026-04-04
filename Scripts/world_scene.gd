extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var main_camera: Camera2D = $MainCamera
@onready var back_btn: Button = $UI/TopBar/BackBtn
@onready var nickname_label: Label = $UI/TopBar/PlayerInfoArea/NicknameLabel
@onready var top_bar: Control = $UI/TopBar

@export var move_speed: float = 320.0
@export var follow_speed: float = 0.15

func _ready() -> void:
	_apply_theme_to_ui()
	back_btn.pressed.connect(_on_back_clicked)

func _apply_theme_to_ui() -> void:
	var theme_obj = Theme.new()
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(1, 0.4, 0.6)
	btn_style.corner_radius_top_left = 32
	btn_style.corner_radius_top_right = 32
	btn_style.corner_radius_bottom_left = 32
	btn_style.corner_radius_bottom_right = 32
	btn_style.content_margin_left = 16
	btn_style.content_margin_top = 16
	btn_style.content_margin_right = 16
	btn_style.content_margin_bottom = 16
	theme_obj.set_stylebox("normal", "Button", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(1, 0.5, 0.7)
	theme_obj.set_stylebox("hover", "Button", btn_hover)
	
	var btn_pressed = btn_style.duplicate()
	btn_pressed.bg_color = Color(0.9, 0.3, 0.5)
	theme_obj.set_stylebox("pressed", "Button", btn_pressed)
	
	var avatar_style = StyleBoxFlat.new()
	avatar_style.bg_color = Color(1, 0.4, 0.6)
	avatar_style.corner_radius_top_left = 100
	avatar_style.corner_radius_top_right = 100
	avatar_style.corner_radius_bottom_left = 100
	avatar_style.corner_radius_bottom_right = 100
	theme_obj.set_stylebox("panel", "Avatar", avatar_style)
	
	theme_obj.set_color("font_color", "Button", Color(1, 1, 1))
	theme_obj.set_color("font_color", "Label", Color(0.2, 0.2, 0.2))
	
	top_bar.theme = theme_obj
	nickname_label.add_theme_font_size_override("font_size", 28)

func _physics_process(_delta: float) -> void:
	pass

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		main_camera.global_position = main_camera.global_position.lerp(player.global_position, follow_speed)

func _on_back_clicked() -> void:
	print("🏠 返回大厅")
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")
