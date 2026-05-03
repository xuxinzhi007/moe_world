extends CharacterBody3D

@export var move_speed: float = 6.5
@export var acceleration: float = 18.0
@export var deceleration: float = 22.0
@export var jump_velocity: float = 5.8
@export var dodge_speed: float = 11.5
@export var dodge_duration: float = 0.16
@export var dodge_cooldown: float = 0.82

var _mobile_input: Vector2 = Vector2.ZERO
var _mobile_jump_requested: bool = false
var _mobile_dodge_requested: bool = false
var _gravity: float = 9.8
var _is_dodging: bool = false
var _dodge_timer: float = 0.0
var _dodge_cd: float = 0.0
var _dodge_dir: Vector3 = Vector3.ZERO
var _camera_yaw: float = 0.0


func set_mobile_input(input_dir: Vector2) -> void:
	_mobile_input = input_dir.clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))


func request_mobile_jump() -> void:
	_mobile_jump_requested = true


func request_mobile_dodge() -> void:
	_mobile_dodge_requested = true


func set_camera_yaw(yaw: float) -> void:
	_camera_yaw = yaw


func is_dodging() -> bool:
	return _is_dodging


func get_dodge_cooldown_remaining() -> float:
	return _dodge_cd


func get_dodge_cooldown_total() -> float:
	return dodge_cooldown


func _ready() -> void:
	add_to_group("player")
	var grav_setting: Variant = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	_gravity = float(grav_setting)


func _physics_process(delta: float) -> void:
	_dodge_cd = maxf(0.0, _dodge_cd - delta)
	if _is_dodging:
		_dodge_timer = maxf(0.0, _dodge_timer - delta)
		velocity.x = _dodge_dir.x * dodge_speed
		velocity.z = _dodge_dir.z * dodge_speed
		velocity.y = 0.0
		move_and_slide()
		if _dodge_timer <= 0.0:
			_is_dodging = false
		return

	var input_vec: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _mobile_input.length() > input_vec.length():
		input_vec = _mobile_input
	if input_vec.length_squared() > 0.001:
		var local_move := Vector3(input_vec.x, 0.0, input_vec.y)
		var world_move := local_move.rotated(Vector3.UP, _camera_yaw)
		input_vec = Vector2(world_move.x, world_move.z).clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))
	input_vec *= CharacterBuild.move_speed_multiplier()
	var has_move: bool = input_vec.length_squared() > 0.001

	var dodge_pressed: bool = false
	if InputMap.has_action("dodge_roll") and Input.is_action_just_pressed("dodge_roll"):
		dodge_pressed = true
	elif InputMap.has_action("dodge") and Input.is_action_just_pressed("dodge"):
		dodge_pressed = true
	if _mobile_dodge_requested:
		dodge_pressed = true
		_mobile_dodge_requested = false
	if dodge_pressed and _dodge_cd <= 0.0:
		var dodge_vec := Vector3(input_vec.x, 0.0, input_vec.y)
		if dodge_vec.length_squared() <= 0.001:
			dodge_vec = -global_transform.basis.z
		_dodge_dir = dodge_vec.normalized()
		_is_dodging = true
		_dodge_timer = dodge_duration
		_dodge_cd = dodge_cooldown
		return

	var jump_pressed: bool = false
	if InputMap.has_action("jump_3d") and Input.is_action_just_pressed("jump_3d"):
		jump_pressed = true
	elif InputMap.has_action("jump") and Input.is_action_just_pressed("jump"):
		jump_pressed = true
	if _mobile_jump_requested:
		jump_pressed = true
		_mobile_jump_requested = false
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif jump_pressed:
		velocity.y = jump_velocity
	else:
		velocity.y = 0.0
	var target: Vector3 = Vector3(input_vec.x, 0.0, input_vec.y) * move_speed
	var rate: float = acceleration if has_move else deceleration
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)
	move_and_slide()
