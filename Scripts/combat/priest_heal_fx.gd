extends Node2D

## 牧师治疗特效：神圣光环动画

@onready var heal_sprite: Sprite2D = $HealSprite
@onready var cross_symbol: Sprite2D = $CrossSymbol
@onready var sparkle_1: Sprite2D = $Sparkle1
@onready var sparkle_2: Sprite2D = $Sparkle2
@onready var sparkle_3: Sprite2D = $Sparkle3
@onready var sparkle_4: Sprite2D = $Sparkle4

var _heal_texture: Texture2D
var _cross_texture: Texture2D
var _sparkle_texture: Texture2D
var _duration: float = 1.2
var _elapsed: float = 0.0
var _target_pos: Vector2


func _ready() -> void:
	_heal_texture = preload("res://Assets/sprites/priest_heal_effect.svg")
	_cross_texture = preload("res://Assets/sprites/priest_heal_effect.svg")
	sparkle_1.texture = _heal_texture
	sparkle_2.texture = _heal_texture
	sparkle_3.texture = _heal_texture
	sparkle_4.texture = _heal_texture
	z_index = 10
	z_as_relative = false


func play_heal(world_pos: Vector2) -> void:
	global_position = world_pos
	_target_pos = world_pos
	_elapsed = 0.0
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	heal_sprite.scale = Vector2.ZERO
	cross_symbol.scale = Vector2.ZERO
	sparkle_1.position = Vector2(randf_range(-60, -40), randf_range(-60, -40))
	sparkle_2.position = Vector2(randf_range(40, 60), randf_range(-60, -40))
	sparkle_3.position = Vector2(randf_range(-60, -40), randf_range(40, 60))
	sparkle_4.position = Vector2(randf_range(40, 60), randf_range(40, 60))
	_animate_heal()


func _animate_heal() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(heal_sprite, "scale", Vector2.ONE * 1.2, _duration * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(heal_sprite, "modulate:a", 0.0, _duration * 0.7).set_delay(_duration * 0.3)
	tween.tween_property(cross_symbol, "scale", Vector2.ONE * 1.0, _duration * 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(cross_symbol, "modulate:a", 0.0, _duration * 0.6).set_delay(_duration * 0.4)
	tween.tween_property(sparkle_1, "scale", Vector2.ONE * 0.3, _duration * 0.25).set_delay(_duration * 0.1)
	tween.tween_property(sparkle_1, "modulate:a", 0.0, _duration * 0.5).set_delay(_duration * 0.2)
	tween.tween_property(sparkle_2, "scale", Vector2.ONE * 0.3, _duration * 0.25).set_delay(_duration * 0.15)
	tween.tween_property(sparkle_2, "modulate:a", 0.0, _duration * 0.5).set_delay(_duration * 0.25)
	tween.tween_property(sparkle_3, "scale", Vector2.ONE * 0.3, _duration * 0.25).set_delay(_duration * 0.2)
	tween.tween_property(sparkle_3, "modulate:a", 0.0, _duration * 0.5).set_delay(_duration * 0.3)
	tween.tween_property(sparkle_4, "scale", Vector2.ONE * 0.3, _duration * 0.25).set_delay(_duration * 0.25)
	tween.tween_property(sparkle_4, "modulate:a", 0.0, _duration * 0.5).set_delay(_duration * 0.35)
	await tween.finished
	queue_free()
