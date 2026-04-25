extends CanvasLayer

const UiTheme := preload("res://Scripts/ui_theme.gd")

@onready var dim: ColorRect = $Dim
@onready var sheet: Panel = $Sheet
@onready var title_label: Label = $Sheet/Margin/VBox/TitleLabel
@onready var scroll: ScrollContainer = $Sheet/Margin/VBox/Scroll
@onready var body_label: Label = $Sheet/Margin/VBox/Scroll/BodyLabel
@onready var ok_btn: Button = $Sheet/Margin/VBox/OkBtn


func _ready() -> void:
	layer = 120
	_style_sheet()
	get_tree().root.size_changed.connect(_layout_dialog_sheet)
	_layout_dialog_sheet()
	ok_btn.pressed.connect(_close_self)
	dim.gui_input.connect(_on_dim_input)
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP


func _style_sheet() -> void:
	dim.color = Color(0.1, 0.03, 0.07, 0.52)
	sheet.add_theme_stylebox_override("panel", UiTheme.modern_dialog_sheet())
	title_label.add_theme_color_override("font_color", Color8(255, 85, 145))
	title_label.add_theme_font_size_override("font_size", 24)
	ok_btn.add_theme_stylebox_override("normal", UiTheme.modern_primary_button_normal(22))
	ok_btn.add_theme_stylebox_override("hover", UiTheme.modern_primary_button_hover(22))
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
	body_label.text = body
	call_deferred("_fit_body_width")


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
