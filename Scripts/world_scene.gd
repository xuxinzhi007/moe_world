extends Node2D

const NPC_SCENE := preload("res://Scenes/NPC.tscn")

@onready var player: CharacterBody2D = $Player
@onready var main_camera: Camera2D = $MainCamera
@onready var back_btn: Button = $UI/TopBar/BackBtn
@onready var nickname_label: Label = $UI/TopBar/NicknameLabel
@onready var hint_label: Label = $UI/TopBar/HintLabel
@onready var top_bar: Panel = $UI/TopBar
@onready var mobile_controls: CanvasLayer = $UI/MobileControls
@onready var npcs_root: Node2D = $NPCs

@export var follow_smooth: float = 10.0


func _ready() -> void:
	_apply_theme_to_ui()
	_spawn_npcs()
	back_btn.pressed.connect(_on_back_clicked)
	mobile_controls.move_input.connect(_on_mobile_move_input)
	mobile_controls.interact_pressed.connect(_on_mobile_interact_pressed)
	_load_user_data()
	main_camera.global_position = player.global_position


func _spawn_npcs() -> void:
	_spawn_one_npc(Vector2(380, 220), "店员小桃", "欢迎光临～今天推荐的是草莓牛奶蛋糕哦！")
	_spawn_one_npc(Vector2(860, 300), "旅人米菲", "世界好大呀……你也来散步吗？")
	_spawn_one_npc(Vector2(520, 480), "向导露露", "键盘 E 或右下角「对话」可以和 NPC 聊天。左上角返回大厅。")


func _spawn_one_npc(at: Vector2, display_name: String, message: String) -> void:
	var n: Node2D = NPC_SCENE.instantiate() as Node2D
	n.position = at
	n.set("npc_display_name", display_name)
	n.set("dialog_message", message)
	npcs_root.add_child(n)


func _load_user_data() -> void:
	if ProjectSettings.has_setting("moe_world/current_user"):
		var user_data: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if user_data is Dictionary:
			var username: String = str((user_data as Dictionary).get("username", "萌酱"))
			nickname_label.text = username
			print("👤 世界场景玩家: ", username)


func _on_mobile_move_input(direction: Vector2) -> void:
	if is_instance_valid(player):
		player.set_mobile_input(direction)


func _on_mobile_interact_pressed() -> void:
	if is_instance_valid(player):
		player.try_interact_nearby()


func _apply_theme_to_ui() -> void:
	var col_btn := Color8(255, 102, 153)
	var col_btn_hover := Color8(255, 130, 175)
	var col_btn_pressed := Color8(230, 85, 130)
	var col_card := Color8(255, 230, 230)
	var col_text := Color8(75, 50, 62)

	var theme_obj := Theme.new()
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = col_btn
	btn_style.corner_radius_top_left = 24
	btn_style.corner_radius_top_right = 24
	btn_style.corner_radius_bottom_left = 24
	btn_style.corner_radius_bottom_right = 24
	btn_style.content_margin_left = 14
	btn_style.content_margin_top = 10
	btn_style.content_margin_right = 14
	btn_style.content_margin_bottom = 10
	theme_obj.set_stylebox("normal", "Button", btn_style)
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = col_btn_hover
	theme_obj.set_stylebox("hover", "Button", btn_hover)
	var btn_pressed := btn_style.duplicate()
	btn_pressed.bg_color = col_btn_pressed
	theme_obj.set_stylebox("pressed", "Button", btn_pressed)
	theme_obj.set_color("font_color", "Button", Color8(255, 255, 255))
	theme_obj.set_color("font_color", "Label", col_text)

	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(col_card.r, col_card.g, col_card.b, 0.96)
	bar_style.border_color = Color8(255, 200, 210)
	bar_style.set_border_width_all(1)
	bar_style.corner_radius_bottom_left = 18
	bar_style.corner_radius_bottom_right = 18
	top_bar.add_theme_stylebox_override("panel", bar_style)

	top_bar.theme = theme_obj
	nickname_label.add_theme_font_size_override("font_size", 22)
	hint_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_color_override("font_color", Color8(110, 85, 98))


func _process(delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(main_camera):
		var t: float = clampf(follow_smooth * delta, 0.0, 1.0)
		main_camera.global_position = main_camera.global_position.lerp(player.global_position, t)


func _on_back_clicked() -> void:
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")
