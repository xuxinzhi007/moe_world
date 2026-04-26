extends RefCounted
class_name ArcherVolley

## 「万箭齐发」：在 `origin` 周围 **均匀角度** 射出多支箭，方向互不相同，不会叠在同一射线上。

const ARROW_SCENE := preload("res://Scenes/ArcherArrowProjectile.tscn")
const VOLLEY_COUNT: int = 14
const DEFAULT_LIFETIME_SEC: float = 5.0


static func spawn_radial_volley(
	fx_parent: Node2D,
	origin: Vector2,
	damage_per_arrow: int,
	lifetime_sec: float = DEFAULT_LIFETIME_SEC
) -> void:
	if not is_instance_valid(fx_parent):
		return
	var dmg: int = maxi(1, damage_per_arrow)
	var n: int = maxi(3, VOLLEY_COUNT)
	for i in n:
		## +0.5 使射线与坐标轴错开，视觉上更均匀。
		var ang: float = TAU * (float(i) + 0.5) / float(n)
		var dir: Vector2 = Vector2.from_angle(ang)
		var arrow: Node = ARROW_SCENE.instantiate()
		arrow.call("configure", origin, dir, dmg, lifetime_sec)
		fx_parent.add_child(arrow)
