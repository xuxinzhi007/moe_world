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
	gradient_offset += delta * 0.04
	if gradient_offset > 1.0:
		gradient_offset = 0.0
	var t := gradient_offset
	## 深紫 (#0F0A1E) ↔ 深蓝 (#0D1F3D) 慢速循环 —— 暗色游戏风
	var col1 := _lerp_color(Color(0.059, 0.039, 0.118), Color(0.051, 0.122, 0.239), t)
	var col2 := _lerp_color(Color(0.051, 0.122, 0.239), Color(0.059, 0.039, 0.118), t)
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

	## 全局 Button / LineEdit / Label 颜色
	theme_obj.set_stylebox("normal",  "Button", UiTheme.modern_primary_button_normal(18))
	theme_obj.set_stylebox("hover",   "Button", UiTheme.modern_primary_button_hover(18))
	theme_obj.set_stylebox("pressed", "Button", UiTheme.modern_primary_button_pressed(18))
	theme_obj.set_stylebox("normal",  "LineEdit", UiTheme.modern_line_edit_normal(14))
	theme_obj.set_stylebox("focus",   "LineEdit", UiTheme.modern_line_edit_focus(14))
	theme_obj.set_color("font_color", "Button",  UiTheme.Colors.TEXT_LIGHT)
	theme_obj.set_color("font_color", "Label",   UiTheme.Colors.TEXT_MAIN)
	theme_obj.set_color("font_color", "LineEdit", UiTheme.Colors.TEXT_MAIN)
	theme_obj.set_color("placeholder_font_color", "LineEdit", UiTheme.Colors.TEXT_MUTED)
	self.theme = theme_obj

	## 玩家信息栏
	var player_bar: PanelContainer = $MainContainer/PlayerInfoBar
	player_bar.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(22, 0.90))

	## 游戏模式卡片 — 单机（紫色系）
	var offline_card: PanelContainer = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard
	var off_style := UiTheme.modern_glass_card(24, 0.88)
	off_style.border_color = Color(0.616, 0.306, 0.867, 0.8)
	off_style.border_width_left = 2
	off_style.border_width_top = 2
	off_style.border_width_right = 2
	off_style.border_width_bottom = 2
	offline_card.add_theme_stylebox_override("panel", off_style)

	## 游戏模式卡片 — 联机（青色系）
	var cloud_card: PanelContainer = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard
	var cloud_style := UiTheme.modern_glass_card(24, 0.88)
	cloud_style.border_color = Color(0.0, 0.831, 1.0, 0.8)
	cloud_style.border_width_left = 2
	cloud_style.border_width_top = 2
	cloud_style.border_width_right = 2
	cloud_style.border_width_bottom = 2
	cloud_card.add_theme_stylebox_override("panel", cloud_style)

	## 状态徽章
	var hero_badge: PanelContainer = $MainContainer/HeroStrip/HeroBadge
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.616, 0.306, 0.867, 0.3)
	badge_style.border_color = Color(0.616, 0.306, 0.867, 0.7)
	badge_style.set_border_width_all(1)
	badge_style.corner_radius_top_left = 14
	badge_style.corner_radius_top_right = 14
	badge_style.corner_radius_bottom_left = 14
	badge_style.corner_radius_bottom_right = 14
	badge_style.content_margin_left = 14
	badge_style.content_margin_top = 8
	badge_style.content_margin_right = 14
	badge_style.content_margin_bottom = 8
	if is_instance_valid(hero_badge):
		hero_badge.add_theme_stylebox_override("panel", badge_style)

	## 进入世界 CTA 按钮 — 紫色渐变
	var cta_primary := UiTheme.modern_primary_button_normal(16)
	cta_primary.content_margin_left = 18
	cta_primary.content_margin_right = 18
	var cta_h := UiTheme.modern_primary_button_hover(16)
	cta_h.content_margin_left = 18
	cta_h.content_margin_right = 18
	var cta_p := UiTheme.modern_primary_button_pressed(16)
	cta_p.content_margin_left = 18
	cta_p.content_margin_right = 18
	enter_world_btn.add_theme_stylebox_override("normal", cta_primary)
	enter_world_btn.add_theme_stylebox_override("hover", cta_h)
	enter_world_btn.add_theme_stylebox_override("pressed", cta_p)
	enter_world_btn.add_theme_color_override("font_color", Color.WHITE)

	## 联机按钮 — 青色
	var cta_cloud := StyleBoxFlat.new()
	cta_cloud.bg_color = Color(0.0, 0.510, 0.780, 1.0)
	cta_cloud.corner_radius_top_left = 16
	cta_cloud.corner_radius_top_right = 16
	cta_cloud.corner_radius_bottom_left = 16
	cta_cloud.corner_radius_bottom_right = 16
	cta_cloud.content_margin_left = 18
	cta_cloud.content_margin_top = 12
	cta_cloud.content_margin_right = 18
	cta_cloud.content_margin_bottom = 12
	cta_cloud.shadow_color = Color(0.0, 0.831, 1.0, 0.28)
	cta_cloud.shadow_size = 12
	cta_cloud.shadow_offset = Vector2(0, 4)
	var cta_cloud_h := cta_cloud.duplicate()
	(cta_cloud_h as StyleBoxFlat).bg_color = Color(0.0, 0.650, 0.950, 1.0)
	var cta_cloud_p := cta_cloud.duplicate()
	(cta_cloud_p as StyleBoxFlat).bg_color = Color(0.0, 0.380, 0.620, 1.0)
	cloud_world_btn.add_theme_stylebox_override("normal", cta_cloud)
	cloud_world_btn.add_theme_stylebox_override("hover", cta_cloud_h)
	cloud_world_btn.add_theme_stylebox_override("pressed", cta_cloud_p)
	cloud_world_btn.add_theme_color_override("font_color", Color.WHITE)

	## 头像圈 — 紫色
	var avatar_circle: Panel = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn/AvatarCircle
	if is_instance_valid(avatar_circle):
		var avatar_style := StyleBoxFlat.new()
		avatar_style.bg_color = Color(0.616, 0.306, 0.867, 1.0)
		avatar_style.corner_radius_top_left = 28
		avatar_style.corner_radius_top_right = 28
		avatar_style.corner_radius_bottom_left = 28
		avatar_style.corner_radius_bottom_right = 28
		avatar_style.shadow_color = Color(0.616, 0.306, 0.867, 0.35)
		avatar_style.shadow_size = 12
		avatar_style.shadow_offset = Vector2(0, 3)
		avatar_circle.add_theme_stylebox_override("panel", avatar_style)

	## 快捷键按钮（动态、好友、消息）
	var quick_btn_style := StyleBoxFlat.new()
	quick_btn_style.bg_color = Color(0.25, 0.18, 0.40, 0.85)
	quick_btn_style.border_color = Color(0.616, 0.306, 0.867, 0.5)
	quick_btn_style.set_border_width_all(1)
	quick_btn_style.corner_radius_top_left = 14
	quick_btn_style.corner_radius_top_right = 14
	quick_btn_style.corner_radius_bottom_left = 14
	quick_btn_style.corner_radius_bottom_right = 14
	if is_instance_valid(recent_btn):
		recent_btn.add_theme_stylebox_override("normal", quick_btn_style)
	if is_instance_valid(friends_btn):
		friends_btn.add_theme_stylebox_override("normal", quick_btn_style.duplicate())
	if is_instance_valid(notice_btn):
		notice_btn.add_theme_stylebox_override("normal", quick_btn_style.duplicate())

	## 品牌标题 / 徽章 Label 颜色
	if is_instance_valid(brand_title):
		brand_title.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MAIN)
	if is_instance_valid(brand_subtitle):
		brand_subtitle.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MUTED)
	if is_instance_valid(hero_badge_label):
		hero_badge_label.add_theme_color_override("font_color", UiTheme.Colors.ACCENT_PINK)


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
	MoeDialogBus.show_dialog("云端连接失败", "无法连上服务器 WebSocket。请确认后端已部署 /ws/world，公网需放行该端口且反向代理支持 WebSocket 升级。")


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
