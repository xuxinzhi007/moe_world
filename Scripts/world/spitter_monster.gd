extends Node2D

## 远程喷吐怪：保持中距离、定时发射远程攻击，不靠接触伤害。

signal damaged(actual_damage: int, at_global: Vector2)
signal died(reward_xp: int, at_global: Vector2)
signal player_special_attack(attacker_id: int, damage: int, at_global: Vector2, radius: float, kind: String)

@export var max_hp: int = 46
@export var reward_xp: int = 21
@export var move_speed: float = 62.0
@export var aggro_range: float = 420.0
@export var monster_display_name: String = "毒沫喷吐兽"
@export var monster_level: int = 4
@export var attack_damage: int = 8
@export var attack_cooldown: float = 1.75
@export var preferred_distance: float = 210.0
@export var attack_radius: float = 22.0
@export var attack_spread_px: float = 18.0
@export var visual_texture: Texture2D
@export var discover_icon_path: String = "res://Assets/external/kenney_cursor-pixel-pack/Tiles/tile_0033.png"
@export var eye_texture: Texture2D = preload("res://Assets/external/kenney/monster-builder-pack/PNG/Default/eye_psycho_light.png")
@export var mouth_texture: Texture2D = preload("res://Assets/external/kenney/monster-builder-pack/PNG/Default/mouthG.png")
@export var arm_texture: Texture2D = preload("res://Assets/external/kenney/monster-builder-pack/PNG/Default/arm_greenD.png")
@export var leg_texture: Texture2D = preload("res://Assets/external/kenney/monster-builder-pack/PNG/Default/leg_greenC.png")
@export var detail_texture: Texture2D = preload("res://Assets/external/kenney/monster-builder-pack/PNG/Default/detail_green_antenna_large.png")

var hp: int = 0
var _target: Node2D
var _dying: bool = false
var _atk_cd: float = 0.0
var _bob_time: float = 0.0
var _squash: Vector2 = Vector2.ONE
var _base_modulate: Color = Color(0.72, 1.28, 1.08, 1.0)

@onready var root: Node2D = $SpitterRoot
@onready var body_sprite: Sprite2D = $SpitterRoot/BodySprite
@onready var hp_bar: ProgressBar = $HpBar
@onready var eye_sprite: Sprite2D = get_node_or_null("SpitterRoot/EyeSprite") as Sprite2D
@onready var mouth_sprite: Sprite2D = get_node_or_null("SpitterRoot/MouthSprite") as Sprite2D
@onready var detail_sprite: Sprite2D = get_node_or_null("SpitterRoot/DetailSprite") as Sprite2D
@onready var arm_l_pivot: Node2D = get_node_or_null("SpitterRoot/ArmLPivot") as Node2D
@onready var arm_r_pivot: Node2D = get_node_or_null("SpitterRoot/ArmRPivot") as Node2D
@onready var leg_l_pivot: Node2D = get_node_or_null("SpitterRoot/LegLPivot") as Node2D
@onready var leg_r_pivot: Node2D = get_node_or_null("SpitterRoot/LegRPivot") as Node2D
@onready var arm_l_sprite: Sprite2D = get_node_or_null("SpitterRoot/ArmLPivot/ArmLSprite") as Sprite2D
@onready var arm_r_sprite: Sprite2D = get_node_or_null("SpitterRoot/ArmRPivot/ArmRSprite") as Sprite2D
@onready var leg_l_sprite: Sprite2D = get_node_or_null("SpitterRoot/LegLPivot/LegLSprite") as Sprite2D
@onready var leg_r_sprite: Sprite2D = get_node_or_null("SpitterRoot/LegRPivot/LegRSprite") as Sprite2D

var _fill_style: StyleBoxFlat
var _hit_tween: Tween
var _name_label: Label
var _hp_value_label: Label
var _rig_phase: float = 0.0
var _discover_icon: Sprite2D
var _discover_icon_timer: float = 0.0
var _had_aggro: bool = false
var _discover_icon_texture: Texture2D = null
var _hp_reveal_timer: float = 0.0


func _ready() -> void:
	add_to_group("world_monster")
	z_as_relative = false
	hp = maxi(1, max_hp)
	_style_hp_bar()
	hp_bar.max_value = float(max_hp)
	hp_bar.value = float(hp)
	_update_hp_bar_visual()
	if visual_texture != null:
		body_sprite.texture = visual_texture
	body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	root.modulate = _base_modulate
	_rig_phase = randf() * TAU
	_apply_modular_parts()
	_ensure_overhead_info()
	_refresh_overhead_info()
	hp_bar.visible = false
	if is_instance_valid(_hp_value_label):
		_hp_value_label.visible = false
	_ensure_discover_icon()


func set_aggro_target(t: Node2D) -> void:
	_target = t


func can_damage_player_on_contact() -> bool:
	return false


func is_charge_attacking() -> bool:
	return false


func play_attack_anim(_toward_dir: Vector2) -> void:
	if not is_instance_valid(root) or _dying:
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(root, "scale", Vector2(1.18, 0.84), 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "modulate", Color(1.05, 1.62, 1.48, 1.0), 0.08)
	tw.tween_property(root, "scale", Vector2.ONE, 0.16).set_delay(0.08).set_trans(Tween.TRANS_BACK)
	tw.tween_property(root, "modulate", _base_modulate, 0.18).set_delay(0.08)


func take_damage(amount: int) -> void:
	if is_queued_for_deletion() or _dying:
		return
	amount = maxi(1, amount)
	var prev_hp: int = hp
	hp = maxi(0, hp - amount)
	var dealt: int = prev_hp - hp
	if dealt > 0:
		damaged.emit(dealt, global_position)
	_refresh_hp_bar()
	_play_hit_feedback()
	if hp <= 0:
		_start_death()


func _style_hp_bar() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.12, 0.16, 0.9)
	bg.border_color = Color(0.30, 0.55, 0.68, 1.0)
	bg.set_border_width_all(1)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("background", bg)

	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = Color(0.45, 0.96, 0.96, 1.0)
	_fill_style.corner_radius_top_left = 2
	_fill_style.corner_radius_top_right = 2
	_fill_style.corner_radius_bottom_left = 2
	_fill_style.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("fill", _fill_style)


func _update_hp_bar_visual() -> void:
	if _fill_style == null:
		return
	var ratio: float = 0.0
	if max_hp > 0:
		ratio = float(hp) / float(max_hp)
	_fill_style.bg_color = Color(0.45, 0.96, 0.96, 1.0).lerp(Color(0.95, 0.35, 0.38, 1.0), 1.0 - ratio)


func _refresh_hp_bar() -> void:
	hp_bar.max_value = float(maxi(1, max_hp))
	var tw := create_tween()
	tw.tween_property(hp_bar, "value", float(hp), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_update_hp_bar_visual()
	_refresh_overhead_info()


func _ensure_overhead_info() -> void:
	if is_instance_valid(_name_label) and is_instance_valid(_hp_value_label):
		return
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.custom_minimum_size = Vector2(140.0, 18.0)
	_name_label.position = Vector2(-70.0, -88.0)
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color8(190, 255, 236))
	_name_label.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.06, 1.0))
	_name_label.add_theme_constant_override("outline_size", 2)
	_name_label.z_as_relative = true
	_name_label.z_index = 8
	add_child(_name_label)
	_hp_value_label = Label.new()
	_hp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_value_label.custom_minimum_size = Vector2(140.0, 16.0)
	_hp_value_label.position = Vector2(-70.0, -78.0)
	_hp_value_label.add_theme_font_size_override("font_size", 11)
	_hp_value_label.add_theme_color_override("font_color", Color8(242, 255, 246))
	_hp_value_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.02, 1.0))
	_hp_value_label.add_theme_constant_override("outline_size", 2)
	_hp_value_label.z_as_relative = true
	_hp_value_label.z_index = 8
	add_child(_hp_value_label)


func _refresh_overhead_info() -> void:
	if is_instance_valid(_name_label):
		_name_label.text = "Lv.%d %s" % [maxi(1, monster_level), monster_display_name]
	if is_instance_valid(_hp_value_label):
		_hp_value_label.text = "HP %d/%d" % [maxi(0, hp), maxi(1, max_hp)]


func _apply_modular_parts() -> void:
	if is_instance_valid(eye_sprite) and eye_texture != null:
		eye_sprite.texture = eye_texture
		eye_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if is_instance_valid(mouth_sprite) and mouth_texture != null:
		mouth_sprite.texture = mouth_texture
		mouth_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if is_instance_valid(detail_sprite) and detail_texture != null:
		detail_sprite.texture = detail_texture
		detail_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if is_instance_valid(arm_l_sprite) and arm_texture != null:
		arm_l_sprite.texture = arm_texture
		arm_l_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if is_instance_valid(arm_r_sprite) and arm_texture != null:
		arm_r_sprite.texture = arm_texture
		arm_r_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		arm_r_sprite.flip_h = true
	if is_instance_valid(leg_l_sprite) and leg_texture != null:
		leg_l_sprite.texture = leg_texture
		leg_l_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if is_instance_valid(leg_r_sprite) and leg_texture != null:
		leg_r_sprite.texture = leg_texture
		leg_r_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		leg_r_sprite.flip_h = true


func _animate_modular_rig(delta: float, dist: float) -> void:
	var move_amp: float = 0.05
	if dist > preferred_distance + 24.0 or dist < preferred_distance - 24.0:
		move_amp = 0.26
	var t: float = _bob_time * 6.8 + _rig_phase
	var arm_amp: float = move_amp * 1.1
	var leg_amp: float = move_amp
	var shoot_push: float = 0.0
	if _atk_cd > attack_cooldown - 0.18:
		shoot_push = 0.32
	if is_instance_valid(arm_l_pivot):
		arm_l_pivot.rotation = sin(t) * arm_amp + shoot_push
	if is_instance_valid(arm_r_pivot):
		arm_r_pivot.rotation = -sin(t) * arm_amp - shoot_push
	if is_instance_valid(leg_l_pivot):
		leg_l_pivot.rotation = -sin(t) * leg_amp
	if is_instance_valid(leg_r_pivot):
		leg_r_pivot.rotation = sin(t) * leg_amp
	if is_instance_valid(mouth_sprite):
		mouth_sprite.scale = mouth_sprite.scale.lerp(Vector2.ONE * (1.0 + shoot_push * 0.2), 12.0 * delta)


func _play_hit_feedback() -> void:
	if not is_instance_valid(root):
		return
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	_hit_tween = create_tween()
	root.modulate = Color(1.4, 1.6, 1.7, 1.0)
	_hit_tween.tween_property(root, "modulate", _base_modulate, 0.16).set_ease(Tween.EASE_OUT)


func _start_death() -> void:
	_dying = true
	var rx: int = reward_xp
	var die_at: Vector2 = global_position
	var tw := create_tween().set_parallel(true)
	tw.tween_property(root, "scale", Vector2(1.2, 0.2), 0.24).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.28).set_delay(0.02)
	await tw.finished
	died.emit(rx, die_at)
	queue_free()


func _process(delta: float) -> void:
	if _dying:
		return
	z_index = int(floor(global_position.y))
	_bob_time += delta
	_atk_cd = maxf(0.0, _atk_cd - delta)
	_hp_reveal_timer = maxf(0.0, _hp_reveal_timer - delta)
	if _hp_reveal_timer <= 0.0:
		hp_bar.visible = false
		if is_instance_valid(_hp_value_label):
			_hp_value_label.visible = false
	root.position.y = sin(_bob_time * 4.2) * 1.8

	if _target == null or not is_instance_valid(_target):
		_animate_modular_rig(delta, preferred_distance)
		_had_aggro = false
		return
	var to_player: Vector2 = _target.global_position - global_position
	var dist: float = to_player.length()
	if dist <= 0.01:
		_animate_modular_rig(delta, preferred_distance)
		return
	if dist > aggro_range:
		_animate_modular_rig(delta, dist)
		_had_aggro = false
		return
	if not _had_aggro:
		_show_discover_icon()
	_had_aggro = true

	var dir: Vector2 = to_player / dist
	if dist > preferred_distance + 44.0:
		global_position += dir * move_speed * delta
		_squash = _squash.lerp(Vector2(1.10, 0.92), 8.0 * delta)
	elif dist < preferred_distance - 40.0:
		global_position -= dir * move_speed * 0.82 * delta
		_squash = _squash.lerp(Vector2(1.04, 0.96), 8.0 * delta)
	else:
		_squash = _squash.lerp(Vector2.ONE, 6.0 * delta)

	root.scale = _squash
	_animate_modular_rig(delta, dist)

	if _atk_cd <= 0.0 and dist <= preferred_distance + 86.0:
		_atk_cd = attack_cooldown
		play_attack_anim(dir)
		var aim: Vector2 = _target.global_position + Vector2(
			randf_range(-attack_spread_px, attack_spread_px),
			randf_range(-attack_spread_px * 0.55, attack_spread_px * 0.55)
		)
		player_special_attack.emit(get_instance_id(), attack_damage, aim, attack_radius, "spit")
	_discover_icon_timer = maxf(0.0, _discover_icon_timer - delta)
	if is_instance_valid(_discover_icon):
		_discover_icon.visible = _discover_icon_timer > 0.0


func _ensure_discover_icon() -> void:
	if is_instance_valid(_discover_icon):
		return
	if _discover_icon_texture == null:
		_discover_icon_texture = _load_icon_texture(discover_icon_path)
	_discover_icon = Sprite2D.new()
	_discover_icon.texture = _discover_icon_texture
	_discover_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_discover_icon.position = Vector2(0.0, -104.0)
	_discover_icon.scale = Vector2(1.2, 1.2)
	_discover_icon.z_as_relative = true
	_discover_icon.z_index = 9
	_discover_icon.visible = false
	add_child(_discover_icon)


func _show_discover_icon() -> void:
	_discover_icon_timer = 0.9
	if is_instance_valid(_discover_icon):
		_discover_icon.visible = true


func reveal_hp_bar(seconds: float = 2.4) -> void:
	_hp_reveal_timer = maxf(_hp_reveal_timer, seconds)
	hp_bar.visible = true
	if is_instance_valid(_hp_value_label):
		_hp_value_label.visible = true


func _load_icon_texture(path: String) -> Texture2D:
	var fs_path: String = ProjectSettings.globalize_path(path)
	var img := Image.new()
	if img.load(fs_path) != OK:
		return null
	return ImageTexture.create_from_image(img)
