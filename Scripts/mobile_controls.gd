extends CanvasLayer

signal move_input(direction: Vector2)
signal interact_pressed()

@onready var joystick_zone: Control = $MobileRoot/JoystickZone
@onready var joystick_knob: Panel = $MobileRoot/JoystickZone/JoystickKnob
@onready var interact_button: Button = $InteractButton

var _center: Vector2 = Vector2.ZERO
var _radius: float = 72.0
var _dead: float = 14.0
var _dragging: bool = false
var _touch_id: int = -1


func _ready() -> void:
	_apply_visual_style()
	await get_tree().process_frame
	_recompute_geometry()
	_reset_knob()
	joystick_zone.gui_input.connect(_on_zone_gui_input)
	interact_button.pressed.connect(interact_pressed.emit)
	get_viewport().size_changed.connect(_on_vp_changed)


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
