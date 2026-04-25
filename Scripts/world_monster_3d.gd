extends CharacterBody3D

## 3D 史莱姆：XZ 平面追击、受击、死亡；信号里 at_global 用 Vector3

signal damaged(actual_damage: int, at_global: Vector3)
signal died(reward_xp: int, at_global: Vector3)

@export var max_hp: int = 40
@export var reward_xp: int = 18
@export var move_speed: float = 58.0
@export var aggro_range: float = 300.0
@export var slime_visual_texture: Texture2D

var hp: int = 0
var _target: Node3D
var _dying: bool = false
var _bob_time: float = 0.0
var _bob_phase: float = 0.0
var _last_move: Vector3 = Vector3.ZERO
var _squash: float = 1.0

@onready var _body: MeshInstance3D = $SlimeMesh
@onready var _hit_tween: Tween


func _ready() -> void:
	add_to_group("world_monster")
	collision_layer = 1
	collision_mask = 1
	_bob_phase = randf() * TAU
	hp = maxi(1, max_hp)
	if _body != null:
		var mat: StandardMaterial3D = _body.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.4, 0.88, 0.55)
			_body.material_override = mat
		if slime_visual_texture != null:
			mat.albedo_texture = slime_visual_texture
		_body.visible = true


func set_aggro_target(t: Node3D) -> void:
	_target = t


func take_damage(amount: int) -> void:
	if is_queued_for_deletion() or _dying:
		return
	amount = maxi(1, amount)
	var prev_hp: int = hp
	hp = maxi(0, hp - amount)
	var dealt: int = prev_hp - hp
	if dealt > 0:
		damaged.emit(dealt, global_position)
	_play_hit_feedback()
	if hp <= 0:
		_start_death()


func _play_hit_feedback() -> void:
	if _hit_tween and is_instance_valid(_hit_tween) and _hit_tween.is_valid():
		_hit_tween.kill()
	_hit_tween = create_tween()
	var m: StandardMaterial3D = _body.material_override as StandardMaterial3D
	if m:
		var orig: Color = m.albedo_color
		m.albedo_color = orig.lightened(0.22)
		_hit_tween.tween_callback(func() -> void:
			if m: m.albedo_color = orig
		).set_delay(0.12)
	else:
		_body.scale = Vector3(1.12, 1.1, 1.12)
		_hit_tween.tween_property(_body, "scale", Vector3(0.5, 0.45, 0.5), 0.1)


func _start_death() -> void:
	_dying = true
	var rx: int = reward_xp
	var die_at: Vector3 = global_position
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if _body:
		tw.tween_property(_body, "scale", Vector3(0.5, 0.08, 0.5), 0.32)
	await tw.finished
	if is_instance_valid(self):
		died.emit(rx, die_at)
		queue_free()


func _process(delta: float) -> void:
	if _dying:
		return
	_bob_time += delta
	var bob: float = sin(_bob_time * 3.2 + _bob_phase) * 0.08
	var move_vec := Vector3.ZERO
	if _target != null and is_instance_valid(_target):
		var to_p: Vector3 = _target.global_position - global_position
		to_p.y = 0.0
		var dist: float = to_p.length()
		if dist <= aggro_range and dist > 0.35:
			move_vec = to_p.normalized() * move_speed * delta
			global_position += move_vec
			_last_move = move_vec
		else:
			_last_move = Vector3.ZERO
	else:
		_last_move = Vector3.ZERO

	if _body:
		_body.position.y = 0.28 + bob
		var sp: float = _last_move.length() / maxf(delta, 0.0001)
		_squash = lerp(_squash, 1.0 + clampf(sp / 120.0, 0.0, 0.12) * 0.2, 10.0 * delta)
		_body.scale = Vector3(0.5, 0.45, 0.5) * _squash
	global_position.y = 0.0
