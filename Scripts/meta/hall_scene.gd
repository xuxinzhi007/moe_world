extends Control

const UiTheme := preload("res://Scripts/meta/ui_theme.gd")

const LOGIN_SCENE := preload("res://Scenes/ui/LoginScreen.tscn")

@onready var player_name_label: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/PlayerDetails/PlayerName
@onready var online_time_label: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/PlayerDetails/OnlineTime
@onready var avatar_initial: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn/AvatarCircle/AvatarInitial
@onready var vip_badge: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn/VIPBadge
@onready var recent_btn: Button = $MainContainer/PlayerInfoBar/PlayerInfoContent/QuickAccess/RecentBtn
@onready var friends_btn: Button = $MainContainer/PlayerInfoBar/PlayerInfoContent/QuickAccess/FriendsBtn
@onready var notice_btn: Button = $MainContainer/PlayerInfoBar/PlayerInfoContent/QuickAccess/NoticeBtn
@onready var brand_title: Label = $MainContainer/HeroStrip/BrandBlock/BrandTitle
@onready var brand_subtitle: Label = $MainContainer/HeroStrip/BrandBlock/BrandSubtitle
@onready var hero_badge_label: Label = $MainContainer/HeroStrip/HeroBadge/HeroBadgeLabel
@onready var section_hint: Label = $MainContainer/GameModesSection/SectionHeader/SectionHint
@onready var enter_world_btn: Button = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard/InnerVBox/OfflineCardContent/EnterBtn
@onready var cloud_world_btn: Button = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/CloudBtn
@onready var cloud_room_edit: LineEdit = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/RoomEdit
@onready var profile_btn: Button = $MainContainer/FeaturesSection/ProfileBtn
@onready var growth_btn: Button = $MainContainer/FeaturesSection/GrowthBtn
@onready var login_btn: Button = $MainContainer/FeaturesSection/LoginBtn
@onready var logout_btn: Button = $MainContainer/FeaturesSection/LogoutBtn
@onready var copyright_label: Label = $MainContainer/FooterSection/CopyrightLabel
@onready var character_build_overlay: Control = $CharacterBuildOverlay
@onready var bg_gradient: ColorRect = $BgGradient

var _cloud_wait_timer: SceneTreeTimer
var _cloud_pending: bool = false
var _online_time_seconds: int = 0
var gradient_offset: float = 0.0
var _is_mobile: bool = false
var _login_overlay_layer: CanvasLayer
var _pending_cloud_room: String = ""


func _ready() -> void:
	_apply_theme()
	_refresh_player_info()
	_setup_button_connections()
	_apply_touch_friendly_buttons()
	_start_online_timer()
	
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


func _apply_touch_friendly_buttons() -> void:
	# 触摸：避免焦点抢走首帧；按下即触发（与移动端虚拟键一致）
	for b: BaseButton in [
		enter_world_btn,
		cloud_world_btn,
		profile_btn,
		growth_btn,
		login_btn,
		logout_btn,
		recent_btn,
		friends_btn,
		notice_btn,
		$MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn,
		$MainContainer/GameModesSection/GameModesGrid/OfflineModeCard/InnerVBox/OfflineCardContent/EnterBtn,
		$MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/CloudBtn,
	]:
		if is_instance_valid(b):
			b.focus_mode = Control.FOCUS_NONE
			b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS


func _setup_button_connections() -> void:
	enter_world_btn.pressed.connect(_on_enter_offline_clicked)
	cloud_world_btn.pressed.connect(_on_cloud_world_clicked)
	profile_btn.pressed.connect(_on_profile_clicked)
	growth_btn.pressed.connect(_on_growth_clicked)
	login_btn.pressed.connect(_on_login_btn_clicked)
	logout_btn.pressed.connect(_on_logout_clicked)
	recent_btn.pressed.connect(_on_recent_clicked)
	friends_btn.pressed.connect(_on_friends_clicked)
	notice_btn.pressed.connect(_on_notice_clicked)
	
	_setup_button_hover_effect(enter_world_btn)
	_setup_button_hover_effect(cloud_world_btn)
	_setup_button_hover_effect(profile_btn)
	_setup_button_hover_effect(growth_btn)
	_setup_button_hover_effect(login_btn)
	_setup_button_hover_effect(logout_btn)
	_setup_button_hover_effect(recent_btn)
	_setup_button_hover_effect(friends_btn)
	_setup_button_hover_effect(notice_btn)


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


func _refresh_player_info() -> void:
	var name_str := "萌酱"
	var vip_level := 0
	
	if ProjectSettings.has_setting("moe_world/current_user"):
		var u: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if u is Dictionary and not (u as Dictionary).is_empty():
			name_str = str((u as Dictionary).get("username", "萌酱"))
			vip_level = int((u as Dictionary).get("vip_level", 0))
	
	player_name_label.text = name_str
	avatar_initial.text = name_str.substr(0, 1) if name_str.length() > 0 else "萌"
	if is_instance_valid(hero_badge_label):
		hero_badge_label.text = "已登录" if _is_logged_in() else "游客模式"
	
	if vip_level > 0:
		vip_badge.visible = true
		vip_badge.text = "VIP %d" % vip_level
	else:
		vip_badge.visible = false
	
	_update_auth_buttons()


func _is_logged_in() -> bool:
	if not ProjectSettings.has_setting("moe_world/current_user"):
		return false
	var u: Variant = ProjectSettings.get_setting("moe_world/current_user")
	if not u is Dictionary:
		return false
	var d: Dictionary = u as Dictionary
	if d.is_empty():
		return false
	return not str(d.get("token", "")).strip_edges().is_empty()


func _update_auth_buttons() -> void:
	var logged := _is_logged_in()
	login_btn.visible = not logged
	logout_btn.visible = logged


func _start_online_timer() -> void:
	_online_time_seconds = 0
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(func():
		_online_time_seconds += 1
		var minutes: int = int(floor(float(_online_time_seconds) / 60.0))
		online_time_label.text = "在线: %d分钟" % minutes
	)
	add_child(timer)
	timer.start()


func _apply_theme() -> void:
	var theme_obj := Theme.new()
	
	var outline_btn := StyleBoxFlat.new()
	outline_btn.bg_color = Color(1, 1, 1, 0.38)
	outline_btn.border_color = Color8(230, 175, 200)
	outline_btn.set_border_width_all(1)
	outline_btn.corner_radius_top_left = 18
	outline_btn.corner_radius_top_right = 18
	outline_btn.corner_radius_bottom_left = 18
	outline_btn.corner_radius_bottom_right = 18
	outline_btn.content_margin_left = 16
	outline_btn.content_margin_top = 12
	outline_btn.content_margin_right = 16
	outline_btn.content_margin_bottom = 12
	theme_obj.set_stylebox("normal", "Button", outline_btn)
	var outline_hover := outline_btn.duplicate()
	outline_hover.bg_color = Color(1, 0.96, 0.98, 0.62)
	outline_hover.border_color = Color8(255, 140, 175)
	theme_obj.set_stylebox("hover", "Button", outline_hover)
	var outline_pressed := outline_btn.duplicate()
	outline_pressed.bg_color = Color8(255, 235, 242)
	theme_obj.set_stylebox("pressed", "Button", outline_pressed)

	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(1, 1, 1, 0.92)
	input_style.border_color = Color8(220, 175, 200)
	input_style.set_border_width_all(1)
	input_style.corner_radius_top_left = 14
	input_style.corner_radius_top_right = 14
	input_style.corner_radius_bottom_left = 14
	input_style.corner_radius_bottom_right = 14
	input_style.content_margin_left = 14
	input_style.content_margin_top = 10
	input_style.content_margin_right = 14
	input_style.content_margin_bottom = 10
	theme_obj.set_stylebox("normal", "LineEdit", input_style)
	var input_focus := input_style.duplicate()
	input_focus.border_color = Color8(255, 120, 165)
	input_focus.set_border_width_all(2)
	theme_obj.set_stylebox("focus", "LineEdit", input_focus)

	theme_obj.set_color("font_color", "Button", Color8(92, 48, 72))
	theme_obj.set_color("font_color", "Label", Color8(72, 48, 62))
	theme_obj.set_color("font_color", "LineEdit", Color8(55, 40, 58))
	theme_obj.set_color("placeholder_font_color", "LineEdit", Color8(130, 105, 120))

	self.theme = theme_obj

	var player_bar: PanelContainer = $MainContainer/PlayerInfoBar
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(1, 0.97, 0.99, 0.78)
	bar_style.border_color = Color8(255, 195, 215)
	bar_style.set_border_width_all(1)
	bar_style.corner_radius_top_left = 22
	bar_style.corner_radius_top_right = 22
	bar_style.corner_radius_bottom_left = 22
	bar_style.corner_radius_bottom_right = 22
	bar_style.content_margin_left = 18
	bar_style.content_margin_top = 14
	bar_style.content_margin_right = 18
	bar_style.content_margin_bottom = 14
	bar_style.shadow_color = Color(0.35, 0.12, 0.22, 0.14)
	bar_style.shadow_size = 22
	bar_style.shadow_offset = Vector2(0, 8)
	player_bar.add_theme_stylebox_override("panel", bar_style)

	var offline_card: PanelContainer = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard
	var off_style := StyleBoxFlat.new()
	off_style.bg_color = Color(1, 0.99, 0.995, 0.94)
	off_style.border_color = Color8(255, 185, 205)
	off_style.set_border_width_all(1)
	off_style.corner_radius_top_left = 24
	off_style.corner_radius_top_right = 24
	off_style.corner_radius_bottom_left = 24
	off_style.corner_radius_bottom_right = 24
	off_style.shadow_color = Color(0.4, 0.15, 0.25, 0.1)
	off_style.shadow_size = 20
	off_style.shadow_offset = Vector2(0, 10)
	offline_card.add_theme_stylebox_override("panel", off_style)

	var cloud_card: PanelContainer = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard
	var cloud_style := StyleBoxFlat.new()
	cloud_style.bg_color = Color(0.97, 0.99, 1.0, 0.94)
	cloud_style.border_color = Color8(170, 205, 245)
	cloud_style.set_border_width_all(1)
	cloud_style.corner_radius_top_left = 24
	cloud_style.corner_radius_top_right = 24
	cloud_style.corner_radius_bottom_left = 24
	cloud_style.corner_radius_bottom_right = 24
	cloud_style.shadow_color = Color(0.15, 0.25, 0.45, 0.1)
	cloud_style.shadow_size = 20
	cloud_style.shadow_offset = Vector2(0, 10)
	cloud_card.add_theme_stylebox_override("panel", cloud_style)

	var hero_badge: PanelContainer = $MainContainer/HeroStrip/HeroBadge
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(1, 0.9, 0.95, 0.65)
	badge_style.border_color = Color8(255, 160, 195)
	badge_style.set_border_width_all(1)
	badge_style.corner_radius_top_left = 14
	badge_style.corner_radius_top_right = 14
	badge_style.corner_radius_bottom_left = 14
	badge_style.corner_radius_bottom_right = 14
	badge_style.content_margin_left = 14
	badge_style.content_margin_top = 8
	badge_style.content_margin_right = 14
	badge_style.content_margin_bottom = 8
	hero_badge.add_theme_stylebox_override("panel", badge_style)

	var cta_primary := StyleBoxFlat.new()
	cta_primary.bg_color = Color8(255, 88, 145)
	cta_primary.corner_radius_top_left = 16
	cta_primary.corner_radius_top_right = 16
	cta_primary.corner_radius_bottom_left = 16
	cta_primary.corner_radius_bottom_right = 16
	cta_primary.content_margin_left = 18
	cta_primary.content_margin_top = 12
	cta_primary.content_margin_right = 18
	cta_primary.content_margin_bottom = 12
	cta_primary.shadow_color = Color(0.55, 0.1, 0.3, 0.22)
	cta_primary.shadow_size = 12
	cta_primary.shadow_offset = Vector2(0, 4)
	var cta_h := cta_primary.duplicate()
	cta_h.bg_color = Color8(255, 125, 175)
	var cta_p := cta_primary.duplicate()
	cta_p.bg_color = Color8(230, 70, 125)
	enter_world_btn.add_theme_stylebox_override("normal", cta_primary)
	enter_world_btn.add_theme_stylebox_override("hover", cta_h)
	enter_world_btn.add_theme_stylebox_override("pressed", cta_p)
	enter_world_btn.add_theme_color_override("font_color", Color8(255, 255, 255))

	var cta_cloud := StyleBoxFlat.new()
	cta_cloud.bg_color = Color8(88, 155, 245)
	cta_cloud.corner_radius_top_left = 16
	cta_cloud.corner_radius_top_right = 16
	cta_cloud.corner_radius_bottom_left = 16
	cta_cloud.corner_radius_bottom_right = 16
	cta_cloud.content_margin_left = 18
	cta_cloud.content_margin_top = 12
	cta_cloud.content_margin_right = 18
	cta_cloud.content_margin_bottom = 12
	cta_cloud.shadow_color = Color(0.12, 0.28, 0.55, 0.2)
	cta_cloud.shadow_size = 12
	cta_cloud.shadow_offset = Vector2(0, 4)
	var cta_cloud_h := cta_cloud.duplicate()
	cta_cloud_h.bg_color = Color8(120, 180, 255)
	var cta_cloud_p := cta_cloud.duplicate()
	cta_cloud_p.bg_color = Color8(65, 125, 220)
	cloud_world_btn.add_theme_stylebox_override("normal", cta_cloud)
	cloud_world_btn.add_theme_stylebox_override("hover", cta_cloud_h)
	cloud_world_btn.add_theme_stylebox_override("pressed", cta_cloud_p)
	cloud_world_btn.add_theme_color_override("font_color", Color8(255, 255, 255))

	var avatar_circle: Panel = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn/AvatarCircle
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color8(255, 105, 158)
	avatar_style.corner_radius_top_left = 28
	avatar_style.corner_radius_top_right = 28
	avatar_style.corner_radius_bottom_left = 28
	avatar_style.corner_radius_bottom_right = 28
	avatar_style.shadow_color = Color(0.45, 0.12, 0.28, 0.2)
	avatar_style.shadow_size = 10
	avatar_style.shadow_offset = Vector2(0, 3)
	avatar_circle.add_theme_stylebox_override("panel", avatar_style)

	var quick_btn_style := StyleBoxFlat.new()
	quick_btn_style.bg_color = Color(1, 0.96, 0.98, 0.85)
	quick_btn_style.border_color = Color8(240, 190, 210)
	quick_btn_style.set_border_width_all(1)
	quick_btn_style.corner_radius_top_left = 14
	quick_btn_style.corner_radius_top_right = 14
	quick_btn_style.corner_radius_bottom_left = 14
	quick_btn_style.corner_radius_bottom_right = 14
	recent_btn.add_theme_stylebox_override("normal", quick_btn_style)
	friends_btn.add_theme_stylebox_override("normal", quick_btn_style.duplicate())
	notice_btn.add_theme_stylebox_override("normal", quick_btn_style.duplicate())


func _on_window_resized() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	_is_mobile = screen_size.x < 640
	
	var game_modes_grid: GridContainer = $MainContainer/GameModesSection/GameModesGrid
	# 双列需要足够宽度，否则单列更易读（平板竖屏、窄窗口）
	var min_width_dual_column: float = 700.0
	game_modes_grid.columns = 1 if screen_size.x < min_width_dual_column else 2
	
	var font_scale: float = UiTheme.responsive_ui_font_scale(screen_size)
	var title_size = int(24 * font_scale)
	var body_size := int(16 * font_scale)
	var mode_icon_size := int(30 * font_scale)
	var off_icon: Label = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard/InnerVBox/OfflineCardContent/ModeIcon
	var cl_icon: Label = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/ModeIcon
	off_icon.add_theme_font_size_override("font_size", mode_icon_size)
	cl_icon.add_theme_font_size_override("font_size", mode_icon_size)
	copyright_label.add_theme_font_size_override("font_size", body_size)
	var caption_size = int(14 * font_scale)
	
	player_name_label.add_theme_font_size_override("font_size", title_size)
	online_time_label.add_theme_font_size_override("font_size", caption_size)
	
	var section_title: Label = $MainContainer/GameModesSection/SectionHeader/SectionTitle
	section_title.add_theme_font_size_override("font_size", int(22 * font_scale))
	if is_instance_valid(section_hint):
		section_hint.add_theme_font_size_override("font_size", int(14 * font_scale))
	if is_instance_valid(brand_title):
		brand_title.add_theme_font_size_override("font_size", int(34 * font_scale))
	if is_instance_valid(brand_subtitle):
		brand_subtitle.add_theme_font_size_override("font_size", int(15 * font_scale))
	if is_instance_valid(hero_badge_label):
		hero_badge_label.add_theme_font_size_override("font_size", int(14 * font_scale))
	
	var off_title: Label = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard/InnerVBox/OfflineCardContent/ModeTitle
	var off_desc: Label = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard/InnerVBox/OfflineCardContent/ModeDesc
	off_title.add_theme_font_size_override("font_size", int(19 * font_scale))
	off_desc.add_theme_font_size_override("font_size", int(14 * font_scale))
	var cl_title: Label = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/ModeTitle
	var cl_desc: Label = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/ModeDesc
	cl_title.add_theme_font_size_override("font_size", int(19 * font_scale))
	cl_desc.add_theme_font_size_override("font_size", int(14 * font_scale))
	enter_world_btn.add_theme_font_size_override("font_size", int(17 * font_scale))
	cloud_world_btn.add_theme_font_size_override("font_size", int(17 * font_scale))
	profile_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	growth_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	login_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	logout_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	
	var container: VBoxContainer = $MainContainer
	var game_modes_sec: VBoxContainer = $MainContainer/GameModesSection
	var offline_card: PanelContainer = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard
	var cloud_card: PanelContainer = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard
	
	var m: Dictionary = UiTheme.responsive_main_column_margins(screen_size)
	container.offset_left = m["left"]
	container.offset_right = m["right"]
	container.offset_top = m["top"]
	container.offset_bottom = m["bottom"]
	
	var main_sep: int = 20 if screen_size.x < 640 else (24 if screen_size.x < 1100 else 28)
	container.add_theme_constant_override("separation", main_sep)
	var sec_sep: int = 14 if screen_size.x < 640 else (18 if screen_size.x < 1100 else 22)
	game_modes_sec.add_theme_constant_override("separation", sec_sep)
	var grid_h: int = 16 if screen_size.x < 640 else 24
	var grid_v: int = 16 if screen_size.x < 640 else 24
	game_modes_grid.add_theme_constant_override("h_separation", grid_h)
	game_modes_grid.add_theme_constant_override("v_separation", grid_v)
	
	if game_modes_grid.columns == 2 and screen_size.x >= 860:
		var card_min_h: float = clampf(screen_size.y * 0.23, 210.0, 400.0)
		offline_card.custom_minimum_size = Vector2(0, card_min_h)
		cloud_card.custom_minimum_size = Vector2(0, card_min_h)
	else:
		offline_card.custom_minimum_size = Vector2.ZERO
		cloud_card.custom_minimum_size = Vector2.ZERO


func _play_intro_animation() -> void:
	var hero_strip: Control = $MainContainer/HeroStrip
	var player_info: PanelContainer = $MainContainer/PlayerInfoBar
	var game_modes: VBoxContainer = $MainContainer/GameModesSection
	var features: HBoxContainer = $MainContainer/FeaturesSection
	
	hero_strip.modulate.a = 0.0
	hero_strip.position.y -= 18
	player_info.modulate.a = 0.0
	player_info.position.y -= 26
	game_modes.modulate.a = 0.0
	game_modes.position.y += 14
	features.modulate.a = 0.0
	
	var tw0 := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw0.tween_property(hero_strip, "modulate:a", 1.0, 0.42)
	tw0.parallel().tween_property(hero_strip, "position:y", hero_strip.position.y + 18, 0.42)
	
	await get_tree().create_timer(0.08).timeout
	
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(player_info, "modulate:a", 1.0, 0.48)
	tween.parallel().tween_property(player_info, "position:y", player_info.position.y + 26, 0.48)
	
	await get_tree().create_timer(0.16).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(game_modes, "modulate:a", 1.0, 0.52)
	tween.parallel().tween_property(game_modes, "position:y", game_modes.position.y - 14, 0.52)
	
	await get_tree().create_timer(0.12).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(features, "modulate:a", 1.0, 0.45)


func _on_enter_offline_clicked() -> void:
	UiTheme.pulse(enter_world_btn)
	GameAudio.ui_confirm()
	WorldNetwork.leave_session()
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")


func _on_cloud_world_clicked() -> void:
	UiTheme.pulse(cloud_world_btn)
	GameAudio.ui_confirm()
	var room := cloud_room_edit.text.strip_edges()
	_begin_cloud_connection(room)


func _begin_cloud_connection(room: String) -> void:
	var rid := room.strip_edges()
	if rid.is_empty():
		rid = "default"
	if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
		WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
	if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
		WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
	WorldNetwork.cloud_ready.connect(_on_cloud_ready, CONNECT_ONE_SHOT)
	WorldNetwork.cloud_connection_failed.connect(_on_cloud_failed, CONNECT_ONE_SHOT)
	var err: int = WorldNetwork.start_cloud(rid)
	if err != OK:
		if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
			WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
		if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
			WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
		if err == ERR_UNAUTHORIZED:
			_open_login_overlay(rid)
		else:
			MoeDialogBus.show_dialog("无法连接", "请确认已登录且保存了 API 地址；房间名仅允许字母、数字、下划线与短横线。错误码 %d。" % err)
		return
	_cloud_pending = true
	_cloud_wait_timer = get_tree().create_timer(15.0)
	_cloud_wait_timer.timeout.connect(_on_cloud_timeout, CONNECT_ONE_SHOT)


func _on_login_btn_clicked() -> void:
	UiTheme.pulse(login_btn)
	_open_login_overlay("")


func _open_login_overlay(pending_cloud_room: String) -> void:
	if _login_overlay_layer != null and is_instance_valid(_login_overlay_layer):
		return
	_pending_cloud_room = pending_cloud_room.strip_edges()
	var layer := CanvasLayer.new()
	layer.layer = 120
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var login_inst: Control = LOGIN_SCENE.instantiate()
	login_inst.overlay_mode = true
	login_inst.set_anchors_preset(Control.PRESET_FULL_RECT)
	login_inst.login_success.connect(_on_overlay_login_success, CONNECT_ONE_SHOT)
	login_inst.overlay_closed.connect(_on_login_overlay_closed, CONNECT_ONE_SHOT)
	layer.add_child(login_inst)
	add_child(layer)
	_login_overlay_layer = layer


func _login_overlay_dispose() -> void:
	if _login_overlay_layer != null and is_instance_valid(_login_overlay_layer):
		_login_overlay_layer.queue_free()
	_login_overlay_layer = null


func _on_login_overlay_closed() -> void:
	_pending_cloud_room = ""
	_login_overlay_dispose()


func _on_overlay_login_success() -> void:
	var retry_room := _pending_cloud_room
	_pending_cloud_room = ""
	_login_overlay_dispose()
	_refresh_player_info()
	if not retry_room.is_empty():
		_begin_cloud_connection(retry_room)


func _on_cloud_ready() -> void:
	if not _cloud_pending:
		return
	_cloud_pending = false
	if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
		WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
	get_tree().change_scene_to_file("res://Scenes/WorldScene.tscn")


func _on_cloud_failed(_reason: String) -> void:
	if not _cloud_pending:
		return
	_cloud_pending = false
	if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
		WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
	WorldNetwork.leave_session()
	MoeDialogBus.show_dialog("云端连接失败", "无法连上服务器 WebSocket。请确认后端已部署 /ws/world，且 ngrok 等代理支持 WebSocket。")


func _on_cloud_timeout() -> void:
	if not _cloud_pending:
		return
	_cloud_pending = false
	if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
		WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
	if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
		WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
	WorldNetwork.leave_session()
	MoeDialogBus.show_dialog("云端超时", "长时间未收到服务器欢迎包，请检查网络与 token。")


func _on_recent_clicked() -> void:
	UiTheme.pulse(recent_btn)
	MoeDialogBus.show_dialog("最近访问", "暂无最近访问记录")


func _on_friends_clicked() -> void:
	UiTheme.pulse(friends_btn)
	MoeDialogBus.show_dialog("好友列表", "暂无在线好友")


func _on_notice_clicked() -> void:
	UiTheme.pulse(notice_btn)
	MoeDialogBus.show_dialog("公告", "暂无新公告")


func _on_profile_clicked() -> void:
	UiTheme.pulse(profile_btn)
	GameAudio.ui_click()
	get_tree().change_scene_to_file("res://Scenes/ui/ProfileScene.tscn")


func _on_growth_clicked() -> void:
	UiTheme.pulse(growth_btn)
	GameAudio.ui_click()
	if character_build_overlay.has_method("open_panel"):
		character_build_overlay.open_panel()


func _on_logout_clicked() -> void:
	UiTheme.pulse(logout_btn)
	WorldNetwork.leave_session()
	if ProjectSettings.has_setting("moe_world/current_user"):
		ProjectSettings.set_setting("moe_world/current_user", {})
	UserStorage.clear_session_file()
	_refresh_player_info()
