extends Node3D

## 3D 大世界：与 2D 版玩法对齐（坐标 2D.x→3D.x，2D.y→3D.z）

const NPC_SCENE := preload("res://Scenes/NPC3D.tscn")
const PLAYER_SCENE := preload("res://Scenes/Player3D.tscn")
const MONSTER_SCENE := preload("res://Scenes/Monster3D.tscn")
const FLOATING_TEXT_SCENE := preload("res://Scenes/FloatingWorldText3D.tscn")
const LOOT_PICKUP_SCENE := preload("res://Scenes/LootPickup3D.tscn")
const UiTheme := preload("res://Scripts/ui_theme.gd")
const _DECO_POND: Texture2D = preload("res://Assets/characters/水塘.png")
const _DECO_ROCK: Texture2D = preload("res://Assets/characters/石头.png")
const _DECO_FLOWER: Texture2D = preload("res://Assets/characters/花从.png")
const _DECO_GRASS_PIT: Texture2D = preload("res://Assets/characters/草坑.png")
const _DECO_GRASS: Texture2D = preload("res://Assets/characters/草从.png")

const MELEE_RANGE: float = 78.0
const BASE_MELEE_DAMAGE: int = 12
const BOW_RAY_HALF_WIDTH: float = 38.0
const MAGE_LOCK_RANGE: float = 248.0

@onready var _wn: Node = get_node("/root/WorldNetwork")
@onready var players_root: Node3D = $Players
@onready var monsters_root: Node3D = $Monsters
@onready var camera_rig: Node3D = $CameraRig3D
@onready var back_btn: Button = $UI/TopBar/BackBtn
@onready var exit_game_btn: Button = $UI/TopBar/ExitGameBtn
@onready var combat_label: Label = $UI/TopBar/CombatLabel
@onready var nickname_label: Label = $UI/TopBar/NicknameLabel
@onready var online_label: Label = $UI/TopBar/OnlineLabel
@onready var hint_label: Label = $UI/TopBar/HintLabel
@onready var top_bar: Panel = $UI/TopBar
@onready var mobile_controls: CanvasLayer = $UI/MobileControls
@onready var npcs_root: Node3D = $NPCs
@onready var world_chat: CanvasLayer = $UI/WorldChat
@onready var growth_btn: Button = $UI/TopBar/GrowthBtn
@onready var backpack_btn: Button = $UI/TopBar/BackpackBtn
@onready var backpack_overlay: Control = $UI/BackpackOverlay
@onready var character_build_overlay: Control = $UI/CharacterBuildOverlay
@onready var loot_drops_root: Node3D = $LootDrops
@onready var decorations_root: Node3D = $Decorations
@onready var combat_fx_root: Node3D = $CombatFX
@onready var floating_feedback_root: Node3D = $FloatingFeedback

@export var follow_smooth: float = 8.0
@export var melee_attack_fx_scene: PackedScene = preload("res://Scenes/MeleeAttackFX3D.tscn")

var _local_player: CharacterBody3D
var _local_player_name: String = "萌酱"
var _attack_cd: float = 0.0
var _combat_level: int = 1
var _combat_xp: int = 0
var _combat_xp_next: int = 50
var _monster_respawn_cd: float = 0.0
var _tex_pond: Texture2D
var _tex_rock: Texture2D
var _tex_flower: Texture2D
var _tex_grass_pit: Texture2D
var _tex_grass: Texture2D
var _deco_separation_anchors: Array[Vector2] = []

const WORLD_SPAWN_RECT := Rect2(-2100.0, -2100.0, 4200.0, 4200.0)
const DECO_STRATIFY_COLS := 18
const DECO_STRATIFY_ROWS := 18
const DECO_SPAWN_EXCLUDE_RADIUS := 200.0
const MONSTER_MAX_COUNT := 9
const MONSTER_RESPAWN_INTERVAL := 2.8
const MONSTER_SPAWN_MIN_DIST := 170.0
const MONSTER_SPAWN_MAX_RING := 720.0


func _ready() -> void:
	if _wn.is_cloud():
		call_deferred("_enter_2d_cloud_world")
		return
	add_to_group("world_xp_sink")
	PlayerInventory.clear()
	_apply_theme_to_ui()
	back_btn.pressed.connect(_on_back_clicked)
	exit_game_btn.pressed.connect(_on_exit_game_clicked)
	backpack_btn.pressed.connect(_on_backpack_pressed)
	growth_btn.pressed.connect(_on_growth_pressed)
	mobile_controls.move_input.connect(_on_mobile_move_input)
	mobile_controls.interact_pressed.connect(_on_mobile_interact_pressed)
	mobile_controls.attack_pressed.connect(_on_mobile_attack_pressed)
	mobile_controls.surge_pressed.connect(_on_skill_surge_requested)
	if mobile_controls.has_signal("jump_pressed"):
		mobile_controls.jump_pressed.connect(_on_mobile_jump_pressed)
	var view_btn: Button = get_node_or_null("UI/ViewModeButton") as Button
	if is_instance_valid(view_btn):
		view_btn.pressed.connect(_on_view_mode_pressed)
	_load_user_data()
	_setup_chat()
	_spawn_offline_player()
	_bind_deco_textures()
	_spawn_monsters()
	_spawn_world_fluff()
	_spawn_npcs()
	if not CharacterBuild.build_changed.is_connected(_on_character_build_changed):
		CharacterBuild.build_changed.connect(_on_character_build_changed)
	_refresh_combat_ui()
	get_tree().root.size_changed.connect(_layout_world_top_bar)
	_layout_world_top_bar()
	backpack_btn.visible = true
	growth_btn.visible = true
	if camera_rig and camera_rig.has_method("set_follow_target") and is_instance_valid(_local_player):
		camera_rig.set_follow_target(_local_player)
		camera_rig.follow_smooth = follow_smooth
		if camera_rig.has_method("snap_to_target"):
			camera_rig.call("snap_to_target")
		camera_rig.follow_smooth = follow_smooth


func _enter_2d_cloud_world() -> void:
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")


func _bind_deco_textures() -> void:
	_tex_pond = _DECO_POND
	_tex_rock = _DECO_ROCK
	_tex_flower = _DECO_FLOWER
	_tex_grass_pit = _DECO_GRASS_PIT
	_tex_grass = _DECO_GRASS


func apply_bonus_xp(amount: int) -> void:
	_grant_xp(maxi(1, amount))


func _on_backpack_pressed() -> void:
	if backpack_overlay.has_method("open_panel"):
		backpack_overlay.open_panel()


func _on_growth_pressed() -> void:
	GameAudio.ui_click()
	if character_build_overlay.has_method("open_panel"):
		character_build_overlay.open_panel()


func _on_skill_surge_requested() -> void:
	if not _can_local_attack():
		return
	if CharacterBuild.activate_surge():
		GameAudio.ui_confirm()


static func _v2_v3(p: Vector2) -> Vector3:
	return Vector3(p.x, 0.0, p.y)


static func _v3_v2(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


func _spawn_world_fluff() -> void:
	_deco_separation_anchors.clear()
	for c in decorations_root.get_children():
		if c.is_in_group("world_deco_auto"):
			c.queue_free()
	_spawn_deco_3d(_tex_pond, 6, 9, 0.18, 0.28, false, 280.0)
	_spawn_deco_3d(_tex_grass_pit, 6, 9, 0.22, 0.32, false, 240.0)
	_spawn_deco_3d(_tex_rock, 28, 42, 0.12, 0.2, true, 0.0)
	_spawn_deco_3d(_tex_flower, 28, 42, 0.16, 0.24, true, 0.0)
	_spawn_deco_3d(_tex_grass, 40, 58, 0.1, 0.18, true, 0.0)


func _spawn_deco_3d(
	tex: Texture2D,
	min_c: int,
	max_c: int,
	scale_lo: float,
	scale_hi: float,
	stratify: bool,
	min_sep: float
) -> void:
	if tex == null:
		return
	var n: int = randi_range(min_c, max_c)
	for _i in n:
		var p2: Vector2
		if min_sep > 0.0:
			p2 = _pick_deco_pos_separated(min_sep, stratify)
		elif stratify:
			p2 = _random_world_pos_stratified()
		else:
			p2 = _random_world_pos()
		var s := Sprite3D.new()
		s.texture = tex
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		s.pixel_size = randf_range(scale_lo, scale_hi)
		var sz: Vector2i = tex.get_size()
		var h_world: float = s.pixel_size * float(max(1, sz.y))
		## 贴图中心对齐时，底边约在地表 y=0 略上，避免像素图「陷进」灰地
		s.position = _v2_v3(p2) + Vector3(0, 0.02 + h_world * 0.5, 0)
		s.add_to_group("world_deco_auto")
		decorations_root.add_child(s)


func _deco_excluded_center() -> Vector2:
	if is_instance_valid(_local_player):
		return _v3_v2(_local_player.global_position)
	return Vector2(640.0, 360.0)


func _pick_deco_pos_separated(sep: float, stratify: bool) -> Vector2:
	var excl: Vector2 = _deco_excluded_center()
	var pos: Vector2
	for _t in 55:
		pos = _random_world_pos_stratified() if stratify else _random_world_pos()
		if pos.distance_to(excl) < DECO_SPAWN_EXCLUDE_RADIUS:
			continue
		var ok: bool = true
		for a: Vector2 in _deco_separation_anchors:
			if pos.distance_to(a) < sep:
				ok = false
				break
		if ok:
			_deco_separation_anchors.append(pos)
			return pos
	for _t2 in 20:
		pos = _random_world_pos()
		if pos.distance_to(excl) >= DECO_SPAWN_EXCLUDE_RADIUS * 0.5:
			_deco_separation_anchors.append(pos)
			return pos
	_deco_separation_anchors.append(_random_world_pos())
	return _deco_separation_anchors[_deco_separation_anchors.size() - 1]


func _random_world_pos() -> Vector2:
	var r: Rect2 = WORLD_SPAWN_RECT
	return Vector2(
		randf_range(r.position.x, r.position.x + r.size.x),
		randf_range(r.position.y, r.position.y + r.size.y)
	)


func _random_world_pos_stratified() -> Vector2:
	var r: Rect2 = WORLD_SPAWN_RECT
	var cw: float = r.size.x / float(DECO_STRATIFY_COLS)
	var ch: float = r.size.y / float(DECO_STRATIFY_ROWS)
	var cx: int = randi() % DECO_STRATIFY_COLS
	var cy: int = randi() % DECO_STRATIFY_ROWS
	return Vector2(
		r.position.x + (float(cx) + randf()) * cw,
		r.position.y + (float(cy) + randf()) * ch
	)


func _spawn_loot_drops_3d(at: Vector3, reward_xp: int) -> void:
	var gel_n: int = 1 + randi() % 2
	for _i in gel_n:
		var inst: Node3D = LOOT_PICKUP_SCENE.instantiate() as Node3D
		loot_drops_root.add_child(inst)
		inst.global_position = at + Vector3(randf_range(-0.4, 0.4), 0.0, randf_range(-0.3, 0.3))
		inst.set("item_id", "slime_gel")
		inst.set("display_name", "史莱姆凝胶")
		inst.set("amount", 1)
		inst.set("bonus_xp", 0)
	if randf() < 0.5:
		var xp_inst: Node3D = LOOT_PICKUP_SCENE.instantiate() as Node3D
		loot_drops_root.add_child(xp_inst)
		xp_inst.global_position = at + Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.3, 0.2))
		xp_inst.set("item_id", "")
		xp_inst.set("display_name", "")
		xp_inst.set("amount", 0)
		var bonus: int = clampi(2 + int(floor(float(reward_xp) / 10.0)), 2, 12)
		xp_inst.set("bonus_xp", bonus)


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


func _on_chat_message_sent(message: String) -> void:
	if is_instance_valid(_local_player):
		world_chat.add_local_chat_bubble(_local_player_name, message, _local_player)
	world_chat.add_chat_message(_local_player_name, message)


func _spawn_offline_player() -> void:
	var p: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D
	p.global_position = _v2_v3(Vector2(640, 360))
	players_root.add_child(p)
	_local_player = p
	var uname: String = _saved_username()
	if uname.is_empty():
		uname = "萌酱"
	p.set_display_name(uname)
	world_chat.set_local_player(p)
	CharacterBuild.set_runtime_combat_level(_combat_level)


func _spawn_npcs() -> void:
	_spawn_one_npc_3d(Vector2(380, 220), "店员小桃", "欢迎光临～今天推荐的是草莓牛奶蛋糕哦！")
	_spawn_one_npc_3d(Vector2(860, 300), "旅人米菲", "世界好大呀……你也来散步吗？")
	_spawn_one_npc_3d(Vector2(520, 480), "向导露露", "靠近 NPC 后点「对话」或 E。3D 单机世界。")


func _spawn_one_npc_3d(at2: Vector2, display_name: String, message: String) -> void:
	var n: Node3D = NPC_SCENE.instantiate() as Node3D
	n.position = _v2_v3(at2)
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


func _on_mobile_jump_pressed() -> void:
	if is_instance_valid(_local_player) and _local_player.has_method("queue_jump"):
		_local_player.call("queue_jump")


func _on_view_mode_pressed() -> void:
	if is_instance_valid(camera_rig) and camera_rig.has_method("toggle_mode"):
		camera_rig.toggle_mode()
		GameAudio.ui_click()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_camera_mode"):
		return
	if MoeDialogBus.is_dialog_open():
		return
	var fo: Control = get_viewport().gui_get_focus_owner() as Control
	if fo is LineEdit or fo is TextEdit:
		return
	if is_instance_valid(camera_rig) and camera_rig.has_method("toggle_mode"):
		camera_rig.toggle_mode()
		GameAudio.ui_click()
		get_viewport().set_input_as_handled()


func _apply_theme_to_ui() -> void:
	var col_text: Color = Color8(72, 48, 62)
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
	hint_label.add_theme_font_size_override("font_size", 13)
	_style_header_action_btn(growth_btn)
	_style_header_action_btn(backpack_btn)
	hint_label.text = "WASD/摇杆 · 空格 跳跃 · V/视角 第一或第三人称 · Q 强击"


func _style_header_action_btn(b: Button) -> void:
	if not is_instance_valid(b):
		return
	var d: int = 14
	b.add_theme_color_override("font_color", Color8(255, 255, 255))
	b.add_theme_color_override("font_outline_color", Color8(64, 28, 52))
	b.add_theme_constant_override("outline_size", 3)
	b.add_theme_stylebox_override("normal", _compact_pill_button_style(Color8(118, 44, 88), d))
	b.add_theme_stylebox_override("hover", _compact_pill_button_style(Color8(136, 58, 102), d))
	b.add_theme_stylebox_override("pressed", _compact_pill_button_style(Color8(96, 36, 72), d))


func _compact_pill_button_style(bg: Color, r: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_left = r
	s.corner_radius_bottom_right = r
	s.content_margin_left = 6
	s.content_margin_top = 6
	s.content_margin_right = 6
	s.content_margin_bottom = 6
	return s


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
	var bag_w: float = clampf(52.0 + W * 0.028, 46.0, 76.0)
	_world_bar_place(growth_btn, x, y0, bag_w, btn_h)
	x = growth_btn.offset_right + g
	_world_bar_place(backpack_btn, x, y0, bag_w, btn_h)
	x = backpack_btn.offset_right + g
	var nick_w: float = clampf(92.0 + W * 0.055, 70.0, 200.0)
	nickname_label.offset_top = y0 + 2.0
	nickname_label.offset_bottom = bar_h - (y0 + 2.0)
	nickname_label.offset_right = W - pad
	nickname_label.offset_left = nickname_label.offset_right - nick_w
	var mid_end: float = nickname_label.offset_left - g
	var combat_w: float = clampf(W * 0.12, 96.0, 220.0)
	combat_label.offset_left = x
	combat_label.offset_right = x + combat_w
	combat_label.offset_top = y0 + 2.0
	combat_label.offset_bottom = bar_h - (y0 + 2.0)
	x = combat_label.offset_right + g
	var on_w: float = clampf(W * 0.095, 80.0, 158.0)
	online_label.offset_left = x
	online_label.offset_right = x + on_w
	x = online_label.offset_right + g
	hint_label.offset_left = x
	hint_label.offset_right = maxf(x + 48.0, mid_end)
	var fs: float = UiTheme.responsive_ui_font_scale(vp)
	combat_label.add_theme_font_size_override("font_size", int(17 * fs))
	online_label.add_theme_font_size_override("font_size", int(16 * fs))
	hint_label.add_theme_font_size_override("font_size", int(12 * fs))
	nickname_label.add_theme_font_size_override("font_size", int(18 * fs))
	back_btn.add_theme_font_size_override("font_size", int(16 * fs))
	exit_game_btn.add_theme_font_size_override("font_size", int(16 * fs))
	growth_btn.add_theme_font_size_override("font_size", int(14 * fs))
	backpack_btn.add_theme_font_size_override("font_size", int(14 * fs))


func _world_bar_place(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.offset_left = x
	c.offset_top = y
	c.offset_right = x + w
	c.offset_bottom = y + h


func _process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_monster_respawn_cd = maxf(0.0, _monster_respawn_cd - delta)
	if is_instance_valid(players_root):
		online_label.text = "在线: %d" % players_root.get_child_count()
	if _can_local_attack():
		if Input.is_action_just_pressed("attack"):
			_try_primary_attack()
		if Input.is_action_just_pressed("skill_surge"):
			_on_skill_surge_requested()
	if _monster_respawn_cd <= 0.01:
		_ensure_monster_population()
		_monster_respawn_cd = MONSTER_RESPAWN_INTERVAL


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


## 与 3D 角色 VisualPivot 一致；站立攻击不会错误地回到 0 弧度
func _attack_facing_yaw() -> float:
	if is_instance_valid(_local_player) and _local_player.has_method("get_facing_yaw"):
		return _local_player.get_facing_yaw()
	return 0.0


func _attack_forward_v2() -> Vector2:
	if is_instance_valid(_local_player) and _local_player.has_method("get_facing_forward_xz"):
		var f: Vector3 = _local_player.get_facing_forward_xz() as Vector3
		return Vector2(f.x, f.z).normalized()
	return Vector2(0, -1)


func _horiz_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _spawn_melee_3d(origin: Vector3, facing_yaw: float, did_hit: bool) -> void:
	if melee_attack_fx_scene == null:
		return
	var inst: Node3D = melee_attack_fx_scene.instantiate() as Node3D
	combat_fx_root.add_child(inst)
	if inst.has_method("play_melee"):
		inst.call("play_melee", origin, facing_yaw, did_hit)


func _spawn_bow_line_fx_3d(from: Vector3, to: Vector3, did_hit: bool) -> void:
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(0.18, 0.12, from.distance_to(to))
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.72, 0.38, 0.9) if did_hit else Color(0.75, 0.82, 0.95, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.mesh = bmesh
	mi.material_override = mat
	var mid: Vector3 = (from + to) * 0.5
	combat_fx_root.add_child(mi)
	mi.global_position = mid
	mi.look_at(to, Vector3.UP)
	var tw: Tween = mi.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.22)
	tw.finished.connect(mi.queue_free)


func _spawn_mage_aoe_fx_3d(center: Vector3, radius: float) -> void:
	var c := CylinderMesh.new()
	c.height = 0.18
	c.top_radius = radius
	c.bottom_radius = radius
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.35, 1.0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.mesh = c
	mi.material_override = mat
	combat_fx_root.add_child(mi)
	mi.position = center + Vector3(0, 0.08, 0)
	var tw: Tween = mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.34)
	tw.tween_property(mi, "scale", Vector3(1.1, 1, 1.1), 0.22).from(Vector3(0.9, 1, 0.9))
	tw.finished.connect(mi.queue_free)


func _nearest_monster_3d(origin: Vector3, max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d2: float = max_dist * max_dist
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node3D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m: Node3D = n as Node3D
		var o2: Vector2 = _v3_v2(origin)
		var m2: Vector2 = _v3_v2(m.global_position)
		var d2: float = o2.distance_squared_to(m2)
		if d2 < best_d2:
			best_d2 = d2
			best = m
	return best


func _first_monster_on_ray_3d(origin: Vector2, dir2: Vector2, max_range: float, half_width: float) -> Node3D:
	dir2 = dir2.normalized()
	var best: Node3D = null
	var best_t: float = max_range + 1.0
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node3D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m2: Vector2 = _v3_v2((n as Node3D).global_position)
		var rel: Vector2 = m2 - origin
		var t: float = rel.dot(dir2)
		if t < 0.1 or t > max_range:
			continue
		var closest: Vector2 = origin + dir2 * t
		if closest.distance_squared_to(m2) > half_width * half_width:
			continue
		if t < best_t:
			best_t = t
			best = n as Node3D
	return best


func _perform_warrior_melee_3d(origin: Vector3, dmg_mul: float) -> bool:
	var f: Vector3 = Vector3(0, 0, -1.0)
	if is_instance_valid(_local_player) and _local_player.has_method("get_facing_forward_xz"):
		var ff: Vector3 = _local_player.get_facing_forward_xz() as Vector3
		ff.y = 0.0
		if ff.length_squared() > 0.0001:
			f = ff.normalized()
	## 仅命中角色面前扇形内（全周球判会导致「反方向也打到」）
	const FRONT_DOT: float = 0.22
	var hit_any := false
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node3D:
			continue
		if not n.has_method("take_damage"):
			continue
		if _horiz_dist(origin, (n as Node3D).global_position) > MELEE_RANGE:
			continue
		var to_m: Vector3 = (n as Node3D).global_position - origin
		to_m.y = 0.0
		if to_m.length_squared() < 0.0001:
			continue
		if f.dot(to_m.normalized()) < FRONT_DOT:
			continue
		hit_any = true
		var dmg: int = int(round(float(_melee_damage()) * dmg_mul))
		n.call("take_damage", maxi(1, dmg))
	return hit_any


func _perform_archer_attack_3d(origin: Vector3, _facing_yaw: float, dmg_mul: float) -> bool:
	var bow_r: float = CharacterBuild.bow_range()
	var dir2: Vector2
	if CharacterBuild.ranged_auto_lock:
		var nm: Node3D = _nearest_monster_3d(origin, bow_r)
		if nm != null:
			dir2 = _v3_v2(nm.global_position) - _v3_v2(origin)
			if dir2.length() > 0.01:
				dir2 = dir2.normalized()
			else:
				dir2 = _attack_forward_v2()
		else:
			dir2 = _attack_forward_v2()
	else:
		dir2 = _attack_forward_v2()
	var o2: Vector2 = _v3_v2(origin)
	var tgt: Node3D = _first_monster_on_ray_3d(o2, dir2, bow_r, BOW_RAY_HALF_WIDTH)
	var to_pt3: Vector3 = origin + Vector3(dir2.x, 0, dir2.y) * bow_r
	if tgt != null:
		var dist: float = _horiz_dist(origin, tgt.global_position)
		to_pt3 = origin + Vector3(dir2.x, 0, dir2.y) * clampf(dist + 0.1, 0.5, bow_r)
		var dmg: int = int(round(float(_melee_damage()) * dmg_mul * 0.9))
		tgt.call("take_damage", maxi(1, dmg))
		_spawn_bow_line_fx_3d(origin + Vector3(0, 0.5, 0), to_pt3 + Vector3(0, 0.5, 0), true)
		return true
	_spawn_bow_line_fx_3d(origin + Vector3(0, 0.5, 0), to_pt3 + Vector3(0, 0.5, 0), false)
	return false


func _perform_mage_aoe_3d(origin: Vector3, _facing_yaw: float, dmg_mul: float) -> bool:
	var center2: Vector2
	if CharacterBuild.ranged_auto_lock:
		var nm: Node3D = _nearest_monster_3d(origin, MAGE_LOCK_RANGE)
		if nm != null:
			center2 = _v3_v2(nm.global_position)
		else:
			center2 = _v3_v2(origin) + _attack_forward_v2() * 0.9
	else:
		center2 = _v3_v2(origin) + _attack_forward_v2() * 1.1
	var r: float = CharacterBuild.mage_aoe_radius()
	var center3: Vector3 = _v2_v3(center2)
	_spawn_mage_aoe_fx_3d(center3, r)
	var dmg_each: int = int(round(float(_melee_damage()) * dmg_mul * 0.52))
	var hit_any := false
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node3D:
			continue
		if not n.has_method("take_damage"):
			continue
		if _horiz_dist(center3, (n as Node3D).global_position) <= r:
			hit_any = true
			n.call("take_damage", maxi(1, dmg_each))
	return hit_any


func _perform_priest_heal_3d(dmg_mul: float) -> void:
	var gained: int = CharacterBuild.heal_priest_with_multiplier(_combat_level, dmg_mul)
	if is_instance_valid(_local_player):
		if gained > 0:
			_spawn_floating_3d(
				_local_player.global_position + Vector3(0, 1.2, 0),
				"+%d 生命" % gained,
				Color8(120, 255, 188),
				22,
				0.6
			)
		else:
			_spawn_floating_3d(
				_local_player.global_position + Vector3(0, 1.1, 0),
				"生命已满",
				Color8(180, 200, 220),
				18,
				0.5
			)


func _try_primary_attack() -> void:
	if _attack_cd > 0.0:
		return
	if not _can_local_attack():
		return
	var origin: Vector3 = _local_player.global_position
	var facing: float = _attack_facing_yaw()
	var dmg_mul: float = CharacterBuild.consume_melee_damage_multiplier()
	var cls: int = CharacterBuild.get_combat_class()
	var hit_any: bool = false
	match cls:
		CharacterBuild.CLASS_ARCHER:
			hit_any = _perform_archer_attack_3d(origin, facing, dmg_mul)
		CharacterBuild.CLASS_MAGE:
			hit_any = _perform_mage_aoe_3d(origin, facing, dmg_mul)
		CharacterBuild.CLASS_PRIEST:
			_perform_priest_heal_3d(dmg_mul)
			hit_any = true
		_:
			hit_any = _perform_warrior_melee_3d(origin, dmg_mul)
	if cls == CharacterBuild.CLASS_PRIEST:
		GameAudio.heal_chime()
	else:
		GameAudio.melee_swing()
		if hit_any:
			GameAudio.melee_hit()
	if cls == CharacterBuild.CLASS_WARRIOR:
		_spawn_melee_3d(origin, facing, hit_any)
	_attack_cd = CharacterBuild.effective_primary_cooldown()


func _on_mobile_attack_pressed() -> void:
	_try_primary_attack()


func _grant_xp(amount: int) -> void:
	amount = maxi(1, amount)
	var prev_level: int = _combat_level
	_combat_xp += amount
	while _combat_xp >= _combat_xp_next:
		_combat_xp -= _combat_xp_next
		_combat_level += 1
		_combat_xp_next = _xp_for_next_level(_combat_level)
	_refresh_combat_ui()
	if _combat_level > prev_level:
		CharacterBuild.grant_points_for_levels(_combat_level - prev_level)
		GameAudio.level_up()
	if _combat_level > prev_level and is_instance_valid(_local_player):
		_spawn_floating_3d(
			_local_player.global_position + Vector3(0, 0.1, 0),
			"升级到 Lv.%d！" % _combat_level,
			Color8(255, 214, 96),
			26,
			0.7
		)


func _refresh_combat_ui() -> void:
	if not is_instance_valid(combat_label):
		return
	CharacterBuild.set_runtime_combat_level(_combat_level)
	combat_label.visible = true
	combat_label.text = "HP %d/%d" % [CharacterBuild.get_player_hp(), CharacterBuild.get_max_hp()]
	if is_instance_valid(_local_player) and _local_player.has_method("set_level_exp_caption"):
		_local_player.set_level_exp_caption("Lv.%d  %d/%d EXP" % [_combat_level, _combat_xp, _combat_xp_next])
		_local_player.set_level_exp_visible(true)


func _spawn_floating_3d(world_pos: Vector3, text: String, color: Color, font_size: int, rise: float) -> void:
	if not is_instance_valid(floating_feedback_root):
		return
	var ft: Node3D = FLOATING_TEXT_SCENE.instantiate() as Node3D
	floating_feedback_root.add_child(ft)
	ft.global_position = world_pos + Vector3(randf_range(-0.1, 0.1), 0, randf_range(-0.1, 0.1))
	if ft.has_method("begin"):
		ft.call("begin", text, color, font_size, rise)


func _on_monster_damaged_3d(actual_damage: int, at_global: Vector3) -> void:
	_spawn_floating_3d(at_global, str(actual_damage), Color8(255, 188, 120), 21, 0.45)


func _on_monster_died_3d(reward_xp: int, at_global: Vector3) -> void:
	GameAudio.monster_death()
	_grant_xp(reward_xp)
	GameAudio.xp_tick()
	_spawn_loot_drops_3d(at_global, reward_xp)
	_spawn_floating_3d(at_global, "+%d 经验" % reward_xp, Color8(118, 232, 168), 22, 0.55)
	_monster_respawn_cd = minf(_monster_respawn_cd, 1.2)


func _spawn_monsters() -> void:
	_spawn_monster_batch_3d(MONSTER_MAX_COUNT)


func _ensure_monster_population() -> void:
	if not is_instance_valid(monsters_root) or not is_instance_valid(_local_player):
		return
	var alive: int = 0
	for c in monsters_root.get_children():
		if is_instance_valid(c):
			alive += 1
	if alive >= MONSTER_MAX_COUNT:
		return
	_spawn_monster_batch_3d(mini(2, MONSTER_MAX_COUNT - alive))


func _spawn_monster_batch_3d(count: int) -> void:
	if not is_instance_valid(_local_player):
		return
	for i in count:
		var pos3: Vector3 = _random_monster_spawn_3d()
		var mon: Node = MONSTER_SCENE.instantiate()
		mon.set("max_hp", 28 + i * 6)
		mon.set("reward_xp", 14 + (i % 4) * 4)
		mon.set("move_speed", 48.0 + float(i % 3) * 8.0)
		monsters_root.add_child(mon)
		if mon is Node3D:
			(mon as Node3D).global_position = pos3
		if mon.has_signal("damaged"):
			mon.damaged.connect(_on_monster_damaged_3d)
		if mon.has_signal("died"):
			mon.died.connect(_on_monster_died_3d)
		if mon.has_method("set_aggro_target"):
			mon.call("set_aggro_target", _local_player)


func _random_monster_spawn_3d() -> Vector3:
	if not is_instance_valid(_local_player):
		return _v2_v3(_random_world_pos())
	var p2: Vector2 = _v3_v2(_local_player.global_position)
	var r: Rect2 = WORLD_SPAWN_RECT
	for _i in 32:
		var ang: float = randf() * TAU
		var d: float = randf_range(MONSTER_SPAWN_MIN_DIST, MONSTER_SPAWN_MAX_RING)
		var p: Vector2 = p2 + Vector2(cos(ang), sin(ang)) * d
		if r.has_point(p):
			return _v2_v3(p)
	for _k in 20:
		var p2b: Vector2 = _random_world_pos()
		if p2b.distance_to(p2) >= MONSTER_SPAWN_MIN_DIST:
			return _v2_v3(p2b)
	return _v2_v3(_random_world_pos())


func _on_exit_game_clicked() -> void:
	if _wn.is_cloud():
		_wn.leave_session()
	get_tree().quit()


func _on_back_clicked() -> void:
	if _wn.is_cloud():
		_wn.leave_session()
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")


func _on_character_build_changed() -> void:
	_refresh_combat_ui()
