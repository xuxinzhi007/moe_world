extends Node3D

## 3D 斩击：Sprite3D 片 + 面向 Y 周向淡出

const _FALLBACK_SLASH_PATH := "res://Assets/sprites/melee_slash.svg"

@export var slash_texture: Texture2D
@export var duration: float = 0.24
@export var hit_tint: Color = Color(1.0, 0.65, 0.88, 0.85)
@export var miss_tint: Color = Color(0.85, 0.92, 1.0, 0.5)
@export var scale_from: float = 0.2
@export var scale_to: float = 0.7


func _ready() -> void:
	var tex: Texture2D = slash_texture
	if tex == null and ResourceLoader.exists(_FALLBACK_SLASH_PATH):
		var l: Resource = ResourceLoader.load(_FALLBACK_SLASH_PATH)
		if l is Texture2D:
			tex = l as Texture2D
	if tex:
		var sl: Sprite3D = get_node_or_null("Slash") as Sprite3D
		if sl:
			sl.texture = tex


## facing_yaw：面向弧度（Y 轴），与玩家攻击扇区一致
func play_melee(origin: Vector3, facing_yaw: float, did_hit: bool) -> void:
	global_position = origin + Vector3(0, 0.55, 0)
	rotation.y = facing_yaw
	for c in get_children():
		if c is Sprite3D:
			var s: Sprite3D = c as Sprite3D
			s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			s.modulate = hit_tint if did_hit else miss_tint
			s.pixel_size = scale_from
			s.scale = Vector3.ONE
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, duration)
	if get_child(0) is Sprite3D:
		tw.tween_property((get_child(0) as Sprite3D), "pixel_size", scale_to, duration)
	await tw.finished
	if is_instance_valid(self):
		queue_free()
