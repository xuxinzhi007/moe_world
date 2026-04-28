extends Control

const UiTheme := preload("res://Scripts/meta/ui_theme.gd")
const SHOP_WEAPONS: Array[Dictionary] = [
	{
		"id": "weapon:轻剑",
		"name": "轻剑",
		"path": "res://Assets/characters/轻剑.png",
		"class": CharacterBuild.CLASS_WARRIOR
	},
	{
		"id": "weapon:武器战斧",
		"name": "武器战斧",
		"path": "res://Assets/characters/武器战斧.png",
		"class": CharacterBuild.CLASS_WARRIOR
	},
	{
		"id": "weapon:法杖",
		"name": "法杖",
		"path": "res://Assets/characters/法杖.png",
		"class": CharacterBuild.CLASS_MAGE
	}
]

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $CenterPanel
@onready var title_label: Label = $CenterPanel/Margin/VBox/Title
@onready var grid: GridContainer = $CenterPanel/Margin/VBox/Scroll/Grid
@onready var close_btn: Button = $CenterPanel/Margin/VBox/CloseBtn

var _weapon_defs: Array[Dictionary] = []


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(22, 0.95))
	dim.gui_input.connect(_on_dim_gui)
	close_btn.pressed.connect(close_panel)
	CharacterBuild.build_changed.connect(_on_build_changed)


func open_panel() -> void:
	_load_shop_defs()
	_refresh_grid()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
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


func _on_build_changed() -> void:
	if visible:
		_refresh_grid()


func _load_shop_defs() -> void:
	_weapon_defs.clear()
	for src in SHOP_WEAPONS:
		var d: Dictionary = src.duplicate()
		var p: String = str(d.get("path", ""))
		if p.is_empty():
			continue
		var tex: Texture2D = load(p) as Texture2D
		if tex == null:
			continue
		d["texture"] = tex
		_weapon_defs.append(d)
	_weapon_defs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", ""))
	)


func _class_label(cls: int) -> String:
	match cls:
		CharacterBuild.CLASS_ARCHER:
			return "弓箭"
		CharacterBuild.CLASS_MAGE:
			return "法杖"
		CharacterBuild.CLASS_PRIEST:
			return "治疗"
		_:
			return "近战"


func _is_owned(item_id: String) -> bool:
	return CharacterBuild.has_owned_weapon(item_id)


func _clear_grid() -> void:
	for c in grid.get_children():
		(c as Node).queue_free()


func _refresh_grid() -> void:
	_clear_grid()
	title_label.text = "武器商店（限购1把）"
	if _weapon_defs.is_empty():
		var lb := Label.new()
		lb.text = "商店武器配置为空，请检查 SHOP_WEAPONS。"
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_color_override("font_color", Color8(80, 64, 76))
		grid.add_child(lb)
		return
	for d in _weapon_defs:
		grid.add_child(_make_weapon_card(d))


func _make_weapon_card(d: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 230)
	card.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(14, 0.92))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(0, 120)
	preview.texture = d.get("texture") as Texture2D
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = Control.TEXTURE_FILTER_NEAREST
	vb.add_child(preview)

	var name_lb := Label.new()
	name_lb.text = str(d.get("name", "武器"))
	name_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lb.add_theme_font_size_override("font_size", 16)
	name_lb.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MAIN)
	vb.add_child(name_lb)

	var cls: int = int(d.get("class", CharacterBuild.CLASS_WARRIOR))
	var type_lb := Label.new()
	type_lb.text = "类型：%s" % _class_label(cls)
	type_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lb.add_theme_font_size_override("font_size", 13)
	type_lb.add_theme_color_override("font_color", UiTheme.Colors.ACCENT_CYAN)
	vb.add_child(type_lb)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 38)
	var item_id: String = str(d.get("id", ""))
	var owned: bool = _is_owned(item_id)
	var equipped: bool = CharacterBuild.get_equipped_weapon_id() == item_id
	if owned:
		btn.text = "已装备" if equipped else "装备"
	else:
		btn.text = "购买并装备"
	btn.pressed.connect(func() -> void:
		_on_weapon_pressed(d)
	)
	vb.add_child(btn)
	return card


func _on_weapon_pressed(d: Dictionary) -> void:
	var item_id: String = str(d.get("id", ""))
	var owned: bool = _is_owned(item_id)
	if not owned:
		CharacterBuild.add_owned_weapon(item_id)
		GameAudio.ui_confirm()
	else:
		GameAudio.ui_click()
	var cls: int = int(d.get("class", CharacterBuild.CLASS_WARRIOR))
	CharacterBuild.equip_weapon(item_id, cls)
	_refresh_grid()
