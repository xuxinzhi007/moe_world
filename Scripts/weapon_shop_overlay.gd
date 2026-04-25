extends Control

const UiTheme := preload("res://Scripts/ui_theme.gd")
const WEAPON_DIR := "res://Assets/characters"
const WEAPON_NAME_HINTS := ["剑", "刀", "斧", "弓", "杖", "枪", "矛", "锤"]
const EXCLUDE_NAME_HINTS := ["地面", "水塘", "草", "花", "树", "房屋", "角色", "素材", "攻击", "序列", "npc", "QQ", "猛鬼", "扣完"]

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
	PlayerInventory.inventory_changed.connect(_on_inventory_changed)
	CharacterBuild.build_changed.connect(_on_build_changed)


func open_panel() -> void:
	_scan_weapons()
	_refresh_grid()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	dim.mouse_filter = Control.MOUSE_FILTER_STOP


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


func _on_inventory_changed() -> void:
	if visible:
		_refresh_grid()


func _on_build_changed() -> void:
	if visible:
		_refresh_grid()


func _scan_weapons() -> void:
	_weapon_defs.clear()
	var dir: DirAccess = DirAccess.open(WEAPON_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var fn: String = dir.get_next()
		if fn.is_empty():
			break
		if dir.current_is_dir():
			continue
		var lower: String = fn.to_lower()
		if not lower.ends_with(".png"):
			continue
		var base: String = fn.get_basename()
		if not _looks_like_weapon(base):
			continue
		var tex: Texture2D = load("%s/%s" % [WEAPON_DIR, fn]) as Texture2D
		if tex == null:
			continue
		var cls: int = _class_for_weapon_name(base)
		_weapon_defs.append({
			"id": "weapon:" + base,
			"name": base,
			"path": "%s/%s" % [WEAPON_DIR, fn],
			"texture": tex,
			"class": cls
		})
	dir.list_dir_end()
	_weapon_defs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", ""))
	)


func _looks_like_weapon(base_name: String) -> bool:
	var n: String = base_name.strip_edges()
	if n.is_empty():
		return false
	for ex in EXCLUDE_NAME_HINTS:
		if n.contains(ex):
			return false
	for k in WEAPON_NAME_HINTS:
		if n.contains(k):
			return true
	return false


func _class_for_weapon_name(n: String) -> int:
	if n.contains("弓"):
		return CharacterBuild.CLASS_ARCHER
	if n.contains("杖"):
		return CharacterBuild.CLASS_MAGE
	return CharacterBuild.CLASS_WARRIOR


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
	for s in PlayerInventory.get_stacks():
		if str((s as Dictionary).get("id", "")) == item_id:
			return int((s as Dictionary).get("count", 0)) > 0
	return false


func _clear_grid() -> void:
	for c in grid.get_children():
		(c as Node).queue_free()


func _refresh_grid() -> void:
	_clear_grid()
	title_label.text = "武器商店（限购1把）"
	if _weapon_defs.is_empty():
		var lb := Label.new()
		lb.text = "武器目录为空，请把武器 PNG 放到 Assets/characters。"
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
	name_lb.add_theme_color_override("font_color", Color8(62, 40, 58))
	vb.add_child(name_lb)

	var cls: int = int(d.get("class", CharacterBuild.CLASS_WARRIOR))
	var type_lb := Label.new()
	type_lb.text = "类型：%s" % _class_label(cls)
	type_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lb.add_theme_font_size_override("font_size", 13)
	type_lb.add_theme_color_override("font_color", Color8(106, 78, 92))
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
		PlayerInventory.add_item(item_id, str(d.get("name", "武器")), 1)
		GameAudio.ui_confirm()
	else:
		GameAudio.ui_click()
	var cls: int = int(d.get("class", CharacterBuild.CLASS_WARRIOR))
	CharacterBuild.equip_weapon(item_id, cls)
	_refresh_grid()
