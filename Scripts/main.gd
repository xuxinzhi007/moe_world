extends Node2D

@onready var map_generator: Node2D = get_node_or_null("MapGenerator")

func _ready() -> void:
	# Main 只做流程协调，地图只由 MapGenerator 负责生成，避免重复创建房间。
	if map_generator and map_generator.has_method("generate_map"):
		print("✅ Main 初始化完成，地图生成由 MapGenerator 管理")
	else:
		print("❌ 未找到 MapGenerator 或 generate_map 方法，请检查节点绑定")
