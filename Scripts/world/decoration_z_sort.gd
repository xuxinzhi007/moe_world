extends Node2D

## 装饰物Z轴排序：根据Y坐标自动调整Z轴，实现正确的前后关系

func _ready() -> void:
	z_as_relative = false
	_update_z_index()


func _process(delta: float) -> void:
	_update_z_index()


func _update_z_index() -> void:
	## y 越大越靠后，保证与角色的前后关系正确
	## 装饰物流的Z轴比角色低1，这样当角色和装饰物Y坐标相同时，角色显示在前面
	z_index = int(floor(global_position.y)) - 1