extends Node

signal map_switch_started(from_map: String, to_map: String, entry_dir: String)
signal map_switch_finished(from_map: String, to_map: String, entry_dir: String)

@export var switch_cooldown_sec: float = 0.22

var _switch_locked: bool = false
var _last_switch_msec: int = -1000000
var _map_scene_paths: Dictionary = {}
var _scene_cache: Dictionary = {}
var _pending_world_map_switch: Dictionary = {}


func register_map_scene(map_id: String, scene_path: String) -> void:
	var id: String = map_id.strip_edges()
	var path: String = scene_path.strip_edges()
	if id.is_empty() or path.is_empty():
		return
	_map_scene_paths[id] = path


func register_map_scenes(rows: Array[Dictionary]) -> void:
	for row in rows:
		var id: String = str(row.get("id", ""))
		var path: String = str(row.get("path", ""))
		register_map_scene(id, path)


func preload_map_scene(map_id: String) -> PackedScene:
	var id: String = map_id.strip_edges()
	if id.is_empty():
		return null
	if _scene_cache.has(id):
		return _scene_cache[id] as PackedScene
	var path: String = str(_map_scene_paths.get(id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var ps: PackedScene = load(path) as PackedScene
	if ps != null:
		_scene_cache[id] = ps
	return ps


func can_switch_map() -> bool:
	if _switch_locked:
		return false
	var now_ms: int = Time.get_ticks_msec()
	var cd_ms: int = int(maxf(0.01, switch_cooldown_sec) * 1000.0)
	return now_ms - _last_switch_msec >= cd_ms


func begin_map_switch(from_map: String, to_map: String, entry_dir: String) -> bool:
	if not can_switch_map():
		return false
	if to_map.strip_edges().is_empty():
		return false
	_switch_locked = true
	map_switch_started.emit(from_map, to_map, entry_dir)
	return true


func finish_map_switch(from_map: String, to_map: String, entry_dir: String) -> void:
	_last_switch_msec = Time.get_ticks_msec()
	_switch_locked = false
	map_switch_finished.emit(from_map, to_map, entry_dir)


func opposite_dir(exit_dir: String) -> String:
	match exit_dir:
		"left":
			return "right"
		"right":
			return "left"
		"top":
			return "bottom"
		"bottom":
			return "top"
		_:
			return ""


func set_pending_world_map_switch(to_map_id: String, entry_dir: String = "left", title: String = "") -> void:
	_pending_world_map_switch = {
		"to_map_id": to_map_id.strip_edges(),
		"entry_dir": entry_dir.strip_edges(),
		"title": title,
	}


func consume_pending_world_map_switch() -> Dictionary:
	var out: Dictionary = _pending_world_map_switch.duplicate()
	_pending_world_map_switch.clear()
	return out
