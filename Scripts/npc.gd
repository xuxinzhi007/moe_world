extends CharacterBody2D

signal npc_interacted(npc: Node2D)

@export var npc_name: String = "小萌"
@export var greeting: String = "你好呀~"
@export var move_speed: float = 50.0
@export var wander_range: float = 100.0
@export var interact_range: float = 80.0
@export var npc_color: Color = Color(1, 0.5, 0.8, 1)

var start_position: Vector2
var target_position: Vector2
var is_wandering: bool = true
var wander_timer: Timer
var interact_area: Area2D
var nearby_player: CharacterBody2D
var can_interact: bool = false

func _ready() -> void:
	start_position = global_position
	target_position = start_position
	
	_setup_interact_area()
	_setup_wander_timer()
	_setup_visuals()

func _setup_interact_area() -> void:
	interact_area = Area2D.new()
	interact_area.name = "InteractArea"
	add_child(interact_area)
	
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = interact_range
	collision_shape.shape = circle_shape
	interact_area.add_child(collision_shape)
	
	interact_area.body_entered.connect(_on_player_enter_interact)
	interact_area.body_exited.connect(_on_player_exit_interact)

func _setup_wander_timer() -> void:
	wander_timer = Timer.new()
	wander_timer.wait_time = randf_range(2.0, 5.0)
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	add_child(wander_timer)
	wander_timer.start()

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
	color_rect.color = npc_color
	sprite.add_child(color_rect)
	
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(-40, -45)
	name_label.text = npc_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.modulate = Color(1, 1, 1, 1)
	add_child(name_label)
	
	var hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.position = Vector2(-50, 30)
	hint_label.text = "按 E 对话"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.visible = false
	hint_label.modulate = Color(1, 1, 0, 1)
	add_child(hint_label)

func _physics_process(delta: float) -> void:
	if not is_wandering or can_interact:
		return
	
	var direction = (target_position - global_position).normalized()
	if direction.length() > 5:
		velocity = direction * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func _on_wander_timer_timeout() -> void:
	if not is_wandering or can_interact:
		return
	
	var angle = randf() * TAU
	var distance = randf() * wander_range
	target_position = start_position + Vector2(cos(angle), sin(angle)) * distance
	wander_timer.wait_time = randf_range(3.0, 8.0)

func _on_player_enter_interact(body: Node) -> void:
	if body.is_in_group("player"):
		nearby_player = body
		can_interact = true
		is_wandering = false
		velocity = Vector2.ZERO
		if has_node("HintLabel"):
			$HintLabel.visible = true
		if nearby_player and nearby_player.has_method("add_nearby_npc"):
			nearby_player.add_nearby_npc(self)

func _on_player_exit_interact(body: Node) -> void:
	if body == nearby_player:
		if nearby_player and nearby_player.has_method("remove_nearby_npc"):
			nearby_player.remove_nearby_npc(self)
		nearby_player = null
		can_interact = false
		is_wandering = true
		if has_node("HintLabel"):
			$HintLabel.visible = false

func try_interact() -> bool:
	if not can_interact:
		return false
	
	npc_interacted.emit(self)
	return true
