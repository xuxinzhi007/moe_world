extends Control

const UiTheme := preload("res://Scripts/meta/ui_theme.gd")

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $CenterPanel
@onready var avatar: TextureRect = $CenterPanel/Margin/MainVBox/HeaderPanel/HeaderMargin/HeaderHBox/AvatarContainer/AvatarMargin/Avatar
@onready var player_name_label: Label = $CenterPanel/Margin/MainVBox/HeaderPanel/HeaderMargin/HeaderHBox/PlayerInfoVBox/PlayerNameLabel
@onready var class_label: Label = $CenterPanel/Margin/MainVBox/HeaderPanel/HeaderMargin/HeaderHBox/PlayerInfoVBox/ClassBadge/ClassBadgeMargin/ClassLabel
@onready var level_label: Label = $CenterPanel/Margin/MainVBox/HeaderPanel/HeaderMargin/HeaderHBox/PlayerInfoVBox/LevelLabel
@onready var points_value: Label = $CenterPanel/Margin/MainVBox/BottomHBox/PointsContainer/PointsMargin/PointsVBox/PointsValue
@onready var hp_label: Label = $CenterPanel/Margin/MainVBox/ContentHBox/RightVBox/StatsPanel/StatsMargin/StatsVBox/HpRow/HpLabel
@onready var atk_label: Label = $CenterPanel/Margin/MainVBox/ContentHBox/RightVBox/StatsPanel/StatsMargin/StatsVBox/AtkRow/AtkLabel
@onready var speed_label: Label = $CenterPanel/Margin/MainVBox/ContentHBox/RightVBox/StatsPanel/StatsMargin/StatsVBox/SpeedRow/SpeedLabel
@onready var build_detail_label: Label = $CenterPanel/Margin/MainVBox/ContentHBox/RightVBox/StatsPanel/StatsMargin/StatsVBox/BuildDetailLabel
@onready var atk_upgrade_level: Label = $CenterPanel/Margin/MainVBox/BottomHBox/UpgradePanel/UpgradeMargin/UpgradeVBox/AtkUpgradeHBox/AtkUpgradeInfo/AtkUpgradeLevel
@onready var move_upgrade_level: Label = $CenterPanel/Margin/MainVBox/BottomHBox/UpgradePanel/UpgradeMargin/UpgradeVBox/MoveUpgradeHBox/MoveUpgradeInfo/MoveUpgradeLevel
@onready var btn_warrior: Button = $CenterPanel/Margin/MainVBox/ContentHBox/LeftVBox/ClassGrid/BtnWarrior
@onready var btn_archer: Button = $CenterPanel/Margin/MainVBox/ContentHBox/LeftVBox/ClassGrid/BtnArcher
@onready var btn_mage: Button = $CenterPanel/Margin/MainVBox/ContentHBox/LeftVBox/ClassGrid/BtnMage
@onready var btn_priest: Button = $CenterPanel/Margin/MainVBox/ContentHBox/LeftVBox/ClassGrid/BtnPriest
@onready var lock_btn: Button = $CenterPanel/Margin/MainVBox/LockBtn
@onready var surge_btn: Button = $CenterPanel/Margin/MainVBox/ContentHBox/RightVBox/SkillPanel/SkillMargin/SkillVBox/SurgeBtn
@onready var close_btn: Button = $CenterPanel/Margin/MainVBox/CloseBtn
@onready var atk_plus: Button = $CenterPanel/Margin/MainVBox/BottomHBox/UpgradePanel/UpgradeMargin/UpgradeVBox/AtkUpgradeHBox/AtkPlus
@onready var move_plus: Button = $CenterPanel/Margin/MainVBox/BottomHBox/UpgradePanel/UpgradeMargin/UpgradeVBox/MoveUpgradeHBox/MovePlus

var _trial_survivor_mode: bool = false
var _trial_footer: HBoxContainer
var _trial_defer_btn: Button
var _trial_done_hint: Label
var _trial_auto_close_pending: bool = false
var _class_colors: Dictionary
var _base_panel_width: float = 900.0
var _base_panel_height: float = 640.0
var _current_scale: float = 1.0

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_panel_styles()
	dim.gui_input.connect(_on_dim_gui)
	close_btn.pressed.connect(close_panel)
	atk_plus.pressed.connect(_on_atk_plus)
	move_plus.pressed.connect(_on_move_plus)
	surge_btn.pressed.connect(_on_surge)
	lock_btn.pressed.connect(_on_lock_toggle)
	btn_warrior.pressed.connect(_on_pick_class.bind(CharacterBuild.CLASS_WARRIOR))
	btn_archer.pressed.connect(_on_pick_class.bind(CharacterBuild.CLASS_ARCHER))
	btn_mage.pressed.connect(_on_pick_class.bind(CharacterBuild.CLASS_MAGE))
	btn_priest.pressed.connect(_on_pick_class.bind(CharacterBuild.CLASS_PRIEST))
	_setup_class_colors()
	CharacterBuild.build_changed.connect(_refresh)
	_build_survivor_trial_footer()
	_style_class_buttons()
	_refresh()
	get_tree().root.size_changed.connect(_on_screen_size_changed)
	_on_screen_size_changed()

func _setup_panel_styles() -> void:
	panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(24, 0.95))
	
	var header_panel: PanelContainer = $CenterPanel/Margin/MainVBox/HeaderPanel
	if header_panel:
		header_panel.add_theme_stylebox_override("panel", _create_subpanel_style(Color(0.15, 0.1, 0.2, 0.9)))
	
	var points_container: PanelContainer = $CenterPanel/Margin/MainVBox/BottomHBox/PointsContainer
	if points_container:
		points_container.add_theme_stylebox_override("panel", _create_subpanel_style(Color(0.2, 0.15, 0.1, 0.9)))
	
	var avatar_container: PanelContainer = $CenterPanel/Margin/MainVBox/HeaderPanel/HeaderMargin/HeaderHBox/AvatarContainer
	if avatar_container:
		avatar_container.add_theme_stylebox_override("panel", _create_subpanel_style(Color(0.12, 0.08, 0.15, 1), 12))
	
	var class_badge: PanelContainer = $CenterPanel/Margin/MainVBox/HeaderPanel/HeaderMargin/HeaderHBox/PlayerInfoVBox/ClassBadge
	if class_badge:
		class_badge.add_theme_stylebox_override("panel", _create_subpanel_style(Color(0.25, 0.15, 0.35, 1), 8))
	
	var stats_panel: PanelContainer = $CenterPanel/Margin/MainVBox/ContentHBox/RightVBox/StatsPanel
	if stats_panel:
		stats_panel.add_theme_stylebox_override("panel", _create_subpanel_style(Color(0.1, 0.08, 0.15, 0.9)))
	
	var skill_panel: PanelContainer = $CenterPanel/Margin/MainVBox/ContentHBox/RightVBox/SkillPanel
	if skill_panel:
		skill_panel.add_theme_stylebox_override("panel", _create_subpanel_style(Color(0.08, 0.15, 0.2, 0.9)))
	
	var upgrade_panel: PanelContainer = $CenterPanel/Margin/MainVBox/BottomHBox/UpgradePanel
	if upgrade_panel:
		upgrade_panel.add_theme_stylebox_override("panel", _create_subpanel_style(Color(0.12, 0.1, 0.08, 0.9)))

func _create_subpanel_style(color: Color, radius: float = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	return sb

func _setup_class_colors() -> void:
	_class_colors = {
		CharacterBuild.CLASS_WARRIOR: Color(1.0, 0.4, 0.4, 1.0),
		CharacterBuild.CLASS_ARCHER: Color(0.4, 0.8, 0.4, 1.0),
		CharacterBuild.CLASS_MAGE: Color(0.4, 0.6, 1.0, 1.0),
		CharacterBuild.CLASS_PRIEST: Color(0.9, 0.8, 0.4, 1.0),
	}

func _build_survivor_trial_footer() -> void:
	if is_instance_valid(_trial_footer):
		return
	var vbox: VBoxContainer = close_btn.get_parent() as VBoxContainer
	if vbox == null:
		return
	_trial_footer = HBoxContainer.new()
	_trial_footer.name = "SurvivorTrialFooter"
	_trial_footer.visible = false
	_trial_footer.add_theme_constant_override("separation", 10)
	_trial_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_trial_defer_btn = Button.new()
	_trial_defer_btn.text = "稍后再加点（保留未分配）"
	_trial_defer_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trial_defer_btn.pressed.connect(_on_trial_defer_pressed)
	_trial_footer.add_child(_trial_defer_btn)
	_trial_done_hint = Label.new()
	_trial_done_hint.text = "试炼中：点遮罩不会关闭。未分配点数为 0 时将自动关闭。"
	_trial_done_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_trial_done_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_trial_done_hint.add_theme_font_size_override("font_size", 12)
	_trial_done_hint.add_theme_color_override("font_color", Color(0.85, 0.8, 0.9, 1.0))
	_trial_done_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_trial_footer)
	vbox.move_child(_trial_footer, close_btn.get_index())
	vbox.add_child(_trial_done_hint)
	vbox.move_child(_trial_done_hint, _trial_footer.get_index() + 1)
	_trial_done_hint.visible = false

func _style_class_buttons() -> void:
	var all_buttons: Array = [btn_warrior, btn_archer, btn_mage, btn_priest, lock_btn, atk_plus, move_plus, surge_btn, close_btn]
	if is_instance_valid(_trial_defer_btn):
		all_buttons.push_back(_trial_defer_btn)
	
	for b: Button in all_buttons:
		if is_instance_valid(b):
			b.focus_mode = Control.FOCUS_NONE
			b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
			_apply_button_style(b)

func _apply_button_style(button: Button) -> void:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.23, 0.2, 0.3, 1.0)
	sb_normal.corner_radius_top_left = 12
	sb_normal.corner_radius_top_right = 12
	sb_normal.corner_radius_bottom_left = 12
	sb_normal.corner_radius_bottom_right = 12
	
	var sb_pressed := StyleBoxFlat.new()
	sb_pressed.bg_color = Color(0.35, 0.29, 0.47, 1.0)
	sb_pressed.corner_radius_top_left = 12
	sb_pressed.corner_radius_top_right = 12
	sb_pressed.corner_radius_bottom_left = 12
	sb_pressed.corner_radius_bottom_right = 12
	
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.29, 0.25, 0.39, 1.0)
	sb_hover.corner_radius_top_left = 12
	sb_hover.corner_radius_top_right = 12
	sb_hover.corner_radius_bottom_left = 12
	sb_hover.corner_radius_bottom_right = 12
	
	var sb_disabled := StyleBoxFlat.new()
	sb_disabled.bg_color = Color(0.16, 0.14, 0.22, 1.0)
	sb_disabled.corner_radius_top_left = 12
	sb_disabled.corner_radius_top_right = 12
	sb_disabled.corner_radius_bottom_left = 12
	sb_disabled.corner_radius_bottom_right = 12
	
	button.add_theme_stylebox_override("normal", sb_normal)
	button.add_theme_stylebox_override("pressed", sb_pressed)
	button.add_theme_stylebox_override("hover", sb_hover)
	button.add_theme_stylebox_override("disabled", sb_disabled)
	button.add_theme_color_override("font_color", Color(0.94, 0.9, 0.98, 1.0))
	button.add_theme_color_override("font_color_pressed", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_color_hover", Color(0.98, 0.94, 1.0, 1.0))
	button.add_theme_color_override("font_color_disabled", Color(0.47, 0.43, 0.55, 1.0))
	button.add_theme_font_size_override("font_size", 15)

func _on_screen_size_changed() -> void:
	if not is_instance_valid(panel):
		return
		
	var viewport_size: Vector2 = get_viewport_rect().size
	var max_scale_x: float = viewport_size.x / _base_panel_width
	var max_scale_y: float = viewport_size.y / _base_panel_height
	
	var max_scale: float = min(max_scale_x, max_scale_y)
	max_scale = min(max_scale, 1.0)
	max_scale = max(max_scale, 0.6)
	
	_current_scale = max_scale
	
	var panel_width: float = _base_panel_width * _current_scale
	var panel_height: float = _base_panel_height * _current_scale
	
	panel.offset_left = -panel_width / 2
	panel.offset_top = -panel_height / 2
	panel.offset_right = panel_width / 2
	panel.offset_bottom = panel_height / 2
	
	_apply_font_scaling()

func _apply_font_scaling() -> void:
	var scale_factor: float = _current_scale
	
	var labels: Array = [
		player_name_label, class_label, level_label,
		points_value, hp_label, atk_label, speed_label,
		atk_upgrade_level, move_upgrade_level,
		$CenterPanel/Margin/MainVBox/BottomHBox/PointsContainer/PointsMargin/PointsVBox/PointsTitle,
		$CenterPanel/Margin/MainVBox/ContentHBox/LeftVBox/ClassSelectTitle,
		$CenterPanel/Margin/MainVBox/ContentHBox/RightVBox/StatsPanel/StatsMargin/StatsVBox/StatsTitle,
		$CenterPanel/Margin/MainVBox/ContentHBox/RightVBox/SkillPanel/SkillMargin/SkillVBox/SkillTitle,
		$CenterPanel/Margin/MainVBox/BottomHBox/UpgradePanel/UpgradeMargin/UpgradeVBox/UpgradeTitle,
		$CenterPanel/Margin/MainVBox/BottomHBox/UpgradePanel/UpgradeMargin/UpgradeVBox/AtkUpgradeHBox/AtkUpgradeInfo/AtkUpgradeName,
		$CenterPanel/Margin/MainVBox/BottomHBox/UpgradePanel/UpgradeMargin/UpgradeVBox/MoveUpgradeHBox/MoveUpgradeInfo/MoveUpgradeName,
		build_detail_label
	]
	
	var base_sizes: Array = [20, 13, 15, 26, 12, 12, 12, 11, 11, 12, 14, 14, 14, 13, 13, 11]
	
	for i in range(min(labels.size(), base_sizes.size())):
		var label: Label = labels[i]
		if is_instance_valid(label):
			var base_size: int = base_sizes[i]
			var scaled_size: int = int(base_size * scale_factor)
			scaled_size = max(scaled_size, 10)
			label.add_theme_font_size_override("font_size", scaled_size)
	
	var buttons: Array = [btn_warrior, btn_archer, btn_mage, btn_priest, lock_btn, surge_btn, close_btn, atk_plus, move_plus]
	if is_instance_valid(_trial_defer_btn):
		buttons.push_back(_trial_defer_btn)
	
	for b: Button in buttons:
		if is_instance_valid(b):
			var base_size: int = 15
			var scaled_size: int = int(base_size * scale_factor)
			scaled_size = max(scaled_size, 11)
			b.add_theme_font_size_override("font_size", scaled_size)

func open_panel() -> void:
	_trial_survivor_mode = false
	_trial_auto_close_pending = false
	_apply_survivor_trial_ui()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	_play_open_animation()
	_refresh()

func open_panel_survivor_trial() -> void:
	_trial_survivor_mode = true
	_trial_auto_close_pending = false
	_apply_survivor_trial_ui()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	_play_open_animation()
	_refresh()

func _play_open_animation() -> void:
	var original_scale := panel.scale
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate = Color(1, 1, 1, 0)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", original_scale, 0.3)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)

func _apply_survivor_trial_ui() -> void:
	if not is_instance_valid(close_btn):
		return
	close_btn.visible = not _trial_survivor_mode
	if is_instance_valid(_trial_footer):
		_trial_footer.visible = _trial_survivor_mode
	if is_instance_valid(_trial_done_hint):
		_trial_done_hint.visible = _trial_survivor_mode

func close_panel() -> void:
	GameAudio.ui_click()
	_finish_close()

func _finish_close() -> void:
	_trial_survivor_mode = false
	_trial_auto_close_pending = false
	_apply_survivor_trial_ui()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_dim_gui(event: InputEvent) -> void:
	if _trial_survivor_mode:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		close_panel()

func _on_trial_defer_pressed() -> void:
	if not _trial_survivor_mode:
		return
	GameAudio.ui_confirm()
	_finish_close()

func _on_pick_class(c: int) -> void:
	CharacterBuild.set_combat_class(c)
	GameAudio.ui_confirm()
	_play_button_press_animation(_get_class_button(c))
	_refresh()

func _get_class_button(c: int) -> Button:
	match c:
		CharacterBuild.CLASS_WARRIOR:
			return btn_warrior
		CharacterBuild.CLASS_ARCHER:
			return btn_archer
		CharacterBuild.CLASS_MAGE:
			return btn_mage
		CharacterBuild.CLASS_PRIEST:
			return btn_priest
	return null

func _play_button_press_animation(button: Button) -> void:
	if not is_instance_valid(button):
		return
	
	var original_scale = button.scale
	var tween = create_tween()
	tween.tween_property(button, "scale", original_scale * 0.95, 0.08)
	tween.tween_property(button, "scale", original_scale, 0.12).set_ease(Tween.EASE_OUT)

func _on_lock_toggle() -> void:
	CharacterBuild.toggle_ranged_auto_lock()
	GameAudio.ui_click()
	_refresh()

func _refresh() -> void:
	var cls: int = CharacterBuild.get_combat_class()
	var lv: int = CharacterBuild.runtime_combat_level
	
	points_value.text = str(CharacterBuild.unspent_points)
	
	class_label.text = CharacterBuild.class_display_name()
	level_label.text = "Lv. " + str(lv)
	
	hp_label.text = "生命：%d / %d" % [CharacterBuild.get_player_hp(), CharacterBuild.get_max_hp()]
	atk_label.text = "攻击： %d" % CharacterBuild.attack_power_display(lv)
	speed_label.text = "移速： +%d%%" % CharacterBuild.move_speed_percent_display()
	
	atk_upgrade_level.text = "Lv. %d" % CharacterBuild.atk_speed_level
	move_upgrade_level.text = "Lv. %d" % CharacterBuild.move_level
	
	var cd: float = CharacterBuild.surge_cooldown_remaining()
	var sn: String = CharacterBuild.surge_skill_display_name()
	var hint: String = CharacterBuild.surge_skill_effect_hint()
	if cd > 0.01:
		surge_btn.text = "%s 冷却中 %.1fs" % [sn, cd]
	else:
		surge_btn.text = "%s： %s" % [sn, hint]
	surge_btn.disabled = not CharacterBuild.can_activate_surge()
	
	atk_plus.disabled = CharacterBuild.unspent_points <= 0
	move_plus.disabled = CharacterBuild.unspent_points <= 0
	
	lock_btn.visible = cls == CharacterBuild.CLASS_ARCHER or cls == CharacterBuild.CLASS_MAGE
	if cls == CharacterBuild.CLASS_ARCHER or cls == CharacterBuild.CLASS_MAGE:
		if CharacterBuild.ranged_auto_lock:
			lock_btn.text = "远程锁定：最近敌人（开）"
		else:
			lock_btn.text = "远程锁定：朝向移动方向（关）"
	
	var lines: Array[String] = []
	lines.append("当前职业：%s" % CharacterBuild.class_display_name())
	lines.append("武器：%s" % CharacterBuild.weapon_display_name())
	lines.append("攻速训练 +%d%% · 体能训练 +%d%% 移速" % [CharacterBuild.attack_speed_percent_display(), CharacterBuild.move_speed_percent_display()])
	match cls:
		CharacterBuild.CLASS_ARCHER:
			lines.append("箭沿直线飞行、途中碰怪即伤。")
		CharacterBuild.CLASS_MAGE:
			lines.append("范围攻击，命中多个敌人。")
		CharacterBuild.CLASS_PRIEST:
			lines.append("治疗自己。")
		_:
			lines.append("近战攻击，挥剑造成伤害。")
	build_detail_label.text = "\n".join(lines)
	
	_dim_class_highlight(cls)
	_trial_maybe_schedule_auto_close()

func _trial_maybe_schedule_auto_close() -> void:
	if not _trial_survivor_mode or not visible:
		return
	if CharacterBuild.unspent_points > 0:
		return
	if _trial_auto_close_pending:
		return
	_trial_auto_close_pending = true
	var tw := get_tree().create_timer(0.22)
	tw.timeout.connect(_on_trial_auto_close_timer, CONNECT_ONE_SHOT)

func _on_trial_auto_close_timer() -> void:
	_trial_auto_close_pending = false
	if not _trial_survivor_mode or not visible:
		return
	if CharacterBuild.unspent_points > 0:
		return
	GameAudio.ui_confirm()
	_finish_close()

func _dim_class_highlight(cls: int) -> void:
	var buttons: Array = [btn_warrior, btn_archer, btn_mage, btn_priest]
	var classes: Array = [
		CharacterBuild.CLASS_WARRIOR,
		CharacterBuild.CLASS_ARCHER,
		CharacterBuild.CLASS_MAGE,
		CharacterBuild.CLASS_PRIEST,
	]
	
	for i in buttons.size():
		var b: Button = buttons[i]
		if not is_instance_valid(b):
			continue
		var is_on: bool = classes[i] == cls
		var color: Color = _class_colors.get(classes[i], Color(0.8, 0.8, 0.8, 1.0))
		
		if is_on:
			var sb_active := StyleBoxFlat.new()
			sb_active.bg_color = Color(color.r * 0.35, color.g * 0.35, color.b * 0.35, 0.95)
			sb_active.corner_radius_top_left = 12
			sb_active.corner_radius_top_right = 12
			sb_active.corner_radius_bottom_left = 12
			sb_active.corner_radius_bottom_right = 12
			sb_active.border_width_left = 3
			sb_active.border_width_right = 3
			sb_active.border_width_top = 3
			sb_active.border_width_bottom = 3
			sb_active.border_color = color
			b.add_theme_stylebox_override("normal", sb_active)
			b.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		else:
			var sb_normal := StyleBoxFlat.new()
			sb_normal.bg_color = Color(0.2, 0.16, 0.27, 1.0)
			sb_normal.corner_radius_top_left = 12
			sb_normal.corner_radius_top_right = 12
			sb_normal.corner_radius_bottom_left = 12
			sb_normal.corner_radius_bottom_right = 12
			b.add_theme_stylebox_override("normal", sb_normal)
			b.add_theme_color_override("font_color", Color(0.86, 0.82, 0.94, 1.0))

func _on_atk_plus() -> void:
	if CharacterBuild.try_spend_attack_speed():
		GameAudio.ui_confirm()
		_play_button_press_animation(atk_plus)
		_play_upgrade_effect(atk_upgrade_level)
	_refresh()

func _on_move_plus() -> void:
	if CharacterBuild.try_spend_move_speed():
		GameAudio.ui_confirm()
		_play_button_press_animation(move_plus)
		_play_upgrade_effect(move_upgrade_level)
	_refresh()

func _play_upgrade_effect(label: Label) -> void:
	if not is_instance_valid(label):
		return
	
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)

func _on_surge() -> void:
	if CharacterBuild.activate_surge():
		GameAudio.ui_confirm()
		_play_button_press_animation(surge_btn)
	_refresh()
