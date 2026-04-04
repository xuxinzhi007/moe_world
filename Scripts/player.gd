extends CharacterBody2D

@export var move_speed: float = 200.0
@export var player_color: Color = Color(0.3, 0.6, 1, 1)

var is_in_dialog: bool = false
var nearby_npcs: Array = []
var dialog_system: Node

func _ready() -> void:
	add_to_group("player")
	_setup_visuals()

func _setup_visuals() -> void:
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)
	
	var color_rect = ColorRect.new()
	color_rect.name = "ColorRect"
	color_rect.offset_left = -16
	color_rect.offset_top = -24
	color_rect.offset_right = 16
	color_rect.offset_bottom = 8
	color_rect.color = player_color
	sprite.add_child(color_rect)
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(32, 32)
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.make_current()
	add_child(camera)

func _physics_process(delta: float) -> void:
	if is_in_dialog:
		velocity = Vector2.ZERO
		return
	
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
	
	velocity = input_dir * move_speed
	move_and_slide()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
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
