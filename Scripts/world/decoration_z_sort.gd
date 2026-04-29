extends Node2D

## 装饰物Z轴排序：根据 Sprite2D 子节点的Y坐标自动调整Z轴，实现正确的前后关系

func _ready() -> void:
	z_as_relative = false
	_update_z_index()


func _process(_delta: float) -> void:
	_update_z_index()


func _update_z_index() -> void:
	## 优先用第一个 Sprite2D 子节点的 global_position 作为深度基准
	## （容器 Node2D 本身可能在原点 (0,0)，子节点才有真实世界坐标）
	var ref_y := global_position.y
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			ref_y = (child as Node2D).global_position.y
			break
	z_index = int(floor(ref_y))