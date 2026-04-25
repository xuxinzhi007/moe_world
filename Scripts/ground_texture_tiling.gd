extends TextureRect
## 整张「泥地」贴图在世界里重复的次数（越大=单格贴图在屏幕上越小）
@export var tile_repeat: float = 32.0
@export var back_color: Color = Color(0.42, 0.32, 0.24, 1.0)

const _GSH := preload("res://Shaders/ground_tiling.gdshader")


func _ready() -> void:
	_apply_tiling()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_tiling()


func _apply_tiling() -> void:
	if texture == null or _GSH == null:
		return
	var mat: ShaderMaterial = material as ShaderMaterial
	if mat == null or mat.shader != _GSH:
		mat = ShaderMaterial.new()
		mat.shader = _GSH
		material = mat
	mat.set_shader_parameter("albedo", texture)
	mat.set_shader_parameter("tile_repeat", maxf(1.0, tile_repeat))
	mat.set_shader_parameter("back_color", back_color)
	# 非正方形时保持地面「格」在世界里近似方格
	var sz: Vector2 = size
	if sz.x < 0.1 or sz.y < 0.1:
		sz = Vector2(
			offset_right - offset_left,
			offset_bottom - offset_top
		)
	if sz.y > 0.1:
		mat.set_shader_parameter("y_repeat_scale", sz.x / sz.y)
	# 由 shader 在 UV 里平铺，这里只拉满控件矩形
	stretch_mode = STRETCH_SCALE
	texture_filter = TEXTURE_FILTER_NEAREST
	# 子像素对齐，减轻大矩形片元插值在竖直缝上的伪影
	offset_left = roundf(offset_left)
	offset_top = roundf(offset_top)
	offset_right = roundf(offset_right)
	offset_bottom = roundf(offset_bottom)
