extends CharacterBody3D

signal defeated(monster: Node)

@export var max_hp: int = 30
@export var move_speed: float = 2.4
@export var contact_damage: int = 6
@export var chase_radius: float = 16.0

@onready var _hp_label: Label3D = $HpLabel3D

var _hp: int = 30
var _target: Node3D


func _ready() -> void:
	_hp = maxi(1, max_hp)
	_refresh_hp_label()


func set_target(target: Node3D) -> void:
	_target = target


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_target):
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() > chase_radius:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var dir: Vector3 = to_target.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	velocity.y = 0.0
	move_and_slide()
	if dir.length_squared() > 0.001:
		look_at(global_position + Vector3(dir.x, 0.0, dir.z), Vector3.UP)


func take_damage(amount: int) -> void:
	_hp = maxi(0, _hp - maxi(1, amount))
	_refresh_hp_label()
	if _hp <= 0:
		defeated.emit(self)
		queue_free()


func is_defeated() -> bool:
	return _hp <= 0


func _refresh_hp_label() -> void:
	if is_instance_valid(_hp_label):
		_hp_label.text = "HP %d/%d" % [_hp, maxi(1, max_hp)]
