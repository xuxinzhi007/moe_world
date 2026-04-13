extends CharacterBody2D

@export var move_speed: float = 200.0
@export var player_color: Color = Color(0.3, 0.6, 1, 1)

var is_in_dialog: bool = false
var nearby_npcs: Array = []
var dialog_system: Node

var mobile_input_dir: Vector2 = Vector2.ZERO
var use_mobile_controls: bool = false

func _ready() -> void:
	print("🎮 玩家节点初始化中...")
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	_setup_visuals()
	print("✅ 玩家视觉元素创建完成！")

func _setup_visuals() -> void:
	var body := Polygon2D.new()
	body.name = "BodyPoly"
	body.color = player_color
	body.polygon = PackedVector2Array([Vector2(-16, -32), Vector2(16, -32), Vector2(18, 12), Vector2(-18, 12)])
	add_child(body)
	var face := Polygon2D.new()
	face.name = "FacePoly"
	face.color = Color(1, 0.92, 0.9, 1)
	face.polygon = PackedVector2Array([Vector2(-10, -28), Vector2(10, -28), Vector2(8, -14), Vector2(-8, -14)])
	add_child(face)
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(34, 44)
	collision_shape.shape = rect_shape
	collision_shape.position = Vector2(0, -10)
	add_child(collision_shape)

func set_mobile_input(direction: Vector2) -> void:
	mobile_input_dir = direction
	use_mobile_controls = true

func _physics_process(_delta: float) -> void:
	if is_in_dialog:
		velocity = Vector2.ZERO
		return
	
	var input_dir = Vector2.ZERO
	
	if use_mobile_controls:
		input_dir = mobile_input_dir
	else:
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
	
	velocity = input_dir * move_speed
	move_and_slide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		_try_interact_with_npc()

func try_interact_nearby() -> void:
	_try_interact_with_npc()


func _try_interact_with_npc() -> void:
	if nearby_npcs.is_empty():
		return
	
	var nearest_npc = nearby_npcs[0]
	for npc in nearby_npcs:
		if (global_position - npc.global_position).length() < (global_position - nearest_npc.global_position).length():
			nearest_npc = npc
	
	if nearest_npc and nearest_npc.has_method("try_interact"):
		nearest_npc.try_interact()

func add_nearby_npc(npc: Node) -> void:
	if not nearby_npcs.has(npc):
		nearby_npcs.append(npc)

func remove_nearby_npc(npc: Node) -> void:
	if nearby_npcs.has(npc):
		nearby_npcs.erase(npc)

func set_dialog_system(system: Node) -> void:
	dialog_system = system

func start_dialog() -> void:
	is_in_dialog = true

func end_dialog() -> void:
	is_in_dialog = false
