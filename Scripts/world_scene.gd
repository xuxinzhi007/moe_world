extends Node2D

const NPC_SCENE := preload("res://Scenes/NPC.tscn")
const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const MONSTER_SCENE := preload("res://Scenes/Monster.tscn")
const FLOATING_TEXT_SCENE := preload("res://Scenes/FloatingWorldText.tscn")
const LOOT_PICKUP_SCENE := preload("res://Scenes/LootPickup.tscn")
const UiTheme := preload("res://Scripts/ui_theme.gd")
## 用 preload 避免部分环境下 ResourceLoader.exists/动态加载 对中文路径失败 → 全 null → 不生成
const _DECO_POND: Texture2D = preload("res://Assets/characters/水塘.png")
const _DECO_ROCK: Texture2D = preload("res://Assets/characters/石头.png")
const _DECO_FLOWER: Texture2D = preload("res://Assets/characters/花从.png")
const _DECO_GRASS_PIT: Texture2D = preload("res://Assets/characters/草坑.png")
const _DECO_GRASS: Texture2D = preload("res://Assets/characters/草从.png")

const MELEE_RANGE: float = 78.0
const BASE_MELEE_DAMAGE: int = 12
const BOW_RAY_HALF_WIDTH: float = 38.0
const MAGE_LOCK_RANGE: float = 248.0
const MAGE_SPELL_FX_SCENE := preload("res://Scenes/MageSpellFX.tscn")

@onready var _wn: Node = get_node("/root/WorldNetwork")
@onready var players_root: Node2D = $Playfield/Players
@onready var monsters_root: Node2D = $Playfield/Monsters
@onready var main_camera: Camera2D = $Playfield/MainCamera
@onready var back_btn: Button = $UI/TopBar/BackBtn
@onready var exit_game_btn: Button = $UI/TopBar/ExitGameBtn
@onready var combat_label: Label = $UI/TopBar/CombatLabel
@onready var nickname_label: Label = $UI/TopBar/NicknameLabel
@onready var online_label: Label = $UI/TopBar/OnlineLabel
@onready var hint_label: Label = $UI/TopBar/HintLabel
@onready var top_bar: Panel = $UI/TopBar
@onready var mobile_controls: CanvasLayer = $UI/MobileControls
@onready var npcs_root: Node2D = $Playfield/NPCs
@onready var world_chat: CanvasLayer = $UI/WorldChat
@onready var growth_btn: Button = $UI/TopBar/GrowthBtn
@onready var backpack_btn: Button = $UI/TopBar/BackpackBtn
@onready var shop_btn: Button = $UI/TopBar/ShopBtn
@onready var backpack_overlay: Control = $UI/BackpackOverlay
@onready var character_build_overlay: Control = $UI/CharacterBuildOverlay
@onready var weapon_shop_overlay: Control = $UI/WeaponShopOverlay
@onready var loot_drops_root: Node2D = $Playfield/LootDrops
@onready var decorations_root: Node2D = $Playfield/Decorations

@export var follow_smooth: float = 10.0
## 挥击特效；在编辑器中拖入你的 PackedScene 即可替换。根节点可选实现 play_melee(origin, facing_rad, did_hit)。
@export var melee_attack_fx_scene: PackedScene = preload("res://Scenes/MeleeAttackFX.tscn")
## 法师 AOE 序列帧（单套 `mage_aoe`）；换图只改 `MageSpellFX.tscn` 里 SpellAnim 的 SpriteFrames。
@export var mage_spell_fx_scene: PackedScene = MAGE_SPELL_FX_SCENE

@onready var combat_fx_root: Node2D = $Playfield/CombatFX
@onready var floating_feedback_root: Node2D = $Playfield/FloatingFeedback
@onready var map_overlay: Control = $UI/WorldMapOverlay
@onready var map_btn: Button = $UI/TopBar/MapBtn
@onready var hud_clock_label: Label = $UI/HudClock
@onready var time_weather: Node = $TimeWeather
@onready var radar_minimap: Control = $UI/RadarMinimap

var _local_player: CharacterBody2D
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
## 水塘/草坑等大件：互相保持间距，减少叠成一团；与 _spawn_deco_sprites(..., min_separation) 共用
var _deco_separation_anchors: Array[Vector2] = []

# 随机物/野怪与「无限大泥地地皮」解耦：地皮可很大，生成分布仍用原先稳定范围，避免一帧内上千 Node 未响应或难以见到
const WORLD_SPAWN_RECT := Rect2(-2100.0, -2100.0, 4200.0, 4200.0)
const DECO_STRATIFY_COLS := 18
const DECO_STRATIFY_ROWS := 18
## 出生点附近不放大件装饰，避免开局糊脸（坐标与 Player 默认 640,360 对齐）
const DECO_SPAWN_EXCLUDE_RADIUS := 200.0
const MONSTER_MAX_COUNT := 9
const MONSTER_RESPAWN_INTERVAL := 2.8
## 与刷怪用；全图均匀随机时少量怪几乎总在屏外
const MONSTER_SPAWN_MIN_DIST := 170.0
const MONSTER_SPAWN_MAX_RING := 720.0


func _ready() -> void:
	add_to_group("world_xp_sink")
	set_process_unhandled_input(true)
	PlayerInventory.clear()
	_apply_theme_to_ui()
	back_btn.pressed.connect(_on_back_clicked)
	exit_game_btn.pressed.connect(_on_exit_game_clicked)
	backpack_btn.pressed.connect(_on_backpack_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	growth_btn.pressed.connect(_on_growth_pressed)
	mobile_controls.move_input.connect(_on_mobile_move_input)
	mobile_controls.interact_pressed.connect(_on_mobile_interact_pressed)
	mobile_controls.attack_pressed.connect(_on_mobile_attack_pressed)
	mobile_controls.surge_pressed.connect(_on_skill_surge_requested)
	_load_user_data()
	_setup_chat()
	
	if _wn.is_cloud():
		_connect_cloud_signals()
		_bootstrap_cloud_players()
		push_warning("联机：不生成野怪、随机水塘/花草等，仅保留手摆物件与 NPC。")
	else:
		_spawn_offline_player()
		_bind_deco_textures()
		_spawn_monsters()
		_spawn_world_fluff()
		_combat_level = maxi(1, CharacterBuild.runtime_combat_level)
		_combat_xp_next = CharacterBuild.combat_xp_to_next_level(_combat_level)
	
	_spawn_npcs()
	if not CharacterBuild.build_changed.is_connected(_on_character_build_changed):
		CharacterBuild.build_changed.connect(_on_character_build_changed)
	_refresh_combat_ui()
	get_tree().root.size_changed.connect(_layout_world_top_bar)
	backpack_btn.visible = not _wn.is_cloud()
	growth_btn.visible = not _wn.is_cloud()
	shop_btn.visible = not _wn.is_cloud()
	if is_instance_valid(map_btn):
		map_btn.visible = true
		map_btn.pressed.connect(_on_map_btn_pressed)
		_style_header_action_btn(map_btn)
	if is_instance_valid(time_weather) and time_weather.has_method("bind_hud_clock"):
		time_weather.bind_hud_clock(hud_clock_label)
	if is_instance_valid(map_overlay) and map_overlay.has_method("setup"):
		map_overlay.setup(self)
	if is_instance_valid(radar_minimap) and radar_minimap.has_method("setup"):
		radar_minimap.setup(self)
	_layout_world_top_bar()


func _bind_deco_textures() -> void:
	_tex_pond = _DECO_POND
	_tex_rock = _DECO_ROCK
	_tex_flower = _DECO_FLOWER
	_tex_grass_pit = _DECO_GRASS_PIT
	_tex_grass = _DECO_GRASS


func apply_bonus_xp(amount: int) -> void:
	if _wn.is_cloud():
		return
	_grant_xp(maxi(1, amount))


func _on_backpack_pressed() -> void:
	if _wn.is_cloud():
		return
	if backpack_overlay.has_method("open_panel"):
		backpack_overlay.open_panel()


func _on_growth_pressed() -> void:
	if _wn.is_cloud():
		return
	GameAudio.ui_click()
	if character_build_overlay.has_method("open_panel"):
		character_build_overlay.open_panel()


func _on_shop_pressed() -> void:
	if _wn.is_cloud():
		return
	GameAudio.ui_click()
	if weapon_shop_overlay.has_method("open_panel"):
		weapon_shop_overlay.open_panel()


func _on_skill_surge_requested() -> void:
	if _wn.is_cloud():
		return
	if not _can_local_attack():
		return
	if CharacterBuild.activate_surge():
		GameAudio.ui_confirm()


func _spawn_world_fluff() -> void:
	if not is_instance_valid(decorations_root):
		return
	_deco_separation_anchors.clear()
	for c in decorations_root.get_children():
		if c.is_in_group("world_deco_auto"):
			c.queue_free()
	# 与「无限大地面」分条前的数量/范围一致，保证出生点周围可见
	_spawn_deco_sprites(_tex_pond, 6, 9, Vector2(0.16, 0.2), Vector2(0.24, 0.3), 0, 0.0, 0.0, false, 280.0)
	_spawn_deco_sprites(_tex_grass_pit, 6, 9, Vector2(0.2, 0.25), Vector2(0.3, 0.34), 0, 0.0, 0.0, false, 240.0)
	_spawn_deco_sprites(_tex_rock, 28, 42, Vector2(0.1, 0.13), Vector2(0.18, 0.2), 1, -8.0, 6.0, true, 0.0)
	_spawn_deco_sprites(_tex_flower, 28, 42, Vector2(0.14, 0.18), Vector2(0.22, 0.26), 1, -8.0, 6.0, true, 0.0)
	_spawn_deco_sprites(_tex_grass, 40, 58, Vector2(0.1, 0.14), Vector2(0.18, 0.22), 1, -6.0, 6.0, true, 0.0)
	_apply_decoration_depth()


func _apply_decoration_depth() -> void:
	if not is_instance_valid(decorations_root):
		return
	for c in decorations_root.get_children():
		if c is Sprite2D:
			var s: Sprite2D = c as Sprite2D
			s.z_as_relative = false
			## 自动生成装饰已在生成时写入深度，避免重复叠加
			if s.is_in_group("world_deco_auto"):
				continue
			## 手摆装饰按 y 深度排序；原 z_index 作为微调偏移
			s.z_index = int(floor(s.global_position.y)) + s.z_index


func _load_texture_safe(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = ResourceLoader.load(path)
	return res as Texture2D


func _spawn_deco_sprites(
	texture: Texture2D,
	min_count: int,
	max_count: int,
	scale_min: Vector2,
	scale_max: Vector2,
	z: int,
	offset_y_min: float,
	offset_y_max: float,
	stratify: bool = false,
	min_separation: float = 0.0
) -> void:
	if texture == null or not is_instance_valid(decorations_root):
		return
	var n: int = randi_range(min_count, max_count)
	for _i in n:
		var pos: Vector2
		if min_separation > 0.0:
			pos = _pick_deco_pos_separated(min_separation, stratify)
		elif stratify:
			pos = _random_world_pos_stratified()
		else:
			pos = _random_world_pos()
		var s := Sprite2D.new()
		s.texture = texture
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.centered = true
		s.z_as_relative = false
		s.z_index = z
		s.position = pos
		s.scale = Vector2(
			randf_range(scale_min.x, scale_max.x),
			randf_range(scale_min.y, scale_max.y)
		)
		s.offset = Vector2(0.0, randf_range(offset_y_min, offset_y_max))
		s.z_index = int(floor(s.global_position.y)) + z
		s.add_to_group("world_deco_auto")
		decorations_root.add_child(s)


func _deco_excluded_center() -> Vector2:
	if is_instance_valid(_local_player):
		return _local_player.global_position
	return Vector2(640.0, 360.0)


func _pick_deco_pos_separated(sep: float, stratify: bool) -> Vector2:
	var excl := _deco_excluded_center()
	var pos: Vector2
	for _t in 55:
		if stratify:
			pos = _random_world_pos_stratified()
		else:
			pos = _random_world_pos()
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
	# 兜底：仍不靠近出生点
	for _t2 in 20:
		pos = _random_world_pos()
		if pos.distance_to(excl) >= DECO_SPAWN_EXCLUDE_RADIUS * 0.5:
			_deco_separation_anchors.append(pos)
			return pos
	_deco_separation_anchors.append(_random_world_pos())
	return _deco_separation_anchors[_deco_separation_anchors.size() - 1]


func _random_world_pos() -> Vector2:
	var r := WORLD_SPAWN_RECT
	return Vector2(
		randf_range(r.position.x, r.position.x + r.size.x),
		randf_range(r.position.y, r.position.y + r.size.y)
	)


func _random_world_pos_stratified() -> Vector2:
	var r := WORLD_SPAWN_RECT
	var cw: float = r.size.x / float(DECO_STRATIFY_COLS)
	var ch: float = r.size.y / float(DECO_STRATIFY_ROWS)
	var cx: int = randi() % DECO_STRATIFY_COLS
	var cy: int = randi() % DECO_STRATIFY_ROWS
	return Vector2(
		r.position.x + (float(cx) + randf()) * cw,
		r.position.y + (float(cy) + randf()) * ch
	)


func _spawn_loot_drops(at: Vector2, reward_xp: int) -> void:
	if _wn.is_cloud():
		return
	var gel_n: int = 1 + randi() % 2
	for _i in gel_n:
		var inst: Node2D = LOOT_PICKUP_SCENE.instantiate() as Node2D
		loot_drops_root.add_child(inst)
		inst.global_position = at + Vector2(randf_range(-28.0, 28.0), randf_range(-20.0, 14.0))
		inst.set("item_id", "slime_gel")
		inst.set("display_name", "史莱姆凝胶")
		inst.set("amount", 1)
		inst.set("bonus_xp", 0)
	if randf() < 0.5:
		var xp_inst: Node2D = LOOT_PICKUP_SCENE.instantiate() as Node2D
		loot_drops_root.add_child(xp_inst)
		xp_inst.global_position = at + Vector2(randf_range(-18.0, 18.0), randf_range(-32.0, -8.0))
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
	if not _wn.is_cloud():
		CharacterBuild.set_runtime_combat_level(_combat_level)


func _spawn_npcs() -> void:
	var patrol_peach := _patrol_rect_loop(Vector2(380, 220), 85.0, 62.0)
	_spawn_one_npc(Vector2(380, 220), "店员小桃", "欢迎光临～今天推荐的是草莓牛奶蛋糕哦！", patrol_peach)
	var patrol_miffy := PackedVector2Array([
		Vector2(860, 300), Vector2(1010, 300), Vector2(1010, 420),
		Vector2(710, 420), Vector2(710, 300)
	])
	_spawn_one_npc(Vector2(860, 300), "旅人米菲", "世界好大呀……你也来散步吗？", patrol_miffy)
	_spawn_one_npc(Vector2(520, 480), "向导露露", "靠近 NPC 后点右下角「对话」或键盘 E。云端联机时头顶会显示各自身份昵称。")


func _patrol_rect_loop(center: Vector2, half_w: float, half_h: float) -> PackedVector2Array:
	var c: Vector2 = center
	return PackedVector2Array([
		c + Vector2(-half_w, -half_h),
		c + Vector2(half_w, -half_h),
		c + Vector2(half_w, half_h),
		c + Vector2(-half_w, half_h),
	])


func _spawn_one_npc(at: Vector2, display_name: String, message: String, patrol_world: PackedVector2Array = PackedVector2Array()) -> void:
	var n: Node2D = NPC_SCENE.instantiate() as Node2D
	n.position = at
	n.set("npc_display_name", display_name)
	n.set("dialog_message", message)
	if patrol_world.size() >= 2:
		n.set("patrol_waypoints_world", patrol_world)
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
	if not get_tree().get_nodes_in_group("world_map_open").is_empty():
		return
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
	_style_header_action_btn(growth_btn)
	_style_header_action_btn(backpack_btn)
	_style_header_action_btn(shop_btn)
	if _wn.is_cloud():
		hint_label.text = "云端房间「%s」· 头顶显示昵称 · 与好友约定同一房间名" % _wn.cloud_room
	else:
		hint_label.text = "WASD/摇杆 · 攻击随职业（剑/弓/法/牧）·「成长」切职业与锁定 · Q 强击 · M 地图"


func _style_header_action_btn(b: Button) -> void:
	if not is_instance_valid(b):
		return
	var d := 14
	b.add_theme_color_override("font_color", Color8(255, 255, 255))
	b.add_theme_color_override("font_outline_color", Color8(64, 28, 52))
	b.add_theme_constant_override("outline_size", 3)
	b.add_theme_stylebox_override("normal", _compact_pill_button_style(Color8(118, 44, 88), d))
	b.add_theme_stylebox_override("hover", _compact_pill_button_style(Color8(136, 58, 102), d))
	b.add_theme_stylebox_override("pressed", _compact_pill_button_style(Color8(96, 36, 72), d))


func _compact_pill_button_style(bg: Color, r: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
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
	if growth_btn.visible:
		_world_bar_place(growth_btn, x, y0, bag_w, btn_h)
		x = growth_btn.offset_right + g
	if backpack_btn.visible:
		_world_bar_place(backpack_btn, x, y0, bag_w, btn_h)
		x = backpack_btn.offset_right + g
	if shop_btn.visible:
		_world_bar_place(shop_btn, x, y0, bag_w, btn_h)
		x = shop_btn.offset_right + g
	if map_btn.visible:
		_world_bar_place(map_btn, x, y0, bag_w, btn_h)
		x = map_btn.offset_right + g
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
	growth_btn.add_theme_font_size_override("font_size", int(14 * fs))
	backpack_btn.add_theme_font_size_override("font_size", int(14 * fs))
	shop_btn.add_theme_font_size_override("font_size", int(14 * fs))
	map_btn.add_theme_font_size_override("font_size", int(14 * fs))


func _world_bar_place(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.offset_left = x
	c.offset_top = y
	c.offset_right = x + w
	c.offset_bottom = y + h


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_world_map"):
		if is_instance_valid(map_overlay) and map_overlay.has_method("toggle_map"):
			map_overlay.toggle_map()
		get_viewport().set_input_as_handled()


func _on_map_btn_pressed() -> void:
	GameAudio.ui_click()
	if is_instance_valid(map_overlay) and map_overlay.has_method("toggle_map"):
		map_overlay.toggle_map()


func _process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_monster_respawn_cd = maxf(0.0, _monster_respawn_cd - delta)
	if is_instance_valid(players_root):
		online_label.text = "在线: %d" % players_root.get_child_count()
	if is_instance_valid(_local_player) and is_instance_valid(main_camera):
		var t: float = clampf(follow_smooth * delta, 0.0, 1.0)
		main_camera.global_position = main_camera.global_position.lerp(_local_player.global_position, t)
	if not _wn.is_cloud() and _can_local_attack():
		if Input.is_action_just_pressed("attack"):
			_try_primary_attack()
		if Input.is_action_just_pressed("skill_surge"):
			_on_skill_surge_requested()
	if not _wn.is_cloud() and _monster_respawn_cd <= 0.01:
		_ensure_monster_population()
		_monster_respawn_cd = MONSTER_RESPAWN_INTERVAL


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
	## 生成在角色面前而不是身体中心，观感更像挥刀轨迹
	var dir: Vector2 = Vector2.from_angle(facing_rad).normalized()
	var spawn_pos: Vector2 = origin + dir * 56.0 + Vector2(0.0, -14.0)
	var inst := melee_attack_fx_scene.instantiate()
	combat_fx_root.add_child(inst)
	if inst.has_method("play_melee"):
		(inst as Object).call("play_melee", spawn_pos, facing_rad, did_hit)
	elif inst is Node2D:
		var n2: Node2D = inst as Node2D
		n2.global_position = spawn_pos
		n2.rotation = facing_rad + PI * 0.5


func _melee_visual_facing_rad(origin: Vector2, fallback_facing: float) -> float:
	## 优先朝向最近怪物；没有目标时保持角色当前朝向
	var nm: Node2D = _nearest_monster(origin, MELEE_RANGE * 1.6)
	if nm != null:
		var to_target: Vector2 = nm.global_position - origin
		if to_target.length_squared() > 4.0:
			return to_target.angle()
	return fallback_facing


func _on_character_build_changed() -> void:
	if _wn.is_cloud():
		return
	_refresh_combat_ui()


func _nearest_monster(origin: Vector2, max_dist: float) -> Node2D:
	var best: Node2D = null
	var best_d2: float = max_dist * max_dist
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node2D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m: Node2D = n as Node2D
		var d2: float = origin.distance_squared_to(m.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = m
	return best


func _first_monster_on_ray(origin: Vector2, dir: Vector2, max_range: float, half_width: float) -> Node2D:
	dir = dir.normalized()
	var best: Node2D = null
	var best_t: float = max_range + 1.0
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node2D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m: Node2D = n as Node2D
		var rel: Vector2 = m.global_position - origin
		var t: float = rel.dot(dir)
		if t < 6.0 or t > max_range:
			continue
		var closest: Vector2 = origin + dir * t
		if closest.distance_squared_to(m.global_position) > half_width * half_width:
			continue
		if t < best_t:
			best_t = t
			best = m
	return best


func _spawn_bow_line_fx(from: Vector2, to: Vector2, did_hit: bool) -> void:
	var ln := Line2D.new()
	ln.width = 5.5 if did_hit else 3.5
	ln.default_color = Color(0.92, 0.72, 0.38, 0.92) if did_hit else Color(0.75, 0.82, 0.95, 0.65)
	ln.points = PackedVector2Array([from, to])
	ln.z_index = 7
	combat_fx_root.add_child(ln)
	var tw := ln.create_tween()
	tw.tween_property(ln, "modulate:a", 0.0, 0.22).from(1.0)
	tw.finished.connect(ln.queue_free)


func _spawn_mage_aoe_fx(center: Vector2, radius: float) -> void:
	if mage_spell_fx_scene == null:
		return
	var spell_fx: Node = mage_spell_fx_scene.instantiate()
	combat_fx_root.add_child(spell_fx)
	if spell_fx.has_method("play_aoe"):
		spell_fx.play_aoe(center, radius)


func _perform_warrior_melee(origin: Vector2, dmg_mul: float) -> bool:
	var hit_any := false
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node2D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m: Node2D = n as Node2D
		if m.global_position.distance_to(origin) <= MELEE_RANGE:
			hit_any = true
			var dmg: int = int(round(float(_melee_damage()) * dmg_mul))
			n.take_damage(maxi(1, dmg))
	return hit_any


func _perform_archer_attack(origin: Vector2, facing_rad: float, dmg_mul: float) -> bool:
	var bow_r: float = CharacterBuild.bow_range()
	var dir: Vector2
	if CharacterBuild.ranged_auto_lock:
		var nm: Node2D = _nearest_monster(origin, bow_r)
		if nm != null:
			dir = (nm.global_position - origin).normalized()
		else:
			dir = Vector2.from_angle(facing_rad)
	else:
		dir = Vector2.from_angle(facing_rad)
	var tgt: Node2D = _first_monster_on_ray(origin, dir, bow_r, BOW_RAY_HALF_WIDTH)
	var to_pt: Vector2 = origin + dir * bow_r
	if tgt != null:
		var dist: float = origin.distance_to(tgt.global_position)
		to_pt = origin + dir * clampf(dist + 10.0, 48.0, bow_r)
		var dmg: int = int(round(float(_melee_damage()) * dmg_mul * 0.9))
		tgt.take_damage(maxi(1, dmg))
		_spawn_bow_line_fx(origin, to_pt, true)
		return true
	_spawn_bow_line_fx(origin, to_pt, false)
	return false


func _perform_mage_aoe(origin: Vector2, facing_rad: float, dmg_mul: float) -> bool:
	var center: Vector2
	if CharacterBuild.ranged_auto_lock:
		var nm: Node2D = _nearest_monster(origin, MAGE_LOCK_RANGE)
		if nm != null:
			center = nm.global_position
		else:
			center = origin + Vector2.from_angle(facing_rad) * 88.0
	else:
		center = origin + Vector2.from_angle(facing_rad) * 108.0
	var r: float = CharacterBuild.mage_aoe_radius()
	_spawn_mage_aoe_fx(center, r)
	var dmg_each: int = int(round(float(_melee_damage()) * dmg_mul * 0.52))
	var hit_any := false
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node2D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m: Node2D = n as Node2D
		if m.global_position.distance_to(center) <= r:
			hit_any = true
			n.take_damage(maxi(1, dmg_each))
	return hit_any


func _perform_priest_heal(dmg_mul: float) -> void:
	var gained: int = CharacterBuild.heal_priest_with_multiplier(_combat_level, dmg_mul)
	if is_instance_valid(_local_player):
		if gained > 0:
			_spawn_floating_feedback(
				_local_player.global_position + Vector2(0.0, -44.0),
				"+%d 生命" % gained,
				Color8(120, 255, 188),
				22,
				52.0
			)
		else:
			_spawn_floating_feedback(
				_local_player.global_position + Vector2(0.0, -40.0),
				"生命已满",
				Color8(180, 200, 220),
				18,
				40.0
			)


func _try_primary_attack() -> void:
	if _wn.is_cloud():
		return
	if _attack_cd > 0.0:
		return
	if not _can_local_attack():
		return
	var origin: Vector2 = _local_player.global_position
	var facing: float = _attack_facing_rad()
	var dmg_mul: float = CharacterBuild.consume_melee_damage_multiplier()
	var cls: int = CharacterBuild.get_combat_class()
	var hit_any := false
	match cls:
		CharacterBuild.CLASS_ARCHER:
			hit_any = _perform_archer_attack(origin, facing, dmg_mul)
		CharacterBuild.CLASS_MAGE:
			hit_any = _perform_mage_aoe(origin, facing, dmg_mul)
		CharacterBuild.CLASS_PRIEST:
			_perform_priest_heal(dmg_mul)
			hit_any = true
		_:
			hit_any = _perform_warrior_melee(origin, dmg_mul)
	if cls == CharacterBuild.CLASS_PRIEST:
		GameAudio.heal_chime()
	else:
		GameAudio.melee_swing()
		if hit_any:
			GameAudio.melee_hit()
	if cls == CharacterBuild.CLASS_WARRIOR:
		var fx_facing: float = _melee_visual_facing_rad(origin, facing)
		_spawn_melee_attack_fx(origin, fx_facing, hit_any)
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
		_combat_xp_next = CharacterBuild.combat_xp_to_next_level(_combat_level)
	_refresh_combat_ui()
	if _combat_level > prev_level:
		CharacterBuild.grant_points_for_levels(_combat_level - prev_level)
		GameAudio.level_up()
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
		if is_instance_valid(_local_player) and _local_player.has_method("set_level_exp_visible"):
			_local_player.set_level_exp_visible(false)
		return
	CharacterBuild.set_runtime_combat_level(_combat_level)
	combat_label.visible = true
	combat_label.text = "HP %d/%d" % [CharacterBuild.get_player_hp(), CharacterBuild.get_max_hp()]
	if is_instance_valid(_local_player) and _local_player.has_method("set_level_exp_caption"):
		_local_player.set_level_exp_caption("Lv.%d  %d/%d EXP" % [_combat_level, _combat_xp, _combat_xp_next])
		_local_player.set_level_exp_visible(true)


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
	GameAudio.monster_death()
	_grant_xp(reward_xp)
	if not _wn.is_cloud():
		GameAudio.xp_tick()
		_spawn_loot_drops(at_global, reward_xp)
		_spawn_floating_feedback(at_global, "+%d 经验" % reward_xp, Color8(118, 232, 168), 22, 58.0)
		_monster_respawn_cd = minf(_monster_respawn_cd, 1.2)


func _spawn_monsters() -> void:
	_spawn_monster_batch(MONSTER_MAX_COUNT)


func _ensure_monster_population() -> void:
	if not is_instance_valid(monsters_root) or not is_instance_valid(_local_player):
		return
	var alive: int = 0
	for c in monsters_root.get_children():
		if is_instance_valid(c):
			alive += 1
	if alive >= MONSTER_MAX_COUNT:
		return
	_spawn_monster_batch(mini(2, MONSTER_MAX_COUNT - alive))


func _spawn_monster_batch(count: int) -> void:
	if not is_instance_valid(_local_player):
		return
	for i in count:
		var pos := _random_monster_spawn_point()
		var mon = MONSTER_SCENE.instantiate()
		mon.max_hp = 28 + i * 6
		mon.reward_xp = maxi(5, 8 + (i % 4) * 3)
		mon.move_speed = 48.0 + float(i % 3) * 8.0
		mon.damaged.connect(_on_monster_damaged)
		mon.died.connect(_on_monster_died)
		monsters_root.add_child(mon)
		if mon is Node2D:
			(mon as Node2D).global_position = pos
		if mon.has_method("set_aggro_target"):
			mon.set_aggro_target(_local_player)


func _random_monster_spawn_point() -> Vector2:
	if not is_instance_valid(_local_player):
		return _random_world_pos()
	var p := _local_player.global_position
	var r: Rect2 = WORLD_SPAWN_RECT
	for _i in 32:
		var ang := randf() * TAU
		var d := randf_range(MONSTER_SPAWN_MIN_DIST, MONSTER_SPAWN_MAX_RING)
		var pos: Vector2 = p + Vector2(cos(ang), sin(ang)) * d
		if r.has_point(pos):
			return pos
	for _k in 20:
		var pos2 := _random_world_pos()
		if pos2.distance_to(p) >= MONSTER_SPAWN_MIN_DIST:
			return pos2
	return _random_world_pos()


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
