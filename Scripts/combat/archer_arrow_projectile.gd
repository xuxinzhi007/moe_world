extends Node2D

## 弓箭弹射物：根节点 = 箭尖；飞行中子步检测与怪物的线段距离；超时销毁。
## 飞行方向 = 父节点本地 +X。请在 **ArcherArrowProjectile.tscn** 里旋转 Sprite2D，使箭尖与 +X 一致（默认已 +90°，贴图原为朝上）。

const SPAWN_LEAD := 14.0
const DEFAULT_FLIGHT_LIFETIME_SEC := 5.0
## 单帧内每段最大步长（像素），越小越不易「穿过」怪物碰撞体。
const COLLISION_MAX_STEP_PX := 20.0

@export var move_speed: float = 920.0
@export var hit_radius: float = 34.0
## 在场景里 Sprite2D.rotation 基础上的额外弧度（一般保持 0，微调时用）。
@export var sprite_rotation_extra_rad: float = 0.0
@export var sprite_rear_offset_factor: float = 0.46

var _configured: bool = false
var _fire_origin: Vector2
var _dir: Vector2 = Vector2.RIGHT
var _damage: int = 10
var _ttl: float = DEFAULT_FLIGHT_LIFETIME_SEC


func configure(
	player_origin: Vector2,
	dir: Vector2,
	damage: int,
	lifetime_sec: float = DEFAULT_FLIGHT_LIFETIME_SEC
) -> void:
	_configured = true
	_fire_origin = player_origin
	_dir = dir.normalized()
	_damage = maxi(1, damage)
	_ttl = maxf(0.05, lifetime_sec)


func _ready() -> void:
	if not _configured:
		queue_free()
		return
	global_position = _fire_origin + _dir * SPAWN_LEAD
	rotation = _dir.angle()
	z_index = 8
	z_as_relative = false
	var spr: Sprite2D = $Sprite2D as Sprite2D
	spr.centered = true
	spr.rotation += sprite_rotation_extra_rad
	if spr.texture != null:
		var sz: Vector2 = spr.texture.get_size() * spr.scale.abs()
		var shaft_px: float = maxf(sz.x, sz.y)
		var rear: float = clampf(shaft_px * 0.5 * sprite_rear_offset_factor, 8.0, 140.0)
		spr.position = Vector2(-rear, 0.0)
	set_process(true)


func _process(delta: float) -> void:
	_ttl -= delta
	if _ttl <= 0.0:
		queue_free()
		return
	var travel_remaining: float = move_speed * delta
	while travel_remaining > 0.0001:
		var step: float = minf(travel_remaining, COLLISION_MAX_STEP_PX)
		var prev: Vector2 = global_position
		var bow_tip: Vector2 = prev + _dir * step
		var tgt: Object = _find_hit_along_segment(prev, bow_tip)
		if tgt != null and (tgt as Object).has_method("take_damage"):
			(tgt as Object).call("take_damage", _damage)
			GameAudio.melee_hit()
			queue_free()
			return
		global_position = bow_tip
		travel_remaining -= step


static func _dist_point_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ab_len2: float = ab.length_squared()
	if ab_len2 < 1e-6:
		return p.distance_to(a)
	var t: float = clampf(ab.dot(p - a) / ab_len2, 0.0, 1.0)
	return p.distance_to(a.lerp(b, t))


func _find_hit_along_segment(a: Vector2, b: Vector2) -> Object:
	var best: Object = null
	var best_d2: float = INF
	for n in get_tree().get_nodes_in_group("world_monster").duplicate():
		if not is_instance_valid(n) or not n.has_method("take_damage"):
			continue
		var m: Node2D = n as Node2D
		var p: Vector2 = m.global_position
		var d_seg: float = _dist_point_segment(p, a, b)
		var d_tip: float = p.distance_to(b)
		var d_prev: float = p.distance_to(a)
		if minf(d_seg, minf(d_tip, d_prev)) > hit_radius:
			continue
		var d2: float = a.distance_squared_to(p)
		if d2 < best_d2:
			best_d2 = d2
			best = n
	return best
