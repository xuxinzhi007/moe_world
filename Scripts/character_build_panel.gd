extends Control

const UiTheme := preload("res://Scripts/ui_theme.gd")

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $CenterPanel
@onready var points_label: Label = $CenterPanel/Margin/VBox/PointsLabel
@onready var btn_warrior: Button = $CenterPanel/Margin/VBox/ClassRow/BtnWarrior
@onready var btn_archer: Button = $CenterPanel/Margin/VBox/ClassRow/BtnArcher
@onready var btn_mage: Button = $CenterPanel/Margin/VBox/ClassRow/BtnMage
@onready var btn_priest: Button = $CenterPanel/Margin/VBox/ClassRow/BtnPriest
@onready var lock_btn: Button = $CenterPanel/Margin/VBox/LockBtn
@onready var stats_label: Label = $CenterPanel/Margin/VBox/StatsLabel
@onready var atk_label: Label = $CenterPanel/Margin/VBox/AtkHBox/AtkLabel
@onready var move_label: Label = $CenterPanel/Margin/VBox/MoveHBox/MoveLabel
@onready var surge_btn: Button = $CenterPanel/Margin/VBox/SurgeBtn
@onready var close_btn: Button = $CenterPanel/Margin/VBox/CloseBtn
@onready var atk_plus: Button = $CenterPanel/Margin/VBox/AtkHBox/AtkPlus
@onready var move_plus: Button = $CenterPanel/Margin/VBox/MoveHBox/MovePlus

var _trial_survivor_mode: bool = false
var _trial_footer: HBoxContainer
var _trial_defer_btn: Button
var _trial_done_hint: Label
var _trial_auto_close_pending: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(24, 0.95))
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
	CharacterBuild.build_changed.connect(_refresh)
	_build_survivor_trial_footer()
	_style_class_buttons()
	_refresh()


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
	_trial_done_hint.add_theme_color_override("font_color", Color8(220, 200, 235))
	_trial_done_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_trial_footer)
	vbox.move_child(_trial_footer, close_btn.get_index())
	vbox.add_child(_trial_done_hint)
	vbox.move_child(_trial_done_hint, _trial_footer.get_index() + 1)
	_trial_done_hint.visible = false


func _style_class_buttons() -> void:
	for b: Button in [btn_warrior, btn_archer, btn_mage, btn_priest, lock_btn, atk_plus, move_plus, surge_btn, close_btn]:
		b.focus_mode = Control.FOCUS_NONE
		b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	if is_instance_valid(_trial_defer_btn):
		_trial_defer_btn.focus_mode = Control.FOCUS_NONE
		_trial_defer_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS


func open_panel() -> void:
	_trial_survivor_mode = false
	_trial_auto_close_pending = false
	_apply_survivor_trial_ui()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	_refresh()


## 生存试炼内升级：点遮罩不会关；可「稍后再加点」保留点数，或点完加成后自动关闭。
func open_panel_survivor_trial() -> void:
	_trial_survivor_mode = true
	_trial_auto_close_pending = false
	_apply_survivor_trial_ui()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	_refresh()


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
	if event is InputEventMouseButton and event.pressed:
		close_panel()
	if event is InputEventScreenTouch and event.pressed:
		close_panel()


func _on_trial_defer_pressed() -> void:
	if not _trial_survivor_mode:
		return
	GameAudio.ui_confirm()
	_finish_close()


func _on_pick_class(c: int) -> void:
	CharacterBuild.set_combat_class(c)
	GameAudio.ui_confirm()
	_refresh()


func _on_lock_toggle() -> void:
	CharacterBuild.toggle_ranged_auto_lock()
	GameAudio.ui_click()
	_refresh()


func _refresh() -> void:
	points_label.text = "未分配点数：%d" % CharacterBuild.unspent_points
	atk_label.text = "攻速训练 Lv.%d（缩短攻击冷却）" % CharacterBuild.atk_speed_level
	move_label.text = "体能训练 Lv.%d（移速与生命上限）" % CharacterBuild.move_level
	var cd: float = CharacterBuild.surge_cooldown_remaining()
	surge_btn.text = "强击：下次伤害/治疗 +38%%" if cd <= 0.01 else "强击冷却中 %.1fs" % cd
	surge_btn.disabled = not CharacterBuild.can_activate_surge()
	atk_plus.disabled = CharacterBuild.unspent_points <= 0
	move_plus.disabled = CharacterBuild.unspent_points <= 0
	var cls: int = CharacterBuild.get_combat_class()
	lock_btn.visible = cls == CharacterBuild.CLASS_ARCHER or cls == CharacterBuild.CLASS_MAGE
	lock_btn.text = "锁定：最近敌人（开）" if CharacterBuild.ranged_auto_lock else "锁定：关 — 朝移动方向释放"
	var lv: int = CharacterBuild.runtime_combat_level
	var lines: Array[String] = []
	lines.append("当前职业：%s" % CharacterBuild.class_display_name())
	lines.append("武器：%s" % CharacterBuild.weapon_display_name())
	lines.append("生命 %d / %d" % [CharacterBuild.get_player_hp(), CharacterBuild.get_max_hp()])
	lines.append("攻击面板 %d（随战斗等级）" % CharacterBuild.attack_power_display(lv))
	lines.append(
		"攻速训练 +%.0f%%  ·  体能 +%.0f%% 移速"
		% [CharacterBuild.attack_speed_percent_display(), CharacterBuild.move_speed_percent_display()]
	)
	match cls:
		CharacterBuild.CLASS_ARCHER:
			lines.append("弓箭射程 %.0f · 开锁定射最近怪，关锁定朝移动方向" % CharacterBuild.bow_range())
		CharacterBuild.CLASS_MAGE:
			lines.append("范围半径 %.0f · 同上锁定规则" % CharacterBuild.mage_aoe_radius())
		CharacterBuild.CLASS_PRIEST:
			lines.append("治疗基础量约 %d（吃战斗等级与强击）" % CharacterBuild.priest_heal_base(lv))
		_:
			lines.append("近战距离约 78 · 强击强化下一次挥砍")
	stats_label.text = "\n".join(lines)
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


func _dim_class_highlight(active: int) -> void:
	var col_on := Color8(255, 235, 250)
	var col_off := Color8(210, 200, 225)
	var buttons: Array = [btn_warrior, btn_archer, btn_mage, btn_priest]
	var classes: Array = [
		CharacterBuild.CLASS_WARRIOR,
		CharacterBuild.CLASS_ARCHER,
		CharacterBuild.CLASS_MAGE,
		CharacterBuild.CLASS_PRIEST,
	]
	for i in buttons.size():
		var b: Button = buttons[i]
		var is_on: bool = classes[i] == active
		b.add_theme_color_override("font_color", col_on if is_on else col_off)


func _on_atk_plus() -> void:
	if CharacterBuild.try_spend_attack_speed():
		GameAudio.ui_confirm()
	_refresh()


func _on_move_plus() -> void:
	if CharacterBuild.try_spend_move_speed():
		GameAudio.ui_confirm()
	_refresh()


func _on_surge() -> void:
	if CharacterBuild.activate_surge():
		GameAudio.ui_confirm()
	_refresh()
