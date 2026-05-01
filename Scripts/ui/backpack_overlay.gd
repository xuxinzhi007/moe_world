extends Control

const UiTheme := preload("res://Scripts/meta/ui_theme.gd")

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $CenterPanel
@onready var item_rows: VBoxContainer = $CenterPanel/Margin/VBox/Scroll/ItemRows
@onready var close_btn: Button = $CenterPanel/Margin/VBox/CloseBtn

var _icon_cache: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(22, 0.95))
	dim.gui_input.connect(_on_dim_gui)
	close_btn.pressed.connect(close_panel)
	PlayerInventory.inventory_changed.connect(_on_inv_changed)


func open_panel() -> void:
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	_refresh_list()
	UiTheme.pop_open(panel, 0.22)


func close_panel() -> void:
	GameAudio.ui_click()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_dim_gui(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_panel()
	if event is InputEventScreenTouch and event.pressed:
		close_panel()


func _on_inv_changed() -> void:
	if visible:
		_refresh_list()


func _empty_hint_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.16, 0.11, 0.30, 0.6)
	s.border_color = Color(0.420, 0.247, 0.627, 0.5)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_left = 10
	s.content_margin_top = 10
	s.content_margin_right = 10
	s.content_margin_bottom = 10
	return s


func _cell_row_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.18, 0.12, 0.33, 0.75)
	s.border_color = Color(0.420, 0.247, 0.627, 0.55)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.content_margin_left = 8
	s.content_margin_top = 6
	s.content_margin_right = 8
	s.content_margin_bottom = 6
	return s


func _grid_root_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.07, 0.18, 0.36)
	s.border_color = Color(0.420, 0.247, 0.627, 0.40)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.content_margin_left = 8
	s.content_margin_top = 8
	s.content_margin_right = 8
	s.content_margin_bottom = 8
	return s


func _refresh_list() -> void:
	for c in item_rows.get_children():
		(c as Node).queue_free()
	var stacks: Array = PlayerInventory.get_stacks()
	if stacks.is_empty():
		var empty_panel := PanelContainer.new()
		empty_panel.add_theme_stylebox_override("panel", _empty_hint_style())
		var empty: Label = Label.new()
		empty.text = "（空）拾取史莱姆掉落可收集材料"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color8(95, 75, 88))
		empty.add_theme_font_size_override("font_size", 15)
		empty_panel.add_child(empty)
		item_rows.add_child(empty_panel)
		return
	var grid_shell := PanelContainer.new()
	grid_shell.add_theme_stylebox_override("panel", _grid_root_style())
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid_shell.add_child(grid)
	item_rows.add_child(grid_shell)
	for s in stacks:
		if s is Dictionary:
			grid.add_child(_make_item_row(s as Dictionary))


func _tint_for_item_id(id: String) -> Color:
	var t := id.strip_edges()
	if t == "slime_gel":
		return Color8(80, 190, 120)
	if t == "trial_core":
		return Color8(170, 120, 255)
	if t == "forest_resin":
		return Color8(80, 215, 170)
	if t == "ancient_bone":
		return Color8(220, 210, 190)
	if t == "coin":
		return Color8(245, 206, 92)
	var h: int = int(abs(id.hash() % 360))
	return Color.from_hsv(float(h) / 360.0, 0.5, 0.82, 1.0)


func _get_item_icon(id: String) -> Texture2D:
	if _icon_cache.has(id):
		return _icon_cache[id] as Texture2D
	var mapped: String = ""
	if PlayerInventory.has_method("get_item_icon_path"):
		mapped = str(PlayerInventory.get_item_icon_path(id)).strip_edges()
	if not mapped.is_empty() and ResourceLoader.exists(mapped):
		var mapped_tex: Texture2D = load(mapped) as Texture2D
		if mapped_tex != null:
			_icon_cache[id] = mapped_tex
			return mapped_tex
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var col: Color = _tint_for_item_id(id)
	img.fill(col)
	# 轻微高光滑块感
	for x: int in range(32):
		for y: int in range(3):
			img.set_pixel(x, y, col.lightened(0.12))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_icon_cache[id] = tex
	return tex


func _make_item_row(s: Dictionary) -> Control:
	var id: String = str(s.get("id", ""))
	var nm: String = str(s.get("name", "?"))
	var c: int = int(s.get("count", 0))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _cell_row_style())
	card.custom_minimum_size = Vector2(118, 118)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var frame := CenterContainer.new()
	frame.custom_minimum_size = Vector2(64, 64)
	var icon_rect := TextureRect.new()
	icon_rect.texture = _get_item_icon(id)
	icon_rect.texture_filter = Control.TEXTURE_FILTER_NEAREST
	icon_rect.custom_minimum_size = Vector2(56, 56)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(frame)
	frame.add_child(icon_rect)
	var name_l := Label.new()
	name_l.text = nm if nm.length() <= 8 else "%s…" % nm.substr(0, 8)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MAIN)
	name_l.add_theme_font_size_override("font_size", 14)
	v.add_child(name_l)
	var sub := Label.new()
	var meta: Dictionary = {}
	if PlayerInventory.has_method("get_item_meta"):
		meta = PlayerInventory.get_item_meta(id)
	var kind_text: String = str(meta.get("kind", "item")).to_upper()
	sub.text = kind_text
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MUTED)
	sub.add_theme_font_size_override("font_size", 11)
	v.add_child(sub)
	var count_l := Label.new()
	count_l.text = "× %d" % c
	count_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_l.add_theme_color_override("font_color", UiTheme.Colors.GOLD)
	count_l.add_theme_font_size_override("font_size", 18)
	v.add_child(count_l)
	return card
