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
	interact_button.pressed.connect(interact_pressed.emit)
	attack_button.pressed.connect(attack_pressed.emit)
	surge_button.pressed.connect(surge_pressed.emit)
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


func _process(_delta: float) -> void:
	if CharacterBuild.surge_cooldown_remaining() > 0.01:
		_refresh_surge_button()


func _refresh_surge_button() -> void:
	if not is_instance_valid(surge_button):
		return
	var cd: float = CharacterBuild.surge_cooldown_remaining()
	var cap: String = CharacterBuild.surge_skill_button_caption()
	surge_button.text = cap if cd <= 0.01 else "%ds" % int(ceil(cd))
	surge_button.disabled = not CharacterBuild.can_activate_surge()


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
