extends CanvasLayer

signal move_input(direction: Vector2)
signal interact_pressed()

@onready var joystick_background: TextureRect = $JoystickBackground
@onready var joystick_handle: TextureRect = $JoystickBackground/JoystickHandle
@onready var interact_button: Button = $InteractButton

var joystick_center: Vector2 = Vector2(60, 60)
var joystick_radius: float = 50.0
var is_dragging: bool = false
var current_input: Vector2 = Vector2.ZERO

func _ready() -> void:
	joystick_background.gui_input.connect(_on_joystick_gui_input)
	interact_button.pressed.connect(interact_pressed.emit)

func _on_joystick_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			is_dragging = true
			_update_joystick(event.position)
		else:
			is_dragging = false
			_reset_joystick()
	
	elif event is InputEventMouseMotion and is_dragging:
		_update_joystick(event.position)

func _update_joystick(position: Vector2) -> void:
	var direction = position - joystick_center
	var distance = direction.length()
	
	if distance > 0:
		direction = direction.normalized()
		current_input = direction
		
		if distance > joystick_radius:
			distance = joystick_radius
		
		var new_pos = joystick_center + direction * distance
		joystick_handle.position = new_pos - joystick_handle.size / 2
	else:
		current_input = Vector2.ZERO
		_reset_joystick()
	
	move_input.emit(current_input)

func _reset_joystick() -> void:
	joystick_handle.position = joystick_center - joystick_handle.size / 2
	current_input = Vector2.ZERO
	move_input.emit(Vector2.ZERO)

func get_input_direction() -> Vector2:
	return current_input
