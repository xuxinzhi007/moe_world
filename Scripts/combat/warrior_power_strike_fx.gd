extends Node2D

## 战士强击Q技能：超级挥砍特效

@onready var power_sprite: Sprite2D = $PowerSprite
@onready var shockwave_1: Sprite2D = $Shockwave1
@onready var shockwave_2: Sprite2D = $Shockwave2

var _texture: Texture2D
var _duration: float = 0.6


func _ready() -> void:
	_texture = preload("res://Assets/sprites/warrior_power_strike.svg")
	power_sprite.texture = _texture
	shockwave_1.texture = _texture
	shockwave_2.texture = _texture
	z_index = 9
	z_as_relative = false


func play_power_strike(world_pos: Vector2) -> void:
	global_position = world_pos
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	power_sprite.scale = Vector2(0.3, 0.3)
	shockwave_1.scale = Vector2(0.2, 0.2)
	shockwave_2.scale = Vector2(0.2, 0.2)
	shockwave_1.modulate.a = 0.0
	shockwave_2.modulate.a = 0.0
	_animate_power_strike()


func _animate_power_strike() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(power_sprite, "scale", Vector2.ONE * 1.5, _duration * 0.4)
	tween.tween_property(power_sprite, "modulate:a", 0.0, _duration * 0.7).set_delay(_duration * 0.3)
	tween.tween_property(shockwave_1, "scale", Vector2.ONE * 2.0, _duration * 0.5)
	tween.tween_property(shockwave_1, "modulate:a", 0.0, _duration * 0.5)
	tween.tween_property(shockwave_2, "scale", Vector2.ONE * 2.5, _duration * 0.6)
	tween.tween_property(shockwave_2, "modulate:a", 0.0, _duration * 0.6).set_delay(_duration * 0.1)
	await tween.finished
	queue_free()