extends Area2D

## 覆盖一片地图区域；玩家 CharacterBody2D 进入时触发顶部区域提示。

@export var region_title: String = "未命名区域"
@export var region_subtitle: String = ""
@export var allow_monster_spawn: bool = false
@export var ground_texture: Texture2D
@export var ground_tint: Color = Color(1, 1, 1, 0.98)
@export var ground_units_per_full_texture: float = 128.0
@export var ground_fade_width_ratio: float = 0.16

const _ZONE_GROUND_SHADER: Shader = preload("res://Shaders/zone_ground_blend.gdshader")

var _ground_sprite: Sprite2D
var _ground_mat: ShaderMaterial
var _ground_blend := {
	"left": false,
	"right": false,
	"top": false,
	"bottom": false,
}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_ensure_ground_layer()
	_apply_ground_params()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	for n in get_tree().get_nodes_in_group("world_region_toast"):
		if n is Node and (n as Node).is_inside_tree() and n.has_method("show_region"):
			n.show_region(region_title, region_subtitle)
			break


func configure_zone_ground_blend(flags: Dictionary) -> void:
	_ground_blend["left"] = bool(flags.get("left", false))
	_ground_blend["right"] = bool(flags.get("right", false))
	_ground_blend["top"] = bool(flags.get("top", false))
	_ground_blend["bottom"] = bool(flags.get("bottom", false))
	_apply_ground_params()


func _ensure_ground_layer() -> void:
	if is_instance_valid(_ground_sprite):
		return
	_ground_sprite = Sprite2D.new()
	_ground_sprite.name = "GroundLayer"
	_ground_sprite.z_as_relative = false
	_ground_sprite.z_index = -3600
	_ground_sprite.centered = true
	_ground_sprite.texture = _white_1x1()
	_ground_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_ground_sprite)
	if _ground_sprite.get_index() != 0:
		move_child(_ground_sprite, 0)
	_ground_mat = ShaderMaterial.new()
	_ground_mat.shader = _ZONE_GROUND_SHADER
	_ground_sprite.material = _ground_mat


func _apply_ground_params() -> void:
	if not is_instance_valid(_ground_sprite) or not is_instance_valid(_ground_mat):
		return
	if ground_texture == null:
		_ground_sprite.visible = false
		return
	var sz: Vector2 = _zone_size_from_collision()
	_ground_sprite.visible = true
	_ground_sprite.position = Vector2.ZERO
	_ground_sprite.scale = sz
	var rep_x: float = maxf(1.0, sz.x / maxf(1.0, ground_units_per_full_texture))
	var rep_y: float = maxf(1.0, sz.y / maxf(1.0, ground_units_per_full_texture))
	_ground_mat.set_shader_parameter("albedo", ground_texture)
	_ground_mat.set_shader_parameter("tint", ground_tint)
	_ground_mat.set_shader_parameter("tile_repeat", rep_x)
	_ground_mat.set_shader_parameter("y_repeat_scale", rep_y / rep_x)
	_ground_mat.set_shader_parameter("fade_width", clampf(ground_fade_width_ratio, 0.03, 0.45))
	_ground_mat.set_shader_parameter("fade_left", 1.0 if bool(_ground_blend["left"]) else 0.0)
	_ground_mat.set_shader_parameter("fade_right", 1.0 if bool(_ground_blend["right"]) else 0.0)
	_ground_mat.set_shader_parameter("fade_top", 1.0 if bool(_ground_blend["top"]) else 0.0)
	_ground_mat.set_shader_parameter("fade_bottom", 1.0 if bool(_ground_blend["bottom"]) else 0.0)


func _zone_size_from_collision() -> Vector2:
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape is RectangleShape2D:
		return (cs.shape as RectangleShape2D).size
	return Vector2(320.0, 220.0)


static func _white_1x1() -> ImageTexture:
	var im: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	im.set_pixel(0, 0, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(im)
