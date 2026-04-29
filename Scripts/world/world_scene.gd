extends Node2D

const NPC_SCENE := preload("res://Scenes/NPC.tscn")
const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const MONSTER_SCENE := preload("res://Scenes/Monster.tscn")
const DEMON_MONSTER_SCENE := preload("res://Scenes/DemonMonster.tscn")
const FLOATING_TEXT_SCENE := preload("res://Scenes/FloatingWorldText.tscn")
const LOOT_PICKUP_SCENE := preload("res://Scenes/LootPickup.tscn")
const UiTheme := preload("res://Scripts/meta/ui_theme.gd")
## 用 preload 避免部分环境下 ResourceLoader.exists/动态加载 对中文路径失败 → 全 null → 不生成
const _DECO_POND: Texture2D = preload("res://Assets/characters/水塘.png")
const _DECO_ROCK: Texture2D = preload("res://Assets/characters/石头.png")
const _DECO_FLOWER: Texture2D = preload("res://Assets/characters/花从.png")
const _DECO_GRASS_PIT: Texture2D = preload("res://Assets/characters/草坑.png")
const _DECO_GRASS: Texture2D = preload("res://Assets/characters/草从.png")

const MELEE_RANGE: float = 78.0
const BASE_MELEE_DAMAGE: int = 12
const MAGE_LOCK_RANGE: float = 248.0
const MAGE_SPELL_FX_SCENE := preload("res://Scenes/MageSpellFX.tscn")
const ARCHER_ARROW_SCENE := preload("res://Scenes/ArcherArrowProjectile.tscn")
const PRIEST_HEAL_FX_SCENE := preload("res://Scenes/PriestHealFX.tscn")
const PRIEST_HOLY_RAY_FX_SCENE := preload("res://Scenes/PriestHolyRayFX.tscn")
const WARRIOR_POWER_STRIKE_FX_SCENE := preload("res://Scenes/WarriorPowerStrikeFX.tscn")
const MAGE_MANA_BLAST_FX_SCENE := preload("res://Scenes/MageManaBlastFX.tscn")
const PRIEST_DIVINE_PRAYER_FX_SCENE := preload("res://Scenes/PriestDivinePrayerFX.tscn")

@onready var _wn: Node = get_node("/root/WorldNetwork")
@onready var playfield_root: Node2D = $Playfield
@onready var ground_node: Node = $Playfield/Ground
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
@onready var mobile_controls: Control = $UI/MobileControls
@onready var npcs_root: Node2D = $Playfield/NPCs
@onready var world_chat: Control = $UI/WorldChat
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
## 每只怪的独立伤害冷却，key = get_instance_id()，避免全局CD导致多怪卡顿
var _monster_hit_cd: Dictionary = {}
var _screen_damage_overlay: ColorRect = null
const MONSTER_CONTACT_RANGE: float = 58.0
const MONSTER_CONTACT_INTERVAL: float = 0.75
const MONSTER_CONTACT_DAMAGE_BASE: int = 6
## 头顶浮字偏移
const PLAYER_FLOAT_OVERHEAD := Vector2(0.0, -72.0)
var _tex_pond: Texture2D
var _tex_rock: Texture2D
var _tex_flower: Texture2D
var _tex_grass_pit: Texture2D
var _tex_grass: Texture2D
## 水塘/草坑等大件：互相保持间距，减少叠成一团；与 _spawn_deco_sprites(..., min_separation) 共用
var _deco_separation_anchors: Array[Vector2] = []
var _survivor_portal_prompt: bool = false
var _survivor_portal_area: Area2D = null
var _default_offline_hint: String = ""
var _portal_mobile_bubble_shown: bool = false
var _combat_hp_bar: ProgressBar = null
var _combat_hp_fill_style: StyleBoxFlat = null
var _damage_number_pool: Array[Node2D] = []
var _damage_pool_cursor: int = 0
var _boundary_fog_nodes: Array[CanvasItem] = []
var _boundary_fog_phase: float = 0.0

# 随机物/野怪与「无限大泥地地皮」解耦：地皮可很大，生成分布仍用原先稳定范围，避免一帧内上千 Node 未响应或难以见到
const WORLD_SPAWN_RECT := Rect2(-2100.0, -2100.0, 4200.0, 4200.0)
const DECO_STRATIFY_COLS := 18
const DECO_STRATIFY_ROWS := 18
## 单机默认出生点（与传送门拉开距离）；装饰避让中心与此对齐
const WORLD_OFFLINE_SPAWN := Vector2(420.0, 520.0)
## 出生点附近不放大件装饰，避免开局糊脸（坐标与 WORLD_OFFLINE_SPAWN 对齐）
const DECO_SPAWN_EXCLUDE_RADIUS := 200.0
const SURVIVOR_TRIAL_SCENE_PATH := "res://Scenes/SurvivorArena.tscn"
const _SURVIVOR_PORTAL_SCRIPT := preload("res://Scripts/world/survivor_portal.gd")
const MONSTER_MAX_COUNT := 20
const MONSTER_RESPAWN_INTERVAL := 2.8
## 与刷怪用；全图均匀随机时少量怪几乎总在屏外
const MONSTER_SPAWN_MIN_DIST := 170.0
const MONSTER_SPAWN_MAX_RING := 480.0
const WORLD_BOUNDARY_THICKNESS := 180.0
const DAMAGE_NUMBER_POOL_SIZE := 26
const WORLD_BOUNDARY_VISUAL_THICKNESS := 220.0


func _ready() -> void:
	GameAudio.play_bgm_world()
	add_to_group("world_scene")
	add_to_group("world_xp_sink")
	set_process_unhandled_input(true)
	PlayerInventory.clear()
	_apply_theme_to_ui()
	_setup_damage_overlay()
	_setup_world_boundaries()
	_setup_combat_hp_bar()
	_setup_damage_number_pool()
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
	if is_instance_valid(ground_node) and ground_node.has_method("configure_world_rect"):
		ground_node.call("configure_world_rect", WORLD_SPAWN_RECT)
	
	if _wn.is_cloud():
		_connect_cloud_signals()
		_bootstrap_cloud_players()
		push_warning("联机：不生成野怪、随机水塘/花草等，仅保留手摆物件与 NPC。")
	else:
		_combat_level = maxi(1, CharacterBuild.runtime_combat_level)
		_combat_xp = CharacterBuild.runtime_combat_xp
		_combat_xp_next = CharacterBuild.combat_xp_to_next_level(_combat_level)
		_spawn_offline_player()
		_bind_deco_textures()
		_spawn_monsters()
		_spawn_world_fluff()
	
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
	SceneTransition.fade_in()


func _bind_deco_textures() -> void:
	_tex_pond = _DECO_POND
	_tex_rock = _DECO_ROCK
	_tex_flower = _DECO_FLOWER
	_tex_grass_pit = _DECO_GRASS_PIT
	_tex_grass = _DECO_GRASS


func _setup_world_boundaries() -> void:
	if not is_instance_valid(playfield_root):
		return
	if playfield_root.has_node("WorldBoundaries"):
		return
	var root := Node2D.new()
	root.name = "WorldBoundaries"
	root.z_index = -99990
	root.z_as_relative = false
	playfield_root.add_child(root)
	var r := WORLD_SPAWN_RECT
	_add_boundary_body(root, Vector2(r.position.x - WORLD_BOUNDARY_THICKNESS * 0.5, r.position.y + r.size.y * 0.5), Vector2(WORLD_BOUNDARY_THICKNESS, r.size.y + WORLD_BOUNDARY_THICKNESS * 2.0))
	_add_boundary_body(root, Vector2(r.position.x + r.size.x + WORLD_BOUNDARY_THICKNESS * 0.5, r.position.y + r.size.y * 0.5), Vector2(WORLD_BOUNDARY_THICKNESS, r.size.y + WORLD_BOUNDARY_THICKNESS * 2.0))
	_add_boundary_body(root, Vector2(r.position.x + r.size.x * 0.5, r.position.y - WORLD_BOUNDARY_THICKNESS * 0.5), Vector2(r.size.x + WORLD_BOUNDARY_THICKNESS * 2.0, WORLD_BOUNDARY_THICKNESS))
	_add_boundary_body(root, Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y + WORLD_BOUNDARY_THICKNESS * 0.5), Vector2(r.size.x + WORLD_BOUNDARY_THICKNESS * 2.0, WORLD_BOUNDARY_THICKNESS))
	_setup_world_boundary_visual(root, r)


func _add_boundary_body(parent: Node2D, at: Vector2, size: Vector2) -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	sb.position = at
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	sb.add_child(cs)
	parent.add_child(sb)


func _setup_world_boundary_visual(parent: Node2D, r: Rect2) -> void:
	_boundary_fog_nodes.clear()
	_add_boundary_fog_strip(parent, Rect2(r.position.x - WORLD_BOUNDARY_VISUAL_THICKNESS, r.position.y - WORLD_BOUNDARY_VISUAL_THICKNESS, WORLD_BOUNDARY_VISUAL_THICKNESS, r.size.y + WORLD_BOUNDARY_VISUAL_THICKNESS * 2.0), Vector2.RIGHT)
	_add_boundary_fog_strip(parent, Rect2(r.position.x + r.size.x, r.position.y - WORLD_BOUNDARY_VISUAL_THICKNESS, WORLD_BOUNDARY_VISUAL_THICKNESS, r.size.y + WORLD_BOUNDARY_VISUAL_THICKNESS * 2.0), Vector2.LEFT)
	_add_boundary_fog_strip(parent, Rect2(r.position.x - WORLD_BOUNDARY_VISUAL_THICKNESS, r.position.y - WORLD_BOUNDARY_VISUAL_THICKNESS, r.size.x + WORLD_BOUNDARY_VISUAL_THICKNESS * 2.0, WORLD_BOUNDARY_VISUAL_THICKNESS), Vector2.DOWN)
	_add_boundary_fog_strip(parent, Rect2(r.position.x - WORLD_BOUNDARY_VISUAL_THICKNESS, r.position.y + r.size.y, r.size.x + WORLD_BOUNDARY_VISUAL_THICKNESS * 2.0, WORLD_BOUNDARY_VISUAL_THICKNESS), Vector2.UP)


func _add_boundary_fog_strip(parent: Node2D, rr: Rect2, inward: Vector2) -> void:
	var poly := Polygon2D.new()
	poly.z_as_relative = false
	poly.z_index = -99980
	poly.antialiased = true
	poly.polygon = PackedVector2Array([
		rr.position,
		Vector2(rr.position.x + rr.size.x, rr.position.y),
		rr.position + rr.size,
		Vector2(rr.position.x, rr.position.y + rr.size.y),
	])
	var c_outer := Color(0.62, 0.68, 0.82, 0.04)
	var c_inner := Color(0.78, 0.84, 0.95, 0.30)
	if inward == Vector2.RIGHT:
		poly.vertex_colors = PackedColorArray([c_outer, c_inner, c_inner, c_outer])
	elif inward == Vector2.LEFT:
		poly.vertex_colors = PackedColorArray([c_inner, c_outer, c_outer, c_inner])
	elif inward == Vector2.DOWN:
		poly.vertex_colors = PackedColorArray([c_outer, c_outer, c_inner, c_inner])
	else:
		poly.vertex_colors = PackedColorArray([c_inner, c_inner, c_outer, c_outer])
	parent.add_child(poly)
	_boundary_fog_nodes.append(poly)


func _setup_combat_hp_bar() -> void:
	if not is_instance_valid(top_bar) or is_instance_valid(_combat_hp_bar):
		return
	_combat_hp_bar = ProgressBar.new()
	_combat_hp_bar.name = "CombatHpBar"
	_combat_hp_bar.show_percentage = false
	_combat_hp_bar.min_value = 0.0
	_combat_hp_bar.max_value = 100.0
	_combat_hp_bar.value = 100.0
	_combat_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_hp_bar.z_index = 1
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.14, 0.10, 0.20, 0.88)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	bg.set_border_width_all(1)
	bg.border_color = Color(0.42, 0.30, 0.56, 0.8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.97, 0.35, 0.45, 0.95)
	fill.corner_radius_top_left = 7
	fill.corner_radius_top_right = 7
	fill.corner_radius_bottom_left = 7
	fill.corner_radius_bottom_right = 7
	_combat_hp_bar.add_theme_stylebox_override("background", bg)
	_combat_hp_bar.add_theme_stylebox_override("fill", fill)
	_combat_hp_fill_style = fill
	top_bar.add_child(_combat_hp_bar)


func _setup_damage_number_pool() -> void:
	if not is_instance_valid(floating_feedback_root) or not _damage_number_pool.is_empty():
		return
	for _i in DAMAGE_NUMBER_POOL_SIZE:
		var n := Node2D.new()
		n.visible = false
		n.z_as_relative = false
		n.z_index = 4000
		var lbl := Label.new()
		lbl.name = "Text"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(120, 40)
		lbl.position = Vector2(-60.0, -20.0)
		n.add_child(lbl)
		floating_feedback_root.add_child(n)
		_damage_number_pool.append(n)


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
		if is_instance_valid(_local_player):
			var cls: int = CharacterBuild.get_combat_class()
			match cls:
				CharacterBuild.CLASS_WARRIOR:
					_spawn_warrior_power_strike_fx(_local_player.global_position)
				CharacterBuild.CLASS_ARCHER:
					var dpa: int = maxi(1, int(round(float(_melee_damage()) * 0.9 * 0.13)))
					ArcherVolley.spawn_radial_volley(combat_fx_root, _local_player.global_position, dpa)
				CharacterBuild.CLASS_MAGE:
					_spawn_mage_mana_blast_fx(_local_player.global_position)
				CharacterBuild.CLASS_PRIEST:
					_spawn_priest_divine_prayer_fx(_local_player.global_position)
		GameAudio.ui_confirm()


func _spawn_world_fluff() -> void:
	if not is_instance_valid(decorations_root):
		return
	_deco_separation_anchors.clear()
	for c in decorations_root.get_children():
		if c.is_in_group("world_deco_auto"):
			c.queue_free()
	# 与「无限大地面」分条前的数量/范围一致，保证出生点周围可见
	## 水塘：y-sort（底部边缘基准）+ 碰撞体（玩家不能走进去）
	_spawn_deco_sprites(_tex_pond,      6,  9,  Vector2(0.16, 0.2),  Vector2(0.24, 0.3),  0, 0.0,  0.0,  false, 280.0, false, 0.42)
	## 草坑/坑洞：地面凹陷，不排序，永远在角色脚底下
	_spawn_deco_sprites(_tex_grass_pit, 6,  9,  Vector2(0.2,  0.25), Vector2(0.3,  0.34), 2, 0.0,  0.0,  false, 240.0, true,  0.0)
	## 立体装饰：y-sort 与角色产生前后关系
	_spawn_deco_sprites(_tex_rock,      28, 42, Vector2(0.1,  0.13), Vector2(0.18, 0.2),  1, -8.0, 6.0,  true,  0.0,   false, 0.0)
	_spawn_deco_sprites(_tex_flower,    28, 42, Vector2(0.14, 0.18), Vector2(0.22, 0.26), 1, -8.0, 6.0,  true,  0.0,   false, 0.0)
	_spawn_deco_sprites(_tex_grass,     40, 58, Vector2(0.1,  0.14), Vector2(0.18, 0.22), 1, -6.0, 6.0,  true,  0.0,   false, 0.0)
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
	min_separation: float = 0.0,
	floor_level: bool = false,
	collision_radius_frac: float = 0.0
) -> void:
	if texture == null or not is_instance_valid(decorations_root):
		return
	var n: int = randi_range(min_count, max_count)
	for _i in n:
		var pos: Vector2
		if min_separation > 0.0:
			pos = _pick_deco_pos_separated(min_separation, stratify)
		elif stratify:
			## 小件散布：最多尝试 30 次，跳过固定禁区
			var ok := false
			for _t in 30:
				pos = _random_world_pos_stratified()
				if not _is_deco_pos_near_fixed(pos):
					ok = true
					break
			if not ok:
				pos = _random_world_pos()
		else:
			pos = _random_world_pos()
		var s := Sprite2D.new()
		s.texture = texture
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.centered = true
		s.z_as_relative = false
		s.position = pos
		s.scale = Vector2(
			randf_range(scale_min.x, scale_max.x),
			randf_range(scale_min.y, scale_max.y)
		)
		s.offset = Vector2(0.0, randf_range(offset_y_min, offset_y_max))
		if floor_level:
			## 地面凹陷类（草坑/坑洞）：固定 z，永远在角色底层，视觉像地面纹理
			s.z_index = z
		else:
			## 立体装饰 / 水体（石头/花/草/水塘）：以底部边缘 y 做深度排序
			## 底部 = pos.y + 纹理半高 * scale_y；玩家走到底部以南才会在前面
			var bottom_y := pos.y + texture.get_height() * s.scale.y * 0.5
			s.z_index = int(floor(bottom_y)) + z
		s.add_to_group("world_deco_auto")
		decorations_root.add_child(s)
		## 水塘需要碰撞体，玩家无法直接走进水里
		if collision_radius_frac > 0.0:
			var body := StaticBody2D.new()
			body.collision_layer = 1
			body.collision_mask = 0
			body.z_index = -999
			body.position = pos
			var cshape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = texture.get_width() * s.scale.x * collision_radius_frac
			cshape.shape = circle
			body.add_child(cshape)
			decorations_root.add_child(body)


## 世界固定建筑/传送门的禁区列表：(中心坐标, 排除半径)
const _DECO_FIXED_EXCLUSIONS: Array = [
	## NPC 房屋（含视觉占地）
	[Vector2(1119.0, 404.0), 160.0],
	## Tree1
	[Vector2(420.0,  185.0),  80.0],
	## Tree2
	[Vector2(900.0,  320.0),  80.0],
	## 传送门
	[Vector2(728.0,  308.0), 110.0],
	## 玩家出生点
	[Vector2(420.0,  520.0), 200.0],
]


func _is_deco_pos_near_fixed(pos: Vector2) -> bool:
	for e in _DECO_FIXED_EXCLUSIONS:
		if pos.distance_to(e[0] as Vector2) < (e[1] as float):
			return true
	return false


func _deco_excluded_center() -> Vector2:
	if is_instance_valid(_local_player):
		return _local_player.global_position
	return WORLD_OFFLINE_SPAWN


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
		if _is_deco_pos_near_fixed(pos):
			continue
		var ok: bool = true
		for a: Vector2 in _deco_separation_anchors:
			if pos.distance_to(a) < sep:
				ok = false
				break
		if ok:
			_deco_separation_anchors.append(pos)
			return pos
	## 兜底：仍不靠近出生点
	for _t2 in 20:
		pos = _random_world_pos()
		if pos.distance_to(excl) >= DECO_SPAWN_EXCLUDE_RADIUS * 0.5 and not _is_deco_pos_near_fixed(pos):
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
	p.global_position = WORLD_OFFLINE_SPAWN
	players_root.add_child(p)
	p.reset_physics_interpolation()
	_local_player = p
	var uname := _saved_username()
	if uname.is_empty():
		uname = "萌酱"
	p.set_display_name(uname)
	main_camera.global_position = p.global_position
	main_camera.reset_physics_interpolation()
	
	world_chat.set_local_player(p)
	if not _wn.is_cloud():
		CharacterBuild.set_runtime_combat_progress(_combat_level, _combat_xp)


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
	if try_interact_survivor_portal():
		return
	if is_instance_valid(_local_player):
		_local_player.try_interact_nearby()


func set_survivor_portal_prompt(active: bool, portal_area: Area2D) -> void:
	if _wn.is_cloud():
		return
	_survivor_portal_prompt = active
	_survivor_portal_area = portal_area if active else null
	if not is_instance_valid(hint_label):
		return
	if active:
		var mobile_ui: bool = is_instance_valid(_local_player) and bool(_local_player.get("use_mobile_controls"))
		if mobile_ui:
			hint_label.text = "试炼传送门：点右下角「对话」确认进入"
			if not _portal_mobile_bubble_shown and is_instance_valid(portal_area):
				_portal_mobile_bubble_shown = true
				_spawn_floating_feedback(
					portal_area.global_position + Vector2(0.0, -58.0),
					"点「对话」进入试炼",
					Color8(200, 230, 255),
					18,
					42.0
				)
		else:
			hint_label.text = "试炼传送门：按 E 确认进入"
	else:
		_portal_mobile_bubble_shown = false
		if not _wn.is_cloud():
			hint_label.text = _default_offline_hint


func try_interact_survivor_portal() -> bool:
	if _wn.is_cloud() or not _survivor_portal_prompt:
		return false
	if not _SURVIVOR_PORTAL_SCRIPT.can_enter_trial():
		if is_instance_valid(_survivor_portal_area):
			_spawn_floating_feedback(
				_survivor_portal_area.global_position + Vector2(0.0, -48.0),
				"传送门冷却中…",
				Color8(255, 200, 160),
				17,
				36.0
			)
		GameAudio.ui_click()
		return true
	_SURVIVOR_PORTAL_SCRIPT.commit_trial_enter()
	GameAudio.ui_confirm()
	SceneTransition.transition_to(SURVIVOR_TRIAL_SCENE_PATH)
	return true


func _apply_theme_to_ui() -> void:
	## 顶栏面板 — 深色半透明 + 底部圆角
	top_bar.add_theme_stylebox_override("panel", UiTheme.modern_hud_bar_bottom_round())

	var theme_obj := Theme.new()
	theme_obj.set_stylebox("normal",  "Button", UiTheme.modern_primary_button_normal(20))
	theme_obj.set_stylebox("hover",   "Button", UiTheme.modern_primary_button_hover(20))
	theme_obj.set_stylebox("pressed", "Button", UiTheme.modern_primary_button_pressed(20))
	theme_obj.set_color("font_color", "Button", UiTheme.Colors.TEXT_LIGHT)
	theme_obj.set_color("font_color", "Label",  UiTheme.Colors.TEXT_MAIN)
	top_bar.theme = theme_obj

	nickname_label.add_theme_font_size_override("font_size", 20)
	nickname_label.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MAIN)

	online_label.add_theme_font_size_override("font_size", 18)
	online_label.add_theme_color_override("font_color", UiTheme.Colors.XP_GREEN)

	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MUTED)

	_style_header_action_btn(growth_btn)
	_style_header_action_btn(backpack_btn)
	_style_header_action_btn(shop_btn)
	if _wn.is_cloud():
		hint_label.text = "云端房间「%s」· 头顶显示昵称 · 与好友约定同一房间名" % _wn.cloud_room
	else:
		hint_label.text = "WASD/摇杆 · 攻击随职业（剑/弓/法/牧）·「成长」切职业与锁定 · Q 职业技能（随职业变化）· M 地图"
		_default_offline_hint = hint_label.text


func _style_header_action_btn(b: Button) -> void:
	if not is_instance_valid(b):
		return
	var d := 14
	b.add_theme_color_override("font_color", UiTheme.Colors.TEXT_LIGHT)
	b.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.1, 0.6))
	b.add_theme_constant_override("outline_size", 2)
	b.add_theme_stylebox_override("normal",  _compact_pill_button_style(Color(0.32, 0.18, 0.52, 0.82), d))
	b.add_theme_stylebox_override("hover",   _compact_pill_button_style(Color(0.50, 0.30, 0.72, 0.92), d))
	b.add_theme_stylebox_override("pressed", _compact_pill_button_style(Color(0.20, 0.10, 0.36, 0.90), d))


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
	if is_instance_valid(_combat_hp_bar):
		_combat_hp_bar.offset_left = combat_label.offset_left
		_combat_hp_bar.offset_right = combat_label.offset_right
		_combat_hp_bar.offset_top = combat_label.offset_bottom - 10.0
		_combat_hp_bar.offset_bottom = combat_label.offset_bottom - 2.0
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
	_boundary_fog_phase += delta
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_monster_respawn_cd = maxf(0.0, _monster_respawn_cd - delta)
	## 批量递减每只怪的独立伤害 CD
	for k in _monster_hit_cd.keys():
		_monster_hit_cd[k] = _monster_hit_cd[k] - delta
		if _monster_hit_cd[k] <= 0.0:
			_monster_hit_cd.erase(k)
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
	if not _wn.is_cloud():
		_check_monster_contact_damage()
	_update_boundary_fog_anim()


func _update_boundary_fog_anim() -> void:
	if _boundary_fog_nodes.is_empty():
		return
	var a := 0.22 + sin(_boundary_fog_phase * 1.35) * 0.04
	for n in _boundary_fog_nodes:
		if is_instance_valid(n):
			n.modulate.a = clampf(a, 0.14, 0.30)


func _check_monster_contact_damage() -> void:
	if not is_instance_valid(_local_player):
		return
	var ppos: Vector2 = _local_player.global_position
	var dmg_base: int = maxi(1, MONSTER_CONTACT_DAMAGE_BASE + _combat_level)
	var hit_any := false
	for m in monsters_root.get_children():
		if not m is Node2D:
			continue
		if not m.has_method("can_damage_player_on_contact"):
			continue
		if not (m as Object).call("can_damage_player_on_contact"):
			continue
		var m2d: Node2D = m as Node2D
		var dist := ppos.distance_to(m2d.global_position)
		if dist > MONSTER_CONTACT_RANGE:
			continue
		var mid: int = m.get_instance_id()
		var is_charging: bool = m.has_method("is_charge_attacking") and bool((m as Object).call("is_charge_attacking"))
		if not is_charging:
			## 非冲刺：玩家撞上去 → 把怪物推开，不扣血
			## 用独立 push CD 避免每帧都推（ID 偏移区分 push 与 damage CD）
			var push_key: int = mid + 10000000
			if _monster_hit_cd.get(push_key, 0.0) <= 0.0:
				var push_dir: Vector2 = m2d.global_position - ppos
				if push_dir.length_squared() > 0.01:
					m2d.global_position += push_dir.normalized() * 22.0
				_monster_hit_cd[push_key] = 0.12
			continue
		## ── 怪物主动冲刺：判定伤害 ──
		if _monster_hit_cd.get(mid, 0.0) > 0.0:
			continue
		var dmg: int = dmg_base + (randi() % 3)
		CharacterBuild.damage_player(dmg)
		_monster_hit_cd[mid] = MONSTER_CONTACT_INTERVAL
		hit_any = true
		var offset_x := randf_range(-20.0, 20.0)
		_spawn_inline_damage_number(
			ppos + PLAYER_FLOAT_OVERHEAD + Vector2(offset_x, 0.0),
			"-%d" % dmg,
			UiTheme.Colors.HP_RED, 28
		)
		var dir_to_player: Vector2 = ppos - m2d.global_position
		if m.has_method("play_attack_anim"):
			m.call("play_attack_anim", dir_to_player)
	if hit_any:
		_flash_damage_overlay()
		UiTheme.camera_shake(main_camera, 5.0, 0.16)
		if _local_player.has_method("play_hurt_animation"):
			_local_player.call("play_hurt_animation")
		_shake_combat_label()


## 屏幕红闪遮罩 — 受伤时最醒目的反馈
func _flash_damage_overlay() -> void:
	if not is_instance_valid(_screen_damage_overlay):
		return
	_screen_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.38)
	var tw := _screen_damage_overlay.create_tween()
	tw.tween_property(_screen_damage_overlay, "color", Color(1.0, 0.0, 0.0, 0.0), 0.45)


## 直接内联创建伤害数字 Label，不依赖 FloatingWorldText 场景
func _spawn_inline_damage_number(world_pos: Vector2, text: String, col: Color, size: int) -> void:
	if _damage_number_pool.is_empty():
		return
	var n: Node2D = _damage_number_pool[_damage_pool_cursor]
	_damage_pool_cursor = (_damage_pool_cursor + 1) % _damage_number_pool.size()
	if n.has_meta("tw"):
		var old_tw: Variant = n.get_meta("tw")
		if old_tw is Tween and (old_tw as Tween).is_valid():
			(old_tw as Tween).kill()
	n.global_position = world_pos + Vector2(randf_range(-14.0, 14.0), 0.0)
	n.visible = true
	var lbl := n.get_node("Text") as Label
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.0, 0.05, 1.0))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.modulate.a = 1.0
	var start_y := n.global_position.y
	var tw := n.create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(n, "global_position:y", start_y - 60.0, 0.85)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.38)
	tw.finished.connect(func() -> void:
		if is_instance_valid(n):
			n.visible = false
	, CONNECT_ONE_SHOT)
	n.set_meta("tw", tw)


## 初始化受伤屏幕红闪 CanvasLayer 遮罩
func _setup_damage_overlay() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 50
	add_child(cl)
	_screen_damage_overlay = ColorRect.new()
	_screen_damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
	_screen_damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_screen_damage_overlay)


func _shake_combat_label() -> void:
	if not is_instance_valid(combat_label):
		return
	combat_label.add_theme_color_override("font_color", UiTheme.Colors.HP_RED)
	var orig := combat_label.position
	var tw := combat_label.create_tween()
	tw.tween_property(combat_label, "position", orig + Vector2(5, 0), 0.04)
	tw.tween_property(combat_label, "position", orig - Vector2(4, 0), 0.04)
	tw.tween_property(combat_label, "position", orig, 0.05)
	tw.tween_callback(func() -> void:
		if is_instance_valid(combat_label):
			combat_label.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MAIN)
	).set_delay(0.3)


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


func _spawn_mage_aoe_fx(center: Vector2, radius: float) -> void:
	if mage_spell_fx_scene == null:
		return
	var spell_fx: Node = mage_spell_fx_scene.instantiate()
	combat_fx_root.add_child(spell_fx)
	if spell_fx.has_method("play_aoe"):
		spell_fx.play_aoe(center, radius)


func _spawn_warrior_power_strike_fx(world_pos: Vector2) -> void:
	if WARRIOR_POWER_STRIKE_FX_SCENE == null:
		return
	var fx: Node = WARRIOR_POWER_STRIKE_FX_SCENE.instantiate()
	combat_fx_root.add_child(fx)
	if fx.has_method("play_power_strike"):
		fx.play_power_strike(world_pos)


func _spawn_mage_mana_blast_fx(world_pos: Vector2) -> void:
	if MAGE_MANA_BLAST_FX_SCENE == null:
		return
	var fx: Node = MAGE_MANA_BLAST_FX_SCENE.instantiate()
	combat_fx_root.add_child(fx)
	if fx.has_method("play_mana_blast"):
		fx.play_mana_blast(world_pos)


func _spawn_priest_divine_prayer_fx(world_pos: Vector2) -> void:
	if PRIEST_DIVINE_PRAYER_FX_SCENE == null:
		return
	var fx: Node = PRIEST_DIVINE_PRAYER_FX_SCENE.instantiate()
	combat_fx_root.add_child(fx)
	if fx.has_method("play_divine_prayer"):
		fx.play_divine_prayer(world_pos)


func _spawn_priest_heal_fx(world_pos: Vector2) -> void:
	if PRIEST_HEAL_FX_SCENE == null:
		return
	var heal_fx: Node = PRIEST_HEAL_FX_SCENE.instantiate()
	combat_fx_root.add_child(heal_fx)
	if heal_fx.has_method("play_heal"):
		heal_fx.play_heal(world_pos)


func _spawn_priest_holy_ray_fx(origin: Vector2, angle: float) -> void:
	if PRIEST_HOLY_RAY_FX_SCENE == null:
		return
	var ray_fx: Node = PRIEST_HOLY_RAY_FX_SCENE.instantiate()
	combat_fx_root.add_child(ray_fx)
	if ray_fx.has_method("play_holy_ray"):
		ray_fx.play_holy_ray(origin, angle)


func _perform_priest_attack(origin: Vector2, facing: float, dmg_mul: float) -> bool:
	_spawn_priest_holy_ray_fx(origin, facing)
	var dmg: int = int(round(float(_melee_damage()) * dmg_mul * 0.75))
	AttackRangeFx.spawn_mage_hit_ring(combat_fx_root, origin + Vector2.from_angle(facing) * 85.0, 48.0)
	var hit_any := false
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node2D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m: Node2D = n as Node2D
		var target_pos := origin + Vector2.from_angle(facing) * 85.0
		if m.global_position.distance_to(target_pos) <= 48.0:
			hit_any = true
			n.take_damage(maxi(1, dmg))
	return hit_any


func _perform_warrior_melee(origin: Vector2, dmg_mul: float) -> bool:
	AttackRangeFx.spawn_melee_ring(combat_fx_root, origin, MELEE_RANGE)
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
	var dir: Vector2
	if CharacterBuild.ranged_auto_lock:
		var nm: Node2D = _nearest_monster(origin, CharacterBuild.archer_auto_lock_search_radius())
		if nm != null:
			dir = (nm.global_position - origin).normalized()
		else:
			dir = Vector2.from_angle(facing_rad)
	else:
		dir = Vector2.from_angle(facing_rad)
	var dmg: int = int(round(float(_melee_damage()) * dmg_mul * 0.9))
	var arrow: Node = ARCHER_ARROW_SCENE.instantiate()
	arrow.call("configure", origin, dir, maxi(1, dmg))
	combat_fx_root.add_child(arrow)
	## 订阅命中信号：箭矢飞行命中怪物时触发相机震动（与近战命中体验对齐）
	if arrow.has_signal("hit_monster"):
		arrow.hit_monster.connect(_on_archer_arrow_hit.bind(), CONNECT_ONE_SHOT)
	return false


func _on_archer_arrow_hit(_at_pos: Vector2) -> void:
	UiTheme.camera_shake(main_camera, 3.0, 0.09)


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
	AttackRangeFx.spawn_mage_hit_ring(combat_fx_root, center, r)
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
		_spawn_priest_heal_fx(_local_player.global_position)
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
			hit_any = _perform_priest_attack(origin, facing, dmg_mul)
		_:
			hit_any = _perform_warrior_melee(origin, dmg_mul)

	## 攻击动画：立即触发，无论是否命中
	if is_instance_valid(_local_player) and _local_player.has_method("play_attack_animation"):
		_local_player.call("play_attack_animation", Vector2.from_angle(facing))

	if cls == CharacterBuild.CLASS_PRIEST:
		GameAudio.heal_chime()
	else:
		GameAudio.melee_swing()
		if hit_any:
			GameAudio.melee_hit()
			## 命中时轻微屏幕震动（增强打击感）
			UiTheme.camera_shake(main_camera, 3.5, 0.10)
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
		if is_instance_valid(_combat_hp_bar):
			_combat_hp_bar.visible = false
		if is_instance_valid(_local_player) and _local_player.has_method("set_level_exp_visible"):
			_local_player.set_level_exp_visible(false)
		if is_instance_valid(_local_player) and _local_player.has_method("set_overhead_hp"):
			_local_player.call("set_overhead_hp", 0, 1, false)
		return
	CharacterBuild.set_runtime_combat_progress(_combat_level, _combat_xp)
	combat_label.visible = true
	var hp_now: int = CharacterBuild.get_player_hp()
	var hp_max: int = maxi(1, CharacterBuild.get_max_hp())
	combat_label.text = "HP %d/%d" % [hp_now, hp_max]
	if is_instance_valid(_combat_hp_bar):
		_combat_hp_bar.visible = true
		_combat_hp_bar.max_value = float(hp_max)
		_combat_hp_bar.value = float(hp_now)
		var ratio := float(hp_now) / float(hp_max)
		if is_instance_valid(_combat_hp_fill_style):
			_combat_hp_fill_style.bg_color = Color(0.97, 0.35, 0.45, 0.95).lerp(Color(0.35, 0.89, 0.50, 0.95), ratio)
	if is_instance_valid(_local_player) and _local_player.has_method("set_level_exp_progress"):
		_local_player.set_level_exp_progress(_combat_level, _combat_xp, _combat_xp_next)
	elif is_instance_valid(_local_player) and _local_player.has_method("set_level_exp_caption"):
		_local_player.set_level_exp_caption("Lv.%d  %d/%d EXP" % [_combat_level, _combat_xp, _combat_xp_next])
	if is_instance_valid(_local_player) and _local_player.has_method("set_level_exp_visible"):
		_local_player.set_level_exp_visible(true)
	if is_instance_valid(_local_player) and _local_player.has_method("set_overhead_hp"):
		_local_player.call("set_overhead_hp", hp_now, hp_max, true)


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
	## 暴击 / 重击（伤害高于平均）使用更大字号、金色文字
	var is_heavy := actual_damage >= 30
	var dmg_color := UiTheme.Colors.GOLD if is_heavy else Color8(255, 210, 100)
	var size := 28 if is_heavy else 21
	var rise := 62.0 if is_heavy else 46.0
	_spawn_floating_feedback(at_global, str(actual_damage), dmg_color, size, rise)


func _on_monster_died(reward_xp: int, at_global: Vector2) -> void:
	GameAudio.monster_death()
	_grant_xp(reward_xp)
	if not _wn.is_cloud():
		GameAudio.xp_tick()
		_spawn_loot_drops(at_global, reward_xp)
		_spawn_floating_feedback(at_global, "+%d 经验" % reward_xp, UiTheme.Colors.XP_GREEN, 22, 58.0)
		_monster_respawn_cd = minf(_monster_respawn_cd, 1.2)
		## 怪物击杀时额外震动强调
		UiTheme.camera_shake(main_camera, 6.0, 0.14)


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
		var mon_scene: PackedScene
		var max_hp_override: int
		var reward_override: int
		var speed_override: float
		if randf() < 0.3:
			mon_scene = DEMON_MONSTER_SCENE
			max_hp_override = 45 + i * 10
			reward_override = maxi(10, 18 + (i % 4) * 5)
			speed_override = 58.0 + float(i % 3) * 12.0
		else:
			mon_scene = MONSTER_SCENE
			max_hp_override = 28 + i * 6
			reward_override = maxi(5, 8 + (i % 4) * 3)
			speed_override = 48.0 + float(i % 3) * 8.0
		var mon = mon_scene.instantiate()
		mon.max_hp = max_hp_override
		mon.reward_xp = reward_override
		mon.move_speed = speed_override
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
	_show_exit_confirm(
		"退出游戏",
		"确定要退出游戏吗？",
		func() -> void:
			if _wn.is_cloud():
				_wn.leave_session()
			get_tree().quit()
	)


func _on_back_clicked() -> void:
	_show_exit_confirm(
		"返回大厅",
		"确定要返回大厅吗？",
		func() -> void:
			if _wn.is_cloud():
				_wn.leave_session()
			SceneTransition.transition_to("res://Scenes/ui/HallScene.tscn")
	)


## 通用确认弹窗：confirm_callback 在用户点「确定」后执行。
func _show_exit_confirm(title: String, body: String, confirm_callback: Callable) -> void:
	GameAudio.ui_click()
	var cl := CanvasLayer.new()
	cl.layer = 80
	add_child(cl)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.52)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	cl.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.13, 0.09, 0.20, 0.97)
	ps.corner_radius_top_left = 20
	ps.corner_radius_top_right = 20
	ps.corner_radius_bottom_left = 20
	ps.corner_radius_bottom_right = 20
	ps.border_color = Color(0.50, 0.30, 0.72, 0.85)
	ps.set_border_width_all(2)
	ps.content_margin_left = 32
	ps.content_margin_right = 32
	ps.content_margin_top = 28
	ps.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", ps)
	panel.custom_minimum_size = Vector2(320, 0)
	cl.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.96))
	vbox.add_child(title_lbl)

	var body_lbl := Label.new()
	body_lbl.text = body
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 15)
	body_lbl.add_theme_color_override("font_color", Color(0.85, 0.80, 0.90, 0.90))
	vbox.add_child(body_lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var cancel_btn := Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(110, 44)
	cancel_btn.focus_mode = Control.FOCUS_NONE
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.28, 0.22, 0.38, 0.90)
	cs.corner_radius_top_left = 14
	cs.corner_radius_top_right = 14
	cs.corner_radius_bottom_left = 14
	cs.corner_radius_bottom_right = 14
	cancel_btn.add_theme_stylebox_override("normal", cs)
	cancel_btn.add_theme_stylebox_override("hover", cs)
	cancel_btn.add_theme_stylebox_override("pressed", cs)
	cancel_btn.add_theme_color_override("font_color", Color.WHITE)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	hbox.add_child(cancel_btn)

	var ok_btn := Button.new()
	ok_btn.text = "确定"
	ok_btn.custom_minimum_size = Vector2(110, 44)
	ok_btn.focus_mode = Control.FOCUS_NONE
	var os := StyleBoxFlat.new()
	os.bg_color = Color(0.72, 0.22, 0.30, 0.95)
	os.corner_radius_top_left = 14
	os.corner_radius_top_right = 14
	os.corner_radius_bottom_left = 14
	os.corner_radius_bottom_right = 14
	ok_btn.add_theme_stylebox_override("normal", os)
	ok_btn.add_theme_stylebox_override("hover", os)
	ok_btn.add_theme_stylebox_override("pressed", os)
	ok_btn.add_theme_color_override("font_color", Color.WHITE)
	ok_btn.add_theme_font_size_override("font_size", 16)
	hbox.add_child(ok_btn)

	cancel_btn.pressed.connect(func() -> void:
		GameAudio.ui_click()
		cl.queue_free()
	)
	ok_btn.pressed.connect(func() -> void:
		GameAudio.ui_confirm()
		cl.queue_free()
		confirm_callback.call()
	)


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
	SceneTransition.transition_to("res://Scenes/ui/HallScene.tscn")


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
	p.reset_physics_interpolation()
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
