extends Area2D

## 单机大世界：本地玩家进入传送门碰撞范围时，由 WorldScene 显示「按 E / 点对话确认」；确认后才进试炼。
## 子节点 Sprite2D 使用传送门贴图便于辨认。联机云端不触发。
## 静态时间戳：两次确认进试炼的最短间隔（毫秒），跨场景仍生效。

const TRIAL_SCENE := "res://Scenes/SurvivorArena.tscn"
const _REENTER_COOLDOWN_MS := 3200

static var _last_trial_enter_tick_ms: int = -10_000_000

var _body_inside: CharacterBody2D = null


static func can_enter_trial() -> bool:
	return Time.get_ticks_msec() - _last_trial_enter_tick_ms >= _REENTER_COOLDOWN_MS


static func commit_trial_enter() -> void:
	_last_trial_enter_tick_ms = Time.get_ticks_msec()


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _world_scene() -> Node:
	return get_tree().get_first_node_in_group("world_scene")


func _on_body_entered(body: Node) -> void:
	if WorldNetwork.is_cloud():
		return
	if not body is CharacterBody2D:
		return
	if not body.is_in_group("player"):
		return
	if not (body as CharacterBody2D).is_local_controllable():
		return
	_body_inside = body as CharacterBody2D
	var w := _world_scene()
	if w != null and w.has_method("set_survivor_portal_prompt"):
		w.set_survivor_portal_prompt(true, self)


func _on_body_exited(body: Node) -> void:
	if body != _body_inside:
		return
	_body_inside = null
	var w := _world_scene()
	if w != null and w.has_method("set_survivor_portal_prompt"):
		w.set_survivor_portal_prompt(false, null)
