extends Node2D

const NPC_SCENE := preload("res://Scenes/NPC.tscn")
const PLAYER_SCENE := preload("res://Scenes/Player.tscn")

@onready var _wn: Node = get_node("/root/WorldNetwork")
@onready var players_root: Node2D = $Players
@onready var main_camera: Camera2D = $MainCamera
@onready var back_btn: Button = $UI/TopBar/BackBtn
@onready var nickname_label: Label = $UI/TopBar/NicknameLabel
@onready var online_label: Label = $UI/TopBar/OnlineLabel
@onready var hint_label: Label = $UI/TopBar/HintLabel
@onready var top_bar: Panel = $UI/TopBar
@onready var mobile_controls: CanvasLayer = $UI/MobileControls
@onready var npcs_root: Node2D = $NPCs

@export var follow_smooth: float = 10.0

var _local_player: CharacterBody2D


func _ready() -> void:
	_apply_theme_to_ui()
	back_btn.pressed.connect(_on_back_clicked)
	mobile_controls.move_input.connect(_on_mobile_move_input)
	mobile_controls.interact_pressed.connect(_on_mobile_interact_pressed)
	_load_user_data()

	if _wn.is_cloud():
		_connect_cloud_signals()
		_bootstrap_cloud_players()
	elif _wn.is_network_world():
		multiplayer.peer_connected.connect(_on_net_peer_connected)
		if multiplayer.is_server():
			call_deferred("_net_host_spawn_self")
	else:
		_spawn_offline_player()

	_spawn_npcs()


func _net_host_spawn_self() -> void:
	if not multiplayer.is_server():
		return
	server_spawn_player.rpc(1, Vector2(640, 360))


func _on_net_peer_connected(new_peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	for c in players_root.get_children():
		var pid: int = int(str(c.name))
		server_spawn_player.rpc(pid, (c as Node2D).global_position)
	var spawn_pt := Vector2(640 + new_peer_id * 48, 360 + (new_peer_id % 4) * 36)
	server_spawn_player.rpc(new_peer_id, spawn_pt)


@rpc("call_local", "reliable")
func server_spawn_player(peer_id: int, at: Vector2) -> void:
	var key := str(peer_id)
	if players_root.has_node(key):
		var ex := players_root.get_node(key) as CharacterBody2D
		ex.global_position = at
		return
	var p: CharacterBody2D = PLAYER_SCENE.instantiate() as CharacterBody2D
	p.name = key
	p.global_position = at
	p.set_multiplayer_authority(peer_id)
	players_root.add_child(p, true)
	if peer_id == multiplayer.get_unique_id():
		_local_player = p
	if peer_id != multiplayer.get_unique_id():
		p.apply_remote_visual()


func _spawn_offline_player() -> void:
	var p: CharacterBody2D = PLAYER_SCENE.instantiate() as CharacterBody2D
	p.global_position = Vector2(640, 360)
	players_root.add_child(p)
	_local_player = p
	main_camera.global_position = p.global_position


func _spawn_npcs() -> void:
	_spawn_one_npc(Vector2(380, 220), "店员小桃", "欢迎光临～今天推荐的是草莓牛奶蛋糕哦！")
	_spawn_one_npc(Vector2(860, 300), "旅人米菲", "世界好大呀……你也来散步吗？")
	_spawn_one_npc(Vector2(520, 480), "向导露露", "靠近 NPC 后点「对话」或键盘 E。联机时仅本机角色可触发对话。")


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
			nickname_label.text = str((user_data as Dictionary).get("username", "萌酱"))


func _on_mobile_move_input(direction: Vector2) -> void:
	if is_instance_valid(_local_player) and _local_player.is_in_dialog:
		_local_player.set_mobile_input(Vector2.ZERO)
		return
	if is_instance_valid(_local_player):
		_local_player.set_mobile_input(direction)


func _on_mobile_interact_pressed() -> void:
	if is_instance_valid(_local_player):
		_local_player.try_interact_nearby()


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
	nickname_label.add_theme_font_size_override("font_size", 20)
	online_label.add_theme_font_size_override("font_size", 18)
	online_label.add_theme_color_override("font_color", Color8(50, 130, 80))
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color8(110, 85, 98))
	if _wn.is_cloud():
		hint_label.text = "云端房间「%s」· WebSocket · 与好友约定同一房间名" % _wn.cloud_room
	elif _wn.is_network_world():
		hint_label.text = "摇杆移动 · 对话与单机相同 · 端口 ENet %d" % _wn.port
	else:
		hint_label.text = "WASD / 左下摇杆移动 · 对话键或右下角按钮"


func _process(delta: float) -> void:
	if is_instance_valid(players_root):
		online_label.text = "在线: %d" % players_root.get_child_count()
	if is_instance_valid(_local_player) and is_instance_valid(main_camera):
		var t: float = clampf(follow_smooth * delta, 0.0, 1.0)
		main_camera.global_position = main_camera.global_position.lerp(_local_player.global_position, t)


func _on_back_clicked() -> void:
	if _wn.is_network_world() or _wn.is_cloud():
		_wn.leave_session()
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")


func _connect_cloud_signals() -> void:
	if not _wn.cloud_peer_joined.is_connected(_on_cloud_peer_joined):
		_wn.cloud_peer_joined.connect(_on_cloud_peer_joined)
	if not _wn.cloud_peer_left.is_connected(_on_cloud_peer_left):
		_wn.cloud_peer_left.connect(_on_cloud_peer_left)
	if not _wn.cloud_peer_moved.is_connected(_on_cloud_peer_moved):
		_wn.cloud_peer_moved.connect(_on_cloud_peer_moved)
	if not _wn.cloud_connection_failed.is_connected(_on_cloud_ws_broken):
		_wn.cloud_connection_failed.connect(_on_cloud_ws_broken)


func _on_cloud_ws_broken(_reason: String) -> void:
	MoeDialogBus.show_dialog("联机断开", "与服务器的 WebSocket 已关闭。")
	_wn.leave_session()
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")


func _bootstrap_cloud_players() -> void:
	var my_id: String = _wn.cloud_my_user_id
	if my_id.is_empty():
		return
	_spawn_player_node(my_id, _wn.cloud_spawn, false)
	for item in _wn.cloud_initial_peers:
		if item is Dictionary:
			var d: Dictionary = item
			var uid := str(d.get("user_id", ""))
			if uid.is_empty() or uid == my_id:
				continue
			var pos := Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
			_spawn_player_node(uid, pos, true)


func _spawn_player_node(key: String, at: Vector2, as_remote_visual: bool) -> void:
	if players_root.has_node(key):
		var ex := players_root.get_node(key) as CharacterBody2D
		ex.global_position = at
		return
	var p: CharacterBody2D = PLAYER_SCENE.instantiate() as CharacterBody2D
	p.name = key
	p.global_position = at
	players_root.add_child(p, true)
	if as_remote_visual:
		p.apply_remote_visual()
	else:
		_local_player = p


func _on_cloud_peer_joined(user_id: String, pos: Vector2) -> void:
	if user_id.is_empty() or user_id == _wn.cloud_my_user_id:
		return
	_spawn_player_node(user_id, pos, true)


func _on_cloud_peer_left(user_id: String) -> void:
	if user_id.is_empty():
		return
	var n := players_root.get_node_or_null(user_id)
	if n:
		n.queue_free()


func _on_cloud_peer_moved(user_id: String, pos: Vector2) -> void:
	if user_id.is_empty() or user_id == _wn.cloud_my_user_id:
		return
	var pl := players_root.get_node_or_null(user_id) as CharacterBody2D
	if pl:
		pl.apply_sync_position(pos)
