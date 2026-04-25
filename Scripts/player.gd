extends CharacterBody2D

const _FALLBACK_CHARACTER_PATH := "res://Assets/sprites/player_character.svg"

@export var move_speed: float = 200.0
@export var player_color: Color = Color(0.3, 0.6, 1, 1)
## 角色展示用图（PNG / SVG / 图集单帧等）；可在 Player 场景里指定，留空则从路径加载内置立绘。
@export var character_texture: Texture2D
## 与 player_color 混合程度；0 保留原画色彩，1 完全乘上色。
@export_range(0.0, 1.0, 0.05) var character_color_tint_strength: float = 0.32

var is_in_dialog: bool = false
var nearby_npcs: Array = []
var dialog_system: Node

var mobile_input_dir: Vector2 = Vector2.ZERO
var use_mobile_controls: bool = false

var _sync_pos: Vector2 = Vector2.ZERO
var _name_label: Label


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	_setup_visuals()
	_ensure_nameplate()
	_sync_pos = global_position


func _ensure_nameplate() -> void:
	if is_instance_valid(_name_label):
		return
	_name_label = Label.new()
	_name_label.name = "Nameplate"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.position = Vector2(-80, -56)
	_name_label.custom_minimum_size = Vector2(160, 22)
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_color_override("font_color", Color8(75, 50, 62))
	_name_label.add_theme_color_override("font_outline_color", Color8(255, 248, 252))
	_name_label.add_theme_constant_override("outline_size", 4)
	add_child(_name_label)


func set_display_name(text: String) -> void:
	_ensure_nameplate()
	var label_text := text.strip_edges()
	if label_text.is_empty():
		label_text = str(name)
	_name_label.text = label_text


func _setup_visuals() -> void:
	var tex: Texture2D = character_texture
	if tex == null and ResourceLoader.exists(_FALLBACK_CHARACTER_PATH):
		var loaded := ResourceLoader.load(_FALLBACK_CHARACTER_PATH)
		if loaded is Texture2D:
			tex = loaded as Texture2D
	if tex != null:
		var spr := Sprite2D.new()
		spr.name = "CharacterSprite"
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		spr.centered = true
		spr.offset = Vector2(0, -30)
		spr.scale = Vector2(0.74, 0.74)
		spr.z_index = 1
		var tint := Color.WHITE.lerp(player_color, character_color_tint_strength)
		spr.modulate = tint
		add_child(spr)
	else:
		push_warning("Player: 未设置 character_texture 且无法加载 %s" % _FALLBACK_CHARACTER_PATH)
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(34, 44)
	collision_shape.shape = rect_shape
	collision_shape.position = Vector2(0, -10)
	add_child(collision_shape)


func apply_remote_visual() -> void:
	var spr := get_node_or_null("CharacterSprite") as Sprite2D
	if spr:
		spr.modulate = Color(0.98, 0.55, 0.74, 1.0)


func apply_sync_position(pos: Vector2) -> void:
	_sync_pos = pos


func set_mobile_input(direction: Vector2) -> void:
	mobile_input_dir = direction
	use_mobile_controls = true


func _physics_process(_delta: float) -> void:
	if _is_remote_player():
		global_position = global_position.lerp(_sync_pos, clampf(14.0 * _delta, 0.0, 1.0))
		velocity = Vector2.ZERO
		return

	if is_in_dialog:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir := Vector2.ZERO
	if use_mobile_controls:
		input_dir = mobile_input_dir
	else:
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

	velocity = input_dir * move_speed * CharacterBuild.move_speed_multiplier()
	move_and_slide()

	if WorldNetwork.is_cloud() and str(name) == WorldNetwork.cloud_my_user_id:
		WorldNetwork.send_cloud_move(global_position)


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
	if is_in_dialog:
		return
	if MoeDialogBus.is_dialog_open():
		return
	if nearby_npcs.is_empty():
		return
	var nearest_npc: Node2D = nearby_npcs[0]
	for npc in nearby_npcs:
		if (global_position - (npc as Node2D).global_position).length() < (global_position - nearest_npc.global_position).length():
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
