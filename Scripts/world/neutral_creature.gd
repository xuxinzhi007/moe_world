extends Node2D

signal died(creature_id: String, at_global: Vector2)

@export var creature_id: String = "forest_sheep"
@export var creature_name: String = "林地绵羊"
@export var creature_level: int = 2
@export var max_hp: int = 24
@export var move_speed: float = 34.0
@export var visual_texture: Texture2D

@onready var sprite: Sprite2D = $BodySprite

var _hp: int = 0
var _home: Vector2 = Vector2.ZERO
var _wander_target: Vector2 = Vector2.ZERO
var _wander_cd: float = 0.0
var _dying: bool = false
var _name_label: Label = null


func _ready() -> void:
	add_to_group("neutral_creature")
	z_as_relative = false
	_hp = maxi(1, max_hp)
	_home = global_position
	_wander_target = global_position
	if is_instance_valid(sprite) and visual_texture != null:
		sprite.texture = visual_texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ensure_name_label()
	_refresh_name_label()


func _process(delta: float) -> void:
	if _dying:
		return
	z_index = int(floor(global_position.y))
	_wander_cd = maxf(0.0, _wander_cd - delta)
	if _wander_cd <= 0.0:
		_wander_cd = randf_range(0.9, 1.8)
		_wander_target = _home + Vector2(randf_range(-90.0, 90.0), randf_range(-64.0, 64.0))
	var to_v: Vector2 = _wander_target - global_position
	if to_v.length_squared() > 9.0:
		global_position += to_v.normalized() * move_speed * delta
	_refresh_name_label()


func take_damage(amount: int) -> void:
	if _dying:
		return
	amount = maxi(1, amount)
	_hp = maxi(0, _hp - amount)
	modulate = Color(1.28, 1.0, 1.0, 1.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)
	_refresh_name_label()
	if _hp <= 0:
		_start_death()


func is_ecology_target() -> bool:
	return not _dying


func _start_death() -> void:
	_dying = true
	var at: Vector2 = global_position
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.15, 0.26), 0.22)
	tw.tween_property(self, "modulate:a", 0.0, 0.24)
	await tw.finished
	died.emit(creature_id, at)
	queue_free()


func _ensure_name_label() -> void:
	if is_instance_valid(_name_label):
		return
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.custom_minimum_size = Vector2(140.0, 18.0)
	_name_label.position = Vector2(-70.0, -66.0)
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color8(210, 255, 220))
	_name_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.06, 1.0))
	_name_label.add_theme_constant_override("outline_size", 2)
	_name_label.z_as_relative = true
	_name_label.z_index = 8
	add_child(_name_label)


func _refresh_name_label() -> void:
	if not is_instance_valid(_name_label):
		return
	_name_label.text = "Lv.%d %s  HP %d/%d" % [maxi(1, creature_level), creature_name, maxi(0, _hp), maxi(1, max_hp)]
