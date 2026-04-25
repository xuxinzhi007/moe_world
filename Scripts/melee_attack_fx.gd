extends Node2D

## 近战挥击：双层贴图（柔光 + 刀光）+ 缩放旋转淡出。
##
## 自定义：
## 1) 旧方案：换本场景的 Slash Texture（单图）
## 2) 新方案：启用 use_frame_animation + 在 SlashAnim 里配置 SpriteFrames 序列帧

const _FALLBACK_SLASH_PATH := "res://Assets/sprites/melee_slash.svg"

@export var slash_texture: Texture2D
@export var duration: float = 0.24
@export var hit_glow_color: Color = Color(1.0, 0.65, 0.88, 0.52)
@export var hit_core_modulate: Color = Color(1.0, 0.95, 1.0, 1.0)
@export var miss_glow_color: Color = Color(0.85, 0.92, 1.0, 0.28)
@export var miss_core_modulate: Color = Color(0.95, 0.98, 1.0, 0.62)
@export var scale_from: float = 1.2
@export var scale_to: float = 1.9
@export var hit_spin_deg: float = 14.0
@export var use_frame_animation: bool = true
@export var frame_anim_name: StringName = &"slash"
@export var frame_anim_fps: float = 16.0
@export var frame_sprite_scale: float = 2.2

@onready var _glow: Sprite2D = $Glow
@onready var _core: Sprite2D = $Core
@onready var _slash_anim: AnimatedSprite2D = $SlashAnim


func _ready() -> void:
	_apply_slash_texture()
	_setup_mode()


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


func _setup_mode() -> void:
	var can_use_anim: bool = use_frame_animation and _slash_anim != null and _slash_anim.sprite_frames != null
	if can_use_anim and _sprite_frames_has_frames():
		_glow.visible = false
		_core.visible = false
		_slash_anim.visible = true
		_slash_anim.centered = true
		_slash_anim.scale = Vector2.ONE * frame_sprite_scale
		_slash_anim.speed_scale = frame_anim_fps / maxf(1.0, _slash_anim.sprite_frames.get_animation_speed(frame_anim_name))
		## 从第 0 帧开始，避免场景里存成末帧时「预览 / 进游戏一帧就结束」
		if _slash_anim.sprite_frames.has_animation(frame_anim_name):
			_slash_anim.animation = frame_anim_name
			_slash_anim.frame = 0
			_slash_anim.frame_progress = 0.0
	else:
		_glow.visible = true
		_core.visible = true
		if _slash_anim:
			_slash_anim.visible = false
		_glow.scale = Vector2.ONE * 1.18
		_core.scale = Vector2.ONE


func _sprite_frames_has_frames() -> bool:
	if _slash_anim == null or _slash_anim.sprite_frames == null:
		return false
	if not _slash_anim.sprite_frames.has_animation(frame_anim_name):
		return false
	return _slash_anim.sprite_frames.get_frame_count(frame_anim_name) > 0


## 与序列帧时长相匹配，避免 0.24s 就 queue_free 把动画切掉
func _slash_frame_anim_duration() -> float:
	if _slash_anim == null or _slash_anim.sprite_frames == null:
		return duration
	if not _slash_anim.sprite_frames.has_animation(frame_anim_name):
		return duration
	var sf: SpriteFrames = _slash_anim.sprite_frames
	var n: int = sf.get_frame_count(frame_anim_name)
	if n <= 0:
		return duration
	var base_fps: float = sf.get_animation_speed(frame_anim_name) * _slash_anim.speed_scale
	if base_fps < 0.01:
		return duration
	var total: float = 0.0
	if sf.has_method("get_frame_duration"):
		for i in n:
			total += float(sf.get_frame_duration(frame_anim_name, i)) / base_fps
	else:
		total = float(n) / base_fps
	return maxf(duration, total)


func _play_frame_animation() -> void:
	if _slash_anim == null or _slash_anim.sprite_frames == null:
		return
	if not _slash_anim.sprite_frames.has_animation(frame_anim_name):
		return
	_slash_anim.play(frame_anim_name)


## WorldScene 调用：origin 为玩家位置，facing_rad 为面朝角（弧度），did_hit 是否命中。
func play_melee(origin: Vector2, facing_rad: float, did_hit: bool) -> void:
	global_position = origin
	rotation = facing_rad + PI * 0.5
	scale = Vector2.ONE * scale_from
	modulate.a = 1.0
	_setup_mode()
	var use_frames: bool = use_frame_animation and _slash_anim.visible
	var twlen: float = duration
	if use_frames:
		_slash_anim.rotation = 0.0
		_slash_anim.modulate = hit_core_modulate if did_hit else miss_core_modulate
		_play_frame_animation()
		twlen = _slash_frame_anim_duration()
	else:
		_glow.rotation = 0.0
		_core.rotation = 0.0
		if did_hit:
			_glow.modulate = hit_glow_color
			_core.modulate = hit_core_modulate
		else:
			_glow.modulate = miss_glow_color
			_core.modulate = miss_core_modulate
	var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "modulate:a", 0.0, twlen)
	tw.tween_property(self, "scale", Vector2.ONE * scale_to, twlen)
	if did_hit and not use_frames:
		var spin := deg_to_rad(hit_spin_deg)
		tw.tween_property(_core, "rotation", spin, twlen * 0.85).from(deg_to_rad(-6.0))
		tw.tween_property(_glow, "rotation", spin * 0.55, twlen * 0.9).from(0.0)
	## 序列帧：等动效时长结束再销毁（与 tween 同长，不再提前 queue_free）
	await tw.finished
	queue_free()
