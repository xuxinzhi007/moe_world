extends Area2D

## 地面拾取物：史莱姆凝胶、小经验珠等。

@export var item_id: String = "slime_gel"
@export var display_name: String = "史莱姆凝胶"
@export var amount: int = 1
## 拾取时额外增加世界内经验（与击杀经验独立的小奖励）。
@export var bonus_xp: int = 0

var _magnet_target: Node2D
var _magnet_speed: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if bonus_xp > 0 and item_id.strip_edges().is_empty():
		var lbl: Label = $Label
		lbl.text = "+%d" % bonus_xp
		$Visual.color = Color(1.0, 0.88, 0.35, 0.95)
		$Glow.color = Color(1.0, 0.95, 0.55, 0.45)
	_magnet_target = get_tree().get_first_node_in_group("player") as Node2D
	call_deferred("_arm")


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
		_magnet_speed = mini(_magnet_speed + delta * 420.0, 320.0)
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
	GameAudio.xp_tick()
	queue_free()
