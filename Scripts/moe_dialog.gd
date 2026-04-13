extends CanvasLayer

@onready var dim: ColorRect = $Dim
@onready var sheet: Panel = $Sheet
@onready var title_label: Label = $Sheet/Margin/VBox/TitleLabel
@onready var scroll: ScrollContainer = $Sheet/Margin/VBox/Scroll
@onready var body_label: Label = $Sheet/Margin/VBox/Scroll/BodyLabel
@onready var ok_btn: Button = $Sheet/Margin/VBox/OkBtn


func _ready() -> void:
	layer = 120
	_style_sheet()
	ok_btn.pressed.connect(_close_self)
	dim.gui_input.connect(_on_dim_input)
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP


func _style_sheet() -> void:
	var card := StyleBoxFlat.new()
	card.bg_color = Color8(255, 230, 230)
	card.border_color = Color8(255, 180, 200)
	card.set_border_width_all(2)
	card.corner_radius_top_left = 28
	card.corner_radius_top_right = 28
	sheet.add_theme_stylebox_override("panel", card)
	title_label.add_theme_color_override("font_color", Color8(255, 102, 153))
	var ob := StyleBoxFlat.new()
	ob.bg_color = Color8(255, 102, 153)
	ob.corner_radius_top_left = 24
	ob.corner_radius_top_right = 24
	ob.corner_radius_bottom_left = 24
	ob.corner_radius_bottom_right = 24
	ob.content_margin_top = 14
	ob.content_margin_bottom = 14
	ok_btn.add_theme_stylebox_override("normal", ob)
	ok_btn.add_theme_color_override("font_color", Color.WHITE)
	ok_btn.add_theme_font_size_override("font_size", 20)


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
	queue_free()
