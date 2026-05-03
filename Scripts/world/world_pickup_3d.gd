extends Area3D

signal picked(item_id: String, display_name: String, amount: int)

@export var item_id: String = "coin"
@export var display_name: String = "金币"
@export var amount: int = 1
@export var ttl_sec: float = 16.0

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _label: Label3D = $Label3D

var _life: float = 0.0
var _collected: bool = false


func _ready() -> void:
	_life = ttl_sec
	body_entered.connect(_on_body_entered)
	_refresh_visual()


func configure_pickup(new_item_id: String, new_display_name: String, new_amount: int) -> void:
	item_id = new_item_id.strip_edges()
	display_name = new_display_name.strip_edges()
	amount = maxi(1, new_amount)
	_refresh_visual()


func _process(delta: float) -> void:
	_life = maxf(0.0, _life - delta)
	rotate_y(1.8 * delta)
	position.y = 0.5 + sin(Time.get_unix_time_from_system() * 4.0) * 0.04
	if _life <= 0.0 and not _collected:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body == null or not body.is_in_group("player"):
		return
	_collected = true
	picked.emit(item_id, display_name, amount)
	queue_free()


func _refresh_visual() -> void:
	if is_instance_valid(_label):
		_label.text = "%s x%d" % [display_name, amount]
	if not is_instance_valid(_mesh):
		return
	var mat := StandardMaterial3D.new()
	if item_id == "coin":
		mat.albedo_color = Color(1.0, 0.85, 0.25, 1.0)
	elif item_id == "trial_core":
		mat.albedo_color = Color(0.45, 0.95, 1.0, 1.0)
	else:
		mat.albedo_color = Color(0.85, 0.85, 0.85, 1.0)
	mat.roughness = 0.3
	mat.metallic = 0.2
	_mesh.material_override = mat
