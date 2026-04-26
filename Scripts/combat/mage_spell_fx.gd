extends Node2D

## 法师 AOE：仅一套序列动画 **`mage_aoe`**（在 `SpellAnim` → SpriteFrames 里改帧即可）。
## 与大世界 `_spawn_mage_aoe_fx` 里 Polygon2D 同挂 **CombatFX**。

const ANIM_MAGE_AOE := &"mage_aoe"

@onready var _spell_anim: AnimatedSprite2D = $SpellAnim

@export var reference_aoe_radius: float = 92.0
@export var visual_scale_mul: float = 1.12


func play_aoe(world_center: Vector2, aoe_radius: float) -> void:
	global_position = world_center
	z_index = 7
	z_as_relative = false
	if _spell_anim == null or _spell_anim.sprite_frames == null:
		queue_free()
		return
	if not _spell_anim.sprite_frames.has_animation(ANIM_MAGE_AOE):
		push_warning("MageSpellFX: SpriteFrames 需包含动画「mage_aoe」。")
		queue_free()
		return
	var k: float = (aoe_radius / maxf(1.0, reference_aoe_radius)) * visual_scale_mul
	k = clampf(k, 0.22, 6.0)
	_spell_anim.scale = Vector2.ONE * k
	_spell_anim.centered = true
	_spell_anim.offset = Vector2.ZERO
	_spell_anim.animation = ANIM_MAGE_AOE
	_spell_anim.frame = 0
	_spell_anim.frame_progress = 0.0
	_spell_anim.play()
	await get_tree().process_frame
	while is_instance_valid(_spell_anim) and _spell_anim.is_playing():
		await get_tree().process_frame
	if is_instance_valid(self):
		queue_free()
