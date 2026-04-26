extends Node2D

## 简单可交互 NPC：进入 Area2D 范围后玩家可按交互键或手机「E」对话。
## 可选固定路点巡逻：至少 2 个世界坐标；或在场景里放子节点 PatrolRoute/Marker2D（或任意 Node2D）作为路点。

enum PatrolMode { LOOP, PING_PONG }

@export var npc_display_name: String = "萌系店员"
@export_multiline var dialog_message: String = "欢迎光临 moe world～今天也要开心哦！"
## 立绘在场景里的大致高度（像素），大图会自动缩小。
@export_range(32.0, 200.0, 2.0) var portrait_target_height: float = 88.0
## 世界坐标路点（顺序即巡逻顺序）。若为空且存在 PatrolRoute 子节点，则从子 Node2D 读取位置。
@export var patrol_waypoints_world: PackedVector2Array = PackedVector2Array()
@export_range(12.0, 400.0, 1.0) var patrol_speed: float = 52.0
@export var patrol_mode: PatrolMode = PatrolMode.LOOP

@onready var interact_area: Area2D = $InteractArea
@onready var portrait: Sprite2D = $Portrait

var _patrol_wp: PackedVector2Array = PackedVector2Array()
var _patrol_active: bool = false
var _patrol_target_i: int = 0
var _patrol_dir: int = 1


func _ready() -> void:
	z_as_relative = false
	if is_instance_valid(portrait) and portrait.texture != null:
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var h: float = maxf(1.0, float(portrait.texture.get_height()))
		var s: float = clampf(portrait_target_height / h, 0.02, 2.0)
		portrait.scale = Vector2.ONE * s
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_setup_patrol()
	z_index = int(floor(global_position.y))


func _setup_patrol() -> void:
	_patrol_wp = patrol_waypoints_world.duplicate()
	if _patrol_wp.size() < 2 and has_node("PatrolRoute"):
		_patrol_wp = PackedVector2Array()
		var pr: Node = get_node("PatrolRoute")
		for c in pr.get_children():
			if c is Node2D:
				_patrol_wp.append((c as Node2D).global_position)
	if _patrol_wp.size() < 2:
		return
	_patrol_active = true
	global_position = _patrol_wp[0]
	_patrol_target_i = 1
	_patrol_dir = 1


func _physics_process(delta: float) -> void:
	z_index = int(floor(global_position.y))
	if not _patrol_active:
		return
	if MoeDialogBus.is_dialog_open():
		return
	var n: int = _patrol_wp.size()
	var target: Vector2 = _patrol_wp[_patrol_target_i]
	var to_v: Vector2 = target - global_position
	var step: float = patrol_speed * delta
	if to_v.length() <= step:
		global_position = target
		_advance_patrol(n)
	else:
		global_position += to_v.normalized() * step


func _advance_patrol(n: int) -> void:
	if patrol_mode == PatrolMode.PING_PONG:
		if _patrol_dir > 0 and _patrol_target_i >= n - 1:
			_patrol_dir = -1
			_patrol_target_i = maxi(0, n - 2)
		elif _patrol_dir < 0 and _patrol_target_i <= 0:
			_patrol_dir = 1
			_patrol_target_i = mini(n - 1, 1)
		else:
			_patrol_target_i += _patrol_dir
	else:
		_patrol_target_i = (_patrol_target_i + 1) % n


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.add_nearby_npc(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.remove_nearby_npc(self)


func try_interact() -> void:
	if MoeDialogBus.is_dialog_open():
		return
	MoeDialogBus.show_dialog(npc_display_name, dialog_message)
