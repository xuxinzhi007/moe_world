extends Node2D

const NPC_SCENE := preload("res://Scenes/NPC.tscn")
const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const MONSTER_SCENE := preload("res://Scenes/Monster.tscn")
const FLOATING_TEXT_SCENE := preload("res://Scenes/FloatingWorldText.tscn")
const UiTheme := preload("res://Scripts/ui_theme.gd")

const MELEE_RANGE: float = 78.0
const MELEE_COOLDOWN: float = 0.38
const BASE_MELEE_DAMAGE: int = 12

@onready var _wn: Node = get_node("/root/WorldNetwork")
@onready var players_root: Node2D = $Players
@onready var monsters_root: Node2D = $Monsters
@onready var main_camera: Camera2D = $MainCamera
@onready var back_btn: Button = $UI/TopBar/BackBtn
@onready var exit_game_btn: Button = $UI/TopBar/ExitGameBtn
@onready var combat_label: Label = $UI/TopBar/CombatLabel
@onready var nickname_label: Label = $UI/TopBar/NicknameLabel
@onready var online_label: Label = $UI/TopBar/OnlineLabel
@onready var hint_label: Label = $UI/TopBar/HintLabel
@onready var top_bar: Panel = $UI/TopBar
@onready var mobile_controls: CanvasLayer = $UI/MobileControls
@onready var npcs_root: Node2D = $NPCs
@onready var world_chat: CanvasLayer = $UI/WorldChat

@export var follow_smooth: float = 10.0
## 挥击特效；在编辑器中拖入你的 PackedScene 即可替换。根节点可选实现 play_melee(origin, facing_rad, did_hit)。
@export var melee_attack_fx_scene: PackedScene = preload("res://Scenes/MeleeAttackFX.tscn")

@onready var combat_fx_root: Node2D = $CombatFX
@onready var floating_feedback_root: Node2D = $FloatingFeedback

var _local_player: CharacterBody2D
var _local_player_name: String = "萌酱"
var _attack_cd: float = 0.0
var _combat_level: int = 1
var _combat_xp: int = 0
var _combat_xp_next: int = 50


func _ready() -> void:
	_apply_theme_to_ui()
	back_btn.pressed.connect(_on_back_clicked)
	exit_game_btn.pressed.connect(_on_exit_game_clicked)
	mobile_controls.move_input.connect(_on_mobile_move_input)
	mobile_controls.interact_pressed.connect(_on_mobile_interact_pressed)
	mobile_controls.attack_pressed.connect(_on_mobile_attack_pressed)
	_load_user_data()
	_setup_chat()
	
	if _wn.is_cloud():
		_connect_cloud_signals()
		_bootstrap_cloud_players()
	else:
		_spawn_offline_player()
	
	_spawn_npcs()
	if not _wn.is_cloud():
		_spawn_monsters()
	_refresh_combat_ui()
	get_tree().root.size_changed.connect(_layout_world_top_bar)
	_layout_world_top_bar()


func _saved_username() -> String:
	if ProjectSettings.has_setting("moe_world/current_user"):
		var user_data: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if user_data is Dictionary:
			return str((user_data as Dictionary).get("username", "")).strip_edges()
	return ""


func _setup_chat() -> void:
	_local_player_name = _saved_username()
	if _local_player_name.is_empty():
		_local_player_name = "萌酱"
	
	world_chat.chat_message_sent.connect(_on_chat_message_sent)
	
	if _wn.is_cloud():
		if not _wn.cloud_chat_received.is_connected(_on_cloud_chat_received):
			_wn.cloud_chat_received.connect(_on_cloud_chat_received)


func _on_chat_message_sent(message: String) -> void:
	print("💬 本地发送聊天消息: ", message)
	
	if is_instance_valid(_local_player):
		world_chat.add_local_chat_bubble(_local_player_name, message, _local_player)
	# 对话列表里立即显示自己发的内容；云端回显自己时会跳过避免重复
	world_chat.add_chat_message(_local_player_name, message)
	
	if _wn.is_cloud():
		_wn.send_chat_message(message)


func _on_cloud_chat_received(sender_id: String, sender_name: String, message: String) -> void:
	if sender_id == _wn.cloud_my_user_id:
		return
	print("💬 收到远程聊天消息 [%s]: %s" % [sender_name, message])
	
	var remote_player := players_root.get_node_or_null(sender_id) as CharacterBody2D
	if is_instance_valid(remote_player):
		world_chat.add_remote_chat_bubble(sender_name, message, remote_player)
	world_chat.add_chat_message(sender_name, message)


func _spawn_offline_player() -> void:
	var p: CharacterBody2D = PLAYER_SCENE.instantiate() as CharacterBody2D
	p.global_position = Vector2(640, 360)
	players_root.add_child(p)
	_local_player = p
	var uname := _saved_username()
	if uname.is_empty():
		uname = "萌酱"
	p.set_display_name(uname)
	main_camera.global_position = p.global_position
	
	world_chat.set_local_player(p)


func _spawn_npcs() -> void:
	_spawn_one_npc(Vector2(380, 220), "店员小桃", "欢迎光临～今天推荐的是草莓牛奶蛋糕哦！")
	_spawn_one_npc(Vector2(860, 300), "旅人米菲", "世界好大呀……你也来散步吗？")
	_spawn_one_npc(Vector2(520, 480), "向导露露", "靠近 NPC 后点右下角「对话」或键盘 E。云端联机时头顶会显示各自身份昵称。")


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
	var col_text := Color8(72, 48, 62)
	
	var theme_obj := Theme.new()
	theme_obj.set_stylebox("normal", "Button", UiTheme.modern_primary_button_normal(20))
	theme_obj.set_stylebox("hover", "Button", UiTheme.modern_primary_button_hover(20))
	theme_obj.set_stylebox("pressed", "Button", UiTheme.modern_primary_button_pressed(20))
	theme_obj.set_color("font_color", "Button", Color8(255, 255, 255))
	theme_obj.set_color("font_color", "Label", col_text)
	
	top_bar.add_theme_stylebox_override("panel", UiTheme.modern_hud_bar_bottom_round())
	
	top_bar.theme = theme_obj
	nickname_label.add_theme_font_size_override("font_size", 20)
	online_label.add_theme_font_size_override("font_size", 18)
	online_label.add_theme_color_override("font_color", Color8(50, 130, 80))
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color8(110, 85, 98))
	if _wn.is_cloud():
		hint_label.text = "云端房间「%s」· 头顶显示昵称 · 与好友约定同一房间名" % _wn.cloud_room
	else:
		hint_label.text = "WASD / 左下摇杆移动 · E 对话 · J 或右下角「攻击」打史莱姆升级"


func _layout_world_top_bar() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var W: float = vp.x
	if W < 8.0:
		return
	var bar_h: float = clampf(56.0 + W * 0.014, 52.0, 86.0)
	top_bar.offset_bottom = bar_h
	var pad: float = clampf(8.0 + W * 0.008, 6.0, 22.0)
	var g: float = maxf(4.0, W * 0.004)
	var btn_h: float = clampf(bar_h - 16.0, 40.0, 66.0)
	var y0: float = (bar_h - btn_h) * 0.5
	var btn_w: float = clampf(124.0 * minf(W / 1280.0, 1.2), 86.0, 152.0)
	var x: float = pad
	_world_bar_place(back_btn, x, y0, btn_w, btn_h)
	x = back_btn.offset_right + g
	_world_bar_place(exit_game_btn, x, y0, btn_w, btn_h)
	x = exit_game_btn.offset_right + g
	var nick_w: float = clampf(92.0 + W * 0.055, 70.0, 200.0)
	nickname_label.offset_top = y0 + 2.0
	nickname_label.offset_bottom = bar_h - (y0 + 2.0)
	nickname_label.offset_right = W - pad
	nickname_label.offset_left = nickname_label.offset_right - nick_w
	var mid_end: float = nickname_label.offset_left - g
	var combat_w: float = clampf(W * 0.19, 140.0, 300.0)
	combat_label.offset_left = x
	combat_label.offset_right = x + combat_w
	combat_label.offset_top = y0 + 2.0
	combat_label.offset_bottom = bar_h - (y0 + 2.0)
	x = combat_label.offset_right + g
	var on_w: float = clampf(W * 0.095, 80.0, 158.0)
	online_label.offset_left = x
	online_label.offset_right = x + on_w
	online_label.offset_top = y0 + 2.0
	online_label.offset_bottom = bar_h - (y0 + 2.0)
	x = online_label.offset_right + g
	hint_label.offset_left = x
	hint_label.offset_right = maxf(x + 48.0, mid_end)
	hint_label.offset_top = y0 + 4.0
	hint_label.offset_bottom = bar_h - (y0 + 4.0)
	hint_label.visible = hint_label.offset_right - hint_label.offset_left >= 56.0
	var fs: float = UiTheme.responsive_ui_font_scale(vp)
	combat_label.add_theme_font_size_override("font_size", int(17 * fs))
	online_label.add_theme_font_size_override("font_size", int(16 * fs))
	hint_label.add_theme_font_size_override("font_size", int(12 * fs))
	nickname_label.add_theme_font_size_override("font_size", int(18 * fs))
	back_btn.add_theme_font_size_override("font_size", int(16 * fs))
	exit_game_btn.add_theme_font_size_override("font_size", int(16 * fs))


func _world_bar_place(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.offset_left = x
	c.offset_top = y
	c.offset_right = x + w
	c.offset_bottom = y + h


func _process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)
	if is_instance_valid(players_root):
		online_label.text = "在线: %d" % players_root.get_child_count()
	if is_instance_valid(_local_player) and is_instance_valid(main_camera):
		var t: float = clampf(follow_smooth * delta, 0.0, 1.0)
		main_camera.global_position = main_camera.global_position.lerp(_local_player.global_position, t)
	if not _wn.is_cloud() and _can_local_attack() and Input.is_action_just_pressed("attack"):
		_try_melee_attack()


func _xp_for_next_level(level: int) -> int:
	return 28 + level * 22


func _melee_damage() -> int:
	return BASE_MELEE_DAMAGE + _combat_level * 4


func _can_local_attack() -> bool:
	if not is_instance_valid(_local_player):
		return false
	if not _local_player.is_local_controllable():
		return false
	if _local_player.is_in_dialog:
		return false
	if MoeDialogBus.is_dialog_open():
		return false
	return true


func _attack_facing_rad() -> float:
	var v: Vector2 = _local_player.velocity
	if v.length_squared() > 400.0:
		return v.angle()
	var ix: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var iy: float = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	var aim := Vector2(ix, iy)
	if aim.length_squared() > 0.04:
		return aim.angle()
	if _local_player.use_mobile_controls and _local_player.mobile_input_dir.length_squared() > 0.04:
		return _local_player.mobile_input_dir.angle()
	return PI * 0.5


func _spawn_melee_attack_fx(origin: Vector2, facing_rad: float, did_hit: bool) -> void:
	if melee_attack_fx_scene == null:
		return
	var inst := melee_attack_fx_scene.instantiate()
	combat_fx_root.add_child(inst)
	if inst.has_method("play_melee"):
		(inst as Object).call("play_melee", origin, facing_rad, did_hit)
	elif inst is Node2D:
		var n2: Node2D = inst as Node2D
		n2.global_position = origin
		n2.rotation = facing_rad + PI * 0.5


func _try_melee_attack() -> void:
	if _wn.is_cloud():
		return
	if _attack_cd > 0.0:
		return
	if not _can_local_attack():
		return
	var origin: Vector2 = _local_player.global_position
	var facing: float = _attack_facing_rad()
	var hit_any := false
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n):
			continue
		if not n is Node2D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m: Node2D = n as Node2D
		if m.global_position.distance_to(origin) <= MELEE_RANGE:
			hit_any = true
			n.take_damage(_melee_damage())
	_spawn_melee_attack_fx(origin, facing, hit_any)
	_attack_cd = MELEE_COOLDOWN


func _on_mobile_attack_pressed() -> void:
	_try_melee_attack()


func _grant_xp(amount: int) -> void:
	amount = maxi(1, amount)
	var prev_level: int = _combat_level
	_combat_xp += amount
	while _combat_xp >= _combat_xp_next:
		_combat_xp -= _combat_xp_next
		_combat_level += 1
		_combat_xp_next = _xp_for_next_level(_combat_level)
	_refresh_combat_ui()
	if not _wn.is_cloud() and _combat_level > prev_level and is_instance_valid(_local_player):
		_spawn_floating_feedback(
			_local_player.global_position,
			"升级到 Lv.%d！" % _combat_level,
			Color8(255, 214, 96),
			26,
			68.0
		)


func _refresh_combat_ui() -> void:
	if not is_instance_valid(combat_label):
		return
	if _wn.is_cloud():
		combat_label.visible = false
		return
	combat_label.visible = true
	combat_label.text = "Lv.%d  %d/%d EXP" % [_combat_level, _combat_xp, _combat_xp_next]


func _spawn_floating_feedback(world_pos: Vector2, text: String, color: Color, font_size: int = 22, rise_px: float = 56.0) -> void:
	if not is_instance_valid(floating_feedback_root):
		return
	var ft := FLOATING_TEXT_SCENE.instantiate()
	if not ft is Node2D:
		return
	floating_feedback_root.add_child(ft)
	var n2: Node2D = ft as Node2D
	n2.global_position = world_pos + Vector2(randf_range(-10.0, 10.0), -26.0)
	if n2.has_method("begin"):
		n2.call("begin", text, color, font_size, rise_px)


func _on_monster_damaged(actual_damage: int, at_global: Vector2) -> void:
	if _wn.is_cloud():
		return
	_spawn_floating_feedback(at_global, str(actual_damage), Color8(255, 188, 120), 21, 46.0)


func _on_monster_died(reward_xp: int, at_global: Vector2) -> void:
	_grant_xp(reward_xp)
	if not _wn.is_cloud():
		_spawn_floating_feedback(at_global, "+%d 经验" % reward_xp, Color8(118, 232, 168), 22, 58.0)


func _spawn_monsters() -> void:
	if not is_instance_valid(_local_player):
		return
	var spots: Array[Vector2] = [
		Vector2(720, 180), Vector2(980, 420), Vector2(300, 520),
		Vector2(1080, 200), Vector2(180, 280), Vector2(760, 520),
		Vector2(520, 120), Vector2(420, 380)
	]
	var i := 0
	for pos in spots:
		var mon = MONSTER_SCENE.instantiate()
		mon.max_hp = 28 + i * 6
		mon.reward_xp = 14 + (i % 4) * 4
		mon.move_speed = 48.0 + float(i % 3) * 8.0
		mon.damaged.connect(_on_monster_damaged)
		mon.died.connect(_on_monster_died)
		monsters_root.add_child(mon)
		if mon is Node2D:
			(mon as Node2D).global_position = pos
		if mon.has_method("set_aggro_target"):
			mon.set_aggro_target(_local_player)
		i += 1


func _on_exit_game_clicked() -> void:
	if _wn.is_cloud():
		_wn.leave_session()
	get_tree().quit()


func _on_back_clicked() -> void:
	if _wn.is_cloud():
		_wn.leave_session()
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")


func _connect_cloud_signals() -> void:
	if not _wn.cloud_peer_joined.is_connected(_on_cloud_peer_joined):
		_wn.cloud_peer_joined.connect(_on_cloud_peer_joined)
	if not _wn.cloud_peer_left.is_connected(_on_cloud_peer_left):
		_wn.cloud_peer_left.connect(_on_cloud_peer_left)
	if not _wn.cloud_peer_moved.is_connected(_on_cloud_peer_moved):
		_wn.cloud_peer_moved.connect(_on_cloud_peer_moved)
	if not _wn.cloud_peer_profile.is_connected(_on_cloud_peer_profile):
		_wn.cloud_peer_profile.connect(_on_cloud_peer_profile)
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
	var my_name := _saved_username()
	if my_name.is_empty():
		my_name = "玩家%s" % my_id
	_spawn_player_node(my_id, _wn.cloud_spawn, false, my_name)
	for item in _wn.cloud_initial_peers:
		if item is Dictionary:
			var d: Dictionary = item
			var uid := str(d.get("user_id", ""))
			if uid.is_empty() or uid == my_id:
				continue
			var pos := Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
			var peer_name := str(d.get("username", "")).strip_edges()
			_spawn_player_node(uid, pos, true, peer_name)


func _spawn_player_node(key: String, at: Vector2, as_remote_visual: bool, display_name: String) -> void:
	if players_root.has_node(key):
		var ex := players_root.get_node(key) as CharacterBody2D
		ex.global_position = at
		if not display_name.is_empty():
			ex.set_display_name(display_name)
		return
	var p: CharacterBody2D = PLAYER_SCENE.instantiate() as CharacterBody2D
	p.name = key
	p.global_position = at
	players_root.add_child(p, true)
	if not display_name.is_empty():
		p.set_display_name(display_name)
	else:
		p.set_display_name(key)
	if as_remote_visual:
		p.apply_remote_visual()
	else:
		_local_player = p
		world_chat.set_local_player(p)


func _on_cloud_peer_joined(user_id: String, pos: Vector2, username: String) -> void:
	if user_id.is_empty() or user_id == _wn.cloud_my_user_id:
		return
	_spawn_player_node(user_id, pos, true, username)


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


func _on_cloud_peer_profile(user_id: String, username: String) -> void:
	if user_id.is_empty():
		return
	var pl := players_root.get_node_or_null(user_id) as CharacterBody2D
	if pl and not username.strip_edges().is_empty():
		pl.set_display_name(username)
