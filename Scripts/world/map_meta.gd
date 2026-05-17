extends Node

@export var map_id: String = ""
@export var neighbors: Dictionary = {}
@export var camera_frame_size: Vector2 = Vector2.ZERO


func get_neighbor(exit_dir: String) -> String:
	return str(neighbors.get(exit_dir, ""))
