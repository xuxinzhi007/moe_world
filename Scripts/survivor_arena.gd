extends Node2D

## 单机「生存试炼」副本：从大世界传送门进入；离开或倒下后回到 WorldScene。战斗与 WorldScene 对齐（职业 / 冷却 / 音效）。

const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const MONSTER_SCENE := preload("res://Scenes/Monster.tscn")
const FLOATING_TEXT_SCENE := preload("res://Scenes/FloatingWorldText.tscn")
const SURVIVOR_MOBILE_HUD := preload("res://Scenes/SurvivorMobileHud.tscn")
const MAGE_SPELL_FX_SCENE := preload("res://Scenes/MageSpellFX.tscn")
const ARCHER_ARROW_SCENE := preload("res://Scenes/ArcherArrowProjectile.tscn")
const CHARACTER_BUILD_PANEL := preload("res://Scenes/CharacterBuildPanel.tscn")
const DECO_TREE := preload("res://Assets/characters/树木.png")
const UiTheme := preload("res://Scripts/ui_theme.gd")
const WORLD_SCENE := "res://Scenes/WorldScene.tscn"
const HALL_SCENE := "res://Scenes/HallScene.tscn"

const MELEE_RANGE: float = 78.0
const BASE_MELEE_DAMAGE: int = 12
const MAGE_LOCK_RANGE: float = 248.0

## 场地半宽/半高（世界坐标，中心为 0,0）
const ARENA_HALF: Vector2 = Vector2(880.0, 480.0)
const MONSTER_CAP: int = 52
const SPAWN_BASE_INTERVAL: float = 1.15
const WAVE_EVERY_SEC: float = 28.0
const MONSTER_CONTACT_RANGE: float = 42.0
const MONSTER_CONTACT_INTERVAL: float = 0.55

@export var melee_attack_fx_scene: PackedScene = preload("res://Scenes/MeleeAttackFX.tscn")
@export var mage_spell_fx_scene: PackedScene = MAGE_SPELL_FX_SCENE

var _players: Node2D
var _monsters: Node2D
var _combat_fx: Node2D
var _float_root: Node2D
var _camera: Camera2D
var _ui_layer: CanvasLayer
var _hud_wave: Label
var _hud_time: Label
var _hud_kills: Label
var _hud_combat: Label
var _leave_btn: Button
var _growth_overlay: Control

var _local_player: CharacterBody2D
var _attack_cd: float = 0.0
var _combat_level: int = 1
var _combat_xp: int = 0
var _combat_xp_next: int = 50
var _wave: int = 1
var _run_time: float = 0.0
var _spawn_cd: float = 0.0
var _kills: int = 0
var _next_wave_at: float = WAVE_EVERY_SEC
var _contact_hit_cd: float = 0.0
var _trial_defeat_handled: bool = false


func _ready() -> void:
	if WorldNetwork.is_cloud():
		push_warning("SurvivorArena: 联机态不应进入，退回大厅。")
		get_tree().change_scene_to_file(HALL_SCENE)
		return
	_build_arena_world()
	_build_ui()
	_setup_growth_overlay()
	_combat_level = maxi(1, CharacterBuild.runtime_combat_level)
	_combat_xp = 0
	_combat_xp_next = CharacterBuild.combat_xp_to_next_level(_combat_level)
	CharacterBuild.set_runtime_combat_level(_combat_level)
	_spawn_player()
	_refresh_hud()
	_spawn_opening_batch()
	_mount_survivor_mobile_hud()


func _build_arena_world() -> void:
	var g := ColorRect.new()
	g.color = Color8(62, 48, 58, 255)
	g.size = ARENA_HALF * 2.0
	g.position = -ARENA_HALF
	g.z_index = -8
	add_child(g)

	_add_arena_edge_decoration()

	## 怪物的节点必须先加入，玩家后加入，否则同 z 排序时整层怪会画在角色上面（看起来像被挡住）。
	_monsters = Node2D.new()
	_monsters.name = "Monsters"
	add_child(_monsters)

	_players = Node2D.new()
	_players.name = "Players"
	add_child(_players)

	_combat_fx = Node2D.new()
	_combat_fx.name = "CombatFX"
	_combat_fx.z_index = 8
	add_child(_combat_fx)

	_float_root = Node2D.new()
	_float_root.name = "FloatingFeedback"
	_float_root.z_index = 14
	add_child(_float_root)

	_camera = Camera2D.new()
	_camera.name = "MainCamera"
	_camera.position = Vector2.ZERO
	add_child(_camera)

	_add_wall("W_L", Rect2(-ARENA_HALF.x - 40.0, -ARENA_HALF.y, 40.0, ARENA_HALF.y * 2.0))
	_add_wall("W_R", Rect2(ARENA_HALF.x, -ARENA_HALF.y, 40.0, ARENA_HALF.y * 2.0))
	_add_wall("W_T", Rect2(-ARENA_HALF.x - 40.0, -ARENA_HALF.y - 40.0, ARENA_HALF.x * 2.0 + 80.0, 40.0))
	_add_wall("W_B", Rect2(-ARENA_HALF.x - 40.0, ARENA_HALF.y, ARENA_HALF.x * 2.0 + 80.0, 40.0))


func _add_arena_edge_decoration() -> void:
	var deco := Node2D.new()
	deco.name = "ArenaDecoration"
	deco.z_index = -4
	add_child(deco)
	var positions: Array[Vector2] = [
		Vector2(-ARENA_HALF.x + 120, -ARENA_HALF.y + 90),
		Vector2(ARENA_HALF.x - 130, -ARENA_HALF.y + 100),
		Vector2(-ARENA_HALF.x + 100, ARENA_HALF.y - 120),
		Vector2(ARENA_HALF.x - 110, ARENA_HALF.y - 130),
	]
	for p: Vector2 in positions:
		var s := Sprite2D.new()
		s.texture = DECO_TREE
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = p
		s.scale = Vector2(0.16, 0.16)
		s.offset = Vector2(0, -12)
		deco.add_child(s)


func _add_wall(wname: String, r: Rect2) -> void:
	var b := StaticBody2D.new()
	b.name = wname
	b.collision_layer = 1
	b.collision_mask = 0
	var sh := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	sh.shape = rs
	sh.position = r.position + r.size * 0.5
	b.add_child(sh)
	add_child(b)


func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 30
	add_child(_ui_layer)

	var bar := Panel.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 72.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("panel", UiTheme.modern_hud_bar_bottom_round())
	_ui_layer.add_child(bar)

	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 12.0
	hb.offset_top = 8.0
	hb.offset_right = -12.0
	hb.offset_bottom = -8.0
	hb.add_theme_constant_override("separation", 14)
	bar.add_child(hb)

	_hud_wave = Label.new()
	_hud_time = Label.new()
	_hud_kills = Label.new()
	_hud_combat = Label.new()
	for lb: Label in [_hud_wave, _hud_time, _hud_kills, _hud_combat]:
		lb.add_theme_color_override("font_color", Color8(72, 48, 62))
		lb.add_theme_font_size_override("font_size", 16)
		hb.add_child(lb)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_leave_btn = Button.new()
	_leave_btn.text = "返回大世界"
	_leave_btn.focus_mode = Control.FOCUS_NONE
	_leave_btn.pressed.connect(_on_leave_pressed)
	hb.add_child(_leave_btn)
	_style_cta_btn(_leave_btn, Color8(120, 90, 140))


func _setup_growth_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 42
	layer.name = "GrowthOverlayLayer"
	var panel: Control = CHARACTER_BUILD_PANEL.instantiate() as Control
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.visible = false
	layer.add_child(panel)
	add_child(layer)
	_growth_overlay = panel


func _try_surge() -> void:
	if not _can_local_attack():
		return
	if CharacterBuild.activate_surge():
		if CharacterBuild.get_combat_class() == CharacterBuild.CLASS_ARCHER and is_instance_valid(_local_player):
			var dpa: int = maxi(1, int(round(float(_melee_damage()) * 0.9 * 0.13)))
			ArcherVolley.spawn_radial_volley(_combat_fx, _local_player.global_position, dpa)
		GameAudio.ui_confirm()


## 试炼内始终挂载与大世界相同的虚拟摇杆 / 攻击 / 强击（宽屏下也会显示，避免找不到按键）。
func _mount_survivor_mobile_hud() -> void:
	var hud: CanvasLayer = SURVIVOR_MOBILE_HUD.instantiate() as CanvasLayer
	hud.layer = 28
	add_child(hud)
	hud.move_input.connect(_on_mobile_move)
	hud.attack_pressed.connect(_try_primary_attack)
	hud.surge_pressed.connect(_try_surge)
	var inter: Control = hud.get_node_or_null("InteractButton") as Control
	if inter:
		inter.visible = false


func _on_mobile_move(direction: Vector2) -> void:
	if is_instance_valid(_local_player):
		_local_player.set_mobile_input(direction)


func _style_cta_btn(b: Button, bg: Color) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = bg
	n.corner_radius_top_left = 16
	n.corner_radius_top_right = 16
	n.corner_radius_bottom_left = 16
	n.corner_radius_bottom_right = 16
	n.content_margin_left = 14
	n.content_margin_top = 10
	n.content_margin_right = 14
	n.content_margin_bottom = 10
	var h := n.duplicate()
	(h as StyleBoxFlat).bg_color = bg.lightened(0.08)
	var p := n.duplicate()
	(p as StyleBoxFlat).bg_color = bg.darkened(0.08)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_color_override("font_color", Color8(255, 255, 255))


func _spawn_player() -> void:
	var p: CharacterBody2D = PLAYER_SCENE.instantiate() as CharacterBody2D
	p.global_position = Vector2.ZERO
	_players.add_child(p)
	_local_player = p
	var uname := _saved_username()
	if uname.is_empty():
		uname = "萌酱"
	p.set_display_name(uname)
	_camera.global_position = p.global_position
	_sync_player_level_caption()


func _saved_username() -> String:
	if ProjectSettings.has_setting("moe_world/current_user"):
		var user_data: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if user_data is Dictionary:
			return str((user_data as Dictionary).get("username", "")).strip_edges()
	return ""


func _spawn_opening_batch() -> void:
	for _i in 10:
		_spawn_one_monster()


func _physics_process(delta: float) -> void:
	if _trial_defeat_handled:
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_contact_hit_cd = maxf(0.0, _contact_hit_cd - delta)
	_run_time += delta
	_next_wave_at -= delta
	if _next_wave_at <= 0.0:
		_next_wave_at = WAVE_EVERY_SEC
		_wave += 1
		_spawn_floating_feedback(Vector2.ZERO, "第 %d 波！" % _wave, Color8(255, 200, 120), 24, 64.0)
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		_spawn_cd = _spawn_interval()
		var cap_left: int = MONSTER_CAP - _monsters.get_child_count()
		if cap_left > 0:
			var n: int = mini(cap_left, 2 + _wave / 2)
			for _j in n:
				_spawn_one_monster()
	if is_instance_valid(_local_player) and is_instance_valid(_camera):
		var t: float = clampf(12.0 * delta, 0.0, 1.0)
		_camera.global_position = _camera.global_position.lerp(_local_player.global_position, t)
	if _can_local_attack() and Input.is_action_just_pressed("attack"):
		_try_primary_attack()
	if _can_local_attack() and Input.is_action_just_pressed("skill_surge"):
		_try_surge()
	_apply_monster_contact_damage()
	if _trial_defeat_handled:
		return
	if CharacterBuild.get_player_hp() <= 0:
		_trial_defeat_handled = true
		_exit_trial_after_defeat()
		return
	_refresh_hud()


func _spawn_interval() -> float:
	return maxf(0.35, SPAWN_BASE_INTERVAL / (1.0 + float(_wave) * 0.12))


func _spawn_one_monster() -> void:
	if not is_instance_valid(_local_player):
		return
	var pos := _random_spawn_on_ring()
	var mon = MONSTER_SCENE.instantiate()
	var hp_bonus: int = 18 + _wave * 10
	var spd: float = 46.0 + mini(40.0, float(_wave) * 3.5)
	mon.max_hp = hp_bonus
	mon.reward_xp = maxi(3, 4 + _wave * 2)
	mon.move_speed = spd
	mon.aggro_range = 2000.0
	mon.damaged.connect(_on_monster_damaged)
	mon.died.connect(_on_monster_died)
	_monsters.add_child(mon)
	if mon is Node2D:
		(mon as Node2D).global_position = pos
	if mon.has_method("set_aggro_target"):
		mon.set_aggro_target(_local_player)


func _random_spawn_on_ring() -> Vector2:
	var p: Vector2 = _local_player.global_position if is_instance_valid(_local_player) else Vector2.ZERO
	var inner: float = 220.0 + randf() * 120.0
	var outer: float = mini(ARENA_HALF.length() - 40.0, inner + 180.0 + float(_wave) * 8.0)
	var d: float = randf_range(inner, outer)
	var ang: float = randf() * TAU
	var q: Vector2 = p + Vector2(cos(ang), sin(ang)) * d
	q.x = clampf(q.x, -ARENA_HALF.x + 48.0, ARENA_HALF.x - 48.0)
	q.y = clampf(q.y, -ARENA_HALF.y + 48.0, ARENA_HALF.y - 48.0)
	return q


func _refresh_hud() -> void:
	_hud_wave.text = "波次 %d" % _wave
	_hud_time.text = "时间 %.0f 秒" % _run_time
	_hud_kills.text = "击败 %d" % _kills
	_hud_combat.text = "Lv.%d  %d/%d EXP  HP %d/%d" % [
		_combat_level, _combat_xp, _combat_xp_next,
		CharacterBuild.get_player_hp(), CharacterBuild.get_max_hp()
	]
	_sync_player_level_caption()


func _sync_player_level_caption() -> void:
	if not is_instance_valid(_local_player):
		return
	if _local_player.has_method("set_level_exp_caption"):
		_local_player.set_level_exp_caption("Lv.%d  %d/%d EXP" % [_combat_level, _combat_xp, _combat_xp_next])
	if _local_player.has_method("set_level_exp_visible"):
		_local_player.set_level_exp_visible(true)


func _on_leave_pressed() -> void:
	GameAudio.ui_click()
	CharacterBuild.set_runtime_combat_level(_combat_level)
	get_tree().change_scene_to_file(WORLD_SCENE)


func _exit_trial_after_defeat() -> void:
	GameAudio.ui_click()
	CharacterBuild.set_runtime_combat_level(_combat_level)
	CharacterBuild.full_heal_player()
	if is_instance_valid(_local_player):
		_spawn_floating_feedback(_local_player.global_position, "倒下… 已送回大世界", Color8(255, 120, 140), 20, 52.0)
	get_tree().change_scene_to_file(WORLD_SCENE)


func _apply_monster_contact_damage() -> void:
	if _contact_hit_cd > 0.0:
		return
	if not is_instance_valid(_local_player):
		return
	if CharacterBuild.get_player_hp() <= 0:
		return
	var ppos: Vector2 = _local_player.global_position
	var dmg: int = 5 + _wave
	for m in _monsters.get_children():
		if not m is Node2D:
			continue
		if not m.has_method("can_damage_player_on_contact"):
			continue
		if not m.can_damage_player_on_contact():
			continue
		var m2: Node2D = m as Node2D
		if ppos.distance_to(m2.global_position) > MONSTER_CONTACT_RANGE:
			continue
		CharacterBuild.damage_player(dmg)
		_contact_hit_cd = MONSTER_CONTACT_INTERVAL
		_spawn_floating_feedback(ppos, "-%d" % dmg, Color8(255, 92, 108), 19, 40.0)
		break


func _on_monster_damaged(actual_damage: int, at_global: Vector2) -> void:
	_spawn_floating_feedback(at_global, str(actual_damage), Color8(255, 188, 120), 20, 44.0)


func _on_monster_died(reward_xp: int, at_global: Vector2) -> void:
	GameAudio.monster_death()
	_kills += 1
	_grant_xp(reward_xp)
	GameAudio.xp_tick()
	_spawn_floating_feedback(at_global, "+%d 经验" % reward_xp, Color8(118, 232, 168), 21, 54.0)


func _grant_xp(amount: int) -> void:
	## 怪潮击杀极多，略压低单次入账，避免升级过快。
	amount = maxi(1, int(round(float(amount) * 0.78)))
	var prev_level: int = _combat_level
	_combat_xp += amount
	while _combat_xp >= _combat_xp_next:
		_combat_xp -= _combat_xp_next
		_combat_level += 1
		_combat_xp_next = CharacterBuild.combat_xp_to_next_level(_combat_level)
	CharacterBuild.set_runtime_combat_level(_combat_level)
	if _combat_level > prev_level:
		CharacterBuild.grant_points_for_levels(_combat_level - prev_level)
		GameAudio.level_up()
		if is_instance_valid(_local_player):
			_spawn_floating_feedback(
				_local_player.global_position,
				"升级到 Lv.%d！" % _combat_level,
				Color8(255, 214, 96),
				26,
				68.0
			)
		if is_instance_valid(_growth_overlay) and _growth_overlay.has_method("open_panel_survivor_trial"):
			if CharacterBuild.unspent_points > 0:
				_growth_overlay.call_deferred("open_panel_survivor_trial")


func _melee_damage() -> int:
	return BASE_MELEE_DAMAGE + _combat_level * 4


func _spawn_floating_feedback(world_pos: Vector2, text: String, color: Color, font_size: int = 22, rise_px: float = 56.0) -> void:
	var ft := FLOATING_TEXT_SCENE.instantiate()
	if not ft is Node2D:
		return
	_float_root.add_child(ft)
	var n2: Node2D = ft as Node2D
	n2.global_position = world_pos + Vector2(randf_range(-8.0, 8.0), -22.0)
	if n2.has_method("begin"):
		n2.call("begin", text, color, font_size, rise_px)


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


func _try_primary_attack() -> void:
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
			_camera_shake(3.0)
	if cls == CharacterBuild.CLASS_WARRIOR:
		var fx_facing: float = _melee_visual_facing_rad(origin, facing)
		_spawn_melee_attack_fx(origin, fx_facing, hit_any)
	_attack_cd = CharacterBuild.effective_primary_cooldown()


func _camera_shake(px: float) -> void:
	if not is_instance_valid(_camera):
		return
	var o := _camera.offset
	var tw := create_tween()
	tw.tween_property(_camera, "offset", o + Vector2(px, -px * 0.3), 0.04)
	tw.tween_property(_camera, "offset", o - Vector2(px * 0.6, px * 0.2), 0.05)
	tw.tween_property(_camera, "offset", o, 0.07)


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


func _melee_visual_facing_rad(origin: Vector2, fallback_facing: float) -> float:
	var nm: Node2D = _nearest_monster(origin, MELEE_RANGE * 1.6)
	if nm != null:
		var to_target: Vector2 = nm.global_position - origin
		if to_target.length_squared() > 4.0:
			return to_target.angle()
	return fallback_facing


func _spawn_melee_attack_fx(origin: Vector2, facing_rad: float, did_hit: bool) -> void:
	if melee_attack_fx_scene == null:
		return
	var dir: Vector2 = Vector2.from_angle(facing_rad).normalized()
	var spawn_pos: Vector2 = origin + dir * 56.0 + Vector2(0.0, -14.0)
	var inst := melee_attack_fx_scene.instantiate()
	_combat_fx.add_child(inst)
	if inst.has_method("play_melee"):
		(inst as Object).call("play_melee", spawn_pos, facing_rad, did_hit)
	elif inst is Node2D:
		var n2: Node2D = inst as Node2D
		n2.global_position = spawn_pos
		n2.rotation = facing_rad + PI * 0.5


func _spawn_mage_aoe_fx(center: Vector2, radius: float) -> void:
	if mage_spell_fx_scene == null:
		return
	var spell_fx: Node = mage_spell_fx_scene.instantiate()
	_combat_fx.add_child(spell_fx)
	if spell_fx.has_method("play_aoe"):
		spell_fx.play_aoe(center, radius)


func _perform_warrior_melee(origin: Vector2, dmg_mul: float) -> bool:
	AttackRangeFx.spawn_melee_ring(_combat_fx, origin, MELEE_RANGE)
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
	_combat_fx.add_child(arrow)
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
	AttackRangeFx.spawn_mage_hit_ring(_combat_fx, center, r)
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
