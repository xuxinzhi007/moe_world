extends Node2D

## 简单可交互 NPC：进入 Area2D 范围后玩家可按交互键或手机「E」对话。
## 可选固定路点巡逻：至少 2 个世界坐标；或在场景里放子节点 PatrolRoute/Marker2D（或任意 Node2D）作为路点。

enum PatrolMode { LOOP, PING_PONG }

@export var npc_display_name: String = "萌系店员"
@export var npc_key: String = ""
@export var npc_personality: String = "温和"
@export_multiline var dialog_message: String = "欢迎光临 moe world～今天也要开心哦！"
@export var dialog_pool: PackedStringArray = PackedStringArray()
@export var portrait_texture: Texture2D
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
var _next_bubble_interact_ms: int = 0
var _name_label: Label = null
var _next_enter_hint_ms: int = 0


func _ready() -> void:
	z_as_relative = false
	if is_instance_valid(portrait) and portrait_texture != null:
		portrait.texture = portrait_texture
	if is_instance_valid(portrait) and portrait.texture != null:
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var h: float = maxf(1.0, float(portrait.texture.get_height()))
		var s: float = clampf(portrait_target_height / h, 0.02, 2.0)
		portrait.scale = Vector2.ONE * s
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_setup_patrol()
	_ensure_name_label()
	_refresh_name_label()
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
	_refresh_name_label()
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
		if body.has_method("is_local_controllable") and bool(body.call("is_local_controllable")):
			var now_ms: int = Time.get_ticks_msec()
			if now_ms >= _next_enter_hint_ms:
				_next_enter_hint_ms = now_ms + 900
				var ws: Node = get_tree().get_first_node_in_group("world_scene")
				if ws != null and ws.has_method("show_interact_enter_bubble"):
					ws.call("show_interact_enter_bubble", global_position + Vector2(0.0, -62.0), "可对话")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.remove_nearby_npc(self)


func try_interact() -> void:
	if MoeDialogBus.is_dialog_open():
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms < _next_bubble_interact_ms:
		return
	var speaker: String = npc_display_name
	var content: String = dialog_message
	if dialog_pool.size() > 0:
		var i: int = randi() % dialog_pool.size()
		content = str(dialog_pool[i])
	if not npc_personality.strip_edges().is_empty():
		speaker = "%s（%s）" % [npc_display_name, npc_personality]
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm != null and qm.has_method("interact_npc"):
		var key: String = npc_key.strip_edges()
		if key.is_empty():
			key = npc_display_name
		var result: Variant = qm.call("interact_npc", key, npc_display_name, dialog_message)
		if result is Dictionary:
			var d: Dictionary = result
			speaker = str(d.get("speaker", speaker))
			content = str(d.get("message", content))
	var ws: Node = get_tree().get_first_node_in_group("world_scene")
	if ws != null and ws.has_method("show_npc_dialog_bubble"):
		ws.call("show_npc_dialog_bubble", self, speaker, content)
		_next_bubble_interact_ms = now_ms + 550
		return
	MoeDialogBus.show_dialog(speaker, content)


func _ensure_name_label() -> void:
	if is_instance_valid(_name_label):
		return
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.custom_minimum_size = Vector2(180.0, 20.0)
	_name_label.position = Vector2(-90.0, -108.0)
	_name_label.add_theme_font_size_override("font_size", 13)
	_name_label.add_theme_color_override("font_color", Color8(255, 236, 200))
	_name_label.add_theme_color_override("font_outline_color", Color(0.10, 0.05, 0.12, 1.0))
	_name_label.add_theme_constant_override("outline_size", 2)
	_name_label.z_as_relative = true
	_name_label.z_index = 8
	add_child(_name_label)


func _refresh_name_label() -> void:
	if not is_instance_valid(_name_label):
		return
	_name_label.text = npc_display_name
