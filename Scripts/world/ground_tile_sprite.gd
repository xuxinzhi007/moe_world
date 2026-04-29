extends Node2D
## 用 Node2D+Sprite2D 铺泥地，避免同场景里 TextureRect(Control) 画在所有 Sprite2D 上面导致「只剩路面」
@export var mud_texture: Texture2D
@export var back_color: Color = Color(0.42, 0.32, 0.24, 1.0)
@export var world_units_per_full_texture: float = 131.25
@export var half_world_extent: float = 30000.0
## 默认世界地面范围；WorldScene 会在 _ready 中根据 WORLD_SPAWN_RECT 覆盖。
@export var world_rect: Rect2 = Rect2(-2100.0, -2100.0, 4200.0, 4200.0)

const _GSH: Shader = preload("res://Shaders/ground_uv_tile.gdshader")

var _spr: Sprite2D
var _mat: ShaderMaterial


func _ready() -> void:
	## 地皮必须永远在所有实体之下；否则玩家走到负坐标高处时会被地皮盖住。
	z_index = -100000
	z_as_relative = false
	_spr = Sprite2D.new()
	_spr.name = "GroundSprite"
	_spr.z_as_relative = true
	_spr.z_index = 0
	_spr.centered = true
	_spr.position = world_rect.position + world_rect.size * 0.5
	_spr.texture = _white_1x1()
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if world_rect.size.x > 0.0 and world_rect.size.y > 0.0:
		_spr.scale = world_rect.size
	else:
		_spr.scale = Vector2.ONE * (half_world_extent * 2.0)
	_mat = ShaderMaterial.new()
	_mat.shader = _GSH
	_spr.material = _mat
	add_child(_spr)
	_apply_params()


func _apply_params() -> void:
	if _mat == null or mud_texture == null:
		return
	var w: float = maxf(1.0, _spr.scale.x)
	var h: float = maxf(1.0, _spr.scale.y)
	var repeat_n: float = maxf(1.0, w / world_units_per_full_texture)
	_mat.set_shader_parameter("albedo", mud_texture)
	_mat.set_shader_parameter("back_color", back_color)
	_mat.set_shader_parameter("tile_repeat", repeat_n)
	_mat.set_shader_parameter("y_repeat_scale", h / w)


func configure_world_rect(r: Rect2) -> void:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	world_rect = r
	if is_instance_valid(_spr):
		_spr.position = world_rect.position + world_rect.size * 0.5
		_spr.scale = world_rect.size
	_apply_params()


static func _white_1x1() -> ImageTexture:
	var im: Image = Image.create(1, 1, false, Image.FORMAT_RGB8)
	im.set_pixel(0, 0, Color(1, 1, 1))
	return ImageTexture.create_from_image(im)
