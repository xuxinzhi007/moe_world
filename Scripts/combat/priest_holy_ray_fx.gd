extends Node2D

## 牧师神圣射线攻击特效

@onready var ray_sprite: Sprite2D = $RaySprite
@onready var impact_glow: Sprite2D = $ImpactGlow

var _ray_texture: Texture2D
var _duration: float = 0.8
var _facing_angle: float = 0.0


func _ready() -> void:
	_ray_texture = preload("res://Assets/sprites/priest_holy_ray.svg")
	ray_sprite.texture = _ray_texture
	impact_glow.texture = _ray_texture
	z_index = 8
	z_as_relative = false


func play_holy_ray(origin: Vector2, angle: float) -> void:
	global_position = origin
	_facing_angle = angle
	ray_sprite.rotation = angle
	impact_glow.rotation = angle
	ray_sprite.scale = Vector2(0.1, 0.8)
	impact_glow.scale = Vector2(0.1, 0.1)
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	_animate_ray()


func _animate_ray() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ray_sprite, "scale:x", 1.0, _duration * 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(ray_sprite, "scale:y", 1.0, _duration * 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(ray_sprite, "modulate:a", 0.0, _duration * 0.5).set_delay(_duration * 0.5)
	tween.tween_property(impact_glow, "scale:x", 1.2, _duration * 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(impact_glow, "scale:y", 1.2, _duration * 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(impact_glow, "modulate:a", 0.0, _duration * 0.7).set_delay(_duration * 0.3)
	await tween.finished
	queue_free()