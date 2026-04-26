extends Node2D

## 牧师神恩祷言Q技能：神圣祈祷大范围治疗特效

@onready var divine_sprite: Sprite2D = $DivineSprite
@onready var pillar_sprite: Sprite2D = $PillarSprite
@onready var ring_1: Sprite2D = $Ring1
@onready var ring_2: Sprite2D = $Ring2
@onready var ring_3: Sprite2D = $Ring3
@onready var cross_sprite: Sprite2D = $CrossSprite

var _texture: Texture2D
var _duration: float = 1.5


func _ready() -> void:
	_texture = preload("res://Assets/sprites/priest_divine_prayer.svg")
	divine_sprite.texture = _texture
	pillar_sprite.texture = _texture
	ring_1.texture = _texture
	ring_2.texture = _texture
	ring_3.texture = _texture
	cross_sprite.texture = _texture
	z_index = 10
	z_as_relative = false


func play_divine_prayer(world_pos: Vector2) -> void:
	global_position = world_pos
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	divine_sprite.scale = Vector2(0.1, 0.1)
	pillar_sprite.scale = Vector2(0.3, 0.1)
	ring_1.scale = Vector2(0.2, 0.2)
	ring_2.scale = Vector2(0.2, 0.2)
	ring_3.scale = Vector2(0.2, 0.2)
	cross_sprite.scale = Vector2.ZERO
	cross_sprite.modulate.a = 0.0
	ring_1.modulate.a = 0.0
	ring_2.modulate.a = 0.0
	ring_3.modulate.a = 0.0
	_animate_divine_prayer()


func _animate_divine_prayer() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(divine_sprite, "scale", Vector2.ONE * 2.2, _duration * 0.5)
	tween.tween_property(divine_sprite, "modulate:a", 0.0, _duration * 0.8).set_delay(_duration * 0.2)
	tween.tween_property(pillar_sprite, "scale:y", 1.0, _duration * 0.4)
	tween.tween_property(pillar_sprite, "modulate:a", 0.0, _duration * 0.7).set_delay(_duration * 0.3)
	tween.tween_property(cross_sprite, "scale", Vector2.ONE * 0.8, _duration * 0.35)
	tween.tween_property(cross_sprite, "modulate:a", 0.0, _duration * 0.6).set_delay(_duration * 0.4)
	tween.tween_property(ring_1, "scale", Vector2.ONE * 1.5, _duration * 0.45)
	tween.tween_property(ring_1, "modulate:a", 0.0, _duration * 0.45)
	tween.tween_property(ring_2, "scale", Vector2.ONE * 2.0, _duration * 0.55)
	tween.tween_property(ring_2, "modulate:a", 0.0, _duration * 0.55).set_delay(_duration * 0.1)
	tween.tween_property(ring_3, "scale", Vector2.ONE * 2.5, _duration * 0.65)
	tween.tween_property(ring_3, "modulate:a", 0.0, _duration * 0.65).set_delay(_duration * 0.2)
	await tween.finished
	queue_free()