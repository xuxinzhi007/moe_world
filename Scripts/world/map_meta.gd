extends Node

@export var map_id: String = ""
@export var neighbors: Dictionary = {}


func get_neighbor(exit_dir: String) -> String:
	return str(neighbors.get(exit_dir, ""))
