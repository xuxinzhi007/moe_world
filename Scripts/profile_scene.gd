extends Control

const UITheme = preload("res://Scripts/ui_theme.gd")

@onready var back_btn: Button = $MainContainer/HeaderBar/HeaderContent/BackBtn
@onready var avatar_initial: Label = $MainContainer/ProfileCard/ProfileContent/AvatarSection/AvatarContainer/AvatarCircle/AvatarInitial
@onready var vip_badge: Label = $MainContainer/ProfileCard/ProfileContent/AvatarSection/AvatarContainer/VIPBadge
@onready var player_name: Label = $MainContainer/ProfileCard/ProfileContent/AvatarSection/PlayerName
@onready var player_uid: Label = $MainContainer/ProfileCard/ProfileContent/AvatarSection/PlayerUID
@onready var level_value: Label = $MainContainer/ProfileCard/ProfileContent/InfoSection/StatsGrid/LevelCard/LevelContent/LevelValue
@onready var level_progress: ProgressBar = $MainContainer/ProfileCard/ProfileContent/InfoSection/StatsGrid/LevelCard/LevelContent/LevelProgress
@onready var exp_value: Label = $MainContainer/ProfileCard/ProfileContent/InfoSection/StatsGrid/ExpCard/ExpContent/ExpValue
@onready var coins_value: Label = $MainContainer/ProfileCard/ProfileContent/InfoSection/StatsGrid/CoinsCard/CoinsContent/CoinsValue
@onready var signin_value: Label = $MainContainer/ProfileCard/ProfileContent/InfoSection/StatsGrid/SignInCard/SignInContent/SignInValue
@onready var friends_value: Label = $MainContainer/ProfileCard/ProfileContent/InfoSection/StatsGrid/FriendsCard/FriendsContent/FriendsValue
@onready var tab_profile: Button = $MainContainer/ProfileCard/ProfileContent/InfoSection/TabButtons/TabProfile
@onready var tab_achievements: Button = $MainContainer/ProfileCard/ProfileContent/InfoSection/TabButtons/TabAchievements
@onready var tab_collections: Button = $MainContainer/ProfileCard/ProfileContent/InfoSection/TabButtons/TabCollections
@onready var tab_settings: Button = $MainContainer/ProfileCard/ProfileContent/InfoSection/TabButtons/TabSettings
@onready var tab_content_container: VBoxContainer = $MainContainer/ProfileCard/ProfileContent/InfoSection/TabContent/TabContentScroll/TabContentContainer
@onready var edit_profile_btn: Button = $MainContainer/ActionButtons/EditProfileBtn
@onready var security_btn: Button = $MainContainer/ActionButtons/SecurityBtn
@onready var back_hall_btn: Button = $MainContainer/ActionButtons/BackHallBtn
@onready var bg_gradient: ColorRect = $BgGradient

var _current_tab: String = "profile"
var _player_data: Dictionary = {}
var gradient_offset: float = 0.0


func _ready() -> void:
	_apply_theme()
	_load_player_data()
	_setup_buttons()
	_setup_tabs()
	_select_tab("profile")
	
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()
	
	_play_intro_animation()


func _process(delta: float) -> void:
	gradient_offset += delta * 0.05
	if gradient_offset > 1.0:
		gradient_offset = 0.0
	
	var t = gradient_offset
	var col1 = _lerp_color(Color8(255, 243, 196), Color8(255, 230, 240), t)
	var col2 = _lerp_color(Color8(255, 230, 240), Color8(255, 243, 196), t)
	_set_gradient(col1, col2)


func _lerp_color(col1: Color, col2: Color, t: float) -> Color:
	return Color(
		col1.r + (col2.r - col1.r) * t,
		col1.g + (col2.g - col1.g) * t,
		col1.b + (col2.b - col1.b) * t
	)


func _set_gradient(col_top: Color, col_bottom: Color) -> void:
	var shader_material = bg_gradient.material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter("color_top", col_top)
		shader_material.set_shader_parameter("color_bottom", col_bottom)


func _load_player_data() -> void:
	var name_str := "萌酱"
	var uid := "10001"
	var vip_level := 1
	var level := 10
	var exp := 6500
	var coins := 1280
	var signin_days := 7
	var friends := 12
	
	if ProjectSettings.has_setting("moe_world/current_user"):
		var u: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if u is Dictionary and not (u as Dictionary).is_empty():
			name_str = str((u as Dictionary).get("username", "萌酱"))
			uid = str((u as Dictionary).get("id", "10001"))
			vip_level = int((u as Dictionary).get("vip_level", 1))
			level = int((u as Dictionary).get("level", 10))
			exp = int((u as Dictionary).get("exp", 6500))
			coins = int((u as Dictionary).get("coins", 1280))
			signin_days = int((u as Dictionary).get("signin_days", 7))
			friends = int((u as Dictionary).get("friends_count", 12))
	
	_player_data = {
		"username": name_str,
		"uid": uid,
		"vip_level": vip_level,
		"level": level,
		"exp": exp,
		"coins": coins,
		"signin_days": signin_days,
		"friends": friends,
		"email": "moe@example.com",
		"signature": "热爱生活的小萌星~",
		"reg_time": "2026-01-01"
	}
	
	_update_ui()


func _update_ui() -> void:
	player_name.text = _player_data["username"]
	player_uid.text = "UID: %s" % _player_data["uid"]
	avatar_initial.text = _player_data["username"].substr(0, 1) if _player_data["username"].length() > 0 else "萌"
	
	if _player_data["vip_level"] > 0:
		vip_badge.visible = true
		vip_badge.text = "VIP %d" % _player_data["vip_level"]
	else:
		vip_badge.visible = false
	
	level_value.text = "Lv.%d" % _player_data["level"]
	level_progress.value = float(_player_data["exp"] % 100)
	exp_value.text = _format_number(_player_data["exp"])
	coins_value.text = _format_number(_player_data["coins"])
	signin_value.text = "%d天" % _player_data["signin_days"]
	friends_value.text = "%d人" % _player_data["friends"]


func _format_number(num: int) -> String:
	if num >= 10000:
		return "%.1f万" % (num / 10000.0)
	elif num >= 1000:
		return "%.1fk" % (num / 1000.0)
	else:
		return str(num)


func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_clicked)
	edit_profile_btn.pressed.connect(_on_edit_profile)
	security_btn.pressed.connect(_on_security)
	back_hall_btn.pressed.connect(_on_back_hall)
	
	_setup_button_hover_effect(back_btn)
	_setup_button_hover_effect(edit_profile_btn)
	_setup_button_hover_effect(security_btn)
	_setup_button_hover_effect(back_hall_btn)


func _setup_button_hover_effect(btn: Button) -> void:
	if btn:
		btn.mouse_entered.connect(func(): _on_button_hover_enter(btn))
		btn.mouse_exited.connect(func(): _on_button_hover_exit(btn))


func _on_button_hover_enter(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.2)


func _on_button_hover_exit(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2)


func _setup_tabs() -> void:
	tab_profile.pressed.connect(func(): _select_tab("profile"))
	tab_achievements.pressed.connect(func(): _select_tab("achievements"))
	tab_collections.pressed.connect(func(): _select_tab("collections"))
	tab_settings.pressed.connect(func(): _select_tab("settings"))


func _select_tab(tab_name: String) -> void:
	_current_tab = tab_name
	
	_reset_tab_buttons()
	
	match tab_name:
		"profile":
			tab_profile.add_theme_color_override("font_color", Color8(255, 102, 153))
			_show_profile_content()
		"achievements":
			tab_achievements.add_theme_color_override("font_color", Color8(255, 102, 153))
			_show_achievements_content()
		"collections":
			tab_collections.add_theme_color_override("font_color", Color8(255, 102, 153))
			_show_collections_content()
		"settings":
			tab_settings.add_theme_color_override("font_color", Color8(255, 102, 153))
			_show_settings_content()


func _reset_tab_buttons() -> void:
	var default_color = Color8(120, 90, 105)
	tab_profile.remove_theme_color_override("font_color")
	tab_achievements.remove_theme_color_override("font_color")
	tab_collections.remove_theme_color_override("font_color")
	tab_settings.remove_theme_color_override("font_color")


func _clear_tab_content() -> void:
	for child in tab_content_container.get_children():
		child.queue_free()


func _show_profile_content() -> void:
	_clear_tab_content()
	
	var info_container = VBoxContainer.new()
	info_container.layout_mode = 2
	
	var items = [
		["用户名", _player_data["username"]],
		["邮箱", _player_data["email"]],
		["签名", _player_data["signature"]],
		["注册时间", _player_data["reg_time"]]
	]
	
	for item in items:
		var item_row = HBoxContainer.new()
		item_row.layout_mode = 2
		
		var label = Label.new()
		label.text = item[0]
		label.layout_mode = 2
		label.size_flags_horizontal = 2
		
		var value = Label.new()
		value.text = item[1]
		value.layout_mode = 2
		value.size_flags_horizontal = 3
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		
		item_row.add_child(label)
		item_row.add_child(value)
		info_container.add_child(item_row)
	
	tab_content_container.add_child(info_container)


func _show_achievements_content() -> void:
	_clear_tab_content()
	
	var info_container := VBoxContainer.new()
	info_container.layout_mode = 2
	
	var label := Label.new()
	label.text = "成就系统开发中..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(label)
	
	tab_content_container.add_child(info_container)


func _show_collections_content() -> void:
	_clear_tab_content()
	
	var info_container := VBoxContainer.new()
	info_container.layout_mode = 2
	
	var label := Label.new()
	label.text = "收藏系统开发中..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(label)
	
	tab_content_container.add_child(info_container)


func _show_settings_content() -> void:
	_clear_tab_content()
	
	var info_container := VBoxContainer.new()
	info_container.layout_mode = 2
	
	var label := Label.new()
	label.text = "设置系统开发中..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(label)
	
	tab_content_container.add_child(info_container)


func _apply_theme() -> void:
	var theme_obj := Theme.new()
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color8(255, 102, 153)
	btn_style.corner_radius_top_left = 24
	btn_style.corner_radius_top_right = 24
	btn_style.corner_radius_bottom_left = 24
	btn_style.corner_radius_bottom_right = 24
	btn_style.content_margin_left = 20
	btn_style.content_margin_top = 12
	btn_style.content_margin_right = 20
	btn_style.content_margin_bottom = 12
	theme_obj.set_stylebox("normal", "Button", btn_style)
	
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color8(255, 130, 175)
	theme_obj.set_stylebox("hover", "Button", btn_hover)
	
	var btn_pressed := btn_style.duplicate()
	btn_pressed.bg_color = Color8(230, 85, 130)
	theme_obj.set_stylebox("pressed", "Button", btn_pressed)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color8(255, 230, 230)
	card_style.border_color = Color8(255, 200, 210)
	card_style.set_border_width_all(2)
	card_style.corner_radius_top_left = 32
	card_style.corner_radius_top_right = 32
	card_style.corner_radius_bottom_left = 32
	card_style.corner_radius_bottom_right = 32
	card_style.shadow_color = Color(0, 0, 0, 0.1)
	card_style.shadow_size = 10
	card_style.shadow_offset = Vector2(0, 5)
	theme_obj.set_stylebox("panel", "PanelContainer", card_style)

	theme_obj.set_color("font_color", "Button", Color8(255, 255, 255))
	theme_obj.set_color("font_color", "Label", Color8(75, 50, 62))

	self.theme = theme_obj
	
	var avatar_circle: Panel = $MainContainer/ProfileCard/ProfileContent/AvatarSection/AvatarContainer/AvatarCircle
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color8(255, 102, 153)
	avatar_style.corner_radius_top_left = 50
	avatar_style.corner_radius_top_right = 50
	avatar_style.corner_radius_bottom_left = 50
	avatar_style.corner_radius_bottom_right = 50
	avatar_circle.add_theme_stylebox_override("panel", avatar_style)
	
	var avatar_ring3: Panel = $MainContainer/ProfileCard/ProfileContent/AvatarSection/AvatarContainer/AvatarRing3
	var ring3_style := StyleBoxFlat.new()
	ring3_style.bg_color = Color(0, 0, 0, 0)
	ring3_style.border_color = Color8(255, 102, 153)
	ring3_style.border_width_left = 4
	ring3_style.border_width_top = 4
	ring3_style.border_width_right = 4
	ring3_style.border_width_bottom = 4
	ring3_style.corner_radius_top_left = 75
	ring3_style.corner_radius_top_right = 75
	ring3_style.corner_radius_bottom_left = 75
	ring3_style.corner_radius_bottom_right = 75
	avatar_ring3.add_theme_stylebox_override("panel", ring3_style)
	
	var avatar_ring2: Panel = $MainContainer/ProfileCard/ProfileContent/AvatarSection/AvatarContainer/AvatarRing2
	var ring2_style := StyleBoxFlat.new()
	ring2_style.bg_color = Color(0, 0, 0, 0)
	ring2_style.border_color = Color8(255, 180, 200)
	ring2_style.border_width_left = 3
	ring2_style.border_width_top = 3
	ring2_style.border_width_right = 3
	ring2_style.border_width_bottom = 3
	ring2_style.corner_radius_top_left = 65
	ring2_style.corner_radius_top_right = 65
	ring2_style.corner_radius_bottom_left = 65
	ring2_style.corner_radius_bottom_right = 65
	avatar_ring2.add_theme_stylebox_override("panel", ring2_style)
	
	var avatar_ring1: Panel = $MainContainer/ProfileCard/ProfileContent/AvatarSection/AvatarContainer/AvatarRing1
	var ring1_style := StyleBoxFlat.new()
	ring1_style.bg_color = Color(0, 0, 0, 0)
	ring1_style.border_color = Color8(255, 210, 220)
	ring1_style.border_width_left = 2
	ring1_style.border_width_top = 2
	ring1_style.border_width_right = 2
	ring1_style.border_width_bottom = 2
	ring1_style.corner_radius_top_left = 55
	ring1_style.corner_radius_top_right = 55
	ring1_style.corner_radius_bottom_left = 55
	ring1_style.corner_radius_bottom_right = 55
	avatar_ring1.add_theme_stylebox_override("panel", ring1_style)
	
	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = Color8(255, 240, 245)
	progress_bg.corner_radius_top_left = 10
	progress_bg.corner_radius_top_right = 10
	progress_bg.corner_radius_bottom_left = 10
	progress_bg.corner_radius_bottom_right = 10
	
	var stats_cards := ["LevelCard", "ExpCard", "CoinsCard", "SignInCard", "FriendsCard"]
	for card_name in stats_cards:
		var card: PanelContainer = $MainContainer/ProfileCard/ProfileContent/InfoSection/StatsGrid.get_node(card_name)
		if card:
			var card_bg := StyleBoxFlat.new()
			card_bg.bg_color = Color8(255, 240, 245)
			card_bg.border_color = Color8(255, 200, 210)
			card_bg.set_border_width_all(1)
			card_bg.corner_radius_top_left = 16
			card_bg.corner_radius_top_right = 16
			card_bg.corner_radius_bottom_left = 16
			card_bg.corner_radius_bottom_right = 16
			card.add_theme_stylebox_override("panel", card_bg)
	
	level_progress.add_theme_stylebox_override("background", progress_bg)
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color8(255, 102, 153)
	progress_fill.corner_radius_top_left = 10
	progress_fill.corner_radius_top_right = 10
	progress_fill.corner_radius_bottom_left = 10
	progress_fill.corner_radius_bottom_right = 10
	level_progress.add_theme_stylebox_override("fill", progress_fill)


func _on_window_resized() -> void:
	var screen_size = get_viewport().size
	var is_mobile = screen_size.x < 768
	
	var container: VBoxContainer = $MainContainer
	container.offset_left = max(16, screen_size.x * 0.02)
	container.offset_right = max(-16, -screen_size.x * 0.02)
	container.offset_top = max(16, screen_size.y * 0.02)
	container.offset_bottom = max(-16, -screen_size.y * 0.02)


func _play_intro_animation() -> void:
	var header: PanelContainer = $MainContainer/HeaderBar
	var profile_card: PanelContainer = $MainContainer/ProfileCard
	var actions: HBoxContainer = $MainContainer/ActionButtons
	
	header.modulate.a = 0.0
	profile_card.modulate.a = 0.0
	actions.modulate.a = 0.0
	
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(header, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.15).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(profile_card, "modulate:a", 1.0, 0.5)
	
	await get_tree().create_timer(0.15).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(actions, "modulate:a", 1.0, 0.4)


func _on_back_clicked() -> void:
	UITheme.pulse(back_btn)
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")


func _on_edit_profile() -> void:
	UITheme.pulse(edit_profile_btn)
	MoeDialogBus.show_dialog("修改资料", "功能开发中...")


func _on_security() -> void:
	UITheme.pulse(security_btn)
	MoeDialogBus.show_dialog("账号安全", "功能开发中...")


func _on_back_hall() -> void:
	UITheme.pulse(back_hall_btn)
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")
