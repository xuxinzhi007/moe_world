extends Area2D

## 地面拾取物：史莱姆凝胶、小经验珠等。

@export var item_id: String = "slime_gel"
@export var display_name: String = "史莱姆凝胶"
@export var amount: int = 1
## material / currency / trial / xp
@export var drop_kind: String = "material"
## 拾取时额外增加世界内经验（与击杀经验独立的小奖励）。
@export var bonus_xp: int = 0

var _magnet_target: Node2D
var _magnet_speed: float = 0.0
static var _missing_node_warn_once: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_kind_visual()
	_sync_label_from_payload()
	if bonus_xp > 0 and item_id.strip_edges().is_empty():
		var lbl: Label = get_node_or_null("Label") as Label
		var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D
		var glow: Polygon2D = get_node_or_null("Glow") as Polygon2D
		if is_instance_valid(lbl):
			lbl.text = "+%d" % bonus_xp
		else:
			_warn_missing_node_once("Label")
		if is_instance_valid(visual):
			visual.color = Color(1.0, 0.88, 0.35, 0.95)
		else:
			_warn_missing_node_once("Visual")
		if is_instance_valid(glow):
			glow.color = Color(1.0, 0.95, 0.55, 0.45)
		else:
			_warn_missing_node_once("Glow")
	_magnet_target = get_tree().get_first_node_in_group("player") as Node2D
	call_deferred("_arm")


func _apply_kind_visual() -> void:
	var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D
	var glow: Polygon2D = get_node_or_null("Glow") as Polygon2D
	if not is_instance_valid(visual):
		_warn_missing_node_once("Visual")
	if not is_instance_valid(glow):
		_warn_missing_node_once("Glow")
	if not is_instance_valid(visual) or not is_instance_valid(glow):
		return
	var kind: String = drop_kind.strip_edges()
	if kind == "currency":
		visual.color = Color(1.0, 0.85, 0.26, 0.95)
		glow.color = Color(1.0, 0.93, 0.55, 0.45)
	elif kind == "trial":
		visual.color = Color(0.70, 0.52, 1.0, 0.95)
		glow.color = Color(0.82, 0.70, 1.0, 0.45)
	else:
		visual.color = Color(0.55, 0.95, 0.62, 0.92)
		glow.color = Color(0.75, 1.0, 0.85, 0.5)


func _sync_label_from_payload() -> void:
	var lbl: Label = get_node_or_null("Label") as Label
	if not is_instance_valid(lbl):
		_warn_missing_node_once("Label")
		return
	var nm: String = display_name.strip_edges()
	if not nm.is_empty():
		lbl.text = nm
		return
	if bonus_xp > 0:
		lbl.text = "+%d" % bonus_xp
		return
	var kind: String = drop_kind.strip_edges()
	if kind == "currency":
		lbl.text = "金币"
	elif kind == "trial":
		lbl.text = "试炼"
	else:
		lbl.text = "材料"


func _warn_missing_node_once(node_name: String) -> void:
	if not OS.is_debug_build():
		return
	var scene_id: String = scene_file_path
	if scene_id.is_empty():
		scene_id = str(get_script())
	var key: String = "%s::%s" % [scene_id, node_name]
	if _missing_node_warn_once.has(key):
		return
	_missing_node_warn_once[key] = true
	push_warning("LootPickup 缺少节点: %s (scene=%s, drop_kind=%s, item_id=%s)" % [
		node_name,
		scene_id,
		drop_kind,
		item_id
	])


func _arm() -> void:
	monitoring = true
	monitorable = true


func _physics_process(delta: float) -> void:
	if _magnet_target == null or not is_instance_valid(_magnet_target):
		_magnet_target = get_tree().get_first_node_in_group("player") as Node2D
	if _magnet_target == null:
		return
	var d: Vector2 = _magnet_target.global_position - global_position
	var dist: float = d.length()
	if dist < 28.0:
		return
	if dist < 120.0:
		_magnet_speed = minf(_magnet_speed + delta * 420.0, 320.0)
		global_position += d.normalized() * _magnet_speed * delta


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if bonus_xp > 0:
		var w: Node = get_tree().get_first_node_in_group("world_xp_sink")
		if w != null and w.has_method("apply_bonus_xp"):
			w.call("apply_bonus_xp", bonus_xp)
	if not item_id.strip_edges().is_empty() and amount > 0:
		var nm: String = display_name.strip_edges()
		if nm.is_empty():
			nm = item_id
		PlayerInventory.add_item(item_id, nm, amount)
		var qm: Node = get_node_or_null("/root/QuestManager")
		if qm != null and qm.has_method("record_item_pickup"):
			qm.call("record_item_pickup", item_id, amount)
	GameAudio.xp_tick()
	queue_free()
