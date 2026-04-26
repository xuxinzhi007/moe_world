extends Area2D

## 单机大世界：玩家走进传送门碰撞范围即进入生存试炼；子节点 Sprite2D 使用传送门贴图便于辨认。
## 联机云端不触发。

const TRIAL_SCENE := "res://Scenes/SurvivorArena.tscn"

var _transitioning: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _transitioning:
		return
	if WorldNetwork.is_cloud():
		return
	if not body is CharacterBody2D:
		return
	if not body.is_in_group("player"):
		return
	if not body.is_local_controllable():
		return
	_transitioning = true
	monitoring = false
	GameAudio.ui_confirm()
	get_tree().change_scene_to_file(TRIAL_SCENE)
