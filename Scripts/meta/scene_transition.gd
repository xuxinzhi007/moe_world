extends Node

## 全局场景切换过渡：渐黑 → change_scene → 渐出
## 用法：
##   切出：SceneTransition.transition_to("res://Scenes/WorldScene.tscn")
##   切入：在目标场景 _ready() 末尾调用 SceneTransition.fade_in()

const FADE_OUT_SEC: float = 0.28
const FADE_IN_SEC: float  = 0.42

var _overlay: ColorRect
var _hint_label: Label
var _canvas: CanvasLayer


func _ready() -> void:
	_build_overlay()
	## 首次启动时已是黑屏，立刻淡入（HallScene 的 _ready 会再调一次也无妨）
	fade_in(FADE_IN_SEC)


func _build_overlay() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	_canvas.name = "SceneTransitionLayer"
	add_child(_canvas)

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.04, 0.02, 0.06, 1.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_overlay)

	_hint_label = Label.new()
	_hint_label.text = "加载中…"
	_hint_label.set_anchors_preset(Control.PRESET_CENTER)
	_hint_label.offset_left   = -120.0
	_hint_label.offset_top    = -24.0
	_hint_label.offset_right  =  120.0
	_hint_label.offset_bottom =  24.0
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 20)
	_hint_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.65))
	_hint_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.5))
	_hint_label.add_theme_constant_override("outline_size", 4)
	_hint_label.visible = false
	_canvas.add_child(_hint_label)


## 渐出到黑 → 切换场景（在目标场景 _ready 末尾调 fade_in）
func transition_to(scene_path: String) -> void:
	if not is_instance_valid(_overlay):
		get_tree().change_scene_to_file(scene_path)
		return
	_hint_label.visible = false
	var tw := _overlay.create_tween().set_ease(Tween.EASE_IN)
	tw.tween_property(_overlay, "color", Color(0.04, 0.02, 0.06, 1.0), FADE_OUT_SEC)
	tw.tween_callback(func() -> void:
		_hint_label.visible = true
		get_tree().change_scene_to_file(scene_path)
	)


## 在目标场景 _ready() 末尾调用，从黑屏渐出到透明
func fade_in(duration: float = FADE_IN_SEC) -> void:
	if not is_instance_valid(_overlay):
		return
	_hint_label.visible = false
	_overlay.color = Color(0.04, 0.02, 0.06, 1.0)
	var tw := _overlay.create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_overlay, "color", Color(0.04, 0.02, 0.06, 0.0), duration)
