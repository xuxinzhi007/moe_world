extends Node3D

const HALL_SCENE := "res://Scenes/ui/HallScene.tscn"
const WORLD_2D_SCENE := "res://Scenes/WorldScene.tscn"
const SLIME_3D_SCENE := preload("res://Scenes/actors/monsters3d/Slime3D.tscn")
const WORLD_PICKUP_SCENE := preload("res://Scenes/decor/drops3d/WorldPickup3D.tscn")
const GAMEPLAY_PAUSE_MENU_SCRIPT := preload("res://Scripts/ui/gameplay_pause_menu.gd")

@export var camera_offset: Vector3 = Vector3(0.0, 7.2, 10.5)
@export var camera_smooth: float = 7.0
@export var look_sensitivity: float = 0.008
@export var first_person_enabled: bool = true
@export var first_person_eye_height: float = 0.72
@export var first_person_eye_forward_offset: float = 0.10
@export var first_person_pitch_limit_deg: float = 72.0
@export var melee_range: float = 2.2
@export var melee_damage: int = 12
@export var skill_range: float = 4.6
@export var skill_damage: int = 22
@export var attack_cooldown: float = 0.36
@export var skill_cooldown: float = 2.8
@export var monster_respawn_delay: float = 1.8
@export var monster_contact_damage_interval: float = 0.8
@export var stage_goal_kills: int = 8
@export var max_stage: int = 4
@export var stage_alive_base: int = 3
@export var stage_alive_cap: int = 6
@export var world_half_extent: Vector2 = Vector2(20.0, 20.0)

@onready var _enter_2d_btn: Button = $UILayer/TopBar/HBox/Enter2DBtn
@onready var _back_hall_btn: Button = $UILayer/TopBar/HBox/BackHallBtn
@onready var _player: Node3D = $Playfield/Player3D
@onready var _camera: Camera3D = $Playfield/MainCamera3D
@onready var _monsters_root: Node3D = $Playfield/Monsters
@onready var _spawn_a: Marker3D = $Playfield/SpawnPoints/SpawnA
@onready var _spawn_b: Marker3D = $Playfield/SpawnPoints/SpawnB
@onready var _spawn_c: Marker3D = $Playfield/SpawnPoints/SpawnC
@onready var _status_label: Label = $UILayer/StatusLabel
@onready var _playfield: Node3D = $Playfield
@onready var _attack_btn: Button = $UILayer/AttackBtn
@onready var _dodge_btn: Button = $UILayer/DodgeBtn
@onready var _skill_btn: Button = $UILayer/SkillBtn
@onready var _mobile_move_pad: Control = $UILayer/MobileMovePad
@onready var _stick_base: Control = $UILayer/MobileMovePad/StickBase
@onready var _stick_knob: Control = $UILayer/MobileMovePad/StickBase/StickKnob
@onready var _jump_btn: Button = $UILayer/JumpBtn

var _mobile_dir: Vector2 = Vector2.ZERO
var _mobile_controls_enabled: bool = false
var _move_touch_id: int = -1
var _move_origin: Vector2 = Vector2.ZERO
var _look_touch_id: int = -1
var _move_radius: float = 54.0
var _move_deadzone: float = 8.0
var _stick_knob_rest_pos: Vector2 = Vector2.ZERO
var _camera_yaw: float = 0.0
var _camera_pitch: float = 0.0
var _attack_cd: float = 0.0
var _skill_cd: float = 0.0
var _monster_respawn_cd: float = 0.0
var _player_hit_cd: float = 0.0
var _kills: int = 0
var _status_flash: float = 0.0
var _pc_look_enabled: bool = false
var _combat_level: int = 1
var _combat_xp: int = 0
var _combat_xp_next: int = 60
var _stage_index: int = 1
var _stage_kills: int = 0
var _session_coin_gain: int = 0
var _session_core_gain: int = 0
var _session_xp_gain: int = 0
var _run_elapsed_sec: float = 0.0
var _hud_label: Label = null
var _run_completed: bool = false
var _settle_layer: CanvasLayer = null
var _settle_panel: PanelContainer = null
var _settle_label: Label = null
var _floating_text_root: Node3D = null
var _crosshair_label: Label = null
var _pc_mouse_attack_queued: bool = false
var _pc_pause_menu: CanvasLayer = null


func _ready() -> void:
	if is_instance_valid(_back_hall_btn):
		_back_hall_btn.pressed.connect(_on_back_hall_pressed)
	else:
		push_warning("World3DMain: BackHallBtn 节点缺失")
	if is_instance_valid(_enter_2d_btn):
		_enter_2d_btn.pressed.connect(_on_enter_2d_pressed)
	else:
		push_warning("World3DMain: Enter2DBtn 节点缺失")
	_bind_combat_buttons()
	_init_progress_from_build()
	_ensure_hud_label()
	_ensure_floating_text_root()
	_ensure_settlement_panel()
	_spawn_opening_monsters()
	_refresh_status("目标：击败怪物并完成波次")
	_setup_mobile_pad()
	_setup_pc_mouse_look()
	_setup_pc_pause_menu()
	_sync_first_person_visual()
	_ensure_crosshair()
	_refresh_progress_hud()
	SceneTransition.fade_in()


func _process(delta: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_camera):
		return
	if first_person_enabled:
		var fp_forward: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, _camera_yaw)
		var eye_pos := _player.global_position + Vector3(0.0, first_person_eye_height, 0.0) + fp_forward * first_person_eye_forward_offset
		_camera.global_position = eye_pos
		_camera.global_rotation = Vector3(_camera_pitch, _camera_yaw, 0.0)
		_player.rotation.y = _camera_yaw
	else:
		var follow_offset := camera_offset.rotated(Vector3.UP, _camera_yaw)
		var desired: Vector3 = _player.global_position + follow_offset
		var blend: float = clampf(camera_smooth * delta, 0.0, 1.0)
		_camera.global_position = _camera.global_position.lerp(desired, blend)
		_camera.look_at(_player.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_skill_cd = maxf(0.0, _skill_cd - delta)
	_player_hit_cd = maxf(0.0, _player_hit_cd - delta)
	_monster_respawn_cd = maxf(0.0, _monster_respawn_cd - delta)
	if _status_flash > 0.0:
		_status_flash = maxf(0.0, _status_flash - delta)
		if is_instance_valid(_status_label):
			_status_label.modulate.a = 0.72 + sin(_status_flash * 20.0) * 0.28
	elif is_instance_valid(_status_label):
		_status_label.modulate.a = 1.0
	if not _run_completed:
		_check_keyboard_combat()
		_tick_monster_contact_damage()
		_try_respawn_monster()
	_refresh_button_states()
	_sync_player_view_yaw()
	_run_elapsed_sec += delta
	_enforce_world_bounds()
	_refresh_progress_hud()
	_refresh_crosshair_visibility()


func _input(event: InputEvent) -> void:
	if _mobile_controls_enabled:
		return
	if event is InputEventMouseMotion and _pc_look_enabled:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_camera_yaw -= mm.relative.x * look_sensitivity
		_camera_pitch = clampf(
			_camera_pitch - mm.relative.y * look_sensitivity,
			deg_to_rad(-first_person_pitch_limit_deg),
			deg_to_rad(first_person_pitch_limit_deg)
		)
	elif event is InputEventMouseButton and _pc_look_enabled:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_pc_mouse_attack_queued = true


func _setup_mobile_pad() -> void:
	var is_mobile: bool = OS.has_feature("mobile")
	_mobile_controls_enabled = is_mobile
	if is_instance_valid(_mobile_move_pad):
		_mobile_move_pad.visible = is_mobile
	if is_instance_valid(_jump_btn):
		_jump_btn.visible = is_mobile
		_jump_btn.focus_mode = Control.FOCUS_NONE
		_jump_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		if not _jump_btn.pressed.is_connected(_on_mobile_jump_pressed):
			_jump_btn.pressed.connect(_on_mobile_jump_pressed)
	if is_instance_valid(_attack_btn):
		_attack_btn.visible = is_mobile
	if is_instance_valid(_dodge_btn):
		_dodge_btn.visible = is_mobile
	if is_instance_valid(_skill_btn):
		_skill_btn.visible = is_mobile
	if is_instance_valid(_stick_base):
		_stick_base.visible = false
	if is_instance_valid(_stick_knob):
		_stick_knob_rest_pos = _stick_knob.position
		_stick_knob.position = _stick_knob_rest_pos
	_camera_yaw = atan2(camera_offset.x, camera_offset.z)
	_camera_pitch = 0.0


func _setup_pc_mouse_look() -> void:
	if _mobile_controls_enabled:
		_pc_look_enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	_pc_look_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _setup_pc_pause_menu() -> void:
	if not _is_pc_mouse_mode():
		return
	if is_instance_valid(_pc_pause_menu):
		return
	var menu := GAMEPLAY_PAUSE_MENU_SCRIPT.new()
	add_child(menu)
	_pc_pause_menu = menu
	if _pc_pause_menu.has_method("set_auto_lock_enabled"):
		_pc_pause_menu.call("set_auto_lock_enabled", CharacterBuild.ranged_auto_lock)
	if _pc_pause_menu.has_signal("auto_lock_changed"):
		_pc_pause_menu.connect("auto_lock_changed", Callable(self, "_on_pause_menu_auto_lock_changed"))
	if _pc_pause_menu.has_signal("menu_opened"):
		_pc_pause_menu.connect("menu_opened", Callable(self, "_on_pause_menu_opened"))
	if _pc_pause_menu.has_signal("menu_closed"):
		_pc_pause_menu.connect("menu_closed", Callable(self, "_on_pause_menu_closed"))
	if _pc_pause_menu.has_signal("back_hall_requested"):
		_pc_pause_menu.connect("back_hall_requested", Callable(self, "_on_back_hall_pressed"))
	if _pc_pause_menu.has_signal("exit_game_requested"):
		_pc_pause_menu.connect("exit_game_requested", Callable(self, "_on_pause_menu_exit_game_requested"))


func _on_pause_menu_auto_lock_changed(enabled: bool) -> void:
	CharacterBuild.set_ranged_auto_lock(enabled)


func _on_pause_menu_opened() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pc_look_enabled = false


func _on_pause_menu_closed() -> void:
	if _is_pc_mouse_mode():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_pc_look_enabled = true


func _on_pause_menu_exit_game_requested() -> void:
	GameAudio.ui_click()
	get_tree().quit()


func _is_pc_mouse_mode() -> bool:
	return not _mobile_controls_enabled


func _consume_pc_mouse_attack() -> bool:
	if not _is_pc_mouse_mode():
		_pc_mouse_attack_queued = false
		return false
	var fire: bool = _pc_mouse_attack_queued
	_pc_mouse_attack_queued = false
	return fire


func _sync_first_person_visual() -> void:
	if not is_instance_valid(_player):
		return
	var vis: Node3D = _player.get_node_or_null("Visual") as Node3D
	if is_instance_valid(vis):
		vis.visible = not first_person_enabled


func _ensure_crosshair() -> void:
	if is_instance_valid(_crosshair_label):
		return
	var ui: CanvasLayer = get_node_or_null("UILayer") as CanvasLayer
	if not is_instance_valid(ui):
		return
	var lb := Label.new()
	lb.name = "Crosshair"
	lb.text = "+"
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.add_theme_font_size_override("font_size", 28)
	lb.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	lb.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.08, 0.92))
	lb.add_theme_constant_override("outline_size", 3)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lb.anchors_preset = Control.PRESET_CENTER
	lb.offset_left = -12.0
	lb.offset_top = -20.0
	lb.offset_right = 12.0
	lb.offset_bottom = 20.0
	ui.add_child(lb)
	_crosshair_label = lb


func _refresh_crosshair_visibility() -> void:
	if not is_instance_valid(_crosshair_label):
		return
	_crosshair_label.visible = first_person_enabled and _is_pc_mouse_mode()


func _init_progress_from_build() -> void:
	_combat_level = maxi(1, CharacterBuild.runtime_combat_level)
	_combat_xp = maxi(0, CharacterBuild.runtime_combat_xp)
	_combat_xp_next = CharacterBuild.combat_xp_to_next_level(_combat_level)


func _ensure_hud_label() -> void:
	if not is_instance_valid(_hud_label):
		_hud_label = Label.new()
		_hud_label.name = "RunHudLabel"
		_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_hud_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud_label.add_theme_font_size_override("font_size", 16)
		_hud_label.add_theme_color_override("font_color", Color8(230, 245, 255))
		_hud_label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.1, 0.86))
		_hud_label.add_theme_constant_override("outline_size", 3)
		if has_node("UILayer"):
			get_node("UILayer").add_child(_hud_label)
	if is_instance_valid(_hud_label):
		_hud_label.anchors_preset = Control.PRESET_TOP_LEFT
		_hud_label.offset_left = 18.0
		_hud_label.offset_top = 84.0
		_hud_label.offset_right = 520.0
		_hud_label.offset_bottom = 220.0


func _ensure_settlement_panel() -> void:
	if is_instance_valid(_settle_layer):
		return
	_settle_layer = CanvasLayer.new()
	_settle_layer.name = "SettlementLayer"
	_settle_layer.layer = 20
	add_child(_settle_layer)
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.anchors_preset = Control.PRESET_FULL_RECT
	dim.color = Color(0.02, 0.03, 0.06, 0.72)
	_settle_layer.add_child(dim)
	_settle_panel = PanelContainer.new()
	_settle_panel.name = "SettlementPanel"
	_settle_panel.anchors_preset = Control.PRESET_CENTER
	_settle_panel.offset_left = -250.0
	_settle_panel.offset_top = -160.0
	_settle_panel.offset_right = 250.0
	_settle_panel.offset_bottom = 160.0
	_settle_layer.add_child(_settle_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_settle_panel.add_child(vb)
	var title := Label.new()
	title.text = "阶段结算"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vb.add_child(title)
	_settle_label = Label.new()
	_settle_label.text = ""
	_settle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_settle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settle_label.custom_minimum_size = Vector2(460.0, 120.0)
	vb.add_child(_settle_label)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	var continue_btn := Button.new()
	continue_btn.text = "继续挑战"
	continue_btn.pressed.connect(_on_settle_continue_pressed)
	hb.add_child(continue_btn)
	var to_2d_btn := Button.new()
	to_2d_btn.text = "返回2D"
	to_2d_btn.pressed.connect(_on_enter_2d_pressed)
	hb.add_child(to_2d_btn)
	var to_hall_btn := Button.new()
	to_hall_btn.text = "返回大厅"
	to_hall_btn.pressed.connect(_on_back_hall_pressed)
	hb.add_child(to_hall_btn)
	_settle_layer.visible = false


func _ensure_floating_text_root() -> void:
	if is_instance_valid(_floating_text_root):
		return
	_floating_text_root = Node3D.new()
	_floating_text_root.name = "FloatingText3D"
	if is_instance_valid(_playfield):
		_playfield.add_child(_floating_text_root)
	else:
		add_child(_floating_text_root)


func _spawn_damage_number_3d(world_pos: Vector3, text: String, col: Color, up: float = 0.85, sec: float = 0.42, font_size: int = 26) -> void:
	if not is_instance_valid(_floating_text_root):
		return
	var lb := Label3D.new()
	lb.text = text
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.font_size = font_size
	lb.modulate = col
	lb.outline_size = 4
	lb.position = world_pos + Vector3(0.0, 1.25, 0.0)
	_floating_text_root.add_child(lb)
	var tw := create_tween()
	tw.tween_property(lb, "position:y", lb.position.y + up, sec)
	tw.parallel().tween_property(lb, "modulate:a", 0.0, sec)
	tw.finished.connect(func() -> void:
		if is_instance_valid(lb):
			lb.queue_free()
	, CONNECT_ONE_SHOT)


func _show_settlement_panel() -> void:
	_ensure_settlement_panel()
	if is_instance_valid(_settle_label):
		_settle_label.text = "完成第 %d 阶段\n累计击杀 %d\n获得金币 +%d  晶核 +%d  经验 +%d" % [
			_stage_index,
			_kills,
			_session_coin_gain,
			_session_core_gain,
			_session_xp_gain
		]
	if is_instance_valid(_settle_layer):
		_settle_layer.visible = true


func _on_settle_continue_pressed() -> void:
	if is_instance_valid(_settle_layer):
		_settle_layer.visible = false
	_run_completed = false
	_stage_index += 1
	_stage_kills = 0
	_refresh_status("继续挑战：第 %d 阶段" % _stage_index, true)


func _current_stage_goal() -> int:
	if _is_boss_stage():
		return 1
	return stage_goal_kills


func _is_boss_stage() -> bool:
	return _stage_index > 0 and _stage_index % 3 == 0


func _monsters_in_range(max_dist: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	if not is_instance_valid(_monsters_root) or not is_instance_valid(_player):
		return out
	var max_sq: float = max_dist * max_dist
	for n in _monsters_root.get_children():
		if not (n is Node3D):
			continue
		var m: Node3D = n as Node3D
		if m.global_position.distance_squared_to(_player.global_position) <= max_sq:
			out.append(m)
	return out


func _spawn_drop_pickup(item_id: String, item_name: String, amount: int, world_pos: Vector3) -> void:
	if WORLD_PICKUP_SCENE == null:
		return
	var inst := WORLD_PICKUP_SCENE.instantiate()
	if not (inst is Area3D):
		return
	var pickup: Area3D = inst as Area3D
	pickup.global_position = world_pos + Vector3(0.0, 0.35, 0.0)
	if pickup.has_method("configure_pickup"):
		pickup.call("configure_pickup", item_id, item_name, maxi(1, amount))
	if pickup.has_signal("picked"):
		pickup.connect("picked", Callable(self, "_on_pickup_collected"))
	add_child(pickup)


func _on_pickup_collected(item_id: String, display_name: String, amount: int) -> void:
	var gain: int = maxi(1, amount)
	PlayerInventory.add_item(item_id, display_name, gain)
	if item_id == "coin":
		_session_coin_gain += gain
	elif item_id == "trial_core":
		_session_core_gain += gain
	_refresh_status("拾取 %s +%d" % [display_name, gain], true)


func _update_mobile_player_input() -> void:
	if is_instance_valid(_player) and _player.has_method("set_mobile_input"):
		_player.call("set_mobile_input", _mobile_dir.normalized())


func _sync_player_view_yaw() -> void:
	if is_instance_valid(_player) and _player.has_method("set_camera_yaw"):
		_player.call("set_camera_yaw", _camera_yaw)


func _unhandled_input(event: InputEvent) -> void:
	if not _mobile_controls_enabled:
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			var vp_size: Vector2 = get_viewport().get_visible_rect().size
			if touch.position.x <= vp_size.x * 0.5 and _move_touch_id == -1:
				_move_touch_id = touch.index
				_move_origin = touch.position
				_update_mobile_drag_dir(touch.position)
			elif touch.position.x > vp_size.x * 0.5 and _look_touch_id == -1:
				_look_touch_id = touch.index
		elif touch.index == _move_touch_id:
			_clear_mobile_drag()
		elif touch.index == _look_touch_id:
			_look_touch_id = -1
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == _move_touch_id:
			_update_mobile_drag_dir(drag.position)
		elif drag.index == _look_touch_id:
			_camera_yaw -= drag.relative.x * look_sensitivity
			_camera_pitch = clampf(
				_camera_pitch - drag.relative.y * look_sensitivity,
				deg_to_rad(-first_person_pitch_limit_deg),
				deg_to_rad(first_person_pitch_limit_deg)
			)


func _update_mobile_drag_dir(screen_pos: Vector2) -> void:
	var delta: Vector2 = screen_pos - _move_origin
	var dist: float = delta.length()
	if dist <= _move_deadzone:
		_mobile_dir = Vector2.ZERO
	else:
		_mobile_dir = (delta / maxf(_move_radius, 1.0)).clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))
	_update_mobile_player_input()
	if is_instance_valid(_stick_base):
		_stick_base.visible = true
		_stick_base.global_position = _move_origin - (_stick_base.size * 0.5)
	if is_instance_valid(_stick_knob):
		var knob_vec := delta
		if knob_vec.length() > _move_radius:
			knob_vec = knob_vec.normalized() * _move_radius
		_stick_knob.position = _stick_knob_rest_pos + knob_vec


func _clear_mobile_drag() -> void:
	_move_touch_id = -1
	_mobile_dir = Vector2.ZERO
	_update_mobile_player_input()
	if is_instance_valid(_stick_base):
		_stick_base.visible = false
	if is_instance_valid(_stick_knob):
		_stick_knob.position = _stick_knob_rest_pos


func _on_mobile_jump_pressed() -> void:
	if is_instance_valid(_player) and _player.has_method("request_mobile_jump"):
		_player.call("request_mobile_jump")


func _on_mobile_attack_pressed() -> void:
	_try_primary_attack()


func _on_mobile_dodge_pressed() -> void:
	if is_instance_valid(_player) and _player.has_method("request_mobile_dodge"):
		_player.call("request_mobile_dodge")


func _on_mobile_skill_pressed() -> void:
	_try_cast_heavy_skill()


func _on_back_hall_pressed() -> void:
	GameAudio.ui_click()
	_sync_progress_to_build()
	SceneTransition.transition_to(HALL_SCENE)


func _on_enter_2d_pressed() -> void:
	GameAudio.ui_confirm()
	_sync_progress_to_build()
	SceneTransition.transition_to(WORLD_2D_SCENE)


func _exit_tree() -> void:
	if _pc_look_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _bind_combat_buttons() -> void:
	if is_instance_valid(_attack_btn) and not _attack_btn.pressed.is_connected(_on_mobile_attack_pressed):
		_attack_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		_attack_btn.focus_mode = Control.FOCUS_NONE
		_attack_btn.pressed.connect(_on_mobile_attack_pressed)
	if is_instance_valid(_dodge_btn) and not _dodge_btn.pressed.is_connected(_on_mobile_dodge_pressed):
		_dodge_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		_dodge_btn.focus_mode = Control.FOCUS_NONE
		_dodge_btn.pressed.connect(_on_mobile_dodge_pressed)
	if is_instance_valid(_skill_btn) and not _skill_btn.pressed.is_connected(_on_mobile_skill_pressed):
		_skill_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		_skill_btn.focus_mode = Control.FOCUS_NONE
		_skill_btn.pressed.connect(_on_mobile_skill_pressed)


func _check_keyboard_combat() -> void:
	if _consume_pc_mouse_attack() or Input.is_action_just_pressed("attack"):
		_try_primary_attack()
	if Input.is_key_pressed(KEY_K):
		_try_cast_heavy_skill()
	var dodge_pressed: bool = Input.is_key_pressed(KEY_SHIFT)
	if InputMap.has_action("dodge_roll") and Input.is_action_just_pressed("dodge_roll"):
		dodge_pressed = true
	elif InputMap.has_action("dodge") and Input.is_action_just_pressed("dodge"):
		dodge_pressed = true
	if dodge_pressed and is_instance_valid(_player) and _player.has_method("request_mobile_dodge"):
		_player.call("request_mobile_dodge")


func _spawn_opening_monsters() -> void:
	var spawns: Array[Marker3D] = [_spawn_a, _spawn_b, _spawn_c]
	for s in spawns:
		_spawn_one_monster(s)


func _spawn_one_monster(spawn: Marker3D) -> void:
	if not is_instance_valid(_monsters_root) or not is_instance_valid(spawn):
		return
	var m := SLIME_3D_SCENE.instantiate()
	if not (m is Node3D):
		return
	var n3d := m as Node3D
	n3d.global_position = spawn.global_position
	var boss_wave: bool = _is_boss_stage()
	var hp_scaled: int = 26 + _stage_index * 8 + _combat_level * 5 + randi() % 12
	var speed_scaled: float = 1.9 + float(_stage_index - 1) * 0.22
	var touch_scaled: int = 5 + int(round(float(_stage_index) * 1.4))
	if boss_wave:
		hp_scaled = int(round(float(hp_scaled) * 3.2))
		speed_scaled += 0.5
		touch_scaled += 6
		n3d.scale = Vector3(1.55, 1.55, 1.55)
	if n3d.has_method("set"):
		n3d.set("max_hp", hp_scaled)
		n3d.set("move_speed", speed_scaled)
		n3d.set("contact_damage", touch_scaled)
		n3d.set_meta("is_boss", boss_wave)
	_monsters_root.add_child(n3d)
	if n3d.has_method("set_target"):
		n3d.call("set_target", _player)
	if n3d.has_signal("defeated"):
		n3d.connect("defeated", Callable(self, "_on_monster_defeated"))


func _nearest_monster(max_dist: float) -> Node3D:
	if not is_instance_valid(_monsters_root) or not is_instance_valid(_player):
		return null
	var best: Node3D
	var best_dist_sq := max_dist * max_dist
	for n in _monsters_root.get_children():
		if not (n is Node3D):
			continue
		var d2: float = (n as Node3D).global_position.distance_squared_to(_player.global_position)
		if d2 <= best_dist_sq:
			best = n as Node3D
			best_dist_sq = d2
	return best


func _try_primary_attack() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = attack_cooldown
	var damage_now: int = melee_damage + _combat_level * 2
	var m: Node3D = _nearest_monster(melee_range)
	if is_instance_valid(m) and m.has_method("take_damage"):
		m.call("take_damage", damage_now)
		_spawn_damage_number_3d(m.global_position, "-%d" % damage_now, Color(1.0, 0.43, 0.35, 1.0))
		_refresh_status("命中 -%d" % damage_now, true)
		GameAudio.melee_hit()
	else:
		_refresh_status("挥空")
		GameAudio.melee_swing()


func _try_cast_heavy_skill() -> void:
	if _skill_cd > 0.0:
		return
	_skill_cd = skill_cooldown
	var class_id: int = CharacterBuild.get_combat_class()
	var damage_now: int = skill_damage + _combat_level * 3 + _stage_index
	if class_id == CharacterBuild.CLASS_ARCHER:
		var targets: Array[Node3D] = _monsters_in_range(skill_range * 1.3)
		var hit_count: int = mini(3, targets.size())
		for i in hit_count:
			var t: Node3D = targets[i]
			if is_instance_valid(t) and t.has_method("take_damage"):
				var dmg_archer: int = maxi(1, int(round(float(damage_now) * 0.78)))
				t.call("take_damage", dmg_archer)
				_spawn_damage_number_3d(t.global_position, "-%d" % dmg_archer, Color(1.0, 0.56, 0.30, 1.0), 0.9, 0.38, 24)
		if hit_count > 0:
			_refresh_status("弓手连射 命中 %d" % hit_count, true)
			GameAudio.ui_confirm()
		else:
			_refresh_status("弓手连射未命中")
	elif class_id == CharacterBuild.CLASS_MAGE:
		var targets_aoe: Array[Node3D] = _monsters_in_range(skill_range * 1.1)
		for t in targets_aoe:
			if is_instance_valid(t) and t.has_method("take_damage"):
				var dmg_mage: int = maxi(1, int(round(float(damage_now) * 0.92)))
				t.call("take_damage", dmg_mage)
				_spawn_damage_number_3d(t.global_position, "-%d" % dmg_mage, Color(0.45, 0.95, 1.0, 1.0), 1.0, 0.46, 24)
		if not targets_aoe.is_empty():
			_refresh_status("法师爆发 命中 %d" % targets_aoe.size(), true)
			GameAudio.ui_confirm()
		else:
			_refresh_status("法师爆发未命中")
	elif class_id == CharacterBuild.CLASS_PRIEST:
		var heal_gain: int = CharacterBuild.heal_priest_with_multiplier(_combat_level, 1.2)
		var m_priest: Node3D = _nearest_monster(skill_range)
		if is_instance_valid(m_priest) and m_priest.has_method("take_damage"):
			var dmg_priest: int = maxi(1, int(round(float(damage_now) * 0.65)))
			m_priest.call("take_damage", dmg_priest)
			_spawn_damage_number_3d(m_priest.global_position, "-%d" % dmg_priest, Color(0.95, 0.82, 1.0, 1.0), 0.88, 0.4, 24)
		if is_instance_valid(_player):
			_spawn_damage_number_3d(_player.global_position, "+%d" % maxi(0, heal_gain), Color(0.46, 1.0, 0.58, 1.0), 0.92, 0.48, 24)
		_refresh_status("祈祷恢复 +%d" % maxi(0, heal_gain), true)
		GameAudio.heal_chime()
	else:
		var m: Node3D = _nearest_monster(skill_range)
		if is_instance_valid(m) and m.has_method("take_damage"):
			m.call("take_damage", damage_now)
			_spawn_damage_number_3d(m.global_position, "-%d" % damage_now, Color(1.0, 0.66, 0.36, 1.0), 0.95, 0.42, 26)
			_refresh_status("战士重击 -%d" % damage_now, true)
			GameAudio.ui_confirm()
		else:
			_refresh_status("重击未命中")


func _tick_monster_contact_damage() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_monsters_root):
		return
	if _player_hit_cd > 0.0:
		return
	if _player.has_method("is_dodging") and bool(_player.call("is_dodging")):
		return
	for n in _monsters_root.get_children():
		if not (n is Node3D):
			continue
		var m: Node3D = n as Node3D
		if m.global_position.distance_squared_to(_player.global_position) > 1.6 * 1.6:
			continue
		_player_hit_cd = monster_contact_damage_interval
		var dmg: int = 6
		if m.has_method("get"):
			dmg = int(m.get("contact_damage"))
		CharacterBuild.damage_player(maxi(1, dmg))
		if is_instance_valid(_player):
			_spawn_damage_number_3d(_player.global_position, "-%d" % dmg, Color(1.0, 0.26, 0.26, 1.0), 0.86, 0.4, 24)
		_refresh_status("受到伤害 -%d" % dmg, true)
		GameAudio.ui_click()
		_check_player_down()
		break


func _try_respawn_monster() -> void:
	if _monster_respawn_cd > 0.0:
		return
	if not is_instance_valid(_monsters_root):
		return
	var alive: int = _monsters_root.get_child_count()
	var target_alive: int = 1 if _is_boss_stage() else mini(stage_alive_cap, stage_alive_base + maxi(0, _stage_index - 1))
	if alive >= target_alive:
		return
	_monster_respawn_cd = monster_respawn_delay
	var spawns: Array[Marker3D] = [_spawn_a, _spawn_b, _spawn_c]
	var s: Marker3D = spawns[randi() % spawns.size()]
	_spawn_one_monster(s)


func _on_monster_defeated(_monster: Node) -> void:
	_kills += 1
	_stage_kills += 1
	var defeated_pos: Vector3 = Vector3.ZERO
	var defeated_boss: bool = false
	if _monster is Node3D:
		defeated_pos = (_monster as Node3D).global_position
	if _monster is Node and (_monster as Node).has_meta("is_boss"):
		defeated_boss = bool((_monster as Node).get_meta("is_boss"))
	var xp_gain: int = 9 + _stage_index * 3 + int(randf() * 4.0)
	if defeated_boss:
		xp_gain += 28
	_grant_runtime_xp(xp_gain)
	_session_xp_gain += xp_gain
	var core_gain: int = 2 if defeated_boss else 1
	_spawn_drop_pickup("trial_core", "试炼晶核", core_gain, defeated_pos)
	if randf() < 0.9:
		var coin_gain: int = (3 + randi() % 5) if defeated_boss else (1 + randi() % 4)
		_spawn_drop_pickup("coin", "金币", coin_gain, defeated_pos + Vector3(0.4, 0.0, 0.0))
	var goal: int = _current_stage_goal()
	if _stage_kills >= goal:
		if _stage_index >= max_stage:
			_run_completed = true
			_refresh_status("本轮挑战完成！", true)
			_show_settlement_panel()
			return
		_stage_index += 1
		_stage_kills = 0
		_refresh_status("阶段提升！进入第 %d 波" % _stage_index, true)
		GameAudio.level_up()
	else:
		_refresh_status("击败怪物 +1（阶段 %d/%d）" % [_stage_kills, goal], true)


func _refresh_status(text: String, flash: bool = false) -> void:
	if is_instance_valid(_status_label):
		_status_label.text = text
	if flash:
		_status_flash = 0.36


func _refresh_progress_hud() -> void:
	if not is_instance_valid(_hud_label):
		return
	var hp_now: int = CharacterBuild.get_player_hp()
	var hp_max: int = maxi(1, CharacterBuild.get_max_hp())
	var sec: int = int(_run_elapsed_sec)
	var mm: int = sec / 60
	var ss: int = sec % 60
	var aim_now: int = _stage_kills
	_hud_label.text = "阶段 %d  目标 %d/%d  Lv.%d EXP %d/%d\nHP %d/%d  击杀 %d  金币+%d  晶核+%d  用时 %02d:%02d" % [
		_stage_index,
		aim_now,
		stage_goal_kills,
		_combat_level,
		_combat_xp,
		_combat_xp_next,
		hp_now,
		hp_max,
		_kills,
		_session_coin_gain,
		_session_core_gain,
		mm,
		ss
	]


func _grant_runtime_xp(amount: int) -> void:
	var add_xp: int = maxi(1, amount)
	var prev_lv: int = _combat_level
	_combat_xp += add_xp
	while _combat_xp >= _combat_xp_next:
		_combat_xp -= _combat_xp_next
		_combat_level += 1
		_combat_xp_next = CharacterBuild.combat_xp_to_next_level(_combat_level)
	if _combat_level > prev_lv:
		CharacterBuild.grant_points_for_levels(_combat_level - prev_lv)
	CharacterBuild.set_runtime_combat_progress(_combat_level, _combat_xp)


func _check_player_down() -> void:
	if CharacterBuild.get_player_hp() > 0:
		return
	var hp_max: int = maxi(1, CharacterBuild.get_max_hp())
	CharacterBuild.full_heal_player()
	if is_instance_valid(_player):
		_player.global_position = Vector3.ZERO + Vector3(0.0, 1.0, 0.0)
		if _player.has_method("set_mobile_input"):
			_player.call("set_mobile_input", Vector2.ZERO)
	_refresh_status("你被击倒了，已复位（HP %d）" % hp_max, true)
	_stage_kills = maxi(0, _stage_kills - 2)


func _enforce_world_bounds() -> void:
	if not is_instance_valid(_player):
		return
	var p: Vector3 = _player.global_position
	p.x = clampf(p.x, -world_half_extent.x, world_half_extent.x)
	p.z = clampf(p.z, -world_half_extent.y, world_half_extent.y)
	_player.global_position = p


func _sync_progress_to_build() -> void:
	CharacterBuild.set_runtime_combat_progress(_combat_level, _combat_xp)


func _refresh_button_states() -> void:
	if is_instance_valid(_attack_btn):
		_attack_btn.disabled = _attack_cd > 0.01
		_attack_btn.text = "攻 %.1f" % (ceil(_attack_cd * 10.0) / 10.0) if _attack_cd > 0.01 else "攻击"
	if is_instance_valid(_skill_btn):
		_skill_btn.disabled = _skill_cd > 0.01
		_skill_btn.text = "技 %.1f" % (ceil(_skill_cd * 10.0) / 10.0) if _skill_cd > 0.01 else "技能"
	if is_instance_valid(_dodge_btn):
		var cd: float = 0.0
		if is_instance_valid(_player) and _player.has_method("get_dodge_cooldown_remaining"):
			cd = float(_player.call("get_dodge_cooldown_remaining"))
		_dodge_btn.disabled = cd > 0.01
		_dodge_btn.text = "闪 %.1f" % (ceil(cd * 10.0) / 10.0) if cd > 0.01 else "闪避"
