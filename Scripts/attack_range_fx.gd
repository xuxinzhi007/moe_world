extends Node2D
class_name AttackRangeFx

## 与 world_scene / survivor_arena 中普攻判定一致的一帧范围提示（淡出后自毁）。

var _mode: int = 0
var _r: float = 78.0
var _stroke: Color = Color(1, 0.55, 0.78, 0.55)
var _fill: Color = Color(1, 0.62, 0.86, 0.1)
var _fade: float = 0.22


static func spawn_melee_ring(parent: Node2D, world_at: Vector2, radius: float, fade: float = 0.22) -> void:
	var n := AttackRangeFx.new()
	parent.add_child(n)
	n.global_position = world_at
	n.z_index = 4
	n._mode = 0
	n._r = radius
	n._stroke = Color(1.0, 0.48, 0.72, 0.58)
	n._fill = Color(1.0, 0.55, 0.82, 0.09)
	n._fade = fade
	n._run_fade()


static func spawn_mage_hit_ring(parent: Node2D, world_center: Vector2, radius: float, fade: float = 0.26) -> void:
	var n := AttackRangeFx.new()
	parent.add_child(n)
	n.global_position = world_center
	n.z_index = 6
	n._mode = 2
	n._r = radius
	n._stroke = Color(0.72, 0.55, 1.0, 0.52)
	n._fill = Color(0.65, 0.5, 1.0, 0.06)
	n._fade = fade
	n._run_fade()


func _run_fade() -> void:
	modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, _fade).from(0.48)
	tw.finished.connect(queue_free)
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	match _mode:
		0:
			draw_circle(Vector2.ZERO, _r, _fill)
			draw_arc(Vector2.ZERO, _r, 0.0, TAU, 72, _stroke, 2.5, true)
		2:
			draw_arc(Vector2.ZERO, _r, 0.0, TAU, 80, _stroke, 2.25, true)
