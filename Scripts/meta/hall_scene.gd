extends Control

const UiTheme := preload("res://Scripts/meta/ui_theme.gd")

const LOGIN_SCENE := preload("res://Scenes/ui/LoginScreen.tscn")
const WORLD_SCENE := "res://Scenes/maps/World_Main.tscn"

@onready var player_name_label: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/PlayerDetails/PlayerName
@onready var online_time_label: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/PlayerDetails/OnlineTime
@onready var avatar_initial: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn/AvatarCircle/AvatarInitial
@onready var vip_badge: Label = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn/VIPBadge
@onready var recent_btn: Button = $MainContainer/PlayerInfoBar/PlayerInfoContent/QuickAccess/RecentBtn
@onready var friends_btn: Button = $MainContainer/PlayerInfoBar/PlayerInfoContent/QuickAccess/FriendsBtn
@onready var notice_btn: Button = $MainContainer/PlayerInfoBar/PlayerInfoContent/QuickAccess/NoticeBtn
@onready var brand_title: Label = $MainContainer/HeroStrip/BrandBlock/BrandTitle
@onready var brand_subtitle: Label = $MainContainer/HeroStrip/BrandBlock/BrandSubtitle
@onready var hero_badge: PanelContainer = $MainContainer/HeroStrip/HeroBadge
@onready var hero_badge_label: Label = $MainContainer/HeroStrip/HeroBadge/HeroBadgeLabel
@onready var section_title: Label = $MainContainer/GameModesSection/SectionHeader/SectionTitle
@onready var section_hint: Label = $MainContainer/GameModesSection/SectionHeader/SectionHint
@onready var game_modes_grid: GridContainer = $MainContainer/GameModesSection/GameModesGrid
@onready var offline_icon: Label = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard/InnerVBox/OfflineCardContent/ModeIcon
@onready var cloud_icon: Label = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/ModeIcon
@onready var offline_title: Label = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard/InnerVBox/OfflineCardContent/ModeTitle
@onready var offline_desc: Label = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard/InnerVBox/OfflineCardContent/ModeDesc
@onready var cloud_title: Label = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/ModeTitle
@onready var cloud_desc: Label = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/ModeDesc
@onready var enter_world_btn: Button = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard/InnerVBox/OfflineCardContent/EnterBtn
@onready var cloud_world_btn: Button = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/CloudBtn
@onready var cloud_room_edit: LineEdit = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent/RoomEdit
@onready var cloud_card_content: VBoxContainer = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard/InnerVBox/CloudCardContent
@onready var profile_btn: Button = $MainContainer/FeaturesSection/ProfileBtn
@onready var growth_btn: Button = $MainContainer/FeaturesSection/GrowthBtn
@onready var login_btn: Button = $MainContainer/FeaturesSection/LoginBtn
@onready var logout_btn: Button = $MainContainer/FeaturesSection/LogoutBtn
@onready var copyright_label: Label = $MainContainer/FooterSection/CopyrightLabel
@onready var main_container: VBoxContainer = $MainContainer
@onready var hero_strip: HBoxContainer = $MainContainer/HeroStrip
@onready var player_info_bar: PanelContainer = $MainContainer/PlayerInfoBar
@onready var game_modes_section: VBoxContainer = $MainContainer/GameModesSection
@onready var features_section: HBoxContainer = $MainContainer/FeaturesSection
@onready var offline_mode_card: PanelContainer = $MainContainer/GameModesSection/GameModesGrid/OfflineModeCard
@onready var cloud_mode_card: PanelContainer = $MainContainer/GameModesSection/GameModesGrid/CloudModeCard
@onready var avatar_btn: Button = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn
@onready var avatar_circle: Panel = $MainContainer/PlayerInfoBar/PlayerInfoContent/AvatarBtn/AvatarCircle
@onready var footer_section: HBoxContainer = $MainContainer/FooterSection
@onready var character_build_overlay: Control = $CharacterBuildOverlay
@onready var bg_gradient: ColorRect = $BgGradient

const HALL_BUBBLE_QUEUE_LIMIT := 4
const STORY_BRIEF := "雾潮纪元后，世界被裂隙污染。你作为「萌境巡游者」进入各地回收失控晶核，\n在大世界搜集素材、于试炼中压制怪潮，逐步修复四座失衡生态区。"

var _cloud_wait_timer: SceneTreeTimer
var _cloud_pending: bool = false
var _online_time_seconds: int = 0
var gradient_offset: float = 0.0
var _is_mobile: bool = false
var _login_overlay_layer: CanvasLayer
var _pending_cloud_room: String = ""
var _bubble_layer: CanvasLayer
var _bubble_queue: Array[Dictionary] = []
var _bubble_showing: bool = false
var _cloud_status_panel: PanelContainer
var _cloud_status_icon: Label
var _cloud_status_label: Label
var _cloud_status_bar: ProgressBar
var _cloud_status_loop: Tween
var _main_shell: HBoxContainer
var _left_sidebar: VBoxContainer
var _right_stage: VBoxContainer
var _left_top_group: VBoxContainer
var _left_bottom_group: VBoxContainer
var _stage_layout_ready: bool = false
var _info_layer: CanvasLayer
var _info_dim: ColorRect
var _info_panel: PanelContainer
var _info_title_label: Label
var _info_body_label: RichTextLabel


func _ready() -> void:
	GameAudio.play_bgm_hall()
	_setup_bubble_layer()
	_setup_info_panel_layer()
	_setup_stage_layout()
	_setup_cloud_status_panel()
	_apply_theme()
	_refresh_player_info()
	_setup_button_connections()
	_apply_touch_friendly_buttons()
	_start_online_timer()
	
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()
	
	_play_intro_animation()
	SceneTransition.fade_in()


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


func _setup_stage_layout() -> void:
	if _stage_layout_ready:
		return
	_stage_layout_ready = true
	_main_shell = HBoxContainer.new()
	_main_shell.name = "MainShell"
	_main_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_shell.add_theme_constant_override("separation", 24)
	main_container.add_child(_main_shell)
	_left_sidebar = VBoxContainer.new()
	_left_sidebar.name = "LeftSidebar"
	_left_sidebar.size_flags_horizontal = 0
	_left_sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_sidebar.add_theme_constant_override("separation", 0)
	_main_shell.add_child(_left_sidebar)
	_left_top_group = VBoxContainer.new()
	_left_top_group.name = "LeftTopGroup"
	_left_top_group.add_theme_constant_override("separation", 12)
	_left_sidebar.add_child(_left_top_group)
	var sidebar_spacer := Control.new()
	sidebar_spacer.name = "SidebarSpacer"
	sidebar_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_sidebar.add_child(sidebar_spacer)
	_left_bottom_group = VBoxContainer.new()
	_left_bottom_group.name = "LeftBottomGroup"
	_left_bottom_group.add_theme_constant_override("separation", 10)
	_left_sidebar.add_child(_left_bottom_group)
	_right_stage = VBoxContainer.new()
	_right_stage.name = "RightStage"
	_right_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_stage.add_theme_constant_override("separation", 18)
	_main_shell.add_child(_right_stage)
	_reparent_to(hero_strip, _left_top_group)
	_reparent_to(player_info_bar, _left_top_group)
	_reparent_to(features_section, _left_bottom_group)
	_reparent_to(game_modes_section, _right_stage)
	_reparent_to(footer_section, _right_stage)


func _reparent_to(node: Node, dst: Node) -> void:
	if not is_instance_valid(node) or not is_instance_valid(dst):
		return
	var src := node.get_parent()
	if src == dst:
		return
	if is_instance_valid(src):
		src.remove_child(node)
	dst.add_child(node)


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
		avatar_btn,
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
		btn.pivot_offset = btn.size * 0.5
		btn.mouse_entered.connect(func(): _on_button_hover_enter(btn))
		btn.mouse_exited.connect(func(): _on_button_hover_exit(btn))


func _on_button_hover_enter(btn: Button) -> void:
	var s := 1.03
	if btn == enter_world_btn or btn == cloud_world_btn:
		s = 1.01
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "scale", Vector2(s, s), 0.16)


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
		hero_badge_label.text = "账号已就绪" if _is_logged_in() else "游客模式"
	if is_instance_valid(brand_subtitle):
		brand_subtitle.text = "探索 · 组队 · 试炼"
	if is_instance_valid(section_hint):
		section_hint.text = "推荐先单机熟悉手感，再进入联机房间"
	recent_btn.text = "最近"
	recent_btn.tooltip_text = "查看最近访问与推荐房间"
	friends_btn.text = "好友"
	friends_btn.tooltip_text = "查看邀请码与联机组队说明"
	notice_btn.text = "公告"
	notice_btn.tooltip_text = "查看世界背景与版本更新"
	
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
	var player_bar: PanelContainer = player_info_bar
	player_bar.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(22, 0.90))

	## 游戏模式卡片 — 单机（紫色系）
	var offline_card: PanelContainer = offline_mode_card
	var off_style := UiTheme.modern_glass_card(24, 0.88)
	off_style.border_color = Color(0.616, 0.306, 0.867, 0.8)
	off_style.border_width_left = 2
	off_style.border_width_top = 2
	off_style.border_width_right = 2
	off_style.border_width_bottom = 2
	offline_card.add_theme_stylebox_override("panel", off_style)
	offline_card.clip_contents = true

	## 游戏模式卡片 — 联机（青色系）
	var cloud_card: PanelContainer = cloud_mode_card
	var cloud_style := UiTheme.modern_glass_card(24, 0.88)
	cloud_style.border_color = Color(0.0, 0.831, 1.0, 0.8)
	cloud_style.border_width_left = 2
	cloud_style.border_width_top = 2
	cloud_style.border_width_right = 2
	cloud_style.border_width_bottom = 2
	cloud_card.add_theme_stylebox_override("panel", cloud_style)
	cloud_card.clip_contents = true

	## 状态徽章
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
	
	var sidebar_w: float = clampf(screen_size.x * 0.26, 250.0, 360.0)
	if _is_mobile:
		sidebar_w = 240.0
	if is_instance_valid(_left_sidebar):
		_left_sidebar.custom_minimum_size = Vector2(sidebar_w, 0.0)
	if is_instance_valid(_main_shell):
		_main_shell.add_theme_constant_override("separation", 14 if _is_mobile else 24)
	var stage_w: float = screen_size.x - sidebar_w - 120.0
	game_modes_grid.columns = 1 if stage_w < 760.0 else 2
	
	var font_scale: float = UiTheme.responsive_ui_font_scale(screen_size)
	var title_size = int(24 * font_scale)
	var body_size := int(16 * font_scale)
	var mode_icon_size := int(30 * font_scale)
	offline_icon.add_theme_font_size_override("font_size", mode_icon_size)
	cloud_icon.add_theme_font_size_override("font_size", mode_icon_size)
	copyright_label.add_theme_font_size_override("font_size", body_size)
	var caption_size = int(14 * font_scale)
	
	player_name_label.add_theme_font_size_override("font_size", title_size)
	online_time_label.add_theme_font_size_override("font_size", caption_size)
	
	section_title.add_theme_font_size_override("font_size", int(22 * font_scale))
	if is_instance_valid(section_hint):
		section_hint.add_theme_font_size_override("font_size", int(14 * font_scale))
	if is_instance_valid(brand_title):
		brand_title.add_theme_font_size_override("font_size", int(34 * font_scale))
	if is_instance_valid(brand_subtitle):
		brand_subtitle.add_theme_font_size_override("font_size", int(15 * font_scale))
	if is_instance_valid(hero_badge_label):
		hero_badge_label.add_theme_font_size_override("font_size", int(14 * font_scale))
	
	offline_title.add_theme_font_size_override("font_size", int(19 * font_scale))
	offline_desc.add_theme_font_size_override("font_size", int(14 * font_scale))
	cloud_title.add_theme_font_size_override("font_size", int(19 * font_scale))
	cloud_desc.add_theme_font_size_override("font_size", int(14 * font_scale))
	enter_world_btn.add_theme_font_size_override("font_size", int(17 * font_scale))
	cloud_world_btn.add_theme_font_size_override("font_size", int(17 * font_scale))
	profile_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	growth_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	login_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	logout_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	if is_instance_valid(_cloud_status_label):
		_cloud_status_label.add_theme_font_size_override("font_size", int(13 * font_scale))
	if is_instance_valid(_cloud_status_icon):
		_cloud_status_icon.add_theme_font_size_override("font_size", int(15 * font_scale))
	
	var container: VBoxContainer = main_container
	var game_modes_sec: VBoxContainer = game_modes_section
	var offline_card: PanelContainer = offline_mode_card
	var cloud_card: PanelContainer = cloud_mode_card
	
	var m: Dictionary = UiTheme.responsive_main_column_margins(screen_size)
	container.offset_left = m["left"]
	container.offset_right = m["right"]
	container.offset_top = m["top"]
	container.offset_bottom = m["bottom"]
	
	var main_sep: int = 20 if screen_size.x < 640 else (24 if screen_size.x < 1100 else 28)
	container.add_theme_constant_override("separation", main_sep)
	var sec_sep: int = 14 if screen_size.x < 640 else (18 if screen_size.x < 1100 else 22)
	game_modes_sec.add_theme_constant_override("separation", sec_sep)
	hero_strip.add_theme_constant_override("separation", 12 if _is_mobile else 20)
	features_section.add_theme_constant_override("separation", 8 if _is_mobile else 10)
	var grid_h: int = 16 if screen_size.x < 640 else 24
	var grid_v: int = 16 if screen_size.x < 640 else 24
	game_modes_grid.add_theme_constant_override("h_separation", grid_h)
	game_modes_grid.add_theme_constant_override("v_separation", grid_v)
	
	if game_modes_grid.columns == 2 and stage_w >= 780.0:
		var card_min_h: float = clampf(screen_size.y * 0.23, 210.0, 400.0)
		offline_card.custom_minimum_size = Vector2(0, card_min_h)
		cloud_card.custom_minimum_size = Vector2(0, card_min_h)
	else:
		offline_card.custom_minimum_size = Vector2.ZERO
		cloud_card.custom_minimum_size = Vector2.ZERO
	if is_instance_valid(player_info_bar):
		player_info_bar.custom_minimum_size = Vector2(0.0, 88.0 if _is_mobile else 96.0)
	cloud_card.z_index = 3
	offline_card.z_index = 2
	_layout_info_panel()


func _play_intro_animation() -> void:
	var hero_strip_ctrl: Control = hero_strip
	var player_info: PanelContainer = player_info_bar
	var game_modes: VBoxContainer = game_modes_section
	var features: HBoxContainer = features_section
	
	hero_strip_ctrl.modulate.a = 0.0
	hero_strip_ctrl.position.y -= 18
	player_info.modulate.a = 0.0
	player_info.position.y -= 26
	game_modes.modulate.a = 0.0
	game_modes.position.y += 14
	features.modulate.a = 0.0
	
	var tw0 := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw0.tween_property(hero_strip_ctrl, "modulate:a", 1.0, 0.42)
	tw0.parallel().tween_property(hero_strip_ctrl, "position:y", hero_strip_ctrl.position.y + 18, 0.42)
	
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
	GameAudio.ui_confirm()
	WorldNetwork.leave_session()
	SceneTransition.transition_to(WORLD_SCENE)


func _on_cloud_world_clicked() -> void:
	GameAudio.ui_confirm()
	var room := cloud_room_edit.text.strip_edges()
	_begin_cloud_connection(room)


func _begin_cloud_connection(room: String) -> void:
	var rid := room.strip_edges()
	if rid.is_empty():
		rid = "default"
	_set_cloud_status("连接中：%s" % rid, "progress", true)
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
			_set_cloud_status("连接参数无效", "error", false)
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
	_set_cloud_status("连接成功，准备进入世界", "success", false)
	if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
		WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
	SceneTransition.transition_to(WORLD_SCENE)


func _on_cloud_failed(_reason: String) -> void:
	if not _cloud_pending:
		return
	_cloud_pending = false
	_set_cloud_status("连接失败，请检查网络", "error", false)
	_show_hall_bubble("连接失败", "云端连接失败，请检查网络或稍后重试。", false, 2.0, "error")
	if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
		WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
	WorldNetwork.leave_session()
	MoeDialogBus.show_dialog("云端连接失败", "无法连上服务器 WebSocket。请确认后端已部署 /ws/world，公网需放行该端口且反向代理支持 WebSocket 升级。")


func _on_cloud_timeout() -> void:
	if not _cloud_pending:
		return
	_cloud_pending = false
	_set_cloud_status("连接超时，请稍后重试", "warn", false)
	_show_hall_bubble("连接超时", "未收到服务器响应，请检查后重试。", false, 2.0, "warn")
	if WorldNetwork.cloud_ready.is_connected(_on_cloud_ready):
		WorldNetwork.cloud_ready.disconnect(_on_cloud_ready)
	if WorldNetwork.cloud_connection_failed.is_connected(_on_cloud_failed):
		WorldNetwork.cloud_connection_failed.disconnect(_on_cloud_failed)
	WorldNetwork.leave_session()
	MoeDialogBus.show_dialog("云端超时", "长时间未收到服务器欢迎包，请检查网络与 token。")


func _on_recent_clicked() -> void:
	UiTheme.pulse(recent_btn)
	var uname := _saved_username()
	if uname.is_empty():
		uname = "萌酱"
	var room := cloud_room_edit.text.strip_edges()
	if room.is_empty():
		room = "default"
	var mins: int = int(floor(float(_online_time_seconds) / 60.0))
	_open_info_panel(
		"最近访问",
		"玩家：%s\n本次在线：%d 分钟\n推荐联机房间：%s\n上次玩法：大世界探索 / 试炼挑战" % [uname, mins, room],
	)


func _on_friends_clicked() -> void:
	UiTheme.pulse(friends_btn)
	var invite := _build_invite_code()
	_open_info_panel(
		"好友与组队",
		"邀请码：%s\n与好友输入同一联机房间名即可同屏。\n示例：在房间名输入「party_%s」后一起进入云端世界。" % [invite, invite],
	)


func _on_notice_clicked() -> void:
	UiTheme.pulse(notice_btn)
	_open_info_panel(
		"世界观与版本公告",
		"【世界背景】\n%s\n\n【当前版本重点】\n- 试炼评级影响材料收益\n- 世界怪物新增多样化掉落\n- 成长面板加入材料强化入口" % STORY_BRIEF,
	)


func _on_profile_clicked() -> void:
	UiTheme.pulse(profile_btn)
	GameAudio.ui_click()
	SceneTransition.transition_to("res://Scenes/ui/ProfileScene.tscn")


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


func _saved_username() -> String:
	if not ProjectSettings.has_setting("moe_world/current_user"):
		return ""
	var v: Variant = ProjectSettings.get_setting("moe_world/current_user")
	if not (v is Dictionary):
		return ""
	return str((v as Dictionary).get("username", "")).strip_edges()


func _build_invite_code() -> String:
	if not ProjectSettings.has_setting("moe_world/current_user"):
		return "MOE777"
	var v: Variant = ProjectSettings.get_setting("moe_world/current_user")
	if not (v is Dictionary):
		return "MOE777"
	var uid := str((v as Dictionary).get("id", "")).strip_edges()
	if uid.is_empty():
		uid = str((v as Dictionary).get("moe_no", "")).strip_edges()
	if uid.is_empty():
		uid = "777"
	return "MOE%s" % uid


func _setup_bubble_layer() -> void:
	if is_instance_valid(_bubble_layer):
		return
	_bubble_layer = CanvasLayer.new()
	_bubble_layer.layer = 90
	add_child(_bubble_layer)


func _setup_info_panel_layer() -> void:
	if is_instance_valid(_info_layer):
		return
	_info_layer = CanvasLayer.new()
	_info_layer.layer = 110
	add_child(_info_layer)
	_info_dim = ColorRect.new()
	_info_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_info_dim.color = Color(0.02, 0.02, 0.05, 0.58)
	_info_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_info_dim.visible = false
	_info_dim.gui_input.connect(_on_info_dim_gui_input)
	_info_layer.add_child(_info_dim)
	_info_panel = PanelContainer.new()
	_info_panel.name = "HallInfoPanel"
	_info_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_info_panel.visible = false
	_info_panel.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(22, 0.97))
	_info_layer.add_child(_info_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	_info_panel.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vb.add_child(header)
	_info_title_label = Label.new()
	_info_title_label.text = "信息"
	_info_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_title_label.add_theme_font_size_override("font_size", 24)
	_info_title_label.add_theme_color_override("font_color", Color(0.98, 0.94, 1.0, 1.0))
	header.add_child(_info_title_label)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(92, 38)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(_hide_info_panel)
	header.add_child(close_btn)
	vb.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	_info_body_label = RichTextLabel.new()
	_info_body_label.bbcode_enabled = false
	_info_body_label.fit_content = false
	_info_body_label.scroll_active = false
	_info_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_body_label.add_theme_font_size_override("normal_font_size", 16)
	_info_body_label.add_theme_color_override("default_color", Color(0.90, 0.86, 0.96, 0.97))
	scroll.add_child(_info_body_label)
	_layout_info_panel()


func _layout_info_panel() -> void:
	if not is_instance_valid(_info_panel):
		return
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var panel_w: float = clampf(screen_size.x * (0.92 if _is_mobile else 0.62), 360.0, 860.0)
	var panel_h: float = clampf(screen_size.y * (0.78 if _is_mobile else 0.66), 280.0, 620.0)
	_info_panel.set_anchors_preset(Control.PRESET_CENTER)
	_info_panel.offset_left = -panel_w * 0.5
	_info_panel.offset_right = panel_w * 0.5
	_info_panel.offset_top = -panel_h * 0.5
	_info_panel.offset_bottom = panel_h * 0.5


func _open_info_panel(title: String, content: String) -> void:
	if not is_instance_valid(_info_panel):
		_setup_info_panel_layer()
	_info_title_label.text = title
	_info_body_label.text = content
	_info_dim.visible = true
	_info_panel.visible = true


func _hide_info_panel() -> void:
	if is_instance_valid(_info_dim):
		_info_dim.visible = false
	if is_instance_valid(_info_panel):
		_info_panel.visible = false


func _on_info_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_hide_info_panel()


func _show_hall_bubble(title: String, message: String, show_progress: bool = false, hold_sec: float = 2.8, bubble_type: String = "info") -> void:
	if _bubble_queue.size() >= HALL_BUBBLE_QUEUE_LIMIT:
		_bubble_queue.pop_front()
	_bubble_queue.append({
		"title": title,
		"message": message,
		"show_progress": show_progress,
		"hold_sec": hold_sec,
		"type": bubble_type
	})
	_try_show_next_bubble()


func _try_show_next_bubble() -> void:
	if _bubble_showing or _bubble_queue.is_empty():
		return
	_bubble_showing = true
	var item: Dictionary = _bubble_queue.pop_front()
	if not is_instance_valid(_bubble_layer):
		_setup_bubble_layer()
	var bubble := PanelContainer.new()
	bubble.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bubble.offset_left = -420.0
	bubble.offset_top = 94.0
	bubble.offset_right = -20.0
	bubble.offset_bottom = 260.0
	bubble.modulate.a = 0.0
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var typ := str(item.get("type", "info"))
	var style := UiTheme.modern_glass_card(18, 0.96)
	style.border_color = _bubble_accent_color(typ)
	style.set_border_width_all(2)
	bubble.add_theme_stylebox_override("panel", style)
	_bubble_layer.add_child(bubble)
	bubble.z_index = 220
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(vb)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(header)
	var icon := Label.new()
	icon.text = _bubble_type_icon(typ)
	icon.add_theme_font_size_override("font_size", 18)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(icon)
	var t := Label.new()
	t.text = str(item.get("title", "通知"))
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", Color(0.98, 0.95, 1.0, 1.0))
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(t)
	var m := Label.new()
	m.text = str(item.get("message", ""))
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m.add_theme_font_size_override("font_size", 14)
	m.add_theme_color_override("font_color", Color(0.88, 0.84, 0.95, 0.96))
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(m)
	if bool(item.get("show_progress", false)):
		var pb := ProgressBar.new()
		pb.min_value = 0.0
		pb.max_value = 100.0
		pb.value = 20.0
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(360.0, 12.0)
		pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(pb)
		var tw_pb := create_tween().set_loops()
		tw_pb.tween_property(pb, "value", 86.0, 0.55)
		tw_pb.tween_property(pb, "value", 34.0, 0.55)
		pb.set_meta("loop_tw", tw_pb)
	var tw := create_tween()
	tw.tween_property(bubble, "offset_top", 84.0, 0.18).from(116.0)
	tw.parallel().tween_property(bubble, "modulate:a", 1.0, 0.18)
	tw.tween_interval(float(item.get("hold_sec", 2.8)))
	tw.tween_property(bubble, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func() -> void:
		if is_instance_valid(bubble):
			for c in bubble.get_children():
				if c is VBoxContainer:
					for cc in (c as VBoxContainer).get_children():
						if cc is ProgressBar and cc.has_meta("loop_tw"):
							var loop_tw: Variant = cc.get_meta("loop_tw")
							if loop_tw is Tween and (loop_tw as Tween).is_valid():
								(loop_tw as Tween).kill()
			bubble.queue_free()
		_bubble_showing = false
		_try_show_next_bubble()
	)


func _bubble_type_icon(t: String) -> String:
	match t:
		"success":
			return "✓"
		"warn":
			return "!"
		"error":
			return "×"
		"social":
			return "👥"
		"notice":
			return "📣"
		"progress":
			return "↻"
		_:
			return "•"


func _bubble_accent_color(t: String) -> Color:
	match t:
		"success":
			return Color(0.31, 0.85, 0.60, 0.88)
		"warn":
			return Color(0.98, 0.74, 0.34, 0.88)
		"error":
			return Color(0.98, 0.42, 0.42, 0.9)
		"social":
			return Color(0.40, 0.72, 1.0, 0.88)
		"notice":
			return Color(0.85, 0.58, 1.0, 0.88)
		"progress":
			return Color(0.39, 0.84, 1.0, 0.88)
		"idle":
			return Color(0.66, 0.74, 0.92, 0.82)
		_:
			return Color(0.63, 0.37, 0.88, 0.84)


func _setup_cloud_status_panel() -> void:
	if not is_instance_valid(cloud_card_content):
		return
	if is_instance_valid(_cloud_status_panel):
		return
	_cloud_status_panel = PanelContainer.new()
	_cloud_status_panel.name = "CloudStatusPanel"
	_cloud_status_panel.custom_minimum_size = Vector2(0.0, 54.0)
	_cloud_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.14, 0.26, 0.72)
	style.border_color = Color(0.40, 0.72, 1.0, 0.52)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	_cloud_status_panel.add_theme_stylebox_override("panel", style)
	cloud_card_content.add_child(_cloud_status_panel)
	cloud_card_content.move_child(_cloud_status_panel, maxi(0, cloud_card_content.get_child_count() - 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cloud_status_panel.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header)
	_cloud_status_icon = Label.new()
	_cloud_status_icon.text = "○"
	_cloud_status_icon.add_theme_font_size_override("font_size", 15)
	_cloud_status_icon.add_theme_color_override("font_color", Color(0.75, 0.84, 0.98, 0.94))
	_cloud_status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_cloud_status_icon)
	_cloud_status_label = Label.new()
	_cloud_status_label.text = "待连接：输入房间后可开始联机"
	_cloud_status_label.add_theme_font_size_override("font_size", 13)
	_cloud_status_label.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 0.94))
	_cloud_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cloud_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_cloud_status_label)
	_cloud_status_bar = ProgressBar.new()
	_cloud_status_bar.min_value = 0.0
	_cloud_status_bar.max_value = 100.0
	_cloud_status_bar.value = 0.0
	_cloud_status_bar.show_percentage = false
	_cloud_status_bar.custom_minimum_size = Vector2(0.0, 8.0)
	_cloud_status_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_cloud_status_bar)
	_set_cloud_status("待连接：输入房间后可开始联机", "idle", false)


func _set_cloud_status(status: String, state: String, show_progress: bool) -> void:
	if not is_instance_valid(_cloud_status_panel):
		return
	if is_instance_valid(_cloud_status_label):
		_cloud_status_label.text = status
	if is_instance_valid(_cloud_status_icon):
		_cloud_status_icon.text = _cloud_status_icon_text(state)
		_cloud_status_icon.add_theme_color_override("font_color", _bubble_accent_color(state))
	var sb := _cloud_status_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if is_instance_valid(sb):
		sb.border_color = _bubble_accent_color(state).lerp(Color(1, 1, 1, 0.2), 0.28)
	if is_instance_valid(_cloud_status_bar):
		_cloud_status_bar.visible = show_progress
		if show_progress:
			_cloud_status_bar.value = 16.0
			if is_instance_valid(_cloud_status_loop):
				_cloud_status_loop.kill()
			_cloud_status_loop = create_tween().set_loops()
			_cloud_status_loop.tween_property(_cloud_status_bar, "value", 84.0, 0.52)
			_cloud_status_loop.tween_property(_cloud_status_bar, "value", 28.0, 0.52)
		else:
			if is_instance_valid(_cloud_status_loop):
				_cloud_status_loop.kill()
			_cloud_status_loop = null
			_cloud_status_bar.value = 0.0


func _cloud_status_icon_text(state: String) -> String:
	match state:
		"success":
			return "✓"
		"warn":
			return "!"
		"error":
			return "×"
		"progress":
			return "↻"
		"idle":
			return "○"
		_:
			return "•"
