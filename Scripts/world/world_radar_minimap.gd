extends Control

## 右下角圆形雷达：以玩家为中心，实时显示附近 NPC（粉）与怪物（红）。

var world_root: Node2D

@export_range(120.0, 900.0, 10.0) var radar_world_radius: float = 420.0
@export_range(56.0, 200.0, 2.0) var radar_pixel_radius: float = 54.0
const REDRAW_INTERVAL_SEC := 0.1
var _redraw_cd: float = 0.0
var _player_cache: Node2D = null
var _npc_cache: Array[Node2D] = []
var _monster_cache: Array[Node2D] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1


func setup(world: Node2D) -> void:
	world_root = world


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
	var c: Vector2 = size * 0.5
	var rad: float = mini(minf(size.x, size.y) * 0.5 - 2.0, radar_pixel_radius)
	draw_circle(c, rad + 2.0, Color(0, 0, 0, 0.28))
	draw_circle(c, rad, Color8(22, 18, 32, 230))
	draw_arc(c, rad, 0.0, TAU, 72, Color8(255, 195, 215, 0.45), 2.0, true)

	var pl: Node2D = _player_cache
	if pl == null:
		return
	var origin: Vector2 = pl.global_position
	# 中心十字
	draw_line(c - Vector2(6, 0), c + Vector2(6, 0), Color(1, 1, 1, 0.22), 1.0)
	draw_line(c - Vector2(0, 6), c + Vector2(0, 6), Color(1, 1, 1, 0.22), 1.0)

	for npc in _npc_cache:
		if not is_instance_valid(npc):
			continue
		if npc == pl:
			continue
		_draw_blip(origin, npc.global_position, c, rad, Color8(255, 140, 200), 4.0)

	for m in _monster_cache:
		if not is_instance_valid(m):
			continue
		_draw_blip(origin, m.global_position, c, rad, Color8(255, 88, 88), 4.0)


func _refresh_entities_cache() -> void:
	_player_cache = _find_player()
	_npc_cache = _npc_nodes()
	_monster_cache = _monster_nodes()


func _draw_blip(origin: Vector2, world_pos: Vector2, center: Vector2, rad: float, col: Color, dot_r: float) -> void:
	var rel: Vector2 = world_pos - origin
	var d2: float = rel.length_squared()
	if d2 < 2.0:
		return
	var rel_n: Vector2 = rel.normalized()
	var t: float = sqrt(d2) / radar_world_radius
	if t > 1.0:
		t = 1.0
	var p: Vector2 = center + rel_n * t * rad * 0.92
	draw_circle(p, dot_r, col)


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
