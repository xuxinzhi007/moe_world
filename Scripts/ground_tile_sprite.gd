extends Node2D
## 用 Node2D+Sprite2D 铺泥地，避免同场景里 TextureRect(Control) 画在所有 Sprite2D 上面导致「只剩路面」
@export var mud_texture: Texture2D
@export var back_color: Color = Color(0.42, 0.32, 0.24, 1.0)
@export var world_units_per_full_texture: float = 131.25
@export var half_world_extent: float = 30000.0

const _GSH: Shader = preload("res://Shaders/ground_uv_tile.gdshader")

var _spr: Sprite2D
var _mat: ShaderMaterial


func _ready() -> void:
	z_index = -1000
	z_as_relative = false
	_spr = Sprite2D.new()
	_spr.name = "GroundSprite"
	_spr.z_as_relative = true
	_spr.z_index = 0
	_spr.centered = true
	_spr.position = Vector2.ZERO
	_spr.texture = _white_1x1()
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spr.scale = Vector2.ONE * (half_world_extent * 2.0)
	_mat = ShaderMaterial.new()
	_mat.shader = _GSH
	_spr.material = _mat
	add_child(_spr)
	_apply_params()


func _apply_params() -> void:
	if _mat == null or mud_texture == null:
		return
	var w: float = half_world_extent * 2.0
	var repeat_n: float = maxf(1.0, w / world_units_per_full_texture)
	_mat.set_shader_parameter("albedo", mud_texture)
	_mat.set_shader_parameter("back_color", back_color)
	_mat.set_shader_parameter("tile_repeat", repeat_n)
	_mat.set_shader_parameter("y_repeat_scale", 1.0)


static func _white_1x1() -> ImageTexture:
	var im: Image = Image.create(1, 1, false, Image.FORMAT_RGB8)
	im.set_pixel(0, 0, Color(1, 1, 1))
	return ImageTexture.create_from_image(im)
