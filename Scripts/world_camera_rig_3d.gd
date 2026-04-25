extends Node3D

## 第一 / 第三人称：与玩家物理同帧更新，**本帧对齐**目标位与朝向，避免位置 lerp + look_at 打架导致的「加速追赶」「停住绕到面前」与剧烈抖动。
## 前向由玩家 `get_facing_forward_xz()` 提供（与水平速度一致）。

@onready var cam: Camera3D = $MainCamera3D

var _target: Node3D

@export var follow_smooth: float = 10.0
@export var third_height: float = 2.0
@export var third_distance: float = 3.85
@export var third_look_at_height: float = 1.12
@export var first_eye_height: float = 1.45
@export var first_look_depth: float = 30.0
@export var first_forward_nudge: float = 0.06

enum ViewMode { THIRD_PERSON, FIRST_PERSON }
var _mode: ViewMode = ViewMode.THIRD_PERSON
var _goal_pos: Vector3 = Vector3.ZERO


func _ready() -> void:
	## 同帧内晚于默认 priority=0 的玩家，读到已 `move_and_slide` 的位姿
	process_physics_priority = 1


func set_follow_target(t: Node3D) -> void:
	_target = t


func is_first_person() -> bool:
	return _mode == ViewMode.FIRST_PERSON


func toggle_mode() -> void:
	if _mode == ViewMode.THIRD_PERSON:
		_mode = ViewMode.FIRST_PERSON
	else:
		_mode = ViewMode.THIRD_PERSON
	_apply_mode_to_target_visual()
	if is_instance_valid(_target) and cam:
		_snap_orient_immediate()


func set_mode(v: ViewMode) -> void:
	_mode = v
	_apply_mode_to_target_visual()
	if is_instance_valid(_target) and cam:
		_snap_orient_immediate()


func _apply_mode_to_target_visual() -> void:
	if not is_instance_valid(_target) or not _target.has_method("set_first_person_view"):
		return
	_target.set_first_person_view(_mode == ViewMode.FIRST_PERSON)


func _forward_xz() -> Vector3:
	if is_instance_valid(_target) and _target.has_method("get_facing_forward_xz"):
		var f: Vector3 = _target.get_facing_forward_xz() as Vector3
		f.y = 0.0
		if f.length_squared() > 0.0001:
			return f.normalized()
	return Vector3(0, 0, -1.0)


func _desired_third_camera_global() -> Vector3:
	if not is_instance_valid(_target):
		return global_position
	var p: Vector3 = _target.global_position
	var fwd: Vector3 = _forward_xz()
	return p + Vector3(0, third_height, 0) - fwd * third_distance


func _desired_first_camera_global() -> Vector3:
	if not is_instance_valid(_target):
		return global_position
	var p: Vector3 = _target.global_position
	var fwd: Vector3 = _forward_xz()
	return p + Vector3(0, first_eye_height, 0) + fwd * first_forward_nudge


func _snap_orient_immediate() -> void:
	if not is_instance_valid(_target) or not cam:
		return
	_goal_pos = (
		_desired_first_camera_global()
		if _mode == ViewMode.FIRST_PERSON
		else _desired_third_camera_global()
	)
	cam.global_position = _goal_pos
	_apply_camera_basis()


func snap_to_target() -> void:
	_apply_mode_to_target_visual()
	_snap_orient_immediate()


func _apply_camera_basis() -> void:
	if not is_instance_valid(_target) or not cam:
		return
	var fwd: Vector3 = _forward_xz()
	if _mode == ViewMode.FIRST_PERSON:
		## 用 Basis 直接对齐 -Z，避免每帧 look_at 与插值位姿叠加抖动
		cam.global_basis = Basis.looking_at(fwd, Vector3.UP)
	else:
		var aim: Vector3 = _target.global_position + Vector3(0, third_look_at_height, 0)
		var from_cam: Vector3 = aim - cam.global_position
		if from_cam.length_squared() < 0.0001:
			from_cam = fwd
		cam.global_basis = Basis.looking_at(from_cam.normalized(), Vector3.UP)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_target) or not cam:
		return
	_goal_pos = (
		_desired_first_camera_global()
		if _mode == ViewMode.FIRST_PERSON
		else _desired_third_camera_global()
	)
	cam.global_position = _goal_pos
	_apply_camera_basis()
