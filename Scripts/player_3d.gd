extends CharacterBody3D

## 纯 3D 简模：胶囊躯干 + 球头 + 刀条；不再使用 2D 立绘 / Billboard

@export var move_speed: float = 200.0
@export var jump_velocity: float = 5.2
@export var gravity_scale: float = 1.6
@export var player_color: Color = Color(0.3, 0.55, 0.95, 1.0)
@export var skin_color: Color = Color(0.96, 0.78, 0.68, 1.0)
@export var accent_color: Color = Color(0.92, 0.42, 0.32, 1.0)
@export var show_model_in_first_person: bool = false
@export var turn_smooth: float = 12.0

const _MODEL_NAME := "ChibiModel3D"

var is_in_dialog: bool = false
var nearby_npcs: Array[Node] = []
var mobile_input_dir: Vector2 = Vector2.ZERO
var use_mobile_controls: bool = false

var _sync_pos: Vector3 = Vector3.ZERO
var _jump_queued: bool = false
## 与水平速度一致，供摄像机与攻击前向共用；经 turn_smooth 插值，避免瞬切朝向
var _view_forward_xz: Vector3 = Vector3(0, 0, -1)
## 本帧希望朝向（来自输入/速度），_view_forward_xz 会 slerp 贴近它
var _turn_intent: Vector3 = Vector3(0, 0, -1)
@onready var _name_label: Label3D = $NameLabel3D
@onready var _level_label: Label3D = $LevelLabel3D
@onready var _pivot: Node3D = $VisualPivot
var _model_root: Node3D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_stop_on_slope = true
	floor_block_on_wall = true
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.2
	_sync_pos = global_position
	_build_3d_model()
	_refresh_nameplate_vis()


func set_display_name(text: String) -> void:
	var label_text: String = text.strip_edges()
	if label_text.is_empty():
		label_text = str(name)
	_name_label.text = label_text


func set_level_exp_caption(text: String) -> void:
	_level_label.text = text


func set_level_exp_visible(vis: bool) -> void:
	_level_label.visible = vis and not WorldNetwork.is_cloud()


func _base_mat() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.roughness = 0.86
	m.metallic = 0.0
	return m


func _build_3d_model() -> void:
	_clear_model_children()
	_model_root = Node3D.new()
	_model_root.name = _MODEL_NAME
	_pivot.add_child(_model_root)

	## 与碰撞胶囊接近：身长约 0.9，半径约 0.28
	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	var cap := CapsuleMesh.new()
	cap.height = 0.62
	cap.radius = 0.24
	torso.mesh = cap
	torso.position = Vector3(0, 0.4, 0)
	var tmat: StandardMaterial3D = _base_mat()
	tmat.albedo_color = player_color.lerp(Color(0.4, 0.35, 0.3), 0.22)
	torso.material_override = tmat
	_model_root.add_child(torso)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var sph := SphereMesh.new()
	sph.radial_segments = 16
	sph.rings = 8
	sph.radius = 0.18
	head.mesh = sph
	head.position = Vector3(0, 0.9, 0.02)
	var hmat: StandardMaterial3D = _base_mat()
	hmat.albedo_color = skin_color
	head.material_override = hmat
	_model_root.add_child(head)

	## 装饰腰带
	var belt := MeshInstance3D.new()
	belt.name = "Belt"
	var tb := BoxMesh.new()
	tb.size = Vector3(0.48, 0.08, 0.22)
	belt.mesh = tb
	belt.position = Vector3(0, 0.58, 0)
	var bmat: StandardMaterial3D = _base_mat()
	bmat.albedo_color = accent_color
	belt.material_override = bmat
	_model_root.add_child(belt)

	## 长刀 / 大剑 简形
	var sword := MeshInstance3D.new()
	sword.name = "Sword"
	var blade := BoxMesh.new()
	blade.size = Vector3(0.06, 0.4, 0.05)
	sword.mesh = blade
	sword.position = Vector3(0.22, 0.5, 0.05)
	sword.rotation_degrees = Vector3(8, 0, -6)
	var smat: StandardMaterial3D = _base_mat()
	smat.albedo_color = Color(0.75, 0.78, 0.9)
	smat.metallic = 0.55
	smat.roughness = 0.35
	sword.material_override = smat
	_model_root.add_child(sword)

	## 两只脚 简形（球）避免视觉悬空
	for side in [-1, 1]:
		var foot_m: MeshInstance3D = MeshInstance3D.new()
		foot_m.name = "Foot" + str(side)
		var sf := SphereMesh.new()
		sf.radius = 0.1
		sf.radial_segments = 12
		sf.rings = 6
		foot_m.mesh = sf
		foot_m.position = Vector3(float(side) * 0.12, 0.12, 0.02)
		var fmat: StandardMaterial3D = _base_mat()
		fmat.albedo_color = Color(0.2, 0.18, 0.16)
		foot_m.material_override = fmat
		_model_root.add_child(foot_m)


func _clear_model_children() -> void:
	if not is_instance_valid(_pivot):
		return
	for c in _pivot.get_children():
		if c is Node3D and (c as Node3D).name == _MODEL_NAME:
			(c as Node3D).queue_free()


func _refresh_nameplate_vis() -> void:
	_name_label.visible = true
	_name_label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_level_label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_level_label.visible = not WorldNetwork.is_cloud()
	## 3D 角色身高约 1.0+，字牌在头顶
	_name_label.position = Vector3(0, 1.4, 0)
	_level_label.position = Vector3(0, 1.1, 0)


func apply_remote_visual() -> void:
	if not is_instance_valid(_model_root):
		return
	for ch in _model_root.get_children():
		if ch is MeshInstance3D:
			var mm: StandardMaterial3D = (ch as MeshInstance3D).material_override
			if mm:
				var dup: StandardMaterial3D = mm.duplicate() as StandardMaterial3D
				dup.albedo_color = Color(0.95, 0.55, 0.7)
				(ch as MeshInstance3D).material_override = dup


func apply_sync_position(pos: Vector3) -> void:
	_sync_pos = pos


func set_mobile_input(direction: Vector2) -> void:
	mobile_input_dir = direction
	use_mobile_controls = true


func queue_jump() -> void:
	_jump_queued = true


func get_facing_forward_xz() -> Vector3:
	return _view_forward_xz


## 与 VisualPivot 一致，给近战特效 / 世界脚本用
func get_facing_yaw() -> float:
	if not is_instance_valid(_pivot):
		return 0.0
	return _pivot.global_rotation.y


func set_first_person_view(active: bool) -> void:
	if not is_instance_valid(_model_root):
		return
	if active and not show_model_in_first_person:
		_model_root.visible = false
	else:
		_model_root.visible = true
	if is_instance_valid(_name_label):
		_name_label.visible = not active
	if active:
		if is_instance_valid(_level_label):
			_level_label.visible = false
	else:
		_refresh_nameplate_vis()


func _physics_process(delta: float) -> void:
	if _is_remote_player():
		var lp: Vector3 = global_position.lerp(_sync_pos, clampf(14.0 * delta, 0.0, 1.0))
		global_position = lp
		velocity = Vector3.ZERO
		return

	if is_in_dialog:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var g: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)) * gravity_scale
	if not is_on_floor():
		velocity.y -= g * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	var input_dir: Vector2 = Vector2.ZERO
	if use_mobile_controls:
		input_dir = mobile_input_dir
	else:
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	var h: Vector3 = Vector3.ZERO
	if input_dir.length_squared() > 0.0001:
		h = (
			Vector3(input_dir.x, 0.0, input_dir.y).normalized()
			* move_speed
			* CharacterBuild.move_speed_multiplier()
		)
		_turn_intent = h.normalized()

	velocity.x = h.x
	velocity.z = h.z

	var want_jump: bool = (
		Input.is_action_just_pressed("jump") or _jump_queued
	)
	_jump_queued = false
	if want_jump and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	## 无输入时用惯性速度更新意图；站定时保持上一帧朝向
	var hv2: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if hv2.length_squared() > 0.04:
		_turn_intent = hv2.normalized()
	var step: float = minf(1.0, turn_smooth * delta)
	_view_forward_xz = _view_forward_xz.slerp(_turn_intent, step)
	if _view_forward_xz.length_squared() < 0.0001:
		_view_forward_xz = _turn_intent
	else:
		_view_forward_xz = _view_forward_xz.normalized()
		## 几乎反向时 slerp 会走长线，给一点 nudge
		if _view_forward_xz.dot(_turn_intent) < -0.85 and step > 0.08:
			_view_forward_xz = _turn_intent
	## 模型与摄像机、攻击前向统一
	_pivot.look_at(global_position + _view_forward_xz, Vector3.UP)

	if WorldNetwork.is_cloud() and str(name) == WorldNetwork.cloud_my_user_id:
		WorldNetwork.send_cloud_move(_xz_to_2d_net(global_position))


func _xz_to_2d_net(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


func is_local_controllable() -> bool:
	return not _is_remote_player()


func _is_remote_player() -> bool:
	if WorldNetwork.is_cloud():
		return str(name) != WorldNetwork.cloud_my_user_id
	return false


func _process(_delta: float) -> void:
	if _is_remote_player():
		return
	if Input.is_action_just_pressed("interact"):
		_try_interact_with_npc()


func try_interact_nearby() -> void:
	if _is_remote_player():
		return
	_try_interact_with_npc()


func _try_interact_with_npc() -> void:
	if is_in_dialog or MoeDialogBus.is_dialog_open():
		return
	if nearby_npcs.is_empty():
		return
	var nearest: Node = nearby_npcs[0]
	for npc in nearby_npcs:
		if not is_instance_valid(nearest) or not is_instance_valid(npc):
			continue
		if _horiz_dist(global_position, (npc as Node3D).global_position) < _horiz_dist(global_position, (nearest as Node3D).global_position):
			nearest = npc
	if nearest and nearest.has_method("try_interact"):
		nearest.call("try_interact")


func _horiz_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func add_nearby_npc(npc: Node) -> void:
	if not nearby_npcs.has(npc):
		nearby_npcs.append(npc)


func remove_nearby_npc(npc: Node) -> void:
	if nearby_npcs.has(npc):
		nearby_npcs.erase(npc)


func start_dialog() -> void:
	is_in_dialog = true


func end_dialog() -> void:
	is_in_dialog = false
