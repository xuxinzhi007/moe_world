extends Node2D

## 装饰物Z轴排序：根据 Sprite2D 子节点的Y坐标自动调整Z轴，实现正确的前后关系

@export var depth_bias: int = 0
@export var use_sprite_bottom: bool = true
@export_range(0.0, 24.0, 1.0) var bottom_soften_px: float = 6.0

var _last_z: int = -2147483648

func _ready() -> void:
	z_as_relative = false
	_update_z_index()


func _process(_delta: float) -> void:
	_update_z_index()


func _update_z_index() -> void:
	## 优先用第一个可渲染子节点作为深度基准；容器本身可能在原点。
	var ref_y: float = global_position.y
	for child in get_children():
		var node2d := child as Node2D
		if node2d == null:
			continue
		if child is Sprite2D:
			ref_y = _sprite_depth_y(child as Sprite2D)
			break
		if child is AnimatedSprite2D:
			ref_y = _animated_depth_y(child as AnimatedSprite2D)
			break
	var next_z: int = int(floor(ref_y)) + depth_bias
	if next_z == _last_z:
		return
	_last_z = next_z
	z_index = next_z


func _sprite_depth_y(spr: Sprite2D) -> float:
	var y: float = spr.global_position.y + spr.offset.y * spr.global_scale.y
	if not use_sprite_bottom or spr.texture == null:
		return y
	var h: float = float(spr.texture.get_height()) * absf(spr.global_scale.y)
	return y + h * 0.5 - bottom_soften_px


func _animated_depth_y(spr: AnimatedSprite2D) -> float:
	var y: float = spr.global_position.y + spr.offset.y * spr.global_scale.y
	if not use_sprite_bottom:
		return y
	var frames: SpriteFrames = spr.sprite_frames
	if frames == null:
		return y
	var tex: Texture2D = frames.get_frame_texture(spr.animation, spr.frame)
	if tex == null:
		return y
	var h: float = float(tex.get_height()) * absf(spr.global_scale.y)
	return y + h * 0.5 - bottom_soften_px