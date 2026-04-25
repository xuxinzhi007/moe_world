extends Control

## 在固定世界矩形内绘制分区、玩家（黄点）、NPC（粉）、怪物（红）。超出地图矩形时标点贴在边缘。

var world_root: Node2D

const WORLD_RECT := Rect2(-2100.0, -2100.0, 4200.0, 4200.0)

const _ZONES: Array = [
	{"r": Rect2(470, 258, 340, 220), "c": Color(1.0, 0.72, 0.82, 0.5), "n": "传送广场"},
	{"r": Rect2(255, 130, 280, 210), "c": Color(0.7, 0.88, 1.0, 0.45), "n": "东市商街"},
	{"r": Rect2(375, 418, 480, 200), "c": Color(0.75, 1.0, 0.78, 0.42), "n": "南郊野径"},
]


func _process(_dt: float) -> void:
	if not is_visible_in_tree():
		return
	queue_redraw()


func _draw() -> void:
	var sz: Vector2 = size
	var margin: float = 14.0
	var inner := Rect2(Vector2(margin, margin), sz - Vector2(margin * 2.0, margin * 2.0))
	draw_rect(Rect2(Vector2.ZERO, sz), Color8(28, 22, 36, 245))
	draw_rect(inner, Color8(255, 230, 240, 55), false, 2.0)

	var border: Rect2 = _xform_rect(WORLD_RECT, WORLD_RECT, inner)
	draw_rect(border, Color8(255, 190, 210, 35), false, 2.5)

	for z in _ZONES:
		var d: Dictionary = z as Dictionary
		var rr: Rect2 = d["r"] as Rect2
		var col: Color = d["c"] as Color
		var mr: Rect2 = _xform_rect(WORLD_RECT, rr, inner)
		draw_rect(mr, col, true)
		draw_rect(mr, Color(1, 1, 1, 0.32), false, 1.0)

	for npc in _npc_nodes():
		var np: Vector2 = _xform_point_clamped(WORLD_RECT, npc.global_position, inner)
		draw_circle(np, 5.0, Color8(255, 140, 200))
		draw_arc(np, 5.0, 0.0, TAU, 12, Color8(90, 40, 60), 1.0, true)

	for m in _monster_nodes():
		var mp: Vector2 = _xform_point_clamped(WORLD_RECT, m.global_position, inner)
		draw_circle(mp, 5.0, Color8(255, 88, 88))
		draw_arc(mp, 5.0, 0.0, TAU, 12, Color8(70, 20, 20), 1.0, true)

	var pl: Node2D = _find_player()
	if pl:
		var p: Vector2 = _xform_point_clamped(WORLD_RECT, pl.global_position, inner)
		draw_circle(p, 7.0, Color8(255, 220, 70))
		draw_arc(p, 7.0, 0.0, TAU, 18, Color8(80, 55, 30), 2.0, true)


func _xform_rect(world_bounds: Rect2, world_rect: Rect2, target: Rect2) -> Rect2:
	var p1: Vector2 = _xform_point(world_bounds, world_rect.position, target)
	var p2: Vector2 = _xform_point(world_bounds, world_rect.position + world_rect.size, target)
	var ox: float = mini(p1.x, p2.x)
	var oy: float = mini(p1.y, p2.y)
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
