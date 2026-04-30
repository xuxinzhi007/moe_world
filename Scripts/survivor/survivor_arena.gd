extends Node2D

## 单机「生存试炼」副本：从大世界传送门进入；离开或倒下后回到大世界。战斗与大世界对齐（职业 / 冷却 / 音效）。

const PLAYER_SCENE := preload("res://Scenes/actors/Player.tscn")
const MONSTER_SCENE := preload("res://Scenes/actors/Monster.tscn")
const FLOATING_TEXT_SCENE := preload("res://Scenes/fx/FloatingWorldText.tscn")
const MOBILE_GAMEPLAY_CONTROLS := preload("res://Scenes/ui/MobileGameplayControls.tscn")
const MAGE_SPELL_FX_SCENE := preload("res://Scenes/fx/MageSpellFX.tscn")
const ARCHER_ARROW_SCENE := preload("res://Scenes/projectiles/ArcherArrowProjectile.tscn")
const PRIEST_HOLY_RAY_FX_SCENE := preload("res://Scenes/fx/PriestHolyRayFX.tscn")
const CHARACTER_BUILD_PANEL := preload("res://Scenes/ui/CharacterBuildPanel.tscn")
const UiTheme := preload("res://Scripts/meta/ui_theme.gd")
const WORLD_SCENE := "res://Scenes/maps/World_Main.tscn"
const HALL_SCENE := "res://Scenes/ui/HallScene.tscn"

const MELEE_RANGE: float = 78.0
const BASE_MELEE_DAMAGE: int = 12
const MAGE_LOCK_RANGE: float = 248.0

## 场地半宽/半高（世界坐标，中心为 0,0）
const ARENA_HALF: Vector2 = Vector2(880.0, 480.0)
const MONSTER_CAP: int = 52
const SPAWN_BASE_INTERVAL: float = 1.15
const WAVE_EVERY_SEC: float = 28.0
const MONSTER_CONTACT_RANGE: float = 42.0
const MONSTER_CONTACT_RANGE_SQ: float = MONSTER_CONTACT_RANGE * MONSTER_CONTACT_RANGE
const MONSTER_CONTACT_INTERVAL: float = 0.55
## 玩家头顶附近飘字（相对角色原点，Y+ 向下）
const PLAYER_FLOAT_OVERHEAD := Vector2(0.0, -96.0)

@export var melee_attack_fx_scene: PackedScene = preload("res://Scenes/fx/MeleeAttackFX.tscn")
@export var mage_spell_fx_scene: PackedScene = MAGE_SPELL_FX_SCENE

@onready var _monsters: Node2D = $Monsters
@onready var _players: Node2D = $Players
@onready var _combat_fx: Node2D = $CombatFX
@onready var _float_root: Node2D = $FloatingFeedback
@onready var _camera: Camera2D = $MainCamera
@onready var _ui_layer: CanvasLayer = $UiLayer
@onready var _growth_overlay_layer: CanvasLayer = $GrowthOverlayLayer

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
## 每只怪独立伤害冷却（与大世界保持一致）
var _monster_hit_cd: Dictionary = {}
var _screen_damage_overlay: ColorRect = null
var _trial_defeat_handled: bool = false
var _trial_result_layer: CanvasLayer = null
var _damage_number_pool: Array[Node2D] = []
var _damage_pool_cursor: int = 0
const DAMAGE_NUMBER_POOL_SIZE := 20
var _max_single_hit: int = 0
var _total_damage_dealt: int = 0
var _hud_refresh_cd: float = 0.0
var _camera_shake_tween: Tween = null


func _ready() -> void:
	if WorldNetwork.is_cloud():
		push_warning("SurvivorArena: 联机态不应进入，退回大厅。")
		SceneTransition.transition_to(HALL_SCENE)
		return
	GameAudio.play_bgm_trial()
	_build_ui()
	_setup_growth_overlay()
	_setup_damage_overlay()
	_setup_damage_number_pool()
	_combat_level = maxi(1, CharacterBuild.runtime_combat_level)
	_combat_xp = CharacterBuild.runtime_combat_xp
	_combat_xp_next = CharacterBuild.combat_xp_to_next_level(_combat_level)
	CharacterBuild.ensure_player_hp()
	_spawn_player()
	_refresh_hud()
	_spawn_opening_batch()
	_mount_trial_mobile_controls()
	SceneTransition.fade_in()


func _build_ui() -> void:
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
	var panel: Control = CHARACTER_BUILD_PANEL.instantiate() as Control
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.visible = false
	_growth_overlay_layer.add_child(panel)
	_growth_overlay = panel


func _try_surge() -> void:
	if not _can_local_attack():
		return
	if CharacterBuild.activate_surge():
		if CharacterBuild.get_combat_class() == CharacterBuild.CLASS_ARCHER and is_instance_valid(_local_player):
			var dpa: int = maxi(1, int(round(float(_melee_damage()) * 0.9 * 0.13)))
			ArcherVolley.spawn_radial_volley(_combat_fx, _local_player.global_position, dpa)
		GameAudio.ui_confirm()


## 试炼内挂载与大世界 HUD 同一份 `MobileGameplayControls` 子场景（避免重复维护两套摇杆/按键布局）。
## 必须挂在 `_ui_layer`（CanvasLayer）下：若直接 add 到 Node2D 根节点，全屏 Control 无法按视口布局，按钮会挤到世界坐标中间盖住怪物。
func _mount_trial_mobile_controls() -> void:
	var mobile: Control = MOBILE_GAMEPLAY_CONTROLS.instantiate() as Control
	mobile.name = "MobileControls"
	mobile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mobile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile.z_index = 4
	_ui_layer.add_child(mobile)
	mobile.move_input.connect(_on_mobile_move)
	mobile.attack_pressed.connect(_try_primary_attack)
	mobile.surge_pressed.connect(_try_surge)
	var inter: Control = mobile.get_node_or_null("InteractButton") as Control
	if inter:
		inter.visible = false


func _on_mobile_move(direction: Vector2) -> void:
	if is_instance_valid(_local_player) and _local_player.is_in_dialog:
		_local_player.set_mobile_input(Vector2.ZERO)
		return
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
	## 批量递减每只怪的独立伤害 CD（与大世界保持一致）
	for k in _monster_hit_cd.keys():
		_monster_hit_cd[k] = _monster_hit_cd[k] - delta
		if _monster_hit_cd[k] <= 0.0:
			_monster_hit_cd.erase(k)
	_run_time += delta
	_next_wave_at -= delta
	if _next_wave_at <= 0.0:
		_next_wave_at = WAVE_EVERY_SEC
		_wave += 1
		_show_wave_banner()
		_spawn_floating_feedback(Vector2.ZERO, "第 %d 波！" % _wave, Color8(255, 200, 120), 24, 64.0)
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		_spawn_cd = _spawn_interval()
		var cap_left: int = MONSTER_CAP - _monsters.get_child_count()
		if cap_left > 0:
			var n: int = mini(cap_left, 2 + int(floor(float(_wave) / 2.0)))
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
	_hud_refresh_cd = maxf(0.0, _hud_refresh_cd - delta)
	if _hud_refresh_cd <= 0.0:
		_hud_refresh_cd = 0.12
		_refresh_hud()


func _spawn_interval() -> float:
	return maxf(0.35, SPAWN_BASE_INTERVAL / (1.0 + float(_wave) * 0.12))


func _spawn_one_monster() -> void:
	if not is_instance_valid(_local_player):
		return
	var pos := _random_spawn_on_ring()
	var mon = MONSTER_SCENE.instantiate()
	var hp_bonus: int = 18 + _wave * 10
	var spd: float = 46.0 + minf(40.0, float(_wave) * 3.5)
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
	var outer: float = minf(ARENA_HALF.length() - 40.0, inner + 180.0 + float(_wave) * 8.0)
	var d: float = randf_range(inner, outer)
	var ang: float = randf() * TAU
	var q: Vector2 = p + Vector2(cos(ang), sin(ang)) * d
	q.x = clampf(q.x, -ARENA_HALF.x + 48.0, ARENA_HALF.x - 48.0)
	q.y = clampf(q.y, -ARENA_HALF.y + 48.0, ARENA_HALF.y - 48.0)
	return q


func _refresh_hud() -> void:
	_hud_wave.text = "波次 %d" % _wave
	_hud_time.text = "时间 %.0f 秒" % _run_time
	_hud_kills.text = "击杀 %d" % _kills
	_hud_combat.text = "Lv.%d  %d/%d EXP  HP %d/%d" % [
		_combat_level, _combat_xp, _combat_xp_next,
		CharacterBuild.get_player_hp(), CharacterBuild.get_max_hp()
	]
	_sync_player_level_caption()


func _sync_player_level_caption() -> void:
	if not is_instance_valid(_local_player):
		return
	if _local_player.has_method("set_level_exp_progress"):
		_local_player.set_level_exp_progress(_combat_level, _combat_xp, _combat_xp_next)
	elif _local_player.has_method("set_level_exp_caption"):
		_local_player.set_level_exp_caption("Lv.%d  %d/%d EXP" % [_combat_level, _combat_xp, _combat_xp_next])
	if _local_player.has_method("set_level_exp_visible"):
		_local_player.set_level_exp_visible(true)
	if _local_player.has_method("set_overhead_hp"):
		_local_player.call("set_overhead_hp", CharacterBuild.get_player_hp(), CharacterBuild.get_max_hp(), true)


func _on_leave_pressed() -> void:
	if _trial_defeat_handled:
		return
	_trial_defeat_handled = true
	GameAudio.ui_click()
	_show_trial_result(false)


func _exit_trial_after_defeat() -> void:
	_trial_defeat_handled = true
	GameAudio.ui_click()
	_show_trial_result(true)


func _apply_monster_contact_damage() -> void:
	if not is_instance_valid(_local_player):
		return
	if CharacterBuild.get_player_hp() <= 0:
		return
	var ppos: Vector2 = _local_player.global_position
	var dmg_base: int = maxi(1, 5 + _wave)
	var hit_any := false
	for m in _monsters.get_children():
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
			## 非冲刺：玩家撞上去 → 推开怪物，不扣血
			var push_key: int = mid + 10000000
			if _monster_hit_cd.get(push_key, 0.0) <= 0.0:
				var push_dir: Vector2 = m2d.global_position - ppos
				if push_dir.length_squared() > 0.01:
					m2d.global_position += push_dir.normalized() * 22.0
				_monster_hit_cd[push_key] = 0.12
			continue
		## 冲刺攻击命中
		if _monster_hit_cd.get(mid, 0.0) > 0.0:
			continue
		var dmg: int = dmg_base + (randi() % 3)
		CharacterBuild.damage_player(dmg)
		_monster_hit_cd[mid] = MONSTER_CONTACT_INTERVAL
		hit_any = true
		_spawn_inline_damage_number(
			ppos + PLAYER_FLOAT_OVERHEAD + Vector2(randf_range(-18.0, 18.0), 0.0),
			"-%d" % dmg,
			Color8(255, 92, 108), 28
		)
		if m.has_method("play_attack_anim"):
			m.call("play_attack_anim", ppos - m2d.global_position)
	if hit_any:
		_flash_damage_overlay()
		_camera_shake(4.5)
		if _local_player.has_method("play_hurt_animation"):
			_local_player.call("play_hurt_animation")


## 受伤红闪遮罩（与大世界保持一致）
func _flash_damage_overlay() -> void:
	if not is_instance_valid(_screen_damage_overlay):
		return
	_screen_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.38)
	var tw := _screen_damage_overlay.create_tween()
	tw.tween_property(_screen_damage_overlay, "color", Color(1.0, 0.0, 0.0, 0.0), 0.45)


## 直接内联创建伤害数字，不依赖 FloatingWorldText 场景（与大世界保持一致）
func _spawn_inline_damage_number(world_pos: Vector2, text: String, col: Color, size: int) -> void:
	if _damage_number_pool.is_empty():
		return
	var n: Node2D = _damage_number_pool[_damage_pool_cursor]
	_damage_pool_cursor = (_damage_pool_cursor + 1) % _damage_number_pool.size()
	if n.has_meta("tw"):
		var old_tw: Variant = n.get_meta("tw")
		if old_tw is Tween and (old_tw as Tween).is_valid():
			(old_tw as Tween).kill()
	n.global_position = world_pos
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


## 初始化受伤红闪遮罩（与大世界保持一致）
func _setup_damage_overlay() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 50
	add_child(cl)
	_screen_damage_overlay = ColorRect.new()
	_screen_damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
	_screen_damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_screen_damage_overlay)


func _setup_damage_number_pool() -> void:
	if not is_instance_valid(_float_root) or not _damage_number_pool.is_empty():
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
		_float_root.add_child(n)
		_damage_number_pool.append(n)


func _show_trial_result(defeated: bool) -> void:
	if is_instance_valid(_trial_result_layer):
		return
	_trial_result_layer = CanvasLayer.new()
	_trial_result_layer.layer = 120
	add_child(_trial_result_layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_trial_result_layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(430.0, 0.0)
	var style := UiTheme.modern_glass_card(20, 0.96)
	panel.add_theme_stylebox_override("panel", style)
	_trial_result_layer.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.text = "试炼结束"
	vb.add_child(title)
	var desc := Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text = "你在怪潮中倒下，已准备返回大世界。" if defeated else "本次挑战已结算，准备返回大世界。"
	vb.add_child(desc)
	var stats := Label.new()
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 18)
	var dps: float = 0.0
	if _run_time > 0.01:
		dps = float(_kills) / _run_time
	var dmg_ps: float = 0.0
	if _run_time > 0.01:
		dmg_ps = float(_total_damage_dealt) / _run_time
	var rank: String = _trial_rank_text(defeated, dps)
	stats.text = "波次 %d  ·  击杀 %d  ·  存活 %.0f 秒\n最高伤害 %d  ·  每秒击杀 %.2f\n秒伤 %.1f  ·  评价：%s\nLv.%d  %d/%d EXP" % [
		_wave, _kills, _run_time, _max_single_hit, dps, dmg_ps, rank, _combat_level, _combat_xp, _combat_xp_next
	]
	vb.add_child(stats)
	var btn := Button.new()
	btn.text = "确认返回"
	btn.custom_minimum_size = Vector2(160.0, 46.0)
	btn.focus_mode = Control.FOCUS_NONE
	btn.modulate.a = 0.0
	btn.pressed.connect(func() -> void:
		_confirm_leave_trial(defeated)
	, CONNECT_ONE_SHOT)
	vb.add_child(btn)
	var tw_btn := create_tween()
	tw_btn.tween_interval(0.10)
	tw_btn.tween_property(btn, "modulate:a", 1.0, 0.18)


func _confirm_leave_trial(defeated: bool) -> void:
	CharacterBuild.set_runtime_combat_progress(_combat_level, _combat_xp)
	_grant_trial_rewards(defeated)
	PlayerInventory.mark_preserve_once()
	if defeated:
		CharacterBuild.full_heal_player()
	GameAudio.ui_confirm()
	SceneTransition.transition_to(WORLD_SCENE)


func _grant_trial_rewards(defeated: bool) -> void:
	var dps: float = 0.0
	if _run_time > 0.01:
		dps = float(_kills) / _run_time
	var rank: String = _trial_rank_text(defeated, dps)
	var rank_mul: float = 1.0
	match rank:
		"S":
			rank_mul = 1.45
		"A":
			rank_mul = 1.25
		"B":
			rank_mul = 1.0
		"C":
			rank_mul = 0.82
		_:
			rank_mul = 0.68
	var gel_gain: int = maxi(1, int(round(float(maxi(2, _kills / 4 + _wave)) * rank_mul)))
	var trial_core_gain: int = maxi(1, int(round(float(maxi(1, _wave / 2)) * rank_mul)))
	PlayerInventory.add_item("slime_gel", "史莱姆凝胶", gel_gain)
	PlayerInventory.add_item("trial_core", "试炼晶核", trial_core_gain)


func _show_wave_banner() -> void:
	if not is_instance_valid(_ui_layer):
		return
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 360.0
	panel.offset_right = -360.0
	panel.offset_top = 92.0
	panel.offset_bottom = 138.0
	panel.modulate.a = 0.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.94, 0.62, 0.25, 0.25)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.set_border_width_all(2)
	style.border_color = Color(1.0, 0.85, 0.55, 0.9)
	panel.add_theme_stylebox_override("panel", style)
	_ui_layer.add_child(panel)
	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.90, 1.0))
	lbl.text = "第 %d 波来袭" % _wave
	panel.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(panel, "scale", Vector2(1.03, 1.03), 0.12).from(Vector2(0.95, 0.95))
	tw.tween_interval(0.28)
	tw.tween_property(panel, "modulate:a", 0.0, 0.22)
	tw.tween_callback(panel.queue_free)


func _trial_rank_text(defeated: bool, kills_per_sec: float) -> String:
	var score: float = float(_wave) * 1.8 + float(_kills) * 0.35 + kills_per_sec * 120.0 + float(_max_single_hit) * 0.10 + float(_total_damage_dealt) * 0.01
	if defeated:
		score *= 0.88
	if score >= 170.0:
		return "S"
	if score >= 130.0:
		return "A"
	if score >= 95.0:
		return "B"
	if score >= 65.0:
		return "C"
	return "D"


func _on_monster_damaged(actual_damage: int, at_global: Vector2) -> void:
	_max_single_hit = maxi(_max_single_hit, actual_damage)
	_total_damage_dealt += actual_damage
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
	CharacterBuild.set_runtime_combat_progress(_combat_level, _combat_xp)
	if _combat_level > prev_level:
		CharacterBuild.grant_points_for_levels(_combat_level - prev_level)
		GameAudio.level_up()
		if is_instance_valid(_local_player):
			_spawn_floating_feedback(
				_local_player.global_position + PLAYER_FLOAT_OVERHEAD,
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
			hit_any = _perform_priest_attack(origin, facing, dmg_mul)
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
	## 玩家攻击动画（与大世界保持一致）
	if is_instance_valid(_local_player) and _local_player.has_method("play_attack_animation"):
		_local_player.call("play_attack_animation", Vector2.from_angle(facing))
	_attack_cd = CharacterBuild.effective_primary_cooldown()


func _camera_shake(px: float) -> void:
	if not is_instance_valid(_camera):
		return
	var o := _camera.offset
	if is_instance_valid(_camera_shake_tween):
		_camera_shake_tween.kill()
	_camera_shake_tween = create_tween()
	_camera_shake_tween.tween_property(_camera, "offset", o + Vector2(px, -px * 0.3), 0.04)
	_camera_shake_tween.tween_property(_camera, "offset", o - Vector2(px * 0.6, px * 0.2), 0.05)
	_camera_shake_tween.tween_property(_camera, "offset", o, 0.07)


func _nearest_monster(origin: Vector2, max_dist: float) -> Node2D:
	var best: Node2D = null
	var best_d2: float = max_dist * max_dist
	for n in _monsters.get_children():
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
	for n in _monsters.get_children():
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
	## 订阅命中信号：箭矢命中怪物时触发相机震动（与大世界体验对齐）
	if arrow.has_signal("hit_monster"):
		arrow.hit_monster.connect(_on_archer_arrow_hit.bind(), CONNECT_ONE_SHOT)
	return false


func _on_archer_arrow_hit(_at_pos: Vector2) -> void:
	_camera_shake(2.8)


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
	for n in _monsters.get_children():
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
				Color8(120, 255, 168),
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


func _spawn_priest_holy_ray_fx(origin: Vector2, angle: float) -> void:
	if PRIEST_HOLY_RAY_FX_SCENE == null:
		return
	var ray_fx: Node = PRIEST_HOLY_RAY_FX_SCENE.instantiate()
	_combat_fx.add_child(ray_fx)
	if ray_fx.has_method("play_holy_ray"):
		ray_fx.play_holy_ray(origin, angle)


func _perform_priest_attack(origin: Vector2, facing: float, dmg_mul: float) -> bool:
	_spawn_priest_holy_ray_fx(origin, facing)
	var dmg: int = int(round(float(_melee_damage()) * dmg_mul * 0.75))
	var target_pos := origin + Vector2.from_angle(facing) * 85.0
	AttackRangeFx.spawn_mage_hit_ring(_combat_fx, target_pos, 48.0)
	var hit_any := false
	for n in _monsters.get_children():
		if not is_instance_valid(n) or not n is Node2D:
			continue
		if not n.has_method("take_damage"):
			continue
		var m: Node2D = n as Node2D
		if m.global_position.distance_to(target_pos) <= 48.0:
			hit_any = true
			n.take_damage(maxi(1, dmg))
	return hit_any
