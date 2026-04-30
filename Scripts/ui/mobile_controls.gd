extends Control

signal move_input(direction: Vector2)
signal interact_pressed()
signal attack_pressed()
signal surge_pressed()

@onready var joystick_zone: Control = $MobileRoot/JoystickZone
@onready var joystick_knob: Panel = $MobileRoot/JoystickZone/JoystickKnob
@onready var interact_button: Button = $InteractButton
@onready var attack_button: Button = $AttackButton
@onready var surge_button: Button = $SurgeButton

var _center: Vector2 = Vector2.ZERO
var _radius: float = 72.0
var _dead: float = 14.0
var _dragging: bool = false
var _touch_id: int = -1
var _viewport_size_connected: bool = false
## 真机多指：摇杆占一指时，Button 往往收不到第二指的触摸；改由本节点 _input 按矩形派发攻击/技能/对话。
var _touch_action_multitouch: bool = false

const ATTACK_HOLD_CHAIN_DELAY := 0.38 ## 点按后仍按住，首下长按连发延迟（秒）
const ATTACK_HOLD_REPEAT_INTERVAL := 0.12 ## 长按期间连发间隔（秒）；实际攻速仍受大世界 CD 限制

var _attack_hold_active: bool = false
## 正在长按攻击的手指：-1 鼠标，>=0 触摸 id；-999 未激活
var _attack_hold_index: int = -999
var _attack_time_to_repeat: float = 0.0
var _last_surge_bucket: int = -1
var _last_surge_text: String = ""
var _last_surge_disabled: bool = false


func _ready() -> void:
	attack_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	interact_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	surge_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	attack_button.focus_mode = Control.FOCUS_NONE
	interact_button.focus_mode = Control.FOCUS_NONE
	surge_button.focus_mode = Control.FOCUS_NONE
	_apply_visual_style()
	await get_tree().process_frame
	## 等一帧期间可能已切场景（传送门等），本节点被移出树后 get_viewport() 会为 null。
	if not is_inside_tree() or not is_instance_valid(self):
		return
	_recompute_geometry()
	_reset_knob()
	joystick_zone.gui_input.connect(_on_zone_gui_input)
	_touch_action_multitouch = (
		DisplayServer.is_touchscreen_available()
		or OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("mobile")
	)
	if _touch_action_multitouch:
		attack_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		surge_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		interact_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		attack_button.gui_input.connect(_on_attack_desktop_gui_input)
		surge_button.pressed.connect(surge_pressed.emit)
		interact_button.pressed.connect(interact_pressed.emit)
	CharacterBuild.build_changed.connect(_refresh_surge_button)
	_refresh_surge_button()
	_try_connect_viewport_size_changed()
	set_process(true)


func _try_connect_viewport_size_changed() -> void:
	if _viewport_size_connected:
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	vp.size_changed.connect(_on_vp_changed)
	_viewport_size_connected = true


func _exit_tree() -> void:
	if _viewport_size_connected:
		var vp: Viewport = get_viewport()
		if vp != null and vp.size_changed.is_connected(_on_vp_changed):
			vp.size_changed.disconnect(_on_vp_changed)
		_viewport_size_connected = false
	if CharacterBuild.build_changed.is_connected(_refresh_surge_button):
		CharacterBuild.build_changed.disconnect(_refresh_surge_button)


func _process(delta: float) -> void:
	var cd: float = CharacterBuild.surge_cooldown_remaining()
	var bucket: int = 0 if cd <= 0.01 else int(ceil(cd * 10.0))
	if bucket != _last_surge_bucket:
		_last_surge_bucket = bucket
		_refresh_surge_button()
		queue_redraw()
	if _attack_hold_active:
		_attack_time_to_repeat -= delta
		var guard := 0
		while _attack_time_to_repeat <= 0.0 and _attack_hold_active and guard < 24:
			attack_pressed.emit()
			_attack_time_to_repeat += ATTACK_HOLD_REPEAT_INTERVAL
			guard += 1


func _refresh_surge_button() -> void:
	if not is_instance_valid(surge_button):
		return
	var cd: float = CharacterBuild.surge_cooldown_remaining()
	var cap: String = CharacterBuild.surge_skill_button_caption()
	var next_text: String = cap if cd <= 0.01 else "%ds" % int(ceil(cd))
	var next_disabled: bool = not CharacterBuild.can_activate_surge()
	if next_text != _last_surge_text:
		surge_button.text = next_text
		_last_surge_text = next_text
	if next_disabled != _last_surge_disabled:
		surge_button.disabled = next_disabled
		_last_surge_disabled = next_disabled


func _draw() -> void:
	if not is_instance_valid(surge_button) or not surge_button.visible:
		return
	var cd: float = CharacterBuild.surge_cooldown_remaining()
	if cd <= 0.01:
		return
	var ratio: float = clampf(cd / 8.0, 0.0, 1.0)
	var c: Vector2 = surge_button.position + surge_button.size * 0.5
	var radius: float = minf(surge_button.size.x, surge_button.size.y) * 0.52
	draw_arc(c, radius, -PI * 0.5, -PI * 0.5 + TAU * ratio, 48, Color(0.97, 0.97, 1.0, 0.92), 4.0, true)
	draw_arc(c, radius - 5.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 48, Color(0.70, 0.48, 1.0, 0.85), 2.0, true)


func _on_vp_changed() -> void:
	call_deferred("_recompute_geometry")
	call_deferred("_reset_knob")


func _apply_visual_style() -> void:
	var ring := StyleBoxFlat.new()
	ring.bg_color = Color(1, 1, 1, 0.22)
	ring.border_color = Color(1, 0.55, 0.7, 0.55)
	ring.set_border_width_all(3)
	ring.corner_radius_top_left = 999
	ring.corner_radius_top_right = 999
	ring.corner_radius_bottom_left = 999
	ring.corner_radius_bottom_right = 999
	var ring_panel: Panel = $MobileRoot/JoystickZone/JoystickRing
	ring_panel.add_theme_stylebox_override("panel", ring)
	ring_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var knob := StyleBoxFlat.new()
	knob.bg_color = Color(1, 0.45, 0.65, 0.92)
	knob.corner_radius_top_left = 999
	knob.corner_radius_top_right = 999
	knob.corner_radius_bottom_left = 999
	knob.corner_radius_bottom_right = 999
	joystick_knob.add_theme_stylebox_override("panel", knob)

	var ib := StyleBoxFlat.new()
	ib.bg_color = Color8(255, 102, 153)
	ib.corner_radius_top_left = 999
	ib.corner_radius_top_right = 999
	ib.corner_radius_bottom_left = 999
	ib.corner_radius_bottom_right = 999
	ib.content_margin_top = 16
	ib.content_margin_bottom = 16
	interact_button.add_theme_stylebox_override("normal", ib)
	var ib_h := ib.duplicate()
	ib_h.bg_color = Color8(255, 130, 175)
	interact_button.add_theme_stylebox_override("hover", ib_h)
	var ib_p := ib.duplicate()
	ib_p.bg_color = Color8(230, 85, 130)
	interact_button.add_theme_stylebox_override("pressed", ib_p)
	interact_button.add_theme_color_override("font_color", Color.WHITE)
	interact_button.add_theme_font_size_override("font_size", 20)

	var ab := StyleBoxFlat.new()
	ab.bg_color = Color8(120, 170, 255)
	ab.corner_radius_top_left = 999
	ab.corner_radius_top_right = 999
	ab.corner_radius_bottom_left = 999
	ab.corner_radius_bottom_right = 999
	ab.content_margin_top = 16
	ab.content_margin_bottom = 16
	attack_button.add_theme_stylebox_override("normal", ab)
	var ab_h := ab.duplicate()
	ab_h.bg_color = Color8(150, 195, 255)
	attack_button.add_theme_stylebox_override("hover", ab_h)
	var ab_p := ab.duplicate()
	ab_p.bg_color = Color8(90, 140, 220)
	attack_button.add_theme_stylebox_override("pressed", ab_p)
	attack_button.add_theme_color_override("font_color", Color.WHITE)
	attack_button.add_theme_font_size_override("font_size", 20)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(200, 130, 255)
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	surge_button.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate()
	sb_h.bg_color = Color8(220, 165, 255)
	surge_button.add_theme_stylebox_override("hover", sb_h)
	var sb_p := sb.duplicate()
	sb_p.bg_color = Color8(160, 95, 215)
	surge_button.add_theme_stylebox_override("pressed", sb_p)
	surge_button.add_theme_color_override("font_color", Color.WHITE)
	surge_button.add_theme_font_size_override("font_size", 18)


func _recompute_geometry() -> void:
	var z := joystick_zone.size
	_center = z * 0.5
	_radius = minf(z.x, z.y) * 0.38
	_dead = _radius * 0.12


func _on_zone_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_touch_id = -1
				_update_from_local(joystick_zone.get_local_mouse_position())
			else:
				if _dragging and _touch_id == -1:
					_end_drag()
	elif event is InputEventMouseMotion and _dragging and _touch_id == -1:
		_update_from_local(joystick_zone.get_local_mouse_position())
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var ev_loc := st.duplicate() as InputEventScreenTouch
		joystick_zone.make_input_local(ev_loc)
		var local := ev_loc.position
		if st.pressed:
			if Rect2(Vector2.ZERO, joystick_zone.size).has_point(local):
				_dragging = true
				_touch_id = st.index
				_update_from_local(local)
		else:
			if st.index == _touch_id:
				_end_drag()
	elif event is InputEventScreenDrag and _dragging and event.index == _touch_id:
		var sd := event as InputEventScreenDrag
		var evd := sd.duplicate() as InputEventScreenDrag
		joystick_zone.make_input_local(evd)
		_update_from_local(evd.position)


func _update_from_local(local_pos: Vector2) -> void:
	var delta := local_pos - _center
	var dist := delta.length()
	var dir := Vector2.ZERO
	if dist > _dead:
		dir = delta.normalized()
		dist = minf(dist, _radius)
	else:
		dist = 0.0
	var knob_pos := _center + dir * dist - joystick_knob.size * 0.5
	joystick_knob.position = knob_pos
	move_input.emit(dir)


func _end_drag() -> void:
	_dragging = false
	_touch_id = -1
	_reset_knob()
	move_input.emit(Vector2.ZERO)


func _reset_knob() -> void:
	if joystick_knob and _center != Vector2.ZERO:
		joystick_knob.position = _center - joystick_knob.size * 0.5


func _input(event: InputEvent) -> void:
	if not _touch_action_multitouch:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if not st.pressed:
			_attack_hold_clear_for_index(st.index)
			return
		if _try_emit_touch_action(st.position, st.index):
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if not mb.pressed:
			_attack_hold_clear_for_index(-1)
			return
		if _try_emit_touch_action(mb.position, -1):
			get_viewport().set_input_as_handled()


func _try_emit_touch_action(screen_pos: Vector2, touch_index: int) -> bool:
	if not surge_button.disabled and _control_screen_hit(surge_button, screen_pos):
		surge_pressed.emit()
		return true
	if _control_screen_hit(attack_button, screen_pos):
		attack_pressed.emit()
		_attack_hold_start(touch_index)
		return true
	if interact_button.visible and _control_screen_hit(interact_button, screen_pos):
		interact_pressed.emit()
		return true
	return false


func _attack_hold_start(index: int) -> void:
	_attack_hold_active = true
	_attack_hold_index = index
	_attack_time_to_repeat = ATTACK_HOLD_CHAIN_DELAY


func _attack_hold_clear_for_index(index: int) -> void:
	if not _attack_hold_active:
		return
	if _attack_hold_index != index:
		return
	_attack_hold_active = false
	_attack_hold_index = -999
	_attack_time_to_repeat = 0.0


func _on_attack_desktop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			attack_pressed.emit()
			_attack_hold_start(-1)
		else:
			_attack_hold_clear_for_index(-1)
		attack_button.accept_event()


func _control_screen_hit(c: Control, screen_pos: Vector2) -> bool:
	if not is_instance_valid(c) or not c.visible:
		return false
	return c.get_global_rect().has_point(screen_pos)


func _unhandled_input(event: InputEvent) -> void:
	## 桌面：在攻击键上按下后拖到键外再松开，攻击键收不到 mouse up，在此结束长按连发。
	if _touch_action_multitouch:
		return
	if not _attack_hold_active or _attack_hold_index != -1:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_attack_hold_clear_for_index(-1)
