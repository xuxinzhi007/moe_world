extends Control

var world_root: Node2D

const FALLBACK_WORLD_RECT := Rect2(-960.0, -640.0, 1920.0, 1280.0)
const REDRAW_INTERVAL_SEC := 0.1

var _redraw_cd: float = 0.0
var _player_cache: Node2D = null
var _npc_cache: Array[Node2D] = []
var _monster_cache: Array[Node2D] = []
var _neutral_cache: Array[Node2D] = []
var _exit_cache: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1


func setup(world: Node2D) -> void:
	world_root = world


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_redraw_cd = maxf(0.0, _redraw_cd - delta)
	if _redraw_cd > 0.0:
		return
	_redraw_cd = REDRAW_INTERVAL_SEC
	_refresh_entities_cache()
	queue_redraw()


func _draw() -> void:
	var outer := Rect2(Vector2.ZERO, size)
	var inner_pad := 14.0
	var header_h := 24.0
	var panel := outer.grow(-2.0)
	var map_rect := Rect2(Vector2(inner_pad, inner_pad + header_h), Vector2(size.x - inner_pad * 2.0, size.y - inner_pad * 2.0 - header_h))
	if map_rect.size.x <= 8.0 or map_rect.size.y <= 8.0:
		return

	var bg := Color(0.07, 0.08, 0.12, 0.90)
	var border := Color(0.86, 0.83, 0.70, 0.72)
	draw_rect(panel, bg, true)
	draw_rect(panel, border, false, 2.0)
	draw_rect(map_rect, Color(0.15, 0.19, 0.16, 0.92), true)
	draw_rect(map_rect, Color(0.92, 0.92, 0.82, 0.24), false, 1.5)

	var map_title := "区域地图"
	if is_instance_valid(world_root) and world_root.has_method("get_current_map_title"):
		map_title = str(world_root.call("get_current_map_title"))
	draw_string(ThemeDB.fallback_font, Vector2(inner_pad, 18.0), map_title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.97, 0.94, 0.84, 0.96))

	var world_bounds: Rect2 = _current_bounds_for_draw()
	for exit_any in _exit_cache:
		if not (exit_any is Dictionary):
			continue
		var exit_row: Dictionary = exit_any as Dictionary
		var exit_pos: Variant = exit_row.get("world_pos", Vector2.ZERO)
		if not (exit_pos is Vector2):
			continue
		var exit_point: Vector2 = _xform_point_clamped(world_bounds, exit_pos as Vector2, map_rect)
		var active: bool = _is_exit_active(exit_row)
		var exit_col: Color = Color8(255, 208, 120) if active else Color8(150, 190, 255)
		draw_circle(exit_point, 5.0, exit_col)
		draw_arc(exit_point, 7.0, 0.0, TAU, 18, Color(0.08, 0.10, 0.14, 0.95), 1.2, true)

	for npc in _npc_cache:
		if is_instance_valid(npc):
			draw_circle(_xform_point_clamped(world_bounds, npc.global_position, map_rect), 3.5, Color8(255, 150, 210))
	for monster in _monster_cache:
		if is_instance_valid(monster):
			draw_circle(_xform_point_clamped(world_bounds, monster.global_position, map_rect), 3.5, Color8(255, 96, 96))
	for neutral in _neutral_cache:
		if is_instance_valid(neutral):
			draw_circle(_xform_point_clamped(world_bounds, neutral.global_position, map_rect), 3.0, Color8(120, 236, 206))

	if is_instance_valid(_player_cache):
		var player_pos := _xform_point_clamped(world_bounds, _player_cache.global_position, map_rect)
		var facing := _player_facing_dir()
		var side := facing.orthogonal() * 4.0
		var tip := player_pos + facing * 9.0
		var back_left := player_pos - facing * 4.0 + side
		var back_right := player_pos - facing * 4.0 - side
		var tri := PackedVector2Array([tip, back_left, back_right])
		draw_colored_polygon(tri, Color8(255, 225, 92))
		draw_circle(player_pos, 3.0, Color8(80, 52, 18))


func _refresh_entities_cache() -> void:
	_player_cache = _find_player()
	_npc_cache = _npc_nodes()
	_monster_cache = _monster_nodes()
	_neutral_cache = _neutral_nodes()
	_exit_cache = _exit_rows()


func _current_bounds_for_draw() -> Rect2:
	if is_instance_valid(world_root) and world_root.has_method("get_current_minimap_bounds"):
		var rect_any: Variant = world_root.call("get_current_minimap_bounds")
		if rect_any is Rect2:
			var rr: Rect2 = rect_any as Rect2
			if rr.size.x > 1.0 and rr.size.y > 1.0:
				return rr
	return FALLBACK_WORLD_RECT


func _exit_rows() -> Array:
	if is_instance_valid(world_root) and world_root.has_method("get_current_minimap_exits"):
		var rows_any: Variant = world_root.call("get_current_minimap_exits")
		if rows_any is Array:
			return rows_any as Array
	return []


func _is_exit_active(exit_row: Dictionary) -> bool:
	var target_id: String = str(exit_row.get("target_id", ""))
	if target_id.is_empty():
		return false
	if not is_instance_valid(world_root) or not world_root.has_method("get_current_map_id"):
		return false
	return target_id != str(world_root.call("get_current_map_id"))


func _player_facing_dir() -> Vector2:
	if not is_instance_valid(_player_cache):
		return Vector2.RIGHT
	var vel_any: Variant = _player_cache.get("velocity")
	if vel_any is Vector2 and (vel_any as Vector2).length_squared() > 1.0:
		return (vel_any as Vector2).normalized()
	return Vector2.RIGHT if _player_cache.scale.x >= 0.0 else Vector2.LEFT


func _xform_point_clamped(world_bounds: Rect2, world_pt: Vector2, target: Rect2) -> Vector2:
	var u: float = 0.5 if world_bounds.size.x <= 0.01 else (world_pt.x - world_bounds.position.x) / world_bounds.size.x
	var v: float = 0.5 if world_bounds.size.y <= 0.01 else (world_pt.y - world_bounds.position.y) / world_bounds.size.y
	u = clampf(u, 0.0, 1.0)
	v = clampf(v, 0.0, 1.0)
	return Vector2(target.position.x + u * target.size.x, target.position.y + v * target.size.y)


func _find_player() -> Node2D:
	if not is_instance_valid(world_root):
		return null
	var pr: Node2D = world_root.get_node_or_null("Playfield/Players") as Node2D
	if pr == null:
		return null
	for ch in pr.get_children():
		if ch is Node2D and ch.is_in_group("player"):
			return ch as Node2D
	return null


func _npc_nodes() -> Array[Node2D]:
	var out: Array[Node2D] = []
	if not is_instance_valid(world_root):
		return out
	var root_npcs: Node2D = world_root.get_node_or_null("Playfield/NPCs") as Node2D
	if root_npcs == null:
		return out
	for ch in root_npcs.get_children():
		if ch is Node2D:
			out.append(ch as Node2D)
	return out


func _monster_nodes() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for n in get_tree().get_nodes_in_group("world_monster"):
		if n is Node2D and is_instance_valid(n):
			out.append(n as Node2D)
	return out


func _neutral_nodes() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for n in get_tree().get_nodes_in_group("neutral_creature"):
		if n is Node2D and is_instance_valid(n):
			out.append(n as Node2D)
	return out


func get_world_population_summary() -> String:
	_refresh_entities_cache()
	var map_title := ""
	if is_instance_valid(world_root) and world_root.has_method("get_current_map_title"):
		map_title = str(world_root.call("get_current_map_title"))
	return "%s NPC: %d  怪物: %d  中立: %d" % [map_title, _npc_cache.size(), _monster_cache.size(), _neutral_cache.size()]

