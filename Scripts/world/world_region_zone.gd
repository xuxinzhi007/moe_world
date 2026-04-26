extends Area2D

## 覆盖一片地图区域；玩家 CharacterBody2D 进入时触发顶部区域提示。

@export var region_title: String = "未命名区域"
@export var region_subtitle: String = ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	for n in get_tree().get_nodes_in_group("world_region_toast"):
		if n is Node and (n as Node).is_inside_tree() and n.has_method("show_region"):
			n.show_region(region_title, region_subtitle)
			break
