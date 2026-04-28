extends Node

## 受击白闪组件 — 挂到 Monster.tscn 或 Player.tscn 上
## 调用 flash() 触发一次白闪效果

## 挂载此脚本的节点的兄弟或父节点中，应存在一个 CanvasItem（Sprite2D / AnimatedSprite2D）
## 若未指定 target_node，则自动寻找父节点中第一个 CanvasItem
@export var flash_duration: float = 0.09
@export var flash_brightness: float = 2.8

var _target: CanvasItem = null
var _original_modulate: Color = Color.WHITE
var _is_flashing: bool = false


func _ready() -> void:
	_target = _find_canvas_item()


func _find_canvas_item() -> CanvasItem:
	var p: Node = get_parent()
	if p is CanvasItem:
		return p as CanvasItem
	for child in p.get_children():
		if child is CanvasItem and child != self:
			return child as CanvasItem
	return null


func flash() -> void:
	if _is_flashing:
		return
	if not is_instance_valid(_target):
		_target = _find_canvas_item()
	if not is_instance_valid(_target):
		return
	_is_flashing = true
	_original_modulate = _target.modulate
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_target, "modulate", Color(flash_brightness, flash_brightness, flash_brightness, 1.0), flash_duration * 0.25)
	tw.tween_property(_target, "modulate", _original_modulate, flash_duration * 0.75)
	tw.finished.connect(func() -> void: _is_flashing = false, CONNECT_ONE_SHOT)
