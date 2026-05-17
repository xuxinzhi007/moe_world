extends Control

## 在固定世界矩形内绘制分区、玩家（黄点）、NPC（粉）、怪物（红）、中立生物（青绿）。

var world_root: Node2D

const WORLD_RECT := Rect2(-2100.0, -2100.0, 4200.0, 4200.0)
const REDRAW_INTERVAL_SEC := 0.1

const _ZONES: Array = [
	{"r": Rect2(470, 258, 340, 220), "c": Color(1.0, 0.72, 0.82, 0.5), "n": "传送广场"},
	{"r": Rect2(255, 130, 280, 210), "c": Color(0.7, 0.88, 1.0, 0.45), "n": "东市商街"},
	{"r": Rect2(375, 418, 480, 200), "c": Color(0.75, 1.0, 0.78, 0.42), "n": "南郊野径"},
]
var _redraw_cd: float = 0.0
var _player_cache: Node2D = null
var _npc_cache: Array[Node2D] = []
var _monster_cache: Array[Node2D] = []
var _neutral_cache: Array[Node2D] = []


func _process(_dt: float) -> void:
	if not is_visible_in_tree():
		return
	_redraw_cd = maxf(0.0, _redraw_cd - _dt)
	if _redraw_cd > 0.0:
		return
	_redraw_cd = REDRAW_INTERVAL_SEC
	_refresh_entities_cache()
	queue_redraw()


func _draw() -> void:
	var sz: Vector2 = size
	var margin: float = 14.0
	var inner := Rect2(Vector2(margin, margin), sz - Vector2(margin * 2.0, margin * 2.0))
	draw_rect(Rect2(Vector2.ZERO, sz), Color8(28, 22, 36, 245))
	draw_rect(inner, Color8(255, 230, 240, 55), false, 2.0)

	var world_bounds: Rect2 = _world_bounds_for_draw()
	var zones: Array = _zones_for_draw()
	var border: Rect2 = _xform_rect(world_bounds, world_bounds, inner)
	draw_rect(border, Color8(255, 190, 210, 35), false, 2.5)

	for z in zones:
		var d: Dictionary = z as Dictionary
		var rr: Rect2 = d["r"] as Rect2
		var col: Color = d["c"] as Color
		var active: bool = bool(d.get("active", false))
		var mr: Rect2 = _xform_rect(world_bounds, rr, inner)
		draw_rect(mr, col.lightened(0.08) if active else col, true)
		draw_rect(mr, Color(1, 1, 1, 0.68) if active else Color(1, 1, 1, 0.32), false, 2.2 if active else 1.0)

	for npc in _npc_cache:
		if not is_instance_valid(npc):
			continue
		var np: Vector2 = _xform_point_clamped(world_bounds, npc.global_position, inner)
		draw_circle(np, 5.0, Color8(255, 140, 200))
		draw_arc(np, 5.0, 0.0, TAU, 12, Color8(90, 40, 60), 1.0, true)

	for m in _monster_cache:
		if not is_instance_valid(m):
			continue
		var mp: Vector2 = _xform_point_clamped(world_bounds, m.global_position, inner)
		draw_circle(mp, 5.0, Color8(255, 88, 88))
		draw_arc(mp, 5.0, 0.0, TAU, 12, Color8(70, 20, 20), 1.0, true)

	for n in _neutral_cache:
		if not is_instance_valid(n):
			continue
		var np2: Vector2 = _xform_point_clamped(world_bounds, n.global_position, inner)
		draw_circle(np2, 4.0, Color8(122, 236, 206))
		draw_arc(np2, 4.0, 0.0, TAU, 10, Color8(18, 70, 65), 1.0, true)

	var pl: Node2D = _player_cache
	if pl:
		var p: Vector2 = _xform_point_clamped(world_bounds, pl.global_position, inner)
		draw_circle(p, 7.0, Color8(255, 220, 70))
		draw_arc(p, 7.0, 0.0, TAU, 18, Color8(80, 55, 30), 2.0, true)


func _world_bounds_for_draw() -> Rect2:
	if is_instance_valid(world_root) and world_root.has_method("get_world_map_bounds"):
		var r: Variant = world_root.call("get_world_map_bounds")
		if r is Rect2:
			var rr: Rect2 = r as Rect2
			if rr.size.x > 1.0 and rr.size.y > 1.0:
				return rr
	return WORLD_RECT


func _zones_for_draw() -> Array:
	if is_instance_valid(world_root) and world_root.has_method("get_world_map_zones"):
		var z: Variant = world_root.call("get_world_map_zones")
		if z is Array:
			return z as Array
	return _ZONES


func _refresh_entities_cache() -> void:
	_player_cache = _find_player()
	_npc_cache = _npc_nodes()
	_monster_cache = _monster_nodes()
	_neutral_cache = _neutral_nodes()


func _xform_rect(world_bounds: Rect2, world_rect: Rect2, target: Rect2) -> Rect2:
	var p1: Vector2 = _xform_point(world_bounds, world_rect.position, target)
	var p2: Vector2 = _xform_point(world_bounds, world_rect.position + world_rect.size, target)
	var ox: float = minf(p1.x, p2.x)
	var oy: float = minf(p1.y, p2.y)
	return Rect2(Vector2(ox, oy), Vector2(absf(p2.x - p1.x), absf(p2.y - p1.y)))


func _xform_point(world_bounds: Rect2, world_pt: Vector2, target: Rect2) -> Vector2:
	var u: float = (world_pt.x - world_bounds.position.x) / world_bounds.size.x
	var v: float = (world_pt.y - world_bounds.position.y) / world_bounds.size.y
	return Vector2(target.position.x + u * target.size.x, target.position.y + v * target.size.y)


func _xform_point_clamped(world_bounds: Rect2, world_pt: Vector2, target: Rect2) -> Vector2:
	var u: float = (world_pt.x - world_bounds.position.x) / world_bounds.size.x
	var v: float = (world_pt.y - world_bounds.position.y) / world_bounds.size.y
	u = clampf(u, 0.0, 1.0)
	v = clampf(v, 0.0, 1.0)
	return Vector2(target.position.x + u * target.size.x, target.position.y + v * target.size.y)


func _find_player() -> Node2D:
	if not is_instance_valid(world_root):
		return null
	var pr: Node2D = world_root.get_node_or_null("Playfield/Players") as Node2D
	if pr == null:
		return null
	for c in pr.get_children():
		if c is Node2D and c.is_in_group("player"):
			return c as Node2D
	return null


func _npc_nodes() -> Array[Node2D]:
	var out: Array[Node2D] = []
	if not is_instance_valid(world_root):
		return out
	var nr: Node2D = world_root.get_node_or_null("Playfield/NPCs") as Node2D
	if nr == null:
		return out
	for ch in nr.get_children():
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
	var map_title: String = ""
	if is_instance_valid(world_root) and world_root.has_method("get_current_map_title"):
		map_title = str(world_root.call("get_current_map_title"))
	elif is_instance_valid(world_root) and world_root.has_method("get_current_map_id"):
		map_title = str(world_root.call("get_current_map_id"))
	var map_tip: String = ""
	if not map_title.is_empty():
		map_tip = "地图: %s  " % map_title
	return "%sNPC: %d  怪物: %d  中立: %d" % [map_tip, _npc_cache.size(), _monster_cache.size(), _neutral_cache.size()]
