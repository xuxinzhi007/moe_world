extends Node2D

## 法师法力爆发Q技能：魔法能量爆发特效

@onready var blast_sprite: Sprite2D = $BlastSprite
@onready var core_sprite: Sprite2D = $CoreSprite
@onready var ring_1: Sprite2D = $Ring1
@onready var ring_2: Sprite2D = $Ring2
@onready var spark_1: Sprite2D = $Spark1
@onready var spark_2: Sprite2D = $Spark2
@onready var spark_3: Sprite2D = $Spark3
@onready var spark_4: Sprite2D = $Spark4

var _texture: Texture2D
var _duration: float = 0.8


func _ready() -> void:
	_texture = preload("res://Assets/sprites/mage_mana_blast.svg")
	blast_sprite.texture = _texture
	core_sprite.texture = _texture
	ring_1.texture = _texture
	ring_2.texture = _texture
	spark_1.texture = _texture
	spark_2.texture = _texture
	spark_3.texture = _texture
	spark_4.texture = _texture
	z_index = 9
	z_as_relative = false


func play_mana_blast(world_pos: Vector2) -> void:
	global_position = world_pos
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	blast_sprite.scale = Vector2.ZERO
	core_sprite.scale = Vector2.ZERO
	ring_1.scale = Vector2(0.3, 0.3)
	ring_2.scale = Vector2(0.3, 0.3)
	spark_1.scale = Vector2(0.2, 0.2)
	spark_2.scale = Vector2(0.2, 0.2)
	spark_3.scale = Vector2(0.2, 0.2)
	spark_4.scale = Vector2(0.2, 0.2)
	ring_1.modulate.a = 0.0
	ring_2.modulate.a = 0.0
	spark_1.modulate.a = 0.0
	spark_2.modulate.a = 0.0
	spark_3.modulate.a = 0.0
	spark_4.modulate.a = 0.0
	_animate_mana_blast()


func _animate_mana_blast() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(blast_sprite, "scale", Vector2.ONE * 1.8, _duration * 0.35)
	tween.tween_property(blast_sprite, "modulate:a", 0.0, _duration * 0.6).set_delay(_duration * 0.4)
	tween.tween_property(core_sprite, "scale", Vector2.ONE * 1.2, _duration * 0.3)
	tween.tween_property(core_sprite, "modulate:a", 0.0, _duration * 0.5).set_delay(_duration * 0.3)
	tween.tween_property(ring_1, "scale", Vector2.ONE * 2.2, _duration * 0.5)
	tween.tween_property(ring_1, "modulate:a", 0.0, _duration * 0.5)
	tween.tween_property(ring_2, "scale", Vector2.ONE * 2.8, _duration * 0.6)
	tween.tween_property(ring_2, "modulate:a", 0.0, _duration * 0.6).set_delay(_duration * 0.1)
	tween.tween_property(spark_1, "scale", Vector2.ONE * 0.4, _duration * 0.4)
	tween.tween_property(spark_1, "modulate:a", 0.0, _duration * 0.5).set_delay(_duration * 0.2)
	tween.tween_property(spark_2, "scale", Vector2.ONE * 0.4, _duration * 0.4)
	tween.tween_property(spark_2, "modulate:a", 0.0, _duration * 0.5).set_delay(_duration * 0.25)
	tween.tween_property(spark_3, "scale", Vector2.ONE * 0.4, _duration * 0.4)
	tween.tween_property(spark_3, "modulate:a", 0.0, _duration * 0.5).set_delay(_duration * 0.3)
	tween.tween_property(spark_4, "scale", Vector2.ONE * 0.4, _duration * 0.4)
	tween.tween_property(spark_4, "modulate:a", 0.0, _duration * 0.5).set_delay(_duration * 0.35)
	await tween.finished
	queue_free()