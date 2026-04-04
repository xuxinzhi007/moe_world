extends CanvasLayer

signal move_input(direction: Vector2)
signal interact_pressed()

@onready var joystick_background: ColorRect = $JoystickBackground
@onready var joystick_handle: ColorRect = $JoystickBackground/JoystickHandle
@onready var interact_button: Button = $InteractButton

var joystick_center: Vector2 = Vector2(60, 60)
var joystick_radius: float = 50.0
var is_dragging: bool = false
var current_input: Vector2 = Vector2.ZERO
var active_touch_id: int = -1

func _ready() -> void:
	print("🎮 移动端控制初始化...")
	joystick_background.mouse_filter = Control.MOUSE_FILTER_STOP
	joystick_background.gui_input.connect(_on_joystick_gui_input)
	interact_button.pressed.connect(interact_pressed.emit)
	print("✅ 移动端控制初始化完成！")

func _on_joystick_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var local_pos = joystick_background.get_local_mouse_position()
				if local_pos.distance_to(joystick_center) <= joystick_radius * 2:
					is_dragging = true
					print("🖱️ 开始拖动摇杆 (鼠标)")
					_update_joystick(local_pos)
			else:
				if is_dragging and active_touch_id == -1:
					is_dragging = false
					print("🖱️ 结束拖动摇杆 (鼠标)")
					_reset_joystick()
	
	elif event is InputEventMouseMotion and is_dragging and active_touch_id == -1:
		var local_pos = joystick_background.get_local_mouse_position()
		_update_joystick(local_pos)
	
	elif event is InputEventScreenTouch:
		if event.pressed:
			var local_pos = joystick_background.get_local_mouse_position()
			if local_pos.distance_to(joystick_center) <= joystick_radius * 2:
				is_dragging = true
				active_touch_id = event.index
				print("👆 开始拖动摇杆 (触摸)")
				_update_joystick(local_pos)
		else:
			if event.index == active_touch_id:
				is_dragging = false
				active_touch_id = -1
				print("👆 结束拖动摇杆 (触摸)")
				_reset_joystick()
	
	elif event is InputEventScreenDrag and is_dragging and event.index == active_touch_id:
		var local_pos = joystick_background.get_local_mouse_position()
		_update_joystick(local_pos)

func _update_joystick(local_pos: Vector2) -> void:
	var direction = local_pos - joystick_center
	var distance = direction.length()
	
	if distance > 0:
		direction = direction.normalized()
		current_input = direction
		
		if distance > joystick_radius:
			distance = joystick_radius
		
		var new_pos = joystick_center + direction * distance
		joystick_handle.position = new_pos - joystick_handle.size / 2
		print("🎮 摇杆方向: ", current_input)
	else:
		current_input = Vector2.ZERO
		_reset_joystick()
	
	move_input.emit(current_input)

func _reset_joystick() -> void:
	joystick_handle.position = joystick_center - joystick_handle.size / 2
	current_input = Vector2.ZERO
	move_input.emit(Vector2.ZERO)
	print("🎮 摇杆复位")

func get_input_direction() -> Vector2:
	return current_input
