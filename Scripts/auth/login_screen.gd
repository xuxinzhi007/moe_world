extends Control

signal login_success()
## 弹层关闭（未登录成功时点击「返回大厅」）
signal overlay_closed()

@onready var main_card: PanelContainer = $SafeArea/MainScroller/MainCenter/MainCard
@onready var title_main: Label = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/TitleArea/TitleMain
@onready var title_sub: Label = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/TitleArea/TitleSub
@onready var username_input: LineEdit = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/InputArea/UsernameWrapper/UsernameInput
@onready var password_input: LineEdit = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/InputArea/PasswordWrapper/PasswordInput
@onready var login_btn: Button = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/LoginBtn
@onready var register_btn: Button = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/BottomLinks/RegisterBtn
@onready var forget_pwd_btn: Button = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/BottomLinks/ForgetPwdBtn
@onready var toast_panel: Panel = $ToastPanel
@onready var toast_label: Label = $ToastPanel/ToastLabel
@onready var auth_service: Node = $AuthService
@onready var server_status_strip: Panel = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/ServerStatusStrip
@onready var status_dot: Panel = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/ServerStatusStrip/ServerStatusBar/StatusDot
@onready var status_label: Label = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/ServerStatusStrip/ServerStatusBar/StatusLabel
@onready var bg_gradient: ColorRect = $BgGradient
@onready var username_wrapper: PanelContainer = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/InputArea/UsernameWrapper
@onready var password_wrapper: PanelContainer = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/InputArea/PasswordWrapper
@onready var back_to_hall_btn: Button = $TopBar/TopBarContent/BackToHallBtn
@onready var top_hint: Label = $TopBar/TopBarContent/TopHint
@onready var safe_area: MarginContainer = $SafeArea
@onready var main_scroller: ScrollContainer = $SafeArea/MainScroller
@onready var main_center: CenterContainer = $SafeArea/MainScroller/MainCenter
@onready var hero_banner: PanelContainer = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/HeroBanner
@onready var hero_title: Label = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/HeroBanner/HeroContent/HeroTitle
@onready var hero_subtitle: Label = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/HeroBanner/HeroContent/HeroSubtitle
@onready var hero_feature_a: Label = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/HeroBanner/HeroContent/FeatureRow/FeatureA
@onready var hero_feature_b: Label = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/HeroBanner/HeroContent/FeatureRow/FeatureB
@onready var hero_feature_c: Label = $SafeArea/MainScroller/MainCenter/MainCard/CardContent/HeroBanner/HeroContent/FeatureRow/FeatureC

var is_login_mode: bool = true
var is_processing_request: bool = false
var api_ready: bool = false

var username_focused: bool = false
var password_focused: bool = false
var login_btn_hovered: bool = false

var gradient_offset: float = 0.0
var _toast_tween: Tween
var _toast_version: int = 0

## 由大厅以弹层方式实例化时设为 true（须在加入场景树之前赋值）
var overlay_mode: bool = false

const AuthService = preload("res://Scripts/auth/auth_service.gd")
const UiTheme := preload("res://Scripts/meta/ui_theme.gd")

func _ready() -> void:
	_apply_theme()
	_update_back_button_text()
	
	auth_service.login_success.connect(_on_login_success)
	auth_service.login_failed.connect(_on_login_failed)
	auth_service.register_success.connect(_on_register_success)
	auth_service.register_failed.connect(_on_register_failed)
	auth_service.config_fetched.connect(_on_config_fetched)
	auth_service.config_failed.connect(_on_config_failed)
	auth_service.server_status_changed.connect(_on_server_status_changed)
	
	if AuthService.global_has_fetched_config:
		api_ready = true
		_set_processing_request(false)
		print("🔄 登录页面：使用已缓存的配置")
	else:
		_set_processing_request(true)
		_show_message("正在连接服务器...", false, 0.0)
	
	login_btn.pressed.connect(_on_login_clicked)
	register_btn.pressed.connect(_on_register_clicked)
	forget_pwd_btn.pressed.connect(_on_forget_pwd_clicked)
	back_to_hall_btn.pressed.connect(_on_back_to_hall_pressed)
	
	username_input.text_submitted.connect(_focus_to_password)
	password_input.text_submitted.connect(_on_login_clicked)
	
	username_input.focus_entered.connect(_on_username_focus_enter)
	username_input.focus_exited.connect(_on_username_focus_exit)
	password_input.focus_entered.connect(_on_password_focus_enter)
	password_input.focus_exited.connect(_on_password_focus_exit)
	
	login_btn.mouse_entered.connect(_on_login_btn_hover_enter)
	login_btn.mouse_exited.connect(_on_login_btn_hover_exit)
	
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()
	
	_play_intro_animation()
	if not overlay_mode:
		SceneTransition.fade_in()


func _update_back_button_text() -> void:
	back_to_hall_btn.text = "关闭登录" if overlay_mode else "返回大厅"


func _on_back_to_hall_pressed() -> void:
	GameAudio.ui_click()
	if overlay_mode:
		overlay_closed.emit()
		return
	SceneTransition.transition_to("res://Scenes/ui/HallScene.tscn")


func _process(delta: float) -> void:
	gradient_offset += delta * 0.04
	if gradient_offset > 1.0:
		gradient_offset = 0.0
	var t := gradient_offset
	## 深紫 ↔ 深蓝 暗色游戏风背景
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


func _play_intro_animation() -> void:
	main_card.modulate.a = 0.0
	main_card.position.y += 50
	title_main.modulate.a = 0.0
	title_sub.modulate.a = 0.0
	username_wrapper.modulate.a = 0.0
	password_wrapper.modulate.a = 0.0
	login_btn.modulate.a = 0.0
	
	await get_tree().create_timer(0.2).timeout
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(main_card, "modulate:a", 1.0, 0.5)
	tween.tween_property(main_card, "position:y", main_card.position.y - 50, 0.5)
	
	await get_tree().create_timer(0.3).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(title_main, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.15).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(title_sub, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.15).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(username_wrapper, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.1).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(password_wrapper, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.1).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(login_btn, "modulate:a", 1.0, 0.4)

func _on_window_resized() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var pad_x: float = clampf(screen_size.x * 0.03, 14.0, 64.0)
	var pad_top: float = clampf(screen_size.y * 0.06, 74.0, 120.0)
	safe_area.offset_left = pad_x
	safe_area.offset_right = -pad_x
	safe_area.offset_top = pad_top
	safe_area.offset_bottom = -clampf(screen_size.y * 0.03, 12.0, 42.0)

	var card_width: float = clampf(screen_size.x * 0.72, 340.0, 980.0)
	if screen_size.x < 760.0:
		card_width = maxf(320.0, screen_size.x - pad_x * 2.0 - 8.0)
	var card_height: float = clampf(screen_size.y * 0.76, 580.0, 840.0)
	main_card.custom_minimum_size = Vector2(card_width, card_height)
	main_center.custom_minimum_size = Vector2(maxf(320.0, card_width), maxf(card_height + 24.0, screen_size.y - pad_top))
	main_scroller.scroll_horizontal = 0
	var toast_width: float = clampf(card_width * 0.78, 320.0, 760.0)
	var toast_side_margin: float = (screen_size.x - toast_width) * 0.5
	toast_panel.offset_left = toast_side_margin
	toast_panel.offset_right = -toast_side_margin
	
	var font_scale: float = UiTheme.responsive_ui_font_scale(screen_size)
	var compact: bool = screen_size.x < 760.0
	var title_size = int((44 if compact else 50) * font_scale)
	var sub_size = int((17 if compact else 20) * font_scale)
	var input_size = int((18 if compact else 20) * font_scale)
	var btn_size = int((20 if compact else 22) * font_scale)
	
	title_main.add_theme_font_size_override("font_size", title_size)
	title_sub.add_theme_font_size_override("font_size", sub_size)
	top_hint.add_theme_font_size_override("font_size", int(14 * font_scale))
	top_hint.visible = not compact
	back_to_hall_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	hero_title.add_theme_font_size_override("font_size", int((26 if compact else 30) * font_scale))
	hero_subtitle.add_theme_font_size_override("font_size", int((14 if compact else 16) * font_scale))
	hero_feature_a.add_theme_font_size_override("font_size", int(13 * font_scale))
	hero_feature_b.add_theme_font_size_override("font_size", int(13 * font_scale))
	hero_feature_c.add_theme_font_size_override("font_size", int(13 * font_scale))
	hero_feature_c.visible = not compact
	username_input.add_theme_font_size_override("font_size", input_size)
	password_input.add_theme_font_size_override("font_size", input_size)
	login_btn.add_theme_font_size_override("font_size", btn_size)
	register_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	forget_pwd_btn.add_theme_font_size_override("font_size", int(16 * font_scale))
	toast_label.add_theme_font_size_override("font_size", int(20 * font_scale))
	status_label.add_theme_font_size_override("font_size", int(16 * font_scale))

func _on_username_focus_enter() -> void:
	username_focused = true
	_animate_input_wrapper(username_wrapper, true)

func _on_username_focus_exit() -> void:
	username_focused = false
	_animate_input_wrapper(username_wrapper, false)

func _on_password_focus_enter() -> void:
	password_focused = true
	_animate_input_wrapper(password_wrapper, true)

func _on_password_focus_exit() -> void:
	password_focused = false
	_animate_input_wrapper(password_wrapper, false)

func _animate_input_wrapper(wrapper: PanelContainer, _focused: bool) -> void:
	# 输入框焦点放大在窄布局会导致边缘溢出，这里保持尺寸稳定。
	wrapper.scale = Vector2.ONE

func _on_login_btn_hover_enter() -> void:
	login_btn_hovered = true
	# 使用主题高亮，不再缩放按钮，避免选中态超出容器。
	login_btn.scale = Vector2.ONE

func _on_login_btn_hover_exit() -> void:
	login_btn_hovered = false
	login_btn.scale = Vector2.ONE

func _apply_theme() -> void:
	var theme_obj := Theme.new()

	theme_obj.set_stylebox("normal",   "LineEdit", UiTheme.modern_line_edit_normal(16))
	theme_obj.set_stylebox("read_only","LineEdit", UiTheme.modern_line_edit_normal(16))
	theme_obj.set_stylebox("focus",    "LineEdit", UiTheme.modern_line_edit_focus(16))
	theme_obj.set_stylebox("normal",   "Button",   UiTheme.modern_primary_button_normal(20))
	theme_obj.set_stylebox("hover",    "Button",   UiTheme.modern_primary_button_hover(20))
	theme_obj.set_stylebox("pressed",  "Button",   UiTheme.modern_primary_button_pressed(20))
	theme_obj.set_stylebox("focus",    "Button",   UiTheme.modern_primary_button_hover(20))
	theme_obj.set_stylebox("panel",    "PanelContainer", UiTheme.modern_glass_card(32, 0.94))

	theme_obj.set_color("font_color",             "Button",  UiTheme.Colors.TEXT_LIGHT)
	theme_obj.set_color("font_color",             "Label",   UiTheme.Colors.TEXT_MAIN)
	theme_obj.set_color("font_color",             "LineEdit", UiTheme.Colors.TEXT_MAIN)
	theme_obj.set_color("caret_color",            "LineEdit", UiTheme.Colors.ACCENT_PINK)
	theme_obj.set_color("selection_color",        "LineEdit",
		Color(UiTheme.Colors.ACCENT_PINK.r, UiTheme.Colors.ACCENT_PINK.g, UiTheme.Colors.ACCENT_PINK.b, 0.35))
	theme_obj.set_color("placeholder_font_color", "LineEdit", UiTheme.Colors.TEXT_MUTED)

	title_main.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_sub.autowrap_mode  = TextServer.AUTOWRAP_WORD_SMART
	title_main.add_theme_font_size_override("font_size", 54)
	title_main.add_theme_color_override("font_color", UiTheme.Colors.ACCENT_PINK)
	title_sub.add_theme_font_size_override("font_size", 22)
	title_sub.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MUTED)
	hero_title.add_theme_color_override("font_color", Color(0.98, 0.95, 1.0, 1.0))
	hero_subtitle.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MUTED)
	for lb: Label in [hero_feature_a, hero_feature_b, hero_feature_c]:
		lb.add_theme_color_override("font_color", Color(0.80, 0.74, 0.95, 1.0))

	username_input.add_theme_font_size_override("font_size", 20)
	password_input.add_theme_font_size_override("font_size", 20)
	login_btn.add_theme_font_size_override("font_size", 24)
	forget_pwd_btn.add_theme_font_size_override("font_size", 16)
	register_btn.add_theme_font_size_override("font_size", 16)

	var flat_clear := StyleBoxEmpty.new()
	forget_pwd_btn.flat = true
	register_btn.flat   = true
	for b: Button in [forget_pwd_btn, register_btn]:
		b.add_theme_stylebox_override("normal",  flat_clear)
		b.add_theme_stylebox_override("hover",   flat_clear)
		b.add_theme_stylebox_override("pressed", flat_clear)
		b.add_theme_stylebox_override("focus",   flat_clear)
		b.add_theme_color_override("font_color",         UiTheme.Colors.ACCENT_PINK)
		b.add_theme_color_override("font_hover_color",   UiTheme.Colors.PRIMARY_LIGHT)
		b.add_theme_color_override("font_pressed_color", UiTheme.Colors.PRIMARY_LIGHT)

	toast_label.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MAIN)
	toast_label.add_theme_font_size_override("font_size", 20)

	var toast_bg := StyleBoxFlat.new()
	toast_bg.bg_color = Color(0.118, 0.082, 0.251, 0.96)
	toast_bg.border_color = UiTheme.Colors.PRIMARY
	toast_bg.set_border_width_all(1)
	toast_bg.corner_radius_top_left    = 22
	toast_bg.corner_radius_top_right   = 22
	toast_bg.corner_radius_bottom_left = 22
	toast_bg.corner_radius_bottom_right = 22
	toast_panel.add_theme_stylebox_override("panel", toast_bg)

	status_label.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MUTED)
	status_label.add_theme_font_size_override("font_size", 16)

	server_status_strip.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(18, 0.78))
	_apply_status_dot_color(UiTheme.Colors.TEXT_MUTED)
	main_card.add_theme_stylebox_override("panel", UiTheme.modern_glass_card(30, 0.95))
	var hero_style := UiTheme.modern_glass_card(24, 0.72)
	hero_style.border_color = Color(0.42, 0.65, 1.0, 0.45)
	hero_banner.add_theme_stylebox_override("panel", hero_style)

	var back_btn_normal := StyleBoxFlat.new()
	back_btn_normal.bg_color = Color(0.12, 0.10, 0.24, 0.9)
	back_btn_normal.border_color = Color(0.45, 0.38, 0.75, 0.8)
	back_btn_normal.set_border_width_all(1)
	back_btn_normal.corner_radius_top_left = 16
	back_btn_normal.corner_radius_top_right = 16
	back_btn_normal.corner_radius_bottom_left = 16
	back_btn_normal.corner_radius_bottom_right = 16
	back_btn_normal.content_margin_left = 16
	back_btn_normal.content_margin_top = 10
	back_btn_normal.content_margin_right = 16
	back_btn_normal.content_margin_bottom = 10
	var back_btn_hover := back_btn_normal.duplicate()
	(back_btn_hover as StyleBoxFlat).bg_color = Color(0.18, 0.14, 0.34, 0.95)
	var back_btn_pressed := back_btn_normal.duplicate()
	(back_btn_pressed as StyleBoxFlat).bg_color = Color(0.08, 0.07, 0.18, 0.96)
	back_to_hall_btn.add_theme_stylebox_override("normal", back_btn_normal)
	back_to_hall_btn.add_theme_stylebox_override("hover", back_btn_hover)
	back_to_hall_btn.add_theme_stylebox_override("pressed", back_btn_pressed)
	back_to_hall_btn.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MAIN)
	top_hint.add_theme_color_override("font_color", UiTheme.Colors.TEXT_MUTED)

	self.theme = theme_obj

	var wrapper_panel := UiTheme.modern_line_edit_normal(16)
	username_wrapper.add_theme_stylebox_override("panel", wrapper_panel)
	password_wrapper.add_theme_stylebox_override("panel", wrapper_panel.duplicate())

	## 背景色节点（BgColor ColorRect）
	if has_node("BgColor"):
		($BgColor as ColorRect).color = UiTheme.Colors.BG_DEEP

func _on_config_fetched(_url: String) -> void:
	api_ready = true
	_set_processing_request(false)
	_hide_message()
	_show_message("已连接到服务器！", false)
	await get_tree().create_timer(0.5).timeout
	_hide_message()

func _on_config_failed(_error: String) -> void:
	api_ready = true
	_set_processing_request(false)
	_show_message("无法连接到服务器，请检查后端是否启动", true, 0.0)

func _apply_status_dot_color(c: Color) -> void:
	var dot := StyleBoxFlat.new()
	dot.bg_color = c
	dot.corner_radius_top_left = 7
	dot.corner_radius_top_right = 7
	dot.corner_radius_bottom_left = 7
	dot.corner_radius_bottom_right = 7
	status_dot.add_theme_stylebox_override("panel", dot)


func _on_server_status_changed(is_online: bool) -> void:
	status_label.modulate = Color.WHITE
	if is_online:
		_apply_status_dot_color(Color8(46, 204, 113))
		status_label.text = "服务器在线"
		status_label.add_theme_color_override("font_color", Color8(34, 150, 72))
		if is_processing_request:
			api_ready = true
			_set_processing_request(false)
			_hide_message()
			_show_message("已连接到服务器！", false)
			await get_tree().create_timer(0.5).timeout
			_hide_message()
	else:
		_apply_status_dot_color(Color8(235, 87, 87))
		status_label.text = "服务器离线"
		status_label.add_theme_color_override("font_color", Color8(200, 65, 75))
		if is_processing_request:
			api_ready = true
			_set_processing_request(false)
			_show_message("无法连接到服务器，请检查后端是否启动", true, 0.0)

func _show_message(message: String, is_error: bool = false, auto_hide_sec: float = 2.2) -> void:
	_toast_version += 1
	var local_version := _toast_version
	if is_instance_valid(_toast_tween):
		_toast_tween.kill()
		_toast_tween = null
	toast_label.text = message
	toast_label.remove_theme_color_override("font_color")
	if is_error:
		toast_label.add_theme_color_override("font_color", Color8(210, 55, 85))
	else:
		toast_label.add_theme_color_override("font_color", Color8(40, 145, 75))
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	toast_label.modulate.a = 0.0
	_toast_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_toast_tween.set_parallel(true)
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.18)
	_toast_tween.tween_property(toast_label, "modulate:a", 1.0, 0.18)
	
	if auto_hide_sec > 0.0:
		await get_tree().create_timer(auto_hide_sec).timeout
		if local_version == _toast_version:
			_hide_message(true)

func _hide_message(animated: bool = false) -> void:
	_toast_version += 1
	if is_instance_valid(_toast_tween):
		_toast_tween.kill()
		_toast_tween = null
	if not animated:
		toast_panel.visible = false
		toast_panel.modulate.a = 1.0
		toast_label.modulate.a = 1.0
		toast_label.remove_theme_color_override("font_color")
		return
	_toast_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_toast_tween.set_parallel(true)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.2)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.2)
	_toast_tween.tween_callback(func() -> void:
		toast_panel.visible = false
		toast_panel.modulate.a = 1.0
		toast_label.modulate.a = 1.0
	)
	toast_label.remove_theme_color_override("font_color")

func _set_processing_request(processing: bool) -> void:
	is_processing_request = processing
	username_input.editable = not processing
	password_input.editable = not processing
	login_btn.disabled = processing
	register_btn.disabled = processing
	forget_pwd_btn.disabled = processing

func _on_login_clicked() -> void:
	if not api_ready:
		_show_message("正在连接服务器，请稍候...", true)
		return
	
	var input_text = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if input_text.is_empty() or password.is_empty():
		_show_message("请输入用户名（或邮箱）和密码！", true)
		return
	
	var username = ""
	var email = ""
	
	if input_text.contains("@"):
		email = input_text
		print("📧 检测到邮箱登录: %s" % email)
	else:
		username = input_text
		print("👤 检测到用户名登录: %s" % username)
	
	_hide_message()
	_set_processing_request(true)
	auth_service.login(username, password, email)

func _on_register_clicked() -> void:
	if is_processing_request:
		return
	SceneTransition.transition_to("res://Scenes/ui/RegisterScreen.tscn")

func _on_forget_pwd_clicked() -> void:
	print("🔑 跳转忘记密码界面")
	_show_message("忘记密码功能开发中...", false)

func _focus_to_password() -> void:
	password_input.grab_focus()

func _on_login_success(token: String, user_data: Dictionary) -> void:
	_set_processing_request(false)
	GameAudio.ui_confirm()
	user_data["token"] = token
	UserStorage.set_api_base_url(auth_service.api_base_url)
	UserStorage.set_session_login_unix(int(Time.get_unix_time_from_system()))
	var name_hint := str(user_data.get("username", "")).strip_edges()
	var tip := "登录成功！欢迎回来～" if name_hint.is_empty() else ("登录成功！欢迎，%s" % name_hint)
	_show_message(tip, false)
	await get_tree().create_timer(1.6).timeout
	UserStorage.set_current_user(user_data)
	UserStorage.persist_current_session()
	login_success.emit()
	if not overlay_mode:
		SceneTransition.transition_to("res://Scenes/ui/HallScene.tscn")

func _on_login_failed(error: String) -> void:
	_set_processing_request(false)
	_show_message(error, true)

func _on_register_success(user_data: Dictionary) -> void:
	_set_processing_request(false)
	GameAudio.ui_confirm()
	var username = user_data.get("username", "用户")
	_show_message("注册成功！%s，请登录" % username, false)

func _on_register_failed(error: String) -> void:
	_set_processing_request(false)
	_show_message(error, true)
