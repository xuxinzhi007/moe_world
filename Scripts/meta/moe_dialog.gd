extends CanvasLayer

const UiTheme := preload("res://Scripts/meta/ui_theme.gd")

@onready var dim: ColorRect = $Dim
@onready var sheet: Panel = $Sheet
@onready var title_label: Label = $Sheet/Margin/VBox/TitleLabel
@onready var scroll: ScrollContainer = $Sheet/Margin/VBox/Scroll
@onready var body_label: Label = $Sheet/Margin/VBox/Scroll/BodyLabel
@onready var ok_btn: Button = $Sheet/Margin/VBox/OkBtn

var _full_body_text: String = ""
var _typewriter_tween: Tween = null


func _ready() -> void:
	layer = 120
	_style_sheet()
	get_tree().root.size_changed.connect(_layout_dialog_sheet)
	_layout_dialog_sheet()
	ok_btn.pressed.connect(_close_self)
	dim.gui_input.connect(_on_dim_input)
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	## 初始时在屏幕下方，present() 调用时触发 slide_up 进场
	sheet.offset_top    = 0.0
	sheet.offset_bottom = 0.0


func _style_sheet() -> void:
	dim.color = Color(0.02, 0.01, 0.06, 0.65)
	sheet.add_theme_stylebox_override("panel", UiTheme.modern_dialog_sheet())
	title_label.add_theme_color_override("font_color", UiTheme.Colors.ACCENT_PINK)
	title_label.add_theme_font_size_override("font_size", 24)
	body_label.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MAIN)
	ok_btn.add_theme_stylebox_override("normal",  UiTheme.modern_primary_button_normal(22))
	ok_btn.add_theme_stylebox_override("hover",   UiTheme.modern_primary_button_hover(22))
	ok_btn.add_theme_stylebox_override("pressed", UiTheme.modern_primary_button_pressed(22))
	ok_btn.add_theme_color_override("font_color", Color.WHITE)
	ok_btn.add_theme_font_size_override("font_size", 20)


func _layout_dialog_sheet() -> void:
	var s: Vector2 = get_viewport().get_visible_rect().size
	var m: float = UiTheme.responsive_pad_x(s.x)
	sheet.offset_left = m
	sheet.offset_right = -m
	sheet.offset_top = -clampf(s.y * 0.38, 220.0, 480.0)
	sheet.offset_bottom = -clampf(m * 0.65, 10.0, 28.0)
	var fs: float = UiTheme.responsive_ui_font_scale(s)
	title_label.add_theme_font_size_override("font_size", int(22 * fs))
	ok_btn.add_theme_font_size_override("font_size", int(18 * fs))
	var body_fs: int = int(16 * fs)
	body_label.add_theme_font_size_override("font_size", body_fs)


func present(title: String, body: String) -> void:
	title_label.text = title
	_full_body_text   = body
	body_label.text   = ""
	call_deferred("_fit_body_width")
	call_deferred("_play_sheet_open")


func _play_sheet_open() -> void:
	## sheet 从屏幕底部滑入
	var s: Vector2 = get_viewport().get_visible_rect().size
	var slide_h: float = sheet.offset_top - sheet.offset_bottom  ## 负值高度
	sheet.offset_top    = s.y
	sheet.offset_bottom = s.y - slide_h
	var tw := sheet.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_layout_dialog_sheet()  ## 重新计算目标偏移
	var target_top: float    = sheet.offset_top
	var target_bottom: float = sheet.offset_bottom
	sheet.offset_top    = s.y
	sheet.offset_bottom = s.y - slide_h
	tw.tween_property(sheet, "offset_top",    target_top,    0.3)
	tw.tween_property(sheet, "offset_bottom", target_bottom, 0.3)
	tw.finished.connect(_start_typewriter, CONNECT_ONE_SHOT)


func _start_typewriter() -> void:
	if _typewriter_tween != null and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	body_label.text = ""
	var chars: int = _full_body_text.length()
	if chars == 0:
		return
	var duration: float = clampf(float(chars) * 0.025, 0.3, 3.5)
	_typewriter_tween = body_label.create_tween()
	for i in range(chars + 1):
		_typewriter_tween.tween_callback(
			func() -> void: body_label.text = _full_body_text.substr(0, i)
		).set_delay(duration / float(chars))


func _fit_body_width() -> void:
	if scroll.size.x > 8:
		body_label.custom_minimum_size.x = scroll.size.x - 8.0


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_self()
	if event is InputEventScreenTouch and event.pressed:
		_close_self()


func _close_self() -> void:
	GameAudio.ui_click()
	queue_free()
