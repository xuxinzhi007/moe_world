extends Area2D

signal gate_entered(exit_dir: String, body: Node2D)

@export_enum("left", "right", "top", "bottom") var exit_dir: String = "right"
@export var retrigger_cooldown_sec: float = 0.24

var _last_trigger_msec: int = -1000000


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	add_to_group("world_map_gate")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body) or not body.is_in_group("player"):
		return
	var now_ms: int = Time.get_ticks_msec()
	var cooldown_ms: int = int(maxf(0.01, retrigger_cooldown_sec) * 1000.0)
	if now_ms - _last_trigger_msec < cooldown_ms:
		return
	_last_trigger_msec = now_ms
	gate_entered.emit(exit_dir, body)
