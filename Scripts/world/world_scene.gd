extends Node2D

const NPC_SCENE := preload("res://Scenes/actors/NPC.tscn")
const PLAYER_SCENE := preload("res://Scenes/actors/Player.tscn")
const MONSTER_SCENE := preload("res://Scenes/actors/Monster.tscn")
const DEMON_MONSTER_SCENE := preload("res://Scenes/actors/DemonMonster.tscn")
const SPITTER_MONSTER_SCENE := preload("res://Scenes/actors/SpitterMonster.tscn")
const BRUTE_MONSTER_SCENE := preload("res://Scenes/actors/BruteMonster.tscn")
const SLIME_GREEN_SCENE := preload("res://Scenes/actors/monsters/SlimeGreen.tscn")
const SLIME_RED_SCENE := preload("res://Scenes/actors/monsters/SlimeRed.tscn")
const SLIME_BROWN_SCENE := preload("res://Scenes/actors/monsters/SlimeBrown.tscn")
const SLIME_BLUE_SCENE := preload("res://Scenes/actors/monsters/SlimeBlue.tscn")
const GOBLIN_SCENE := preload("res://Scenes/actors/monsters/GoblinMonster.tscn")
const BAT_SCENE := preload("res://Scenes/actors/monsters/BatMonster.tscn")
const RAT_SCENE := preload("res://Scenes/actors/monsters/RatMonster.tscn")
const GOBLIN_ARCHER_SCENE := preload("res://Scenes/actors/monsters/GoblinArcher.tscn")
const GOBLIN_MAGE_SCENE := preload("res://Scenes/actors/monsters/GoblinMage.tscn")
const NEUTRAL_CREATURE_SCENE := preload("res://Scenes/actors/NeutralCreature.tscn")
const FLOATING_TEXT_SCENE := preload("res://Scenes/fx/FloatingWorldText.tscn")
const LOOT_PICKUP_MATERIAL_SCENE := preload("res://Scenes/decor/drops/LootPickupMaterial.tscn")
const LOOT_PICKUP_CURRENCY_SCENE := preload("res://Scenes/decor/drops/LootPickupCurrency.tscn")
const GAMEPLAY_PAUSE_MENU_SCRIPT := preload("res://Scripts/ui/gameplay_pause_menu.gd")
const UiTheme := preload("res://Scripts/meta/ui_theme.gd")
## 用 preload 避免部分环境下 ResourceLoader.exists/动态加载 对中文路径失败 → 全 null → 不生成
const _DECO_POND: Texture2D = preload("res://Assets/characters/floor_decorations/水塘.png")
const _DECO_ROCK: Texture2D = preload("res://Assets/characters/floor_decorations/石头.png")
const _DECO_FLOWER: Texture2D = preload("res://Assets/characters/floor_decorations/花从.png")
const _DECO_GRASS_PIT: Texture2D = preload("res://Assets/characters/floor_decorations/草坑.png")
const _DECO_GRASS: Texture2D = preload("res://Assets/characters/floor_decorations/草从.png")
const _TOPBAR_ICON_SIZE := 32
const _ICON_GROWTH_PATH := "res://Assets/ui/icons/topbar_growth.svg"
const _ICON_BACKPACK_PATH := "res://Assets/ui/backpack.png"
const _ICON_SHOP_PATH := "res://Assets/ui/icons/topbar_shop.svg"
const _ICON_MAP_PATH := "res://Assets/ui/icons/topbar_map.svg"
const _NPC_TEX_BLUE_MALE: Texture2D = preload("res://Assets/npc/蓝色男性npc.png")
const _NPC_TEX_BROWN_MALE: Texture2D = preload("res://Assets/npc/褐色男性npc.png")
const _NPC_TEX_RED_MALE: Texture2D = preload("res://Assets/npc/红色男性npc.png")
const _NPC_TEX_STUDENT_MALE: Texture2D = preload("res://Assets/npc/学生头男性npc.png")
const _NPC_TEX_ORANGE_FEMALE: Texture2D = preload("res://Assets/npc/橘色女性npc.png")
const _NPC_TEX_SHERIFF_MALE: Texture2D = preload("res://Assets/npc/治安官男性npc.png")
const _NPC_TEX_REDHAIR_FEMALE: Texture2D = preload("res://Assets/npc/红发女性npc.png")
const _NPC_TEX_YELLOW_MALE: Texture2D = preload("res://Assets/npc/黄色男性npc.png")

const MELEE_RANGE: float = 78.0
const BASE_MELEE_DAMAGE: int = 12
const MAGE_LOCK_RANGE: float = 248.0
const MAGE_SPELL_FX_SCENE := preload("res://Scenes/fx/MageSpellFX.tscn")
const ARCHER_ARROW_SCENE := preload("res://Scenes/projectiles/ArcherArrowProjectile.tscn")
const PRIEST_HEAL_FX_SCENE := preload("res://Scenes/fx/PriestHealFX.tscn")
const PRIEST_HOLY_RAY_FX_SCENE := preload("res://Scenes/fx/PriestHolyRayFX.tscn")
const WARRIOR_POWER_STRIKE_FX_SCENE := preload("res://Scenes/fx/WarriorPowerStrikeFX.tscn")
const MAGE_MANA_BLAST_FX_SCENE := preload("res://Scenes/fx/MageManaBlastFX.tscn")
const PRIEST_DIVINE_PRAYER_FX_SCENE := preload("res://Scenes/fx/PriestDivinePrayerFX.tscn")
const HALL_SCENE := "res://Scenes/ui/HallScene.tscn"
const TRIAL_SCENE := "res://Scenes/maps/trial/SurvivorArena.tscn"
const ZONE_PLAZA_SCENE := preload("res://Scenes/maps/zones/ZonePlaza.tscn")
const ZONE_EAST_MARKET_SCENE := preload("res://Scenes/maps/zones/ZoneEastMarket.tscn")
const ZONE_SOUTH_TRAIL_SCENE := preload("res://Scenes/maps/zones/ZoneSouthTrail.tscn")
const ZONE_PLAZA_PATH := "res://Scenes/maps/zones/ZonePlaza.tscn"
const ZONE_EAST_MARKET_PATH := "res://Scenes/maps/zones/ZoneEastMarket.tscn"
const ZONE_SOUTH_TRAIL_PATH := "res://Scenes/maps/zones/ZoneSouthTrail.tscn"
const WORLD_CAMERA_ZOOM := Vector2(1.0, 1.0)
const WORLD_VISUAL_RECT := Rect2(-2200.0, -1200.0, 5200.0, 3200.0)

@onready var _wn: Node = get_node("/root/WorldNetwork")
@onready var _scene_router: Node = get_node_or_null("/root/SceneRouter")
@onready var playfield_root: Node2D = $Playfield
@onready var ground_node: Node = $Playfield/Ground
@onready var players_root: Node2D = $Playfield/Players
@onready var monsters_root: Node2D = $Playfield/Monsters
@onready var regions_root: Node2D = $Playfield/Regions
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
@export var melee_attack_fx_scene: PackedScene = preload("res://Scenes/fx/MeleeAttackFX.tscn")
## 法师 AOE 序列帧（单套 `mage_aoe`）；换图只改 `MageSpellFX.tscn` 里 SpellAnim 的 SpriteFrames。
@export var mage_spell_fx_scene: PackedScene = MAGE_SPELL_FX_SCENE

@onready var combat_fx_root: Node2D = $Playfield/CombatFX
@onready var floating_feedback_root: Node2D = $Playfield/FloatingFeedback
@onready var map_overlay: Control = $UI/WorldMapOverlay
@onready var map_btn: Button = $UI/TopBar/MapBtn
@onready var hud_clock_label: Label = $UI/HudClock
@onready var time_weather: Node = $TimeWeather
@onready var radar_minimap: Control = $UI/RadarMinimap
@onready var ui_root: CanvasLayer = $UI

var _local_player: CharacterBody2D
var _local_player_name: String = "萌酱"
var _attack_cd: float = 0.0
var _skill_arc_cd: float = 0.0
var _skill_lance_cd: float = 0.0
var _combat_level: int = 1
var _combat_xp: int = 0
var _combat_xp_next: int = 50
var _monster_respawn_cd: float = 0.0
## 每只怪的独立伤害冷却，key = get_instance_id()，避免全局CD导致多怪卡顿
var _monster_hit_cd: Dictionary = {}
var _screen_damage_overlay: ColorRect = null
const MONSTER_CONTACT_RANGE: float = 58.0
const MONSTER_CONTACT_RANGE_SQ: float = MONSTER_CONTACT_RANGE * MONSTER_CONTACT_RANGE
const MONSTER_CONTACT_INTERVAL: float = 0.75
const MONSTER_CONTACT_DAMAGE_BASE: int = 6
const MONSTER_SPECIAL_ATTACK_INTERVAL: float = 0.72
const ECOLOGY_TICK_INTERVAL: float = 1.15
const SKILL_ARC_COOLDOWN: float = 6.0
const SKILL_LANCE_COOLDOWN: float = 9.0
const SKILL_ARC_RADIUS: float = 134.0
const SKILL_LANCE_LENGTH: float = 252.0
const SKILL_LANCE_WIDTH: float = 44.0
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
var _map_region_label: Label = null
var _missing_ui_icon_warned: Dictionary = {}
var _combat_hp_fill_style: StyleBoxFlat = null
var _damage_number_pool: Array[Node2D] = []
var _damage_pool_cursor: int = 0
var _boundary_fog_nodes: Array[CanvasItem] = []
var _boundary_fog_phase: float = 0.0
var _online_label_refresh_cd: float = 0.0
var _pc_mouse_attack_queued: bool = false
var _last_online_count: int = -1
var _pc_pause_menu: CanvasLayer = null
var _world_defeat_handled: bool = false
var _world_defeat_layer: CanvasLayer = null
var _neutral_root: Node2D = null
var _ecology_tick_cd: float = 0.0
var _neutral_respawn_cd: float = 0.0
var _kill_combo_count: int = 0
var _kill_total_count: int = 0
var _kill_combo_timer: float = 0.0
const KILL_COMBO_WINDOW: float = 3.4
var _combo_break_hint_timer: float = 0.0
var _combo_hud: PanelContainer = null
var _combo_grade_label: Label = null
var _combo_count_label: Label = null
var _combo_total_label: Label = null
var _combo_break_label: Label = null
var _combo_bar: ProgressBar = null
var _combo_ui_tween: Tween = null
var _codex_btn: Button = null
var _codex_overlay: CanvasLayer = null
var _region_stream_cd: float = 0.0
var _region_entries: Array[Dictionary] = []
var _loaded_regions: Dictionary = {}
var _region_transition_layer: CanvasLayer = null
var _region_transition_dim: ColorRect = null
var _region_transition_label: Label = null
var _region_transition_tween: Tween = null
var _last_stream_region_id: String = ""
var _current_region_id: String = ""
var _map_neighbors: Dictionary = {}

# 固定分区后仍保留足够外圈空间，避免“几步跑完地图”的体感。
const WORLD_SPAWN_RECT := Rect2(-520.0, -140.0, 2320.0, 1520.0)
const DECO_STRATIFY_COLS := 18
const DECO_STRATIFY_ROWS := 18
## 单机默认出生点（与传送门拉开距离）；装饰避让中心与此对齐
const WORLD_OFFLINE_SPAWN := Vector2(420.0, 520.0)
## 出生点附近不放大件装饰，避免开局糊脸（坐标与 WORLD_OFFLINE_SPAWN 对齐）
const DECO_SPAWN_EXCLUDE_RADIUS := 200.0
const SURVIVOR_TRIAL_SCENE_PATH := TRIAL_SCENE
const _SURVIVOR_PORTAL_SCRIPT := preload("res://Scripts/world/survivor_portal.gd")
const MONSTER_MAX_COUNT := 14
const MONSTER_RESPAWN_INTERVAL := 2.8
const NEUTRAL_MAX_COUNT := 6
const NEUTRAL_RESPAWN_INTERVAL := 4.8
## 与刷怪用；中尺寸世界使用中等环半径，保证怪物在可追击范围且不贴脸。
const MONSTER_SPAWN_MIN_DIST := 180.0
const MONSTER_SPAWN_MAX_RING := 460.0
const MONSTER_SPAWN_SEPARATION := 128.0
const NEUTRAL_SPAWN_MIN_DIST_FROM_PLAYER := 280.0
const ECOLOGY_ENGAGE_DISTANCE := 320.0
const WORLD_BOUNDARY_THICKNESS := 180.0
const DAMAGE_NUMBER_POOL_SIZE := 26
const WORLD_BOUNDARY_VISUAL_THICKNESS := 220.0
const ENABLE_WORLD_BOUNDARY_BLOCK := false
const REGION_STREAM_TICK_SEC := 0.35
const REGION_PRELOAD_DISTANCE := 520.0
const REGION_ACTIVATE_DISTANCE := 360.0
const REGION_UNLOAD_DISTANCE := 920.0
const REGION_NEIGHBORS := {
	"plaza": ["east_market", "south_trail"],
	"east_market": ["plaza"],
	"south_trail": ["plaza"],
}
const REGION_FALLBACK_EXITS := {
	"plaza": {"left": "south_trail", "right": "east_market"},
	"east_market": {"left": "plaza"},
	"south_trail": {"right": "plaza"},
}
const REGION_STRICT_SINGLE_ACTIVE := true
const REGION_EDGE_PRELOAD_MARGIN := 26.0
const REGION_MAP_SIZES := {
	"plaza": Vector2(340.0, 220.0),
	"east_market": Vector2(280.0, 210.0),
	"south_trail": Vector2(480.0, 200.0),
}
const REGION_MAP_TITLES := {
	"plaza": "传送广场",
	"east_market": "东市商街",
	"south_trail": "南郊野径",
}
const REGION_MAP_COLORS := {
	"plaza": Color(1.0, 0.72, 0.82, 0.5),
	"east_market": Color(0.7, 0.88, 1.0, 0.45),
	"south_trail": Color(0.75, 1.0, 0.78, 0.42),
}


func _ready() -> void:
	GameAudio.play_bgm_world()
	add_to_group("world_scene")
	add_to_group("world_xp_sink")
	set_process_unhandled_input(true)
	if _wn.is_cloud():
		PlayerInventory.clear()
	else:
		if not PlayerInventory.consume_preserve_once():
			PlayerInventory.clear()
	_apply_theme_to_ui()
	_setup_damage_overlay()
	if ENABLE_WORLD_BOUNDARY_BLOCK:
		_setup_world_boundaries()
	_setup_region_transition_fx()
	_setup_combat_hp_bar()
	_setup_damage_number_pool()
	_setup_combo_hud()
	_setup_pc_pause_menu()
	if is_instance_valid(main_camera):
		main_camera.zoom = WORLD_CAMERA_ZOOM
	back_btn.pressed.connect(_on_back_clicked)
	exit_game_btn.pressed.connect(_on_exit_game_clicked)
	back_btn.visible = false
	exit_game_btn.visible = false
	backpack_btn.pressed.connect(_on_backpack_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	growth_btn.pressed.connect(_on_growth_pressed)
	mobile_controls.move_input.connect(_on_mobile_move_input)
	mobile_controls.interact_pressed.connect(_on_mobile_interact_pressed)
	mobile_controls.attack_pressed.connect(_on_mobile_attack_pressed)
	mobile_controls.surge_pressed.connect(_on_skill_surge_requested)
	if mobile_controls.has_signal("menu_pressed"):
		mobile_controls.connect("menu_pressed", Callable(self, "_on_mobile_menu_pressed"))
	if mobile_controls.has_signal("dodge_pressed"):
		mobile_controls.connect("dodge_pressed", Callable(self, "_on_mobile_dodge_pressed"))
	if mobile_controls.has_signal("skill1_pressed"):
		mobile_controls.connect("skill1_pressed", Callable(self, "_on_mobile_skill1_pressed"))
	if mobile_controls.has_signal("skill2_pressed"):
		mobile_controls.connect("skill2_pressed", Callable(self, "_on_mobile_skill2_pressed"))
	_load_user_data()
	_setup_chat()
	_connect_quest_signals()
	if is_instance_valid(ground_node) and ground_node.has_method("configure_world_rect"):
		ground_node.call("configure_world_rect", WORLD_VISUAL_RECT)
	
	if _wn.is_cloud():
		_connect_cloud_signals()
		_bootstrap_cloud_players()
		push_warning("联机：不生成野怪、随机水塘/花草等，仅保留手摆物件与 NPC。")
	else:
		_combat_level = maxi(1, CharacterBuild.runtime_combat_level)
		_combat_xp = CharacterBuild.runtime_combat_xp
		_combat_xp_next = CharacterBuild.combat_xp_to_next_level(_combat_level)
		_spawn_offline_player()
		_ensure_neutral_root()
		_spawn_monsters()
		_spawn_neutral_creatures(NEUTRAL_MAX_COUNT)
		# 固定摆放模式：装饰统一放到各 Zone*.tscn 的 Decorations，不再运行时随机散布。
	_init_region_streaming()
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
	_setup_codex_button()
	if is_instance_valid(time_weather) and time_weather.has_method("bind_hud_clock"):
		time_weather.bind_hud_clock(hud_clock_label)
	if is_instance_valid(map_overlay) and map_overlay.has_method("setup"):
		map_overlay.setup(self)
		if map_overlay.has_signal("map_opened"):
			map_overlay.connect("map_opened", Callable(self, "_on_world_map_opened"))
		if map_overlay.has_signal("map_closed"):
			map_overlay.connect("map_closed", Callable(self, "_on_world_map_closed"))
	if is_instance_valid(radar_minimap) and radar_minimap.has_method("setup"):
		radar_minimap.setup(self)
	_layout_world_top_bar()
	SceneTransition.fade_in()


func _exit_tree() -> void:
	_disconnect_quest_signals()
	if CharacterBuild.build_changed.is_connected(_on_character_build_changed):
		CharacterBuild.build_changed.disconnect(_on_character_build_changed)
	_disconnect_cloud_signals()
	if _wn.cloud_chat_received.is_connected(_on_cloud_chat_received):
		_wn.cloud_chat_received.disconnect(_on_cloud_chat_received)
	var root: Window = get_tree().root
	if root != null and root.size_changed.is_connected(_layout_world_top_bar):
		root.size_changed.disconnect(_layout_world_top_bar)


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
	## 避免低于 CanvasItem Z 最小值导致告警刷屏。
	root.z_index = -4090
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
	poly.z_index = -4080
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


func _setup_region_transition_fx() -> void:
	if is_instance_valid(_region_transition_layer):
		return
	_region_transition_layer = CanvasLayer.new()
	_region_transition_layer.layer = 42
	add_child(_region_transition_layer)
	_region_transition_dim = ColorRect.new()
	_region_transition_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_region_transition_dim.color = Color(0.72, 0.82, 0.95, 0.0)
	_region_transition_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_region_transition_layer.add_child(_region_transition_dim)
	_region_transition_label = Label.new()
	_region_transition_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_region_transition_label.offset_top = 94.0
	_region_transition_label.offset_bottom = 132.0
	_region_transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_region_transition_label.add_theme_font_size_override("font_size", 22)
	_region_transition_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 0.95))
	_region_transition_label.add_theme_color_override("font_outline_color", Color(0.16, 0.20, 0.28, 0.82))
	_region_transition_label.add_theme_constant_override("outline_size", 4)
	_region_transition_label.modulate.a = 0.0
	_region_transition_layer.add_child(_region_transition_label)


func _play_region_transition_fx(title: String) -> void:
	if not is_instance_valid(_region_transition_dim):
		return
	if is_instance_valid(_region_transition_tween):
		_region_transition_tween.kill()
	if is_instance_valid(_region_transition_label):
		_region_transition_label.text = title
	_region_transition_tween = create_tween().set_parallel(true)
	_region_transition_tween.tween_property(_region_transition_dim, "color:a", 0.14, 0.16)
	_region_transition_tween.tween_property(_region_transition_dim, "color:a", 0.0, 0.34).set_delay(0.16)
	if is_instance_valid(_region_transition_label):
		_region_transition_tween.tween_property(_region_transition_label, "modulate:a", 1.0, 0.14)
		_region_transition_tween.tween_property(_region_transition_label, "modulate:a", 0.0, 0.28).set_delay(0.16)


func _init_region_streaming() -> void:
	if not is_instance_valid(regions_root):
		return
	_region_entries = [
		{"id": "plaza", "scene": ZONE_PLAZA_SCENE, "path": ZONE_PLAZA_PATH, "position": Vector2.ZERO},
		{"id": "east_market", "scene": ZONE_EAST_MARKET_SCENE, "path": ZONE_EAST_MARKET_PATH, "position": Vector2.ZERO},
		{"id": "south_trail", "scene": ZONE_SOUTH_TRAIL_SCENE, "path": ZONE_SOUTH_TRAIL_PATH, "position": Vector2.ZERO},
	]
	if is_instance_valid(_scene_router):
		_scene_router.call("register_map_scenes", _region_entries)
		for entry in _region_entries:
			_scene_router.call("preload_map_scene", str(entry.get("id", "")))
	for c in regions_root.get_children():
		c.queue_free()
	_loaded_regions.clear()
	_map_neighbors.clear()
	_last_stream_region_id = ""
	_current_region_id = "plaza"
	_refresh_current_region_label()
	if not is_instance_valid(_local_player):
		var first_entry: Dictionary = _find_region_entry_by_id(_current_region_id)
		if first_entry.is_empty():
			first_entry = _region_entries[0]
		_load_region_entry(first_entry, true)
		return
	_tick_region_streaming()


func _tick_region_streaming() -> void:
	if not is_instance_valid(regions_root):
		return
	if not is_instance_valid(_local_player):
		return
	var ppos: Vector2 = _local_player.global_position
	if REGION_STRICT_SINGLE_ACTIVE:
		var current_id: String = _resolve_current_region_id(ppos)
		if current_id.is_empty():
			return
		_current_region_id = current_id
		if not _loaded_regions.has(current_id):
			var centry: Dictionary = _find_region_entry_by_id(current_id)
			if not centry.is_empty():
				_load_region_entry(centry, true)
		_set_region_state(current_id, "visible", false)
		var keep: Dictionary = {current_id: true}
		var rr: Rect2 = _region_rect_by_id(current_id)
		var near_dir: String = _edge_direction_near(ppos, rr, REGION_EDGE_PRELOAD_MARGIN)
		if not near_dir.is_empty():
			var nid: String = _neighbor_region_from_gate(current_id, near_dir)
			if not nid.is_empty():
				var nentry: Dictionary = _find_region_entry_by_id(nid)
				if not nentry.is_empty() and not _loaded_regions.has(nid):
					_load_region_entry(nentry, false)
				keep[nid] = true
		var unload_ids: Array[String] = []
		for id_any in _loaded_regions.keys():
			var id: String = str(id_any)
			if keep.has(id):
				continue
			unload_ids.append(id)
		for id in unload_ids:
			_unload_region_entry(id)
		return
	for entry in _region_entries:
		var id: String = str(entry["id"])
		var center: Vector2 = entry["position"]
		var dist: float = center.distance_to(ppos)
		var loaded: bool = _loaded_regions.has(id)
		if not loaded and dist <= REGION_PRELOAD_DISTANCE:
			_load_region_entry(entry, false)
			loaded = true
		if not loaded:
			continue
		var row: Dictionary = _loaded_regions[id] as Dictionary
		var state: String = str(row.get("state", "preloaded"))
		if state == "preloaded" and dist <= REGION_ACTIVATE_DISTANCE:
			_set_region_state(id, "visible", true)
		elif dist > REGION_UNLOAD_DISTANCE:
			_unload_region_entry(id)
	# 相邻区域链式加载：当前可见区会带上邻区，避免走到边缘看到黑块。
	var visible_ids: PackedStringArray = PackedStringArray()
	for id_any in _loaded_regions.keys():
		var id: String = str(id_any)
		var row_any: Variant = _loaded_regions.get(id, {})
		if not (row_any is Dictionary):
			continue
		var row: Dictionary = row_any as Dictionary
		if str(row.get("state", "preloaded")) == "visible":
			visible_ids.append(id)
	for id in visible_ids:
		var ns: Variant = REGION_NEIGHBORS.get(id, [])
		if not (ns is Array):
			continue
		for nid_any in ns as Array:
			var nid: String = str(nid_any)
			if not _loaded_regions.has(nid):
				var nentry: Dictionary = _find_region_entry_by_id(nid)
				if not nentry.is_empty():
					_load_region_entry(nentry, false)
			if _loaded_regions.has(nid):
				_set_region_state(nid, "visible", false)
	if _loaded_regions.is_empty():
		var nearest: Dictionary = _nearest_region_entry(ppos)
		if not nearest.is_empty():
			_load_region_entry(nearest, true)


func _find_region_entry_by_id(id: String) -> Dictionary:
	for entry in _region_entries:
		if str(entry.get("id", "")) == id:
			return entry
	return {}


func _bind_region_map_contract(region_id: String, zone_node: Node2D) -> void:
	if not is_instance_valid(zone_node):
		return
	var meta: Node = zone_node.get_node_or_null("MapMeta")
	if is_instance_valid(meta):
		var mapped_id: String = str(meta.get("map_id"))
		var neighbors: Dictionary = meta.get("neighbors") as Dictionary
		if not mapped_id.is_empty():
			_map_neighbors[mapped_id] = neighbors
		elif not region_id.is_empty():
			_map_neighbors[region_id] = neighbors
	var exits_root: Node = zone_node.get_node_or_null("GateExits")
	if not is_instance_valid(exits_root):
		return
	for c in exits_root.get_children():
		if not c.has_signal("gate_entered"):
			continue
		var cb := Callable(self, "_on_region_gate_entered").bind(region_id)
		if not c.is_connected("gate_entered", cb):
			c.connect("gate_entered", cb)


func _build_region_blend_flags(id: String) -> Dictionary:
	var out := {"left": false, "right": false, "top": false, "bottom": false}
	var src: Dictionary = _find_region_entry_by_id(id)
	if src.is_empty():
		return out
	var center: Vector2 = src.get("position", Vector2.ZERO)
	var ns: Variant = REGION_NEIGHBORS.get(id, [])
	if not (ns is Array):
		return out
	for nid_any in ns as Array:
		var nid: String = str(nid_any)
		var dst: Dictionary = _find_region_entry_by_id(nid)
		if dst.is_empty():
			continue
		var dc: Vector2 = dst.get("position", Vector2.ZERO) - center
		if absf(dc.x) >= absf(dc.y):
			if dc.x > 0.0:
				out["right"] = true
			else:
				out["left"] = true
		else:
			if dc.y > 0.0:
				out["bottom"] = true
			else:
				out["top"] = true
	return out


func _region_rect_by_id(id: String) -> Rect2:
	var entry: Dictionary = _find_region_entry_by_id(id)
	if entry.is_empty():
		return Rect2()
	var center: Vector2 = entry.get("position", Vector2.ZERO)
	var size: Vector2 = REGION_MAP_SIZES.get(id, Vector2(320.0, 220.0))
	return Rect2(center - size * 0.5, size)


func _edge_direction_near(ppos: Vector2, rr: Rect2, margin: float) -> String:
	if rr.size.x <= 0.0 or rr.size.y <= 0.0:
		return ""
	if ppos.x <= rr.position.x + margin:
		return "left"
	if ppos.x >= rr.position.x + rr.size.x - margin:
		return "right"
	if ppos.y <= rr.position.y + margin:
		return "top"
	if ppos.y >= rr.position.y + rr.size.y - margin:
		return "bottom"
	return ""


func _opposite_dir(dir: String) -> String:
	if dir == "left":
		return "right"
	if dir == "right":
		return "left"
	if dir == "top":
		return "bottom"
	if dir == "bottom":
		return "top"
	return ""


func _region_spawn_global(region_id: String, spawn_name: String) -> Vector2:
	if not _loaded_regions.has(region_id):
		return Vector2.INF
	var row_any: Variant = _loaded_regions.get(region_id, {})
	if not (row_any is Dictionary):
		return Vector2.INF
	var row: Dictionary = row_any as Dictionary
	var zone: Node2D = row.get("node") as Node2D
	if not is_instance_valid(zone):
		return Vector2.INF
	var marker: Marker2D = zone.get_node_or_null("EntrySpawns/%s" % spawn_name) as Marker2D
	if marker == null:
		return Vector2.INF
	return marker.global_position


func _neighbor_region_in_direction(id: String, dir: String) -> String:
	var src_entry: Dictionary = _find_region_entry_by_id(id)
	if src_entry.is_empty():
		return ""
	var src_center: Vector2 = src_entry.get("position", Vector2.ZERO)
	var ns: Variant = REGION_NEIGHBORS.get(id, [])
	if not (ns is Array):
		return ""
	var best_id: String = ""
	var best_score: float = -INF
	for nid_any in ns as Array:
		var nid: String = str(nid_any)
		var dst_entry: Dictionary = _find_region_entry_by_id(nid)
		if dst_entry.is_empty():
			continue
		var delta: Vector2 = dst_entry.get("position", Vector2.ZERO) - src_center
		var score: float = -INF
		if dir == "left":
			score = -delta.x if delta.x < 0.0 else -INF
		elif dir == "right":
			score = delta.x if delta.x > 0.0 else -INF
		elif dir == "top":
			score = -delta.y if delta.y < 0.0 else -INF
		elif dir == "bottom":
			score = delta.y if delta.y > 0.0 else -INF
		if score > best_score:
			best_score = score
			best_id = nid
	return best_id


func _neighbor_region_from_gate(id: String, exit_dir: String) -> String:
	var row_neighbors: Dictionary = _map_neighbors.get(id, {}) as Dictionary
	var from_meta: String = str(row_neighbors.get(exit_dir, ""))
	if not from_meta.is_empty():
		return from_meta
	return _neighbor_region_in_direction(id, exit_dir)


func _on_region_gate_entered(exit_dir: String, body: Node2D, region_id: String) -> void:
	if not REGION_STRICT_SINGLE_ACTIVE:
		return
	if not is_instance_valid(body) or body != _local_player:
		return
	if region_id != _current_region_id:
		return
	var to_id: String = _neighbor_region_from_gate(region_id, exit_dir)
	if to_id.is_empty():
		return
	var entry_dir: String = ""
	if is_instance_valid(_scene_router) and _scene_router.has_method("opposite_dir"):
		entry_dir = str(_scene_router.call("opposite_dir", exit_dir))
	if entry_dir.is_empty():
		entry_dir = _opposite_dir(exit_dir)
	_switch_to_region(region_id, to_id, entry_dir)


func _switch_to_region(from_id: String, to_id: String, entry_dir: String) -> void:
	if to_id.is_empty() or to_id == from_id:
		return
	if is_instance_valid(_scene_router):
		_scene_router.call("preload_map_scene", to_id)
		if not bool(_scene_router.call("begin_map_switch", from_id, to_id, entry_dir)):
			return
	if SceneTransition.has_method("fade_out_only"):
		await SceneTransition.fade_out_only(0.16)
	var entry: Dictionary = _find_region_entry_by_id(to_id)
	if entry.is_empty():
		if is_instance_valid(_scene_router):
			_scene_router.call("finish_map_switch", from_id, to_id, entry_dir)
		SceneTransition.fade_in(0.18)
		return
	if not _loaded_regions.has(to_id):
		_load_region_entry(entry, false)
	_set_region_state(to_id, "visible", true)
	var spawn: Vector2 = _region_spawn_global(to_id, "spawn_%s" % entry_dir)
	if spawn == Vector2.INF:
		spawn = _local_player.global_position
	_local_player.global_position = spawn
	_current_region_id = to_id
	if _wn.is_cloud():
		_wn.send_cloud_move(spawn)
	if is_instance_valid(main_camera):
		main_camera.global_position = spawn
	for id_any in _loaded_regions.keys().duplicate():
		var id: String = str(id_any)
		if id == to_id:
			continue
		_unload_region_entry(id)
	var row_any: Variant = _loaded_regions.get(to_id, {})
	if row_any is Dictionary:
		_show_stream_region_hint(to_id, row_any as Dictionary)
	SceneTransition.fade_in(0.20)
	if is_instance_valid(_scene_router):
		_scene_router.call("finish_map_switch", from_id, to_id, entry_dir)


func _resolve_current_region_id(ppos: Vector2) -> String:
	if REGION_STRICT_SINGLE_ACTIVE:
		if not _current_region_id.is_empty():
			return _current_region_id
		return "plaza"
	if not _current_region_id.is_empty():
		var keep_rect: Rect2 = _region_rect_by_id(_current_region_id)
		if keep_rect.size.x > 0.0 and keep_rect.has_point(ppos):
			return _current_region_id
	for entry in _region_entries:
		var id: String = str(entry.get("id", ""))
		var rr: Rect2 = _region_rect_by_id(id)
		if rr.size.x > 0.0 and rr.has_point(ppos):
			return id
	var nearest: Dictionary = _nearest_region_entry(ppos)
	return str(nearest.get("id", ""))


func get_world_map_bounds() -> Rect2:
	if REGION_STRICT_SINGLE_ACTIVE:
		var zones: Array[Dictionary] = get_world_map_zones()
		if zones.is_empty():
			return WORLD_SPAWN_RECT
		var first: bool = true
		var bounds := Rect2()
		for z in zones:
			var rr: Rect2 = z.get("r", Rect2()) as Rect2
			if rr.size.x <= 0.0 or rr.size.y <= 0.0:
				continue
			if first:
				bounds = rr
				first = false
			else:
				bounds = bounds.merge(rr)
		return bounds.grow(120.0)
	if _region_entries.is_empty():
		return WORLD_SPAWN_RECT
	var first: bool = true
	var bounds := Rect2()
	for entry in _region_entries:
		var id: String = str(entry.get("id", ""))
		var center: Vector2 = entry.get("position", Vector2.ZERO)
		var size: Vector2 = REGION_MAP_SIZES.get(id, Vector2(320.0, 220.0))
		var rr := Rect2(center - size * 0.5, size)
		if first:
			bounds = rr
			first = false
		else:
			bounds = bounds.merge(rr)
	return bounds.grow(220.0)


func get_world_map_zones() -> Array[Dictionary]:
	if REGION_STRICT_SINGLE_ACTIVE:
		var out_single: Array[Dictionary] = []
		var current_id: String = _current_region_id
		if current_id.is_empty():
			current_id = "plaza"
		var current_size: Vector2 = REGION_MAP_SIZES.get(current_id, Vector2(320.0, 220.0))
		var current_rect := Rect2(-current_size * 0.5, current_size)
		out_single.append({
			"r": current_rect,
			"c": REGION_MAP_COLORS.get(current_id, Color(1.0, 1.0, 1.0, 0.45)),
			"n": str(REGION_MAP_TITLES.get(current_id, current_id)),
		})
		var exits_any: Variant = _map_neighbors.get(current_id, REGION_FALLBACK_EXITS.get(current_id, {}))
		if exits_any is Dictionary:
			var exits: Dictionary = exits_any as Dictionary
			for dir_any in exits.keys():
				var dir: String = str(dir_any)
				var nid: String = str(exits.get(dir, ""))
				if nid.is_empty():
					continue
				var nsize: Vector2 = REGION_MAP_SIZES.get(nid, Vector2(320.0, 220.0))
				var nrect := Rect2(Vector2.ZERO, nsize)
				if dir == "left":
					nrect.position = Vector2(current_rect.position.x - nsize.x, current_rect.get_center().y - nsize.y * 0.5)
				elif dir == "right":
					nrect.position = Vector2(current_rect.end.x, current_rect.get_center().y - nsize.y * 0.5)
				elif dir == "top":
					nrect.position = Vector2(current_rect.get_center().x - nsize.x * 0.5, current_rect.position.y - nsize.y)
				elif dir == "bottom":
					nrect.position = Vector2(current_rect.get_center().x - nsize.x * 0.5, current_rect.end.y)
				else:
					continue
				out_single.append({
					"r": nrect,
					"c": REGION_MAP_COLORS.get(nid, Color(1.0, 1.0, 1.0, 0.30)),
					"n": str(REGION_MAP_TITLES.get(nid, nid)),
				})
		return out_single
	var out: Array[Dictionary] = []
	for entry in _region_entries:
		var id: String = str(entry.get("id", ""))
		var center: Vector2 = entry.get("position", Vector2.ZERO)
		var size: Vector2 = REGION_MAP_SIZES.get(id, Vector2(320.0, 220.0))
		out.append({
			"r": Rect2(center - size * 0.5, size),
			"c": REGION_MAP_COLORS.get(id, Color(1.0, 1.0, 1.0, 0.4)),
			"n": str(REGION_MAP_TITLES.get(id, id)),
		})
	return out


func get_current_map_id() -> String:
	if _current_region_id.is_empty():
		return "plaza"
	return _current_region_id


func _nearest_region_entry(ppos: Vector2) -> Dictionary:
	var nearest: Dictionary = {}
	var best: float = INF
	for entry in _region_entries:
		var center: Vector2 = entry["position"]
		var d2: float = center.distance_squared_to(ppos)
		if d2 < best:
			best = d2
			nearest = entry
	return nearest


func _load_region_entry(entry: Dictionary, visible_immediately: bool) -> void:
	if not is_instance_valid(regions_root):
		return
	var id: String = str(entry["id"])
	if _loaded_regions.has(id):
		return
	var scene: PackedScene = null
	if is_instance_valid(_scene_router):
		scene = _scene_router.call("preload_map_scene", id) as PackedScene
	if scene == null:
		scene = entry["scene"] as PackedScene
	if scene == null:
		return
	var inst: Node = scene.instantiate()
	if not (inst is Node2D):
		return
	var node: Node2D = inst as Node2D
	node.position = Vector2.ZERO if REGION_STRICT_SINGLE_ACTIVE else entry["position"]
	node.name = "Region_%s" % id
	node.modulate.a = 1.0 if visible_immediately else 0.0
	if node is Area2D:
		(node as Area2D).monitoring = visible_immediately
	regions_root.add_child(node)
	if node.has_method("configure_zone_ground_extent"):
		node.call("configure_zone_ground_extent", WORLD_VISUAL_RECT.size)
	if node.has_method("configure_zone_ground_blend"):
		node.call("configure_zone_ground_blend", _build_region_blend_flags(id))
	_bind_region_map_contract(id, node)
	_loaded_regions[id] = {
		"node": node,
		"state": "visible" if visible_immediately else "preloaded",
		"title": str(node.get("region_title")),
		"subtitle": str(node.get("region_subtitle")),
		"allow_monster_spawn": bool(node.get("allow_monster_spawn")),
	}


func _unload_region_entry(id: String) -> void:
	if not _loaded_regions.has(id):
		return
	var row: Dictionary = _loaded_regions[id] as Dictionary
	var node: Node2D = row.get("node") as Node2D
	if is_instance_valid(node):
		var tw := node.create_tween()
		tw.tween_property(node, "modulate:a", 0.0, 0.26)
		tw.finished.connect(func() -> void:
			if is_instance_valid(node):
				node.queue_free()
		, CONNECT_ONE_SHOT)
	_loaded_regions.erase(id)


func _set_region_state(id: String, state: String, use_fx: bool) -> void:
	if not _loaded_regions.has(id):
		return
	var row: Dictionary = _loaded_regions[id] as Dictionary
	var node: Node2D = row.get("node") as Node2D
	if not is_instance_valid(node):
		_loaded_regions.erase(id)
		return
	row["state"] = state
	_loaded_regions[id] = row
	if node is Area2D:
		(node as Area2D).monitoring = (state == "visible")
	if state == "visible":
		var tw := node.create_tween()
		tw.tween_property(node, "modulate:a", 1.0, 0.24)
		if use_fx:
			_play_region_transition_fx(str(row.get("title", "")))


func _show_stream_region_hint(id: String, row: Dictionary) -> void:
	if id == _last_stream_region_id:
		return
	_last_stream_region_id = id
	var title: String = str(row.get("title", ""))
	var subtitle: String = str(row.get("subtitle", ""))
	_refresh_current_region_label(title)
	for n in get_tree().get_nodes_in_group("world_region_toast"):
		if n is Node and (n as Node).is_inside_tree() and n.has_method("show_region"):
			n.show_region(title, subtitle)
			break


func _current_region_display_name() -> String:
	if _current_region_id.is_empty():
		return "未知区域"
	var row_any: Variant = _loaded_regions.get(_current_region_id, {})
	if row_any is Dictionary:
		var title_any: Variant = (row_any as Dictionary).get("title", "")
		var title: String = str(title_any)
		if not title.strip_edges().is_empty():
			return title
	return str(REGION_MAP_TITLES.get(_current_region_id, _current_region_id))


func _refresh_current_region_label(force_title: String = "") -> void:
	if not is_instance_valid(_map_region_label):
		return
	var title: String = force_title.strip_edges()
	if title.is_empty():
		title = _current_region_display_name()
	_map_region_label.text = "区域: %s" % title


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


func _setup_combo_hud() -> void:
	if not is_instance_valid(ui_root) or is_instance_valid(_combo_hud):
		return
	var hud := PanelContainer.new()
	hud.name = "ComboHud"
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(16, 0.93))
	ui_root.add_child(hud)
	_combo_hud = hud
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	hud.add_child(vb)
	var grade := Label.new()
	grade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade.text = "等级 B"
	grade.add_theme_font_size_override("font_size", 20)
	grade.add_theme_color_override("font_color", Color8(148, 210, 255))
	vb.add_child(grade)
	_combo_grade_label = grade
	var combo := Label.new()
	combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo.text = "COMBO x0"
	combo.add_theme_font_size_override("font_size", 28)
	combo.add_theme_color_override("font_color", Color8(240, 248, 255))
	vb.add_child(combo)
	_combo_count_label = combo
	var total := Label.new()
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total.text = "击败总数 0"
	total.add_theme_font_size_override("font_size", 14)
	total.add_theme_color_override("font_color", Color8(190, 210, 230))
	vb.add_child(total)
	_combo_total_label = total
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0.0, 10.0)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.14, 0.25, 0.9)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color8(105, 213, 255)
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_left = 6
	fill.corner_radius_bottom_right = 6
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	vb.add_child(bar)
	_combo_bar = bar
	var break_label := Label.new()
	break_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	break_label.text = "连击中断"
	break_label.visible = false
	break_label.modulate.a = 0.0
	break_label.add_theme_font_size_override("font_size", 15)
	break_label.add_theme_color_override("font_color", Color8(255, 140, 140))
	vb.add_child(break_label)
	_combo_break_label = break_label
	_layout_combo_hud()
	_refresh_combo_hud(true)


func _layout_combo_hud() -> void:
	if not is_instance_valid(_combo_hud):
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var w: float = clampf(vp.x * 0.2, 220.0, 330.0)
	var h: float = clampf(vp.y * 0.16, 112.0, 170.0)
	var pad: float = clampf(vp.x * 0.014, 10.0, 24.0)
	var top_y: float = maxf(10.0, top_bar.offset_bottom + 12.0)
	## 固定放在左上（TopBar 下方），避开右上小地图/时钟区域。
	_combo_hud.offset_left = pad
	_combo_hud.offset_right = pad + w
	_combo_hud.offset_top = top_y
	_combo_hud.offset_bottom = top_y + h


func _combo_grade_for_count(count: int) -> String:
	if count >= 18:
		return "SSS"
	if count >= 11:
		return "SS"
	if count >= 6:
		return "S"
	if count >= 3:
		return "A"
	return "B"


func _combo_grade_color(grade: String) -> Color:
	match grade:
		"SSS":
			return Color8(255, 120, 245)
		"SS":
			return Color8(255, 170, 95)
		"S":
			return Color8(255, 226, 120)
		"A":
			return Color8(160, 234, 255)
		_:
			return Color8(148, 210, 255)


func _refresh_combo_hud(skip_anim: bool = false) -> void:
	if not is_instance_valid(_combo_hud):
		return
	var grade: String = _combo_grade_for_count(_kill_combo_count)
	var col: Color = _combo_grade_color(grade)
	_combo_grade_label.text = "等级 %s" % grade
	_combo_grade_label.add_theme_color_override("font_color", col)
	_combo_count_label.text = "COMBO x%d" % _kill_combo_count
	_combo_total_label.text = "击败总数 %d" % _kill_total_count
	var ratio: float = 0.0
	if _kill_combo_count > 0:
		ratio = clampf(_kill_combo_timer / KILL_COMBO_WINDOW, 0.0, 1.0)
	_combo_bar.value = ratio * 100.0
	_combo_hud.modulate.a = 1.0 if _kill_combo_count > 0 else 0.74
	if not skip_anim:
		_play_combo_hud_punch()


func _play_combo_hud_punch() -> void:
	if not is_instance_valid(_combo_count_label) or not is_instance_valid(_combo_grade_label):
		return
	if is_instance_valid(_combo_ui_tween):
		_combo_ui_tween.kill()
	_combo_count_label.scale = Vector2(1.22, 1.22)
	_combo_grade_label.scale = Vector2(1.16, 1.16)
	_combo_ui_tween = create_tween().set_parallel(true)
	_combo_ui_tween.tween_property(_combo_count_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_combo_ui_tween.tween_property(_combo_grade_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_combo_break_hint() -> void:
	if not is_instance_valid(_combo_break_label):
		return
	_combo_break_label.visible = true
	_combo_break_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_combo_break_label, "modulate:a", 0.0, 0.42).set_delay(0.55)
	tw.finished.connect(func() -> void:
		if is_instance_valid(_combo_break_label):
			_combo_break_label.visible = false
	)


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


func _try_cast_arc_skill() -> void:
	if _wn.is_cloud() or _skill_arc_cd > 0.0:
		return
	if not _can_local_attack():
		return
	if not is_instance_valid(_local_player):
		return
	var origin: Vector2 = _local_player.global_position
	var dmg: int = int(round(float(_melee_damage()) * 1.18))
	var hit_any: bool = false
	AttackRangeFx.spawn_mage_hit_ring(combat_fx_root, origin, SKILL_ARC_RADIUS, 0.38)
	_spawn_mage_mana_blast_fx(origin)
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node2D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m: Node2D = n as Node2D
		if m.global_position.distance_to(origin) <= SKILL_ARC_RADIUS:
			hit_any = true
			n.take_damage(maxi(1, dmg))
			_mark_player_damage_target(n)
	_skill_arc_cd = SKILL_ARC_COOLDOWN
	GameAudio.ui_confirm()
	UiTheme.camera_shake(main_camera, 4.8 if hit_any else 3.2, 0.12)
	_spawn_floating_feedback(origin + Vector2(0.0, -44.0), "弧光震荡", Color8(110, 235, 255), 20, 40.0)


func _try_cast_lance_skill() -> void:
	if _wn.is_cloud() or _skill_lance_cd > 0.0:
		return
	if not _can_local_attack():
		return
	if not is_instance_valid(_local_player):
		return
	var origin: Vector2 = _local_player.global_position
	var facing: float = _attack_facing_rad()
	var dir: Vector2 = Vector2.from_angle(facing).normalized()
	var center: Vector2 = origin + dir * (SKILL_LANCE_LENGTH * 0.5)
	var dmg: int = int(round(float(_melee_damage()) * 1.52))
	var hit_any: bool = false
	_spawn_priest_holy_ray_fx(origin, facing)
	AttackRangeFx.spawn_mage_hit_ring(combat_fx_root, origin + dir * 92.0, 52.0, 0.26)
	AttackRangeFx.spawn_mage_hit_ring(combat_fx_root, origin + dir * 186.0, 60.0, 0.28)
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n is Node2D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m: Node2D = n as Node2D
		var rel: Vector2 = m.global_position - center
		var proj: float = rel.dot(dir)
		var side: float = absf(rel.dot(Vector2(-dir.y, dir.x)))
		if absf(proj) <= SKILL_LANCE_LENGTH * 0.5 and side <= SKILL_LANCE_WIDTH:
			hit_any = true
			n.take_damage(maxi(1, dmg))
			_mark_player_damage_target(n)
	_skill_lance_cd = SKILL_LANCE_COOLDOWN
	GameAudio.ui_confirm()
	UiTheme.camera_shake(main_camera, 5.6 if hit_any else 3.6, 0.14)
	_spawn_floating_feedback(origin + Vector2(0.0, -58.0), "贯穿之矛", Color8(190, 180, 255), 20, 44.0)


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
		_warn_missing_ui_icon_once(path)
		return null
	var res: Resource = ResourceLoader.load(path)
	var tex: Texture2D = res as Texture2D
	if tex == null:
		_warn_missing_ui_icon_once(path)
	return tex


func _scaled_ui_icon(src: Texture2D, target_px: int) -> Texture2D:
	if src == null:
		return null
	var img: Image = src.get_image()
	if img == null or img.is_empty():
		return src
	var out: Image = img.duplicate()
	out.resize(target_px, target_px, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(out)


func _warn_missing_ui_icon_once(path: String) -> void:
	if _missing_ui_icon_warned.get(path, false):
		return
	_missing_ui_icon_warned[path] = true
	push_warning("TopBar icon missing: %s" % path)


func _apply_header_icon_button(btn: Button, icon_path: String, fallback_text: String) -> void:
	if not is_instance_valid(btn):
		return
	var tex: Texture2D = _scaled_ui_icon(_load_texture_safe(icon_path), _TOPBAR_ICON_SIZE)
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.tooltip_text = fallback_text
	if tex != null:
		btn.icon = tex
		btn.text = ""
	else:
		btn.icon = null
		btn.text = fallback_text


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
	var zone_pos: Vector2 = _random_loaded_region_pos()
	if zone_pos.x != INF and zone_pos.y != INF:
		return zone_pos
	var r := WORLD_SPAWN_RECT
	return Vector2(
		randf_range(r.position.x, r.position.x + r.size.x),
		randf_range(r.position.y, r.position.y + r.size.y)
	)


func _random_world_pos_stratified() -> Vector2:
	var zone_pos: Vector2 = _random_loaded_region_pos()
	if zone_pos.x != INF and zone_pos.y != INF:
		return zone_pos
	var r := WORLD_SPAWN_RECT
	var cw: float = r.size.x / float(DECO_STRATIFY_COLS)
	var ch: float = r.size.y / float(DECO_STRATIFY_ROWS)
	var cx: int = randi() % DECO_STRATIFY_COLS
	var cy: int = randi() % DECO_STRATIFY_ROWS
	return Vector2(
		r.position.x + (float(cx) + randf()) * cw,
		r.position.y + (float(cy) + randf()) * ch
	)


func _random_loaded_region_pos() -> Vector2:
	if _loaded_regions.is_empty():
		return Vector2(INF, INF)
	var candidates: Array[Vector2] = []
	for key in _loaded_regions.keys():
		var row: Dictionary = _loaded_regions[key] as Dictionary
		var node: Node2D = row.get("node") as Node2D
		if not is_instance_valid(node):
			continue
		var cs: CollisionShape2D = node.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if not is_instance_valid(cs):
			continue
		if not (cs.shape is RectangleShape2D):
			continue
		var rect_shape: RectangleShape2D = cs.shape as RectangleShape2D
		var half: Vector2 = rect_shape.size * 0.5
		var local: Vector2 = cs.position + Vector2(randf_range(-half.x, half.x), randf_range(-half.y, half.y))
		candidates.append(node.to_global(local))
	if candidates.is_empty():
		return Vector2(INF, INF)
	return candidates[randi() % candidates.size()]


func _spawn_loot_drops(at: Vector2, reward_xp: int) -> void:
	if _wn.is_cloud():
		return
	var gel_n: int = 1 + randi() % 2
	for _i in gel_n:
		var inst: Node2D = LOOT_PICKUP_MATERIAL_SCENE.instantiate() as Node2D
		loot_drops_root.add_child(inst)
		inst.global_position = at + Vector2(randf_range(-28.0, 28.0), randf_range(-20.0, 14.0))
		inst.set("item_id", "slime_gel")
		inst.set("display_name", "凝胶")
		inst.set("amount", 1)
		inst.set("bonus_xp", 0)
	if randf() < 0.35:
		var resin_inst: Node2D = LOOT_PICKUP_MATERIAL_SCENE.instantiate() as Node2D
		loot_drops_root.add_child(resin_inst)
		resin_inst.global_position = at + Vector2(randf_range(-22.0, 22.0), randf_range(-18.0, 12.0))
		resin_inst.set("item_id", "forest_resin")
		resin_inst.set("display_name", "树脂")
		resin_inst.set("amount", 1)
		resin_inst.set("bonus_xp", 0)
	if randf() < 0.18:
		var bone_inst: Node2D = LOOT_PICKUP_MATERIAL_SCENE.instantiate() as Node2D
		loot_drops_root.add_child(bone_inst)
		bone_inst.global_position = at + Vector2(randf_range(-18.0, 18.0), randf_range(-20.0, 8.0))
		bone_inst.set("item_id", "ancient_bone")
		bone_inst.set("display_name", "骨片")
		bone_inst.set("amount", 1)
		bone_inst.set("bonus_xp", 0)
	if randf() < 0.42:
		var coin_inst: Node2D = LOOT_PICKUP_CURRENCY_SCENE.instantiate() as Node2D
		loot_drops_root.add_child(coin_inst)
		coin_inst.global_position = at + Vector2(randf_range(-24.0, 24.0), randf_range(-22.0, 10.0))
		coin_inst.set("item_id", "coin")
		coin_inst.set("display_name", "金币")
		coin_inst.set("amount", 1 + randi() % 4)
		coin_inst.set("bonus_xp", 0)
	if randf() < 0.5:
		var xp_inst: Node2D = LOOT_PICKUP_MATERIAL_SCENE.instantiate() as Node2D
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
	if is_instance_valid(world_chat) and world_chat.has_method("setup"):
		world_chat.call("setup", self)
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
	main_camera.zoom = WORLD_CAMERA_ZOOM
	main_camera.reset_physics_interpolation()
	
	world_chat.set_local_player(p)
	if not _wn.is_cloud():
		CharacterBuild.set_runtime_combat_progress(_combat_level, _combat_xp)


func _spawn_npcs() -> void:
	var shop_spawn: Vector2 = _find_zone_spawn_point("NpcSpawns", "ShopSpawn", Vector2(380, 220))
	var patrol_peach := _patrol_rect_loop(shop_spawn, 85.0, 62.0)
	_spawn_one_npc(
		shop_spawn,
		"店员小桃",
		"欢迎光临～今天推荐的是草莓牛奶蛋糕哦！",
		patrol_peach,
		{
			"key": "shop_peach",
			"personality": "热情外向",
			"portrait": _NPC_TEX_ORANGE_FEMALE,
			"dialog_pool": PackedStringArray([
				"欢迎欢迎！今天补给打折，记得看看背包。",
				"你看起来很有潜力，要不要试试新武器？",
				"冒险前先整备，才不会手忙脚乱哦。"
			])
		}
	)
	var traveler_spawn: Vector2 = _find_zone_spawn_point("NpcSpawns", "TravelerSpawn", Vector2(860, 300))
	var patrol_miffy := PackedVector2Array([
		traveler_spawn + Vector2(0.0, 0.0),
		traveler_spawn + Vector2(150.0, 0.0),
		traveler_spawn + Vector2(150.0, 120.0),
		traveler_spawn + Vector2(-150.0, 120.0),
		traveler_spawn + Vector2(-150.0, 0.0)
	])
	_spawn_one_npc(
		traveler_spawn,
		"旅人米菲",
		"世界好大呀……你也来散步吗？",
		patrol_miffy,
		{
			"key": "traveler_miffy",
			"personality": "好奇探索",
			"portrait": _NPC_TEX_REDHAIR_FEMALE,
			"dialog_pool": PackedStringArray([
				"我在找传说中的风铃谷，听说那边怪物很少。",
				"地图边缘别乱冲，先确认补给再出发。",
				"如果你遇到奇怪脚印，记得回来告诉我。"
			])
		}
	)
	var guide_spawn: Vector2 = _find_zone_spawn_point("NpcSpawns", "GuideSpawn", Vector2(520, 480))
	var guide_npc: Node2D = _spawn_one_npc(
		guide_spawn,
		"向导露露",
		"靠近 NPC 后点右下角「对话」或键盘 E。云端联机时头顶会显示各自身份昵称。",
		PackedVector2Array(),
		{
			"key": "guide_lulu",
			"personality": "耐心教学",
			"portrait": _NPC_TEX_BLUE_MALE,
			"dialog_pool": PackedStringArray([
				"新手建议：先熟悉闪避，再练技能连招。",
				"地图打开后可以查看当前区域生物数量。",
				"远程职业开自动索敌会更稳，但手动瞄准上限更高。"
			])
		}
	)
	if is_instance_valid(guide_npc):
		guide_npc.set("npc_key", "guide_lulu")
	var sheriff_spawn: Vector2 = guide_spawn + Vector2(-210.0, -80.0)
	_spawn_one_npc(
		sheriff_spawn,
		"治安官罗恩",
		"最近野外怪物活动频繁，外出注意安全。",
		_patrol_rect_loop(sheriff_spawn, 46.0, 34.0),
		{
			"key": "sheriff_ron",
			"personality": "严谨负责",
			"portrait": _NPC_TEX_SHERIFF_MALE,
			"dialog_pool": PackedStringArray([
				"治安公告：遇到成群怪物请优先拉开距离。",
				"我会记录巡逻路线，你负责清理突发威胁。",
				"夜晚能见度差，建议别单独深入野外。"
			])
		}
	)
	var student_spawn: Vector2 = traveler_spawn + Vector2(120.0, -110.0)
	_spawn_one_npc(
		student_spawn,
		"学徒艾文",
		"我在练习弓箭，你要不要一起试试？",
		_patrol_rect_loop(student_spawn, 40.0, 28.0),
		{
			"key": "apprentice_evan",
			"personality": "认真内向",
			"portrait": _NPC_TEX_STUDENT_MALE,
			"dialog_pool": PackedStringArray([
				"老师说，稳定比花哨更重要。",
				"我总会在紧张时射偏……你有诀窍吗？",
				"等我练成了，也想去试炼场挑战。"
			])
		}
	)
	var hunter_spawn: Vector2 = shop_spawn + Vector2(190.0, -120.0)
	_spawn_one_npc(
		hunter_spawn,
		"猎手布雷",
		"风向不错，今天应该能追到好猎物。",
		_patrol_rect_loop(hunter_spawn, 52.0, 24.0),
		{
			"key": "hunter_bray",
			"personality": "冷静果断",
			"portrait": _NPC_TEX_BROWN_MALE,
			"dialog_pool": PackedStringArray([
				"别急着冲，先看怪物走位再出手。",
				"弓箭要留节奏，贪输出容易被反打。",
				"你要是去南郊，顺便帮我留意大型足迹。"
			])
		}
	)
	var bard_spawn: Vector2 = guide_spawn + Vector2(220.0, 70.0)
	_spawn_one_npc(
		bard_spawn,
		"吟游诗人赛琳",
		"故事和战斗一样，都需要节奏。",
		_patrol_rect_loop(bard_spawn, 34.0, 26.0),
		{
			"key": "bard_selene",
			"personality": "浪漫开朗",
			"portrait": _NPC_TEX_YELLOW_MALE,
			"dialog_pool": PackedStringArray([
				"听说你刚打出漂亮连击？这值得写进歌里。",
				"每次归来都多一点成长，这就是冒险的意义。",
				"当你迷茫时，先回广场听听风声。"
			])
		}
	)
	var scout_spawn: Vector2 = traveler_spawn + Vector2(-170.0, -90.0)
	_spawn_one_npc(
		scout_spawn,
		"侦察员莱克",
		"我刚从南边回来，那边路况还算安全。",
		_patrol_rect_loop(scout_spawn, 36.0, 26.0),
		{
			"key": "scout_lake",
			"personality": "谨慎机敏",
			"portrait": _NPC_TEX_RED_MALE,
			"dialog_pool": PackedStringArray([
				"远处怪群移动很快，别被包夹。",
				"你如果要赶路，优先清掉侧翼威胁。",
				"我会继续侦察，晚点给你新情报。"
			])
		}
	)


func _patrol_rect_loop(center: Vector2, half_w: float, half_h: float) -> PackedVector2Array:
	var c: Vector2 = center
	return PackedVector2Array([
		c + Vector2(-half_w, -half_h),
		c + Vector2(half_w, -half_h),
		c + Vector2(half_w, half_h),
		c + Vector2(-half_w, half_h),
	])


func _spawn_one_npc(
	at: Vector2,
	display_name: String,
	message: String,
	patrol_world: PackedVector2Array = PackedVector2Array(),
	profile: Dictionary = {}
) -> Node2D:
	var n: Node2D = NPC_SCENE.instantiate() as Node2D
	n.position = at
	n.set("npc_display_name", display_name)
	n.set("dialog_message", message)
	if profile.has("key"):
		n.set("npc_key", str(profile.get("key", "")))
	if profile.has("personality"):
		n.set("npc_personality", str(profile.get("personality", "")))
	if profile.has("portrait"):
		n.set("portrait_texture", profile.get("portrait", null))
	if profile.has("dialog_pool"):
		n.set("dialog_pool", profile.get("dialog_pool", PackedStringArray()))
	if patrol_world.size() >= 2:
		n.set("patrol_waypoints_world", patrol_world)
	npcs_root.add_child(n)
	return n


func _load_user_data() -> void:
	if ProjectSettings.has_setting("moe_world/current_user"):
		var user_data: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if user_data is Dictionary:
			nickname_label.text = str((user_data as Dictionary).get("username", "萌酱"))


func _on_mobile_move_input(direction: Vector2) -> void:
	if _world_defeat_handled:
		if is_instance_valid(_local_player):
			_local_player.set_mobile_input(Vector2.ZERO)
		return
	if is_instance_valid(_local_player) and _local_player.is_in_dialog:
		_local_player.set_mobile_input(Vector2.ZERO)
		return
	if is_instance_valid(_local_player):
		_local_player.set_mobile_input(direction)


func _on_mobile_interact_pressed() -> void:
	if _world_defeat_handled:
		return
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
	if is_instance_valid(_local_player) and _local_player.has_method("set_interact_hint_active"):
		_local_player.call("set_interact_hint_active", active)
	if not is_instance_valid(hint_label):
		return
	if active:
		if is_instance_valid(portal_area):
			show_interact_enter_bubble(portal_area.global_position + Vector2(0.0, -52.0), "可进入")
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


func show_interact_enter_bubble(at_global: Vector2, text: String = "可交互") -> void:
	_spawn_floating_feedback(at_global, text, Color8(255, 220, 140), 16, 30.0)


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
	if not is_instance_valid(_map_region_label):
		var region_label := Label.new()
		region_label.name = "RegionLabel"
		region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		region_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		region_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		region_label.add_theme_font_size_override("font_size", 14)
		region_label.add_theme_color_override("font_color", Color8(255, 235, 170))
		region_label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.14, 0.86))
		region_label.add_theme_constant_override("outline_size", 2)
		top_bar.add_child(region_label)
		_map_region_label = region_label
	_refresh_current_region_label()

	_style_header_action_btn(growth_btn)
	_style_header_action_btn(backpack_btn)
	_style_header_action_btn(shop_btn)
	_style_header_action_btn(map_btn)
	_apply_header_icon_button(growth_btn, _ICON_GROWTH_PATH, "成长")
	_apply_header_icon_button(backpack_btn, _ICON_BACKPACK_PATH, "背包")
	_apply_header_icon_button(shop_btn, _ICON_SHOP_PATH, "商店")
	_apply_header_icon_button(map_btn, _ICON_MAP_PATH, "地图")
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
	if back_btn.visible:
		_world_bar_place(back_btn, x, y0, btn_w, btn_h)
		x = back_btn.offset_right + g
	if exit_game_btn.visible:
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
	if is_instance_valid(_codex_btn):
		_codex_btn.visible = not _wn.is_cloud()
		if _codex_btn.visible:
			_world_bar_place(_codex_btn, x, y0, bag_w, btn_h)
			x = _codex_btn.offset_right + g
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
	if is_instance_valid(_map_region_label):
		var region_w: float = clampf(W * 0.12, 96.0, 200.0)
		_map_region_label.offset_left = x
		_map_region_label.offset_right = x + region_w
		_map_region_label.offset_top = y0 + 2.0
		_map_region_label.offset_bottom = bar_h - (y0 + 2.0)
		x = _map_region_label.offset_right + g
	hint_label.offset_left = x
	hint_label.offset_right = maxf(x + 48.0, mid_end)
	hint_label.offset_top = y0 + 4.0
	hint_label.offset_bottom = bar_h - (y0 + 4.0)
	hint_label.visible = hint_label.offset_right - hint_label.offset_left >= 56.0
	var fs: float = UiTheme.responsive_ui_font_scale(vp)
	combat_label.add_theme_font_size_override("font_size", int(17 * fs))
	online_label.add_theme_font_size_override("font_size", int(16 * fs))
	if is_instance_valid(_map_region_label):
		_map_region_label.add_theme_font_size_override("font_size", int(14 * fs))
	hint_label.add_theme_font_size_override("font_size", int(12 * fs))
	nickname_label.add_theme_font_size_override("font_size", int(18 * fs))
	back_btn.add_theme_font_size_override("font_size", int(16 * fs))
	exit_game_btn.add_theme_font_size_override("font_size", int(16 * fs))
	growth_btn.add_theme_font_size_override("font_size", int(14 * fs))
	backpack_btn.add_theme_font_size_override("font_size", int(14 * fs))
	shop_btn.add_theme_font_size_override("font_size", int(14 * fs))
	map_btn.add_theme_font_size_override("font_size", int(14 * fs))
	if is_instance_valid(_codex_btn):
		_codex_btn.add_theme_font_size_override("font_size", int(14 * fs))
	_layout_combo_hud()


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
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		var is_mobile: bool = OS.has_feature("mobile")
		if not is_mobile and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_pc_mouse_attack_queued = true


func _setup_pc_pause_menu() -> void:
	if is_instance_valid(_pc_pause_menu):
		return
	var menu := GAMEPLAY_PAUSE_MENU_SCRIPT.new()
	add_child(menu)
	_pc_pause_menu = menu
	if _pc_pause_menu.has_method("set_auto_lock_enabled"):
		_pc_pause_menu.call("set_auto_lock_enabled", CharacterBuild.ranged_auto_lock)
	if _pc_pause_menu.has_signal("auto_lock_changed"):
		_pc_pause_menu.connect("auto_lock_changed", Callable(self, "_on_pause_menu_auto_lock_changed"))
	if _pc_pause_menu.has_signal("back_hall_requested"):
		_pc_pause_menu.connect("back_hall_requested", Callable(self, "_on_back_clicked"))
	if _pc_pause_menu.has_signal("exit_game_requested"):
		_pc_pause_menu.connect("exit_game_requested", Callable(self, "_on_exit_game_clicked"))


func _on_pause_menu_auto_lock_changed(enabled: bool) -> void:
	CharacterBuild.set_ranged_auto_lock(enabled)


func _on_mobile_menu_pressed() -> void:
	if is_instance_valid(_pc_pause_menu) and _pc_pause_menu.has_method("open_menu"):
		_pc_pause_menu.call("open_menu")


func _on_map_btn_pressed() -> void:
	GameAudio.ui_click()
	if is_instance_valid(map_overlay) and map_overlay.has_method("toggle_map"):
		map_overlay.toggle_map()


func _on_world_map_opened() -> void:
	if is_instance_valid(mobile_controls):
		mobile_controls.visible = false


func _on_world_map_closed() -> void:
	if is_instance_valid(mobile_controls):
		mobile_controls.visible = true


func _setup_codex_button() -> void:
	if not is_instance_valid(top_bar):
		return
	if is_instance_valid(_codex_btn):
		return
	_codex_btn = Button.new()
	_codex_btn.name = "CodexBtn"
	_codex_btn.text = "图鉴"
	_codex_btn.focus_mode = Control.FOCUS_NONE
	_codex_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_codex_btn.pressed.connect(_on_codex_pressed)
	top_bar.add_child(_codex_btn)
	_style_header_action_btn(_codex_btn)


func _on_codex_pressed() -> void:
	GameAudio.ui_click()
	if is_instance_valid(_codex_overlay):
		_close_codex()
	else:
		_open_codex()


func _open_codex() -> void:
	if is_instance_valid(_codex_overlay):
		return
	_codex_overlay = CanvasLayer.new()
	_codex_overlay.layer = 84
	add_child(_codex_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.56)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_codex_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560.0, 460.0)
	panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(18, 0.96))
	_codex_overlay.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "生物图鉴"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vb.add_child(title)
	var body := RichTextLabel.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.fit_content = false
	body.bbcode_enabled = true
	body.text = _codex_body_text()
	vb.add_child(body)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(_close_codex)
	vb.add_child(close_btn)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed:
				_close_codex()
		elif event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			if st.pressed:
				_close_codex()
	)


func _close_codex() -> void:
	if is_instance_valid(_codex_overlay):
		_codex_overlay.queue_free()
	_codex_overlay = null


func _codex_body_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]中立生物[/b]")
	lines.append("· 野兔（Lv1-3）：低威胁，可被怪物袭击。")
	lines.append("")
	lines.append("[b]怪物[/b]")
	lines.append("· 史莱姆（近战）")
	lines.append("· 恶魔（高速冲锋）")
	lines.append("· 毒沫喷吐兽（远程弹道）")
	lines.append("· 裂地重甲兽（蓄力范围重击）")
	lines.append("")
	lines.append("[b]Boss[/b]")
	lines.append("· 深渊统领（多技能：重击 + 额外喷吐）")
	lines.append("")
	lines.append("[color=#d8c4ff]提示：地图中高等级单位头顶会显示 Lv 与名称。[/color]")
	return "\n".join(lines)


func _process(delta: float) -> void:
	_boundary_fog_phase += delta
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_skill_arc_cd = maxf(0.0, _skill_arc_cd - delta)
	_skill_lance_cd = maxf(0.0, _skill_lance_cd - delta)
	_ecology_tick_cd = maxf(0.0, _ecology_tick_cd - delta)
	_monster_respawn_cd = maxf(0.0, _monster_respawn_cd - delta)
	_neutral_respawn_cd = maxf(0.0, _neutral_respawn_cd - delta)
	_region_stream_cd = maxf(0.0, _region_stream_cd - delta)
	if _region_stream_cd <= 0.0:
		_region_stream_cd = REGION_STREAM_TICK_SEC
		_tick_region_streaming()
	if is_instance_valid(mobile_controls) and mobile_controls.has_method("set_extra_skill_cooldowns"):
		var dodge_cd: float = 0.0
		var dodge_total: float = 0.78
		if is_instance_valid(_local_player) and _local_player.has_method("get_dodge_cooldown_remaining"):
			dodge_cd = float(_local_player.call("get_dodge_cooldown_remaining"))
		if is_instance_valid(_local_player) and _local_player.has_method("get_dodge_cooldown_total"):
			dodge_total = maxf(0.01, float(_local_player.call("get_dodge_cooldown_total")))
		mobile_controls.call("set_extra_skill_cooldowns", _skill_arc_cd, _skill_lance_cd, dodge_cd, dodge_total)
	_tick_kill_combo(delta)
	## 批量递减每只怪的独立伤害 CD
	for k in _monster_hit_cd.keys():
		_monster_hit_cd[k] = _monster_hit_cd[k] - delta
		if _monster_hit_cd[k] <= 0.0:
			_monster_hit_cd.erase(k)
	_online_label_refresh_cd = maxf(0.0, _online_label_refresh_cd - delta)
	if _online_label_refresh_cd <= 0.0 and is_instance_valid(players_root) and is_instance_valid(online_label):
		_online_label_refresh_cd = 0.2
		var online_count: int = players_root.get_child_count()
		if online_count != _last_online_count:
			_last_online_count = online_count
			online_label.text = "在线: %d" % online_count
	if is_instance_valid(_local_player) and is_instance_valid(main_camera):
		var smooth: float = follow_smooth
		if _local_player.has_method("is_dodging") and bool(_local_player.call("is_dodging")):
			## 连续闪避时提高追踪速度，避免镜头滞后导致角色偏离中心。
			smooth = maxf(smooth, 20.0)
		var t: float = clampf(smooth * delta, 0.0, 1.0)
		var target: Vector2 = _local_player.global_position
		main_camera.global_position = main_camera.global_position.lerp(target, t)
		main_camera.offset = main_camera.offset.lerp(Vector2.ZERO, clampf(13.0 * delta, 0.0, 1.0))
		if main_camera.global_position.distance_squared_to(target) > 140.0 * 140.0:
			main_camera.global_position = target
	if not _wn.is_cloud() and _world_defeat_handled:
		_update_boundary_fog_anim()
		return
	if not _wn.is_cloud() and _can_local_attack():
		var click_attack: bool = _pc_mouse_attack_queued
		_pc_mouse_attack_queued = false
		if Input.is_action_just_pressed("attack") or click_attack:
			_try_primary_attack()
		if Input.is_action_just_pressed("skill_surge"):
			_on_skill_surge_requested()
		if Input.is_key_pressed(KEY_Q):
			_try_cast_arc_skill()
		if Input.is_key_pressed(KEY_R):
			_try_cast_lance_skill()
	if not _wn.is_cloud() and _monster_respawn_cd <= 0.01:
		_ensure_monster_population()
		_monster_respawn_cd = MONSTER_RESPAWN_INTERVAL
	if not _wn.is_cloud() and _neutral_respawn_cd <= 0.01:
		_ensure_neutral_population()
		_neutral_respawn_cd = NEUTRAL_RESPAWN_INTERVAL
	if not _wn.is_cloud() and _ecology_tick_cd <= 0.01:
		_ecology_tick_cd = ECOLOGY_TICK_INTERVAL
		_tick_ecology_conflicts()
	if not _wn.is_cloud():
		_check_monster_contact_damage()
		if not _world_defeat_handled and CharacterBuild.get_player_hp() <= 0:
			_handle_world_defeat()
	_update_boundary_fog_anim()


func _handle_world_defeat() -> void:
	if _world_defeat_handled:
		return
	_world_defeat_handled = true
	if is_instance_valid(_local_player):
		_local_player.set_mobile_input(Vector2.ZERO)
		if _local_player.has_method("start_dialog"):
			_local_player.call("start_dialog")
	_show_world_defeat_panel()


func _show_world_defeat_panel() -> void:
	if is_instance_valid(_world_defeat_layer):
		return
	_world_defeat_layer = CanvasLayer.new()
	_world_defeat_layer.layer = 110
	add_child(_world_defeat_layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.64)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_world_defeat_layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420.0, 0.0)
	panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(20, 0.95))
	_world_defeat_layer.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "你倒下了"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vb.add_child(title)
	var desc := Label.new()
	desc.text = "本次探索中断，请选择恢复方式。"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	var recover_btn := Button.new()
	recover_btn.text = "原地恢复"
	recover_btn.custom_minimum_size = Vector2(140.0, 44.0)
	recover_btn.focus_mode = Control.FOCUS_NONE
	recover_btn.pressed.connect(_recover_from_world_defeat, CONNECT_ONE_SHOT)
	hb.add_child(recover_btn)
	var hall_btn := Button.new()
	hall_btn.text = "返回大厅"
	hall_btn.custom_minimum_size = Vector2(140.0, 44.0)
	hall_btn.focus_mode = Control.FOCUS_NONE
	hall_btn.pressed.connect(_return_to_hall_from_world_defeat, CONNECT_ONE_SHOT)
	hb.add_child(hall_btn)


func _recover_from_world_defeat() -> void:
	CharacterBuild.full_heal_player()
	_world_defeat_handled = false
	if is_instance_valid(_local_player) and _local_player.has_method("end_dialog"):
		_local_player.call("end_dialog")
	if is_instance_valid(_world_defeat_layer):
		_world_defeat_layer.queue_free()
	_world_defeat_layer = null
	GameAudio.ui_confirm()


func _return_to_hall_from_world_defeat() -> void:
	if _wn.is_cloud():
		_wn.leave_session()
	GameAudio.ui_click()
	SceneTransition.transition_to(HALL_SCENE)


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
		var delta_pos: Vector2 = m2d.global_position - ppos
		if absf(delta_pos.x) > MONSTER_CONTACT_RANGE or absf(delta_pos.y) > MONSTER_CONTACT_RANGE:
			continue
		if delta_pos.length_squared() > MONSTER_CONTACT_RANGE_SQ:
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
		var dodging_now: bool = _local_player.has_method("is_dodging") and bool(_local_player.call("is_dodging"))
		if dodging_now:
			if _try_trigger_perfect_dodge(ppos):
				_monster_hit_cd[mid] = 0.14
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


func _on_monster_special_attack(attacker_id: int, damage: int, at_global: Vector2, radius: float, kind: String) -> void:
	if _wn.is_cloud() or _world_defeat_handled:
		return
	if not is_instance_valid(_local_player):
		return
	var key: int = attacker_id + 20000000
	if _monster_hit_cd.get(key, 0.0) > 0.0:
		return
	_monster_hit_cd[key] = MONSTER_SPECIAL_ATTACK_INTERVAL
	var source_pos: Vector2 = at_global
	var attacker_obj: Object = instance_from_id(attacker_id)
	if attacker_obj != null and attacker_obj is Node2D and is_instance_valid(attacker_obj as Node2D):
		source_pos = (attacker_obj as Node2D).global_position
	var warn_radius: float = maxf(24.0, radius)
	if kind == "slam":
		_spawn_monster_warning_ring(at_global, warn_radius, Color8(255, 166, 90), 0.22)
	elif kind == "spit":
		_spawn_monster_warning_ring(at_global, warn_radius, Color8(90, 255, 220), 0.14)
	if kind == "spit":
		var travel_sec: float = clampf(source_pos.distance_to(at_global) / 420.0, 0.24, 0.55)
		_spawn_monster_projectile(
			source_pos,
			at_global,
			Color8(88, 255, 228),
			9.0,
			travel_sec,
			func() -> void:
				_apply_monster_special_damage(damage, at_global, radius, kind)
		)
		return
	_apply_monster_special_damage(damage, at_global, radius, kind)


func _apply_monster_special_damage(damage: int, at_global: Vector2, radius: float, kind: String) -> void:
	if _wn.is_cloud() or _world_defeat_handled:
		return
	if not is_instance_valid(_local_player):
		return
	var ppos: Vector2 = _local_player.global_position
	var hit_ok: bool = true
	if radius > 0.0:
		hit_ok = ppos.distance_squared_to(at_global) <= (radius * radius)
	if not hit_ok:
		return
	if _local_player.has_method("is_dodging") and bool(_local_player.call("is_dodging")):
		_try_trigger_perfect_dodge(ppos)
		return
	var dmg: int = maxi(1, damage)
	CharacterBuild.damage_player(dmg)
	_spawn_inline_damage_number(
		ppos + PLAYER_FLOAT_OVERHEAD + Vector2(randf_range(-16.0, 16.0), -4.0),
		"-%d" % dmg,
		UiTheme.Colors.HP_RED,
		30 if kind == "slam" else 27
	)
	_spawn_monster_impact_burst(at_global, maxf(26.0, radius), kind)
	if kind == "slam":
		AttackRangeFx.spawn_mage_hit_ring(combat_fx_root, at_global, maxf(42.0, radius))
		GameAudio.melee_hit()
		UiTheme.camera_shake(main_camera, 6.5, 0.18)
	else:
		AttackRangeFx.spawn_mage_hit_ring(combat_fx_root, at_global, maxf(26.0, radius))
		GameAudio.ui_confirm()
		UiTheme.camera_shake(main_camera, 4.2, 0.14)
	_flash_damage_overlay()
	if _local_player.has_method("play_hurt_animation"):
		_local_player.call("play_hurt_animation")
	_shake_combat_label()


func _spawn_monster_projectile(from_pos: Vector2, to_pos: Vector2, color: Color, size_px: float, travel_sec: float, on_impact: Callable) -> void:
	if not is_instance_valid(combat_fx_root):
		if on_impact.is_valid():
			on_impact.call()
		return
	var node := Node2D.new()
	node.z_as_relative = false
	node.z_index = 30
	node.global_position = from_pos
	var px: int = maxi(4, int(round(size_px)))
	var orb := Sprite2D.new()
	orb.texture = _make_projectile_texture(color, px)
	orb.centered = true
	orb.modulate.a = 0.95
	node.add_child(orb)
	combat_fx_root.add_child(node)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(node, "global_position", to_pos, travel_sec).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(orb, "rotation", PI * 2.0, travel_sec)
	tw.finished.connect(func() -> void:
		if is_instance_valid(node):
			node.queue_free()
		if on_impact.is_valid():
			on_impact.call()
	)


func _spawn_monster_warning_ring(world_pos: Vector2, radius: float, color: Color, windup_sec: float) -> void:
	if not is_instance_valid(combat_fx_root):
		return
	var ring := Line2D.new()
	ring.width = 4.0
	ring.closed = true
	ring.default_color = color
	ring.z_as_relative = false
	ring.z_index = 32
	var points := PackedVector2Array()
	var segs: int = 42
	for i in segs:
		var ang: float = TAU * float(i) / float(segs)
		points.append(world_pos + Vector2(cos(ang), sin(ang)) * radius)
	ring.points = points
	combat_fx_root.add_child(ring)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ring, "width", 9.0, windup_sec).from(3.0)
	tw.tween_property(ring, "modulate:a", 0.0, windup_sec).from(0.95)
	tw.finished.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)


func _spawn_monster_impact_burst(world_pos: Vector2, radius: float, kind: String) -> void:
	if not is_instance_valid(combat_fx_root):
		return
	var color: Color = Color8(255, 140, 88) if kind == "slam" else Color8(92, 250, 226)
	var core := ColorRect.new()
	core.color = color
	core.size = Vector2(radius * 0.8, radius * 0.8)
	core.position = world_pos - core.size * 0.5
	core.z_as_relative = false
	core.z_index = 33
	combat_fx_root.add_child(core)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(core, "size", Vector2(radius * 1.8, radius * 1.8), 0.18).from(Vector2(radius * 0.6, radius * 0.6))
	tw.tween_property(core, "position", world_pos - Vector2(radius * 0.9, radius * 0.9), 0.18)
	tw.tween_property(core, "modulate:a", 0.0, 0.18).from(0.58)
	tw.finished.connect(func() -> void:
		if is_instance_valid(core):
			core.queue_free()
	)


func _make_projectile_texture(color: Color, pixel_size: int) -> ImageTexture:
	var s: int = maxi(4, pixel_size)
	var img: Image = Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c: Vector2 = Vector2(float(s - 1) * 0.5, float(s - 1) * 0.5)
	var r: float = float(s) * 0.48
	for y in s:
		for x in s:
			var p := Vector2(float(x), float(y))
			if p.distance_to(c) <= r:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


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
	if _world_defeat_handled:
		return false
	if not is_instance_valid(_local_player):
		return false
	if not _local_player.is_local_controllable():
		return false
	if _local_player.is_in_dialog:
		return false
	if _local_player.has_method("is_dodging") and bool(_local_player.call("is_dodging")):
		return false
	if MoeDialogBus.is_dialog_open():
		return false
	return true


func _attack_facing_rad() -> float:
	var is_mobile: bool = OS.has_feature("mobile")
	if not is_mobile and is_instance_valid(_local_player):
		var to_mouse: Vector2 = get_global_mouse_position() - _local_player.global_position
		if to_mouse.length_squared() > 9.0:
			return to_mouse.angle()
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
			_mark_player_damage_target(n)
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
			_mark_player_damage_target(n)
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
			_mark_player_damage_target(n)
	return hit_any


func _mark_player_damage_target(target: Object) -> void:
	if target != null and target.has_method("reveal_hp_bar"):
		target.call("reveal_hp_bar", 2.4)


func _try_trigger_perfect_dodge(feedback_pos: Vector2) -> bool:
	if not is_instance_valid(_local_player):
		return false
	if not _local_player.has_method("try_trigger_perfect_dodge"):
		return false
	if not bool(_local_player.call("try_trigger_perfect_dodge")):
		return false
	_spawn_inline_damage_number(
		feedback_pos + Vector2(randf_range(-10.0, 10.0), -46.0),
		"完美闪避!",
		Color8(150, 245, 255),
		26
	)
	UiTheme.camera_shake(main_camera, 2.2, 0.10)
	GameAudio.ui_confirm()
	return true


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


func _on_mobile_skill1_pressed() -> void:
	_try_cast_arc_skill()


func _on_mobile_skill2_pressed() -> void:
	_try_cast_lance_skill()


func _on_mobile_dodge_pressed() -> void:
	if not is_instance_valid(_local_player):
		return
	var dir: Vector2 = _local_player.mobile_input_dir
	if _local_player.has_method("request_dodge"):
		_local_player.call("request_dodge", dir)


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
	_register_kill_combo_feedback(at_global)
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm != null and qm.has_method("record_monster_kill"):
		qm.call("record_monster_kill", "world_monster", 1)
	if not _wn.is_cloud():
		GameAudio.xp_tick()
		_spawn_loot_drops(at_global, reward_xp)
		_spawn_floating_feedback(at_global, "+%d 经验" % reward_xp, UiTheme.Colors.XP_GREEN, 22, 58.0)
		_monster_respawn_cd = minf(_monster_respawn_cd, 1.2)
		## 怪物击杀时额外震动强调
		UiTheme.camera_shake(main_camera, 6.0, 0.14)


func _register_kill_combo_feedback(at_global: Vector2) -> void:
	_kill_total_count += 1
	_kill_combo_count += 1
	_kill_combo_timer = KILL_COMBO_WINDOW
	_combo_break_hint_timer = 0.0
	_refresh_combo_hud(false)
	var grade: String = _combo_grade_for_count(_kill_combo_count)
	if grade == "S" or grade == "SS" or grade == "SSS":
		_spawn_floating_feedback(at_global + Vector2(0.0, -34.0), "%s 连击!" % grade, _combo_grade_color(grade), 20, 48.0)


func _tick_kill_combo(delta: float) -> void:
	if _combo_break_hint_timer > 0.0:
		_combo_break_hint_timer = maxf(0.0, _combo_break_hint_timer - delta)
	if _kill_combo_timer > 0.0:
		_kill_combo_timer = maxf(0.0, _kill_combo_timer - delta)
		if _kill_combo_timer <= 0.0 and _kill_combo_count > 0:
			_kill_combo_count = 0
			_combo_break_hint_timer = 1.0
			_show_combo_break_hint()
	_refresh_combo_hud(true)


func show_npc_dialog_bubble(npc_node: Node2D, speaker: String, message: String) -> void:
	if not is_instance_valid(world_chat):
		MoeDialogBus.show_dialog(speaker, message)
		return
	if world_chat.has_method("add_world_chat_bubble"):
		world_chat.call("add_world_chat_bubble", speaker, message, npc_node, Vector2(0.0, -84.0))
		if world_chat.has_method("add_chat_message"):
			world_chat.call("add_chat_message", speaker, message)
	else:
		MoeDialogBus.show_dialog(speaker, message)


func _connect_quest_signals() -> void:
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm == null:
		return
	if not qm.is_connected("quest_feedback", Callable(self, "_on_quest_feedback")):
		qm.connect("quest_feedback", Callable(self, "_on_quest_feedback"))


func _disconnect_quest_signals() -> void:
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm == null:
		return
	if qm.is_connected("quest_feedback", Callable(self, "_on_quest_feedback")):
		qm.disconnect("quest_feedback", Callable(self, "_on_quest_feedback"))


func _on_quest_feedback(message: String, level: int) -> void:
	if message.strip_edges().is_empty():
		return
	var col: Color = Color8(180, 220, 255)
	var font_size: int = 19
	if level == 1:
		col = UiTheme.Colors.GOLD
		font_size = 21
		GameAudio.ui_confirm()
	elif level == 2:
		col = Color8(140, 255, 170)
		font_size = 22
		GameAudio.level_up()
	else:
		GameAudio.ui_click()
	var anchor: Vector2 = WORLD_OFFLINE_SPAWN
	if is_instance_valid(_local_player):
		anchor = _local_player.global_position
	_spawn_floating_feedback(anchor + Vector2(0.0, -56.0), message, col, font_size, 62.0)


func _spawn_monsters() -> void:
	_spawn_monster_batch(MONSTER_MAX_COUNT)


func _ensure_neutral_root() -> void:
	if is_instance_valid(_neutral_root):
		return
	_neutral_root = Node2D.new()
	_neutral_root.name = "NeutralCreatures"
	_neutral_root.z_as_relative = false
	_neutral_root.z_index = 0
	playfield_root.add_child(_neutral_root)


func _spawn_neutral_creatures(count: int) -> void:
	if not is_instance_valid(_neutral_root):
		return
	for _i in count:
		var nc: Node2D = NEUTRAL_CREATURE_SCENE.instantiate() as Node2D
		if not is_instance_valid(nc):
			continue
		_neutral_root.add_child(nc)
		nc.global_position = _random_neutral_spawn_point()
		if nc.has_method("set"):
			nc.set("creature_id", "wild_rabbit")
			nc.set("creature_name", "野兔")
			nc.set("creature_level", 1 + randi() % 3)


func _ensure_neutral_population() -> void:
	if not is_instance_valid(_neutral_root):
		return
	var alive: int = 0
	for c in _neutral_root.get_children():
		if is_instance_valid(c):
			alive += 1
	if alive >= NEUTRAL_MAX_COUNT:
		return
	_spawn_neutral_creatures(mini(2, NEUTRAL_MAX_COUNT - alive))


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
		if pos == Vector2.INF:
			continue
		if not _is_spawn_position_clear(monsters_root, pos, MONSTER_SPAWN_SEPARATION):
			continue
		var mon_scene: PackedScene
		var max_hp_override: int
		var reward_override: int
		var speed_override: float
		var is_boss: bool = false
		var roll: float = randf()
		if roll < 0.08:
			mon_scene = BRUTE_MONSTER_SCENE
			max_hp_override = 260 + i * 20
			reward_override = 64 + (i % 4) * 10
			speed_override = 44.0
			is_boss = true
		elif roll < 0.14:
			mon_scene = BRUTE_MONSTER_SCENE
			max_hp_override = 76 + i * 9
			reward_override = maxi(16, 22 + (i % 4) * 4)
			speed_override = 40.0 + float(i % 3) * 5.0
		elif roll < 0.20:
			mon_scene = GOBLIN_MAGE_SCENE
			max_hp_override = 48 + i * 7
			reward_override = maxi(16, 24 + (i % 4) * 4)
			speed_override = 58.0 + float(i % 3) * 6.0
		elif roll < 0.28:
			mon_scene = GOBLIN_ARCHER_SCENE
			max_hp_override = 52 + i * 7
			reward_override = maxi(14, 22 + (i % 4) * 4)
			speed_override = 63.0 + float(i % 3) * 7.0
		elif roll < 0.36:
			mon_scene = GOBLIN_SCENE
			max_hp_override = 56 + i * 8
			reward_override = maxi(13, 20 + (i % 4) * 3)
			speed_override = 62.0 + float(i % 3) * 6.0
		elif roll < 0.44:
			mon_scene = BAT_SCENE
			max_hp_override = 34 + i * 5
			reward_override = maxi(10, 15 + (i % 4) * 3)
			speed_override = 70.0 + float(i % 3) * 9.0
		elif roll < 0.52:
			mon_scene = RAT_SCENE
			max_hp_override = 30 + i * 5
			reward_override = maxi(9, 13 + (i % 4) * 3)
			speed_override = 62.0 + float(i % 3) * 8.0
		elif roll < 0.60:
			mon_scene = SLIME_RED_SCENE
			max_hp_override = 42 + i * 6
			reward_override = maxi(8, 12 + (i % 4) * 3)
			speed_override = 56.0 + float(i % 3) * 7.0
		elif roll < 0.68:
			mon_scene = SLIME_BLUE_SCENE
			max_hp_override = 40 + i * 6
			reward_override = maxi(8, 12 + (i % 4) * 3)
			speed_override = 60.0 + float(i % 3) * 8.0
		elif roll < 0.76:
			mon_scene = SLIME_BROWN_SCENE
			max_hp_override = 46 + i * 7
			reward_override = maxi(8, 12 + (i % 4) * 3)
			speed_override = 50.0 + float(i % 3) * 6.0
		elif roll < 0.84:
			mon_scene = SLIME_GREEN_SCENE
			max_hp_override = 38 + i * 6
			reward_override = maxi(7, 11 + (i % 4) * 3)
			speed_override = 54.0 + float(i % 3) * 6.0
		elif roll < 0.90:
			mon_scene = DEMON_MONSTER_SCENE
			max_hp_override = 45 + i * 10
			reward_override = maxi(10, 18 + (i % 4) * 5)
			speed_override = 58.0 + float(i % 3) * 12.0
		elif roll < 0.96:
			mon_scene = SPITTER_MONSTER_SCENE
			max_hp_override = 34 + i * 6
			reward_override = maxi(9, 14 + (i % 4) * 3)
			speed_override = 54.0 + float(i % 3) * 7.0
		else:
			mon_scene = MONSTER_SCENE
			max_hp_override = 28 + i * 6
			reward_override = maxi(5, 8 + (i % 4) * 3)
			speed_override = 48.0 + float(i % 3) * 8.0
		var mon = mon_scene.instantiate()
		mon.max_hp = max_hp_override
		mon.reward_xp = reward_override
		mon.move_speed = speed_override
		var lvl: int = 1
		if mon_scene == BRUTE_MONSTER_SCENE:
			lvl = 10 + (i % 5)
		elif mon_scene == GOBLIN_MAGE_SCENE:
			lvl = 9 + (i % 4)
		elif mon_scene == GOBLIN_ARCHER_SCENE:
			lvl = 8 + (i % 4)
		elif mon_scene == GOBLIN_SCENE:
			lvl = 7 + (i % 4)
		elif mon_scene == BAT_SCENE:
			lvl = 6 + (i % 3)
		elif mon_scene == RAT_SCENE:
			lvl = 5 + (i % 3)
		elif mon_scene == SLIME_RED_SCENE or mon_scene == SLIME_BLUE_SCENE:
			lvl = 4 + (i % 3)
		elif mon_scene == SLIME_BROWN_SCENE or mon_scene == SLIME_GREEN_SCENE:
			lvl = 3 + (i % 3)
		elif mon_scene == DEMON_MONSTER_SCENE:
			lvl = 7 + (i % 4)
		elif mon_scene == SPITTER_MONSTER_SCENE:
			lvl = 6 + (i % 4)
		else:
			lvl = 3 + (i % 3)
		mon.set("monster_level", lvl)
		if is_boss:
			mon.set("monster_display_name", "深渊统领")
			mon.set("monster_level", maxi(18, lvl + 8))
			mon.set_meta("is_boss", true)
		mon.damaged.connect(_on_monster_damaged)
		mon.died.connect(_on_monster_died)
		if mon.has_signal("player_special_attack"):
			mon.connect("player_special_attack", Callable(self, "_on_monster_special_attack"))
		monsters_root.add_child(mon)
		if mon is Node2D:
			(mon as Node2D).global_position = pos
		if mon.has_method("set_aggro_target"):
			mon.set_aggro_target(_local_player)


func _random_monster_spawn_point() -> Vector2:
	if not is_instance_valid(_local_player):
		return Vector2.INF
	var p := _local_player.global_position
	var zone_monster_points: Array[Vector2] = _collect_zone_spawn_points("MonsterSpawns", true)
	if zone_monster_points.is_empty():
		return Vector2.INF
	for _i in 24:
		var base: Vector2 = zone_monster_points[randi() % zone_monster_points.size()]
		var pos_zone: Vector2 = base + Vector2(randf_range(-42.0, 42.0), randf_range(-42.0, 42.0))
		if WORLD_SPAWN_RECT.has_point(pos_zone) and pos_zone.distance_to(p) >= MONSTER_SPAWN_MIN_DIST:
			return pos_zone
	return zone_monster_points[randi() % zone_monster_points.size()]


func _random_neutral_spawn_point() -> Vector2:
	var r: Rect2 = WORLD_SPAWN_RECT
	if not is_instance_valid(_local_player):
		return _random_world_pos()
	var p: Vector2 = _local_player.global_position
	var zone_neutral_points: Array[Vector2] = _collect_zone_spawn_points("NeutralSpawns")
	if not zone_neutral_points.is_empty():
		for _i in 20:
			var base: Vector2 = zone_neutral_points[randi() % zone_neutral_points.size()]
			var pos_zone: Vector2 = base + Vector2(randf_range(-36.0, 36.0), randf_range(-36.0, 36.0))
			if r.has_point(pos_zone) and pos_zone.distance_to(p) >= NEUTRAL_SPAWN_MIN_DIST_FROM_PLAYER:
				return pos_zone
	for _i in 48:
		var pos := _random_world_pos()
		if not r.has_point(pos):
			continue
		if pos.distance_to(p) >= NEUTRAL_SPAWN_MIN_DIST_FROM_PLAYER:
			return pos
	return _random_world_pos()


func _collect_zone_spawn_points(root_name: String, monster_only_zone: bool = false) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for key in _loaded_regions.keys():
		var row: Dictionary = _loaded_regions[key] as Dictionary
		var n: Node2D = row.get("node") as Node2D
		if not is_instance_valid(n):
			continue
		if monster_only_zone and not bool(row.get("allow_monster_spawn", false)):
			continue
		var root: Node = n.get_node_or_null(root_name)
		if not is_instance_valid(root):
			continue
		for c in root.get_children():
			if is_instance_valid(c) and c is Node2D:
				points.append((c as Node2D).global_position)
	return points


func _find_zone_spawn_point(root_name: String, marker_name: String, fallback: Vector2) -> Vector2:
	for key in _loaded_regions.keys():
		var row: Dictionary = _loaded_regions[key] as Dictionary
		var n: Node2D = row.get("node") as Node2D
		if not is_instance_valid(n):
			continue
		var path: String = "%s/%s" % [root_name, marker_name]
		var marker: Node2D = n.get_node_or_null(path) as Node2D
		if is_instance_valid(marker):
			return marker.global_position
	return fallback


func _is_spawn_position_clear(root: Node2D, pos: Vector2, min_dist: float) -> bool:
	if not is_instance_valid(root):
		return true
	var min_dist_sq: float = min_dist * min_dist
	for c in root.get_children():
		if not is_instance_valid(c) or not c is Node2D:
			continue
		var n: Node2D = c as Node2D
		if n.global_position.distance_squared_to(pos) < min_dist_sq:
			return false
	return true


func _tick_ecology_conflicts() -> void:
	if not is_instance_valid(monsters_root):
		return
	if not is_instance_valid(_neutral_root):
		return
	var monsters: Array = []
	for m in monsters_root.get_children():
		if is_instance_valid(m) and m is Node2D:
			monsters.append(m)
	if monsters.is_empty():
		return
	var neutrals: Array = []
	for n in _neutral_root.get_children():
		if is_instance_valid(n) and n is Node2D:
			neutrals.append(n)
	if neutrals.is_empty():
		return
	if randf() > 0.45:
		return
	var attacker: Node2D = monsters[randi() % monsters.size()] as Node2D
	if not is_instance_valid(attacker):
		return
	var choose_neutral: bool = randf() < 0.72
	var target: Node2D = null
	if choose_neutral:
		var neutral_candidates: Array[Node2D] = []
		for n in neutrals:
			var nn: Node2D = n as Node2D
			if is_instance_valid(nn) and attacker.global_position.distance_to(nn.global_position) <= ECOLOGY_ENGAGE_DISTANCE:
				neutral_candidates.append(nn)
		if not neutral_candidates.is_empty():
			target = neutral_candidates[randi() % neutral_candidates.size()]
	else:
		if monsters.size() <= 1:
			return
		var monster_candidates: Array[Node2D] = []
		for m in monsters:
			var mm: Node2D = m as Node2D
			if not is_instance_valid(mm) or mm == attacker:
				continue
			if attacker.global_position.distance_to(mm.global_position) <= ECOLOGY_ENGAGE_DISTANCE:
				monster_candidates.append(mm)
		if not monster_candidates.is_empty():
			target = monster_candidates[randi() % monster_candidates.size()]
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		var dmg: int = 2 + randi() % 7
		target.call("take_damage", dmg)
		if target.has_method("reveal_hp_bar"):
			target.call("reveal_hp_bar", 1.5)
		_spawn_floating_feedback(target.global_position + Vector2(0.0, -26.0), "-%d 生态争斗" % dmg, Color8(255, 176, 122), 14, 30.0)
	if is_instance_valid(_local_player) and attacker.has_meta("is_boss") and randf() < 0.38:
		var aim: Vector2 = _local_player.global_position + Vector2(randf_range(-32.0, 32.0), randf_range(-20.0, 20.0))
		_on_monster_special_attack(attacker.get_instance_id(), 16, aim, 30.0, "spit")


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
			SceneTransition.transition_to(HALL_SCENE)
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


func _disconnect_cloud_signals() -> void:
	if _wn.cloud_peer_joined.is_connected(_on_cloud_peer_joined):
		_wn.cloud_peer_joined.disconnect(_on_cloud_peer_joined)
	if _wn.cloud_peer_left.is_connected(_on_cloud_peer_left):
		_wn.cloud_peer_left.disconnect(_on_cloud_peer_left)
	if _wn.cloud_peer_moved.is_connected(_on_cloud_peer_moved):
		_wn.cloud_peer_moved.disconnect(_on_cloud_peer_moved)
	if _wn.cloud_peer_profile.is_connected(_on_cloud_peer_profile):
		_wn.cloud_peer_profile.disconnect(_on_cloud_peer_profile)
	if _wn.cloud_connection_failed.is_connected(_on_cloud_ws_broken):
		_wn.cloud_connection_failed.disconnect(_on_cloud_ws_broken)


func _on_cloud_ws_broken(_reason: String) -> void:
	MoeDialogBus.show_dialog("联机断开", "与服务器的 WebSocket 已关闭。")
	_disconnect_cloud_signals()
	_wn.leave_session()
	SceneTransition.transition_to(HALL_SCENE)


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
