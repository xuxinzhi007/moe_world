extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var ai_service: Node = $AIService
@onready var dialog_system: CanvasLayer = $DialogSystem
@onready var game_world: Node2D = $GameWorld
@onready var npcs: Node2D = $GameWorld/NPCs

func _ready() -> void:
	print("🌟 萌社区启动！")
	
	dialog_system.set_ai_service(ai_service)
	player.set_dialog_system(dialog_system)
	
	_create_ground()
	_spawn_npcs()

func _create_ground() -> void:
	var ground_node = Node2D.new()
	ground_node.name = "Ground"
	game_world.add_child(ground_node)
	
	var ground_sprite = Sprite2D.new()
	ground_node.add_child(ground_sprite)
	
	var color_rect = ColorRect.new()
	color_rect.offset_left = -1000
	color_rect.offset_top = -1000
	color_rect.offset_right = 1000
	color_rect.offset_bottom = 1000
	color_rect.color = Color(0.95, 0.95, 0.9, 1)
	ground_sprite.add_child(color_rect)

func _spawn_npcs() -> void:
	var npc_data = [
		{"name": "小萌", "position": Vector2(100, 100), "color": Color(1, 0.5, 0.8, 1), "greeting": "你好呀~ 欢迎来到萌社区！"},
		{"name": "阿杰", "position": Vector2(-100, -100), "color": Color(0.5, 0.8, 1, 1), "greeting": "嗨！今天天气真好~"},
		{"name": "小雪", "position": Vector2(150, -80), "color": Color(0.8, 1, 0.5, 1), "greeting": "见到你真开心！"}
	]
	
	for data in npc_data:
		_spawn_single_npc(data)

func _spawn_single_npc(data: Dictionary) -> void:
	var npc_scene = create_npc_instance()
	npc_scene.npc_name = data["name"]
	npc_scene.global_position = data["position"]
	npc_scene.npc_color = data["color"]
	npc_scene.greeting = data["greeting"]
	npcs.add_child(npc_scene)
	
	npc_scene.npc_interacted.connect(_on_npc_interacted)

func create_npc_instance() -> CharacterBody2D:
	var npc = CharacterBody2D.new()
	var script = load("res://Scripts/npc.gd")
	npc.set_script(script)
	return npc

func _on_npc_interacted(npc: Node2D) -> void:
	player.start_dialog()
	var npc_name = npc.npc_name
	var greeting = npc.greeting
	dialog_system.show_dialog(npc, npc_name, greeting)
	dialog_system.dialog_closed.connect(_on_dialog_closed, CONNECT_ONE_SHOT)

func _on_dialog_closed() -> void:
	player.end_dialog()
