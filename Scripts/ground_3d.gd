extends StaticBody3D

@export var mud_texture: Texture2D
@export var half_extent: float = 2100.0
@export var world_uv_scale: float = 0.06
@export var micro_variation: float = 0.1
@export var use_mud_shader: bool = true

const _MUD_SH := preload("res://Shaders/ground_3d_mud.gdshader")
const _FALLBACK_TEX_PATH := "res://Assets/characters/泥土地面.png"


func _ready() -> void:
	if mud_texture == null and ResourceLoader.exists(_FALLBACK_TEX_PATH):
		var t: Resource = ResourceLoader.load(_FALLBACK_TEX_PATH)
		if t is Texture2D:
			mud_texture = t as Texture2D
	var w: float = half_extent * 2.0
	var pm: PlaneMesh = PlaneMesh.new()
	pm.orientation = PlaneMesh.FACE_Y
	pm.size = Vector2(w, w)
	var mi := MeshInstance3D.new()
	mi.name = "GroundMesh"
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mi.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	mi.mesh = pm
	## 顶面 y≈0，与玩家脚底对齐，减少「陷入地面」的观感；碰撞顶面保持 y=0
	if mud_texture != null and use_mud_shader and _MUD_SH != null:
		var shmat: ShaderMaterial = ShaderMaterial.new()
		shmat.shader = _MUD_SH
		shmat.set_shader_parameter("albedo_texture", mud_texture)
		shmat.set_shader_parameter("uv_scale", world_uv_scale)
		shmat.set_shader_parameter("micro_variation", micro_variation)
		shmat.set_shader_parameter("albedo_tint", Color(0.95, 0.9, 0.86))
		shmat.set_shader_parameter("roughness", 0.92)
		mi.material_override = shmat
	elif mud_texture != null:
		## 着色器未启用或加载失败时：用标准材质 + 平铺，避免整片发灰像「无贴图」
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.roughness = 0.92
		mat.albedo_texture = mud_texture
		mat.uv1_scale = Vector3(96, 96, 1.0)
		mat.albedo_color = Color(0.9, 0.85, 0.78, 1.0)
		mi.material_override = mat
	else:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.roughness = 0.92
		mat.albedo_color = Color(0.45, 0.32, 0.24)
		mi.material_override = mat
	mi.position = Vector3(0, 0, 0)
	add_child(mi)

	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(w, 0.5, w)
	cs.shape = box
	cs.position = Vector3(0, -0.25, 0)
	add_child(cs)
