extends Area2D

## 单机大世界：玩家走进传送门碰撞范围即进入生存试炼；子节点 Sprite2D 使用传送门贴图便于辨认。
## 联机云端不触发。
## 使用静态时间戳防抖：避免切场景延迟期间多次 body_entered、或进出试炼过快形成「反复进本」。

const TRIAL_SCENE := "res://Scenes/SurvivorArena.tscn"
## 两次通过传送门进试炼的最短间隔（毫秒），跨场景实例仍生效。
const _REENTER_COOLDOWN_MS := 3200

static var _last_trial_enter_tick_ms: int = -10_000_000

var _transitioning: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _transitioning:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_trial_enter_tick_ms < _REENTER_COOLDOWN_MS:
		return
	if WorldNetwork.is_cloud():
		return
	if not body is CharacterBody2D:
		return
	if not body.is_in_group("player"):
		return
	if not (body as CharacterBody2D).is_local_controllable():
		return
	_transitioning = true
	_last_trial_enter_tick_ms = now
	monitoring = false
	GameAudio.ui_confirm()
	# 推迟到 idle，避免在物理/区域信号栈内直接换场景导致同帧再次触发。
	get_tree().change_scene_to_file.bind(TRIAL_SCENE).call_deferred()
