extends Node2D

## 近战挥击：双层贴图（柔光 + 刀光）+ 缩放旋转淡出。
##
## 自定义：换 WorldScene 的「Melee Attack Fx Scene」，或改本场景的 Slash Texture / 子节点。

const _FALLBACK_SLASH_PATH := "res://Assets/sprites/melee_slash.svg"

@export var slash_texture: Texture2D
@export var duration: float = 0.24
@export var hit_glow_color: Color = Color(1.0, 0.65, 0.88, 0.52)
@export var hit_core_modulate: Color = Color(1.0, 0.95, 1.0, 1.0)
@export var miss_glow_color: Color = Color(0.85, 0.92, 1.0, 0.28)
@export var miss_core_modulate: Color = Color(0.95, 0.98, 1.0, 0.62)
@export var scale_from: float = 0.32
@export var scale_to: float = 1.12
@export var hit_spin_deg: float = 14.0

@onready var _glow: Sprite2D = $Glow
@onready var _core: Sprite2D = $Core


func _ready() -> void:
	_apply_slash_texture()


func _apply_slash_texture() -> void:
	var tex: Texture2D = slash_texture
	if tex == null and ResourceLoader.exists(_FALLBACK_SLASH_PATH):
		var loaded := ResourceLoader.load(_FALLBACK_SLASH_PATH)
		if loaded is Texture2D:
			tex = loaded as Texture2D
	if tex != null:
		_glow.texture = tex
		_core.texture = tex
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_core.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_glow.centered = true
	_core.centered = true


## WorldScene 调用：origin 为玩家位置，facing_rad 为面朝角（弧度），did_hit 是否命中。
func play_melee(origin: Vector2, facing_rad: float, did_hit: bool) -> void:
	global_position = origin
	rotation = facing_rad + PI * 0.5
	scale = Vector2.ONE * scale_from
	modulate.a = 1.0
	_glow.rotation = 0.0
	_core.rotation = 0.0
	if did_hit:
		_glow.modulate = hit_glow_color
		_core.modulate = hit_core_modulate
	else:
		_glow.modulate = miss_glow_color
		_core.modulate = miss_core_modulate
	var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "modulate:a", 0.0, duration)
	tw.tween_property(self, "scale", Vector2.ONE * scale_to, duration)
	if did_hit:
		var spin := deg_to_rad(hit_spin_deg)
		tw.tween_property(_core, "rotation", spin, duration * 0.85).from(deg_to_rad(-6.0))
		tw.tween_property(_glow, "rotation", spin * 0.55, duration * 0.9).from(0.0)
	await tw.finished
	queue_free()
