extends Control

signal login_success()
## 弹层关闭（未登录成功时点击「返回大厅」）
signal overlay_closed()

@onready var main_card: PanelContainer = $MainCard
@onready var title_main: Label = $MainCard/CardContent/TitleArea/TitleMain
@onready var title_sub: Label = $MainCard/CardContent/TitleArea/TitleSub
@onready var username_input: LineEdit = $MainCard/CardContent/InputArea/UsernameWrapper/UsernameInput
@onready var password_input: LineEdit = $MainCard/CardContent/InputArea/PasswordWrapper/PasswordInput
@onready var login_btn: Button = $MainCard/CardContent/LoginBtn
@onready var register_btn: Button = $MainCard/CardContent/BottomLinks/RegisterBtn
@onready var forget_pwd_btn: Button = $MainCard/CardContent/BottomLinks/ForgetPwdBtn
@onready var toast_panel: Panel = $ToastPanel
@onready var toast_label: Label = $ToastPanel/ToastLabel
@onready var auth_service: Node = $AuthService
@onready var server_status_strip: Panel = $ServerStatusStrip
@onready var status_dot: Panel = $ServerStatusStrip/ServerStatusBar/StatusDot
@onready var status_label: Label = $ServerStatusStrip/ServerStatusBar/StatusLabel
@onready var bg_gradient: ColorRect = $BgGradient
@onready var username_wrapper: PanelContainer = $MainCard/CardContent/InputArea/UsernameWrapper
@onready var password_wrapper: PanelContainer = $MainCard/CardContent/InputArea/PasswordWrapper

var is_login_mode: bool = true
var is_processing_request: bool = false
var api_ready: bool = false

var username_focused: bool = false
var password_focused: bool = false
var login_btn_hovered: bool = false

var gradient_offset: float = 0.0

## 由大厅以弹层方式实例化时设为 true（须在加入场景树之前赋值）
var overlay_mode: bool = false

const AuthService = preload("res://Scripts/auth_service.gd")
const UiTheme := preload("res://Scripts/ui_theme.gd")

func _ready() -> void:
	if overlay_mode:
		_setup_overlay_chrome()
	_apply_theme()
	
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
		_show_message("正在连接服务器...", false)
	
	login_btn.pressed.connect(_on_login_clicked)
	register_btn.pressed.connect(_on_register_clicked)
	forget_pwd_btn.pressed.connect(_on_forget_pwd_clicked)
	
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


func _setup_overlay_chrome() -> void:
	var close_btn := Button.new()
	close_btn.name = "OverlayCloseBtn"
	close_btn.text = "返回大厅"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	close_btn.offset_left = 20.0
	close_btn.offset_top = 20.0
	close_btn.offset_right = 20.0 + 132.0
	close_btn.offset_bottom = 20.0 + 44.0
	close_btn.z_index = 50
	close_btn.pressed.connect(_on_overlay_back_pressed)
	add_child(close_btn)


func _on_overlay_back_pressed() -> void:
	overlay_closed.emit()


func _process(delta: float) -> void:
	gradient_offset += delta * 0.1
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
	var he: Vector2 = UiTheme.responsive_auth_card_half_extents(screen_size, false)
	main_card.offset_left = -he.x
	main_card.offset_right = he.x
	main_card.offset_top = -he.y
	main_card.offset_bottom = he.y
	
	var font_scale: float = UiTheme.responsive_ui_font_scale(screen_size)
	var title_size = int(56 * font_scale)
	var sub_size = int(24 * font_scale)
	var input_size = int(20 * font_scale)
	var btn_size = int(24 * font_scale)
	
	title_main.add_theme_font_size_override("font_size", title_size)
	title_sub.add_theme_font_size_override("font_size", sub_size)
	username_input.add_theme_font_size_override("font_size", input_size)
	password_input.add_theme_font_size_override("font_size", input_size)
	login_btn.add_theme_font_size_override("font_size", btn_size)
	register_btn.add_theme_font_size_override("font_size", int(18 * font_scale))
	forget_pwd_btn.add_theme_font_size_override("font_size", int(18 * font_scale))
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

func _animate_input_wrapper(wrapper: PanelContainer, focused: bool) -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if focused:
		tween.tween_property(wrapper, "scale", Vector2(1.02, 1.02), 0.2)
	else:
		tween.tween_property(wrapper, "scale", Vector2(1.0, 1.0), 0.2)

func _on_login_btn_hover_enter() -> void:
	login_btn_hovered = true
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(login_btn, "scale", Vector2(1.05, 1.05), 0.2)

func _on_login_btn_hover_exit() -> void:
	login_btn_hovered = false
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(login_btn, "scale", Vector2(1.0, 1.0), 0.2)

func _apply_theme() -> void:
	var col_bg := Color8(255, 243, 196)
	var col_card := Color8(255, 230, 230)
	var col_btn := Color8(255, 102, 153)
	var col_btn_hover := Color8(255, 130, 175)
	var col_btn_pressed := Color8(230, 85, 130)
	var col_text_main := Color8(80, 55, 70)
	var col_text_muted := Color8(120, 90, 105)
	var col_input_text := Color8(55, 40, 50)
	var col_placeholder := Color8(160, 130, 145)
	var col_link := Color8(230, 70, 130)
	var col_link_hover := Color8(200, 50, 110)

	var theme_obj = Theme.new()

	var line_edit_style: StyleBoxFlat = UiTheme.modern_line_edit_normal(16)
	theme_obj.set_stylebox("normal", "LineEdit", line_edit_style)
	theme_obj.set_stylebox("read_only", "LineEdit", line_edit_style)
	theme_obj.set_stylebox("focus", "LineEdit", UiTheme.modern_line_edit_focus(16))

	theme_obj.set_stylebox("normal", "Button", UiTheme.modern_primary_button_normal(24))
	theme_obj.set_stylebox("hover", "Button", UiTheme.modern_primary_button_hover(24))
	theme_obj.set_stylebox("pressed", "Button", UiTheme.modern_primary_button_pressed(24))

	var card_style: StyleBoxFlat = UiTheme.modern_glass_card(32, 0.94)
	theme_obj.set_stylebox("panel", "PanelContainer", card_style)

	theme_obj.set_color("font_color", "Button", Color8(255, 255, 255))
	theme_obj.set_color("font_color", "Label", col_text_main)
	theme_obj.set_color("font_color", "LineEdit", col_input_text)
	theme_obj.set_color("caret_color", "LineEdit", col_btn)
	theme_obj.set_color("selection_color", "LineEdit", Color(col_btn.r, col_btn.g, col_btn.b, 0.35))
	theme_obj.set_color("placeholder_font_color", "LineEdit", col_placeholder)

	title_main.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_main.add_theme_font_size_override("font_size", 72)
	title_main.add_theme_color_override("font_color", col_btn)
	title_sub.add_theme_font_size_override("font_size", 28)
	title_sub.add_theme_color_override("font_color", col_text_muted)

	username_input.add_theme_font_size_override("font_size", 20)
	password_input.add_theme_font_size_override("font_size", 20)
	login_btn.add_theme_font_size_override("font_size", 24)
	forget_pwd_btn.add_theme_font_size_override("font_size", 18)
	register_btn.add_theme_font_size_override("font_size", 18)

	var flat_clear := StyleBoxEmpty.new()
	forget_pwd_btn.flat = true
	register_btn.flat = true
	forget_pwd_btn.add_theme_stylebox_override("normal", flat_clear)
	forget_pwd_btn.add_theme_stylebox_override("hover", flat_clear)
	forget_pwd_btn.add_theme_stylebox_override("pressed", flat_clear)
	forget_pwd_btn.add_theme_stylebox_override("focus", flat_clear)
	register_btn.add_theme_stylebox_override("normal", flat_clear)
	register_btn.add_theme_stylebox_override("hover", flat_clear)
	register_btn.add_theme_stylebox_override("pressed", flat_clear)
	register_btn.add_theme_stylebox_override("focus", flat_clear)
	forget_pwd_btn.add_theme_color_override("font_color", col_link)
	forget_pwd_btn.add_theme_color_override("font_hover_color", col_link_hover)
	forget_pwd_btn.add_theme_color_override("font_pressed_color", col_link_hover)
	register_btn.add_theme_color_override("font_color", col_link)
	register_btn.add_theme_color_override("font_hover_color", col_link_hover)
	register_btn.add_theme_color_override("font_pressed_color", col_link_hover)

	toast_label.add_theme_color_override("font_color", col_text_main)
	toast_label.add_theme_font_size_override("font_size", 20)

	var toast_bg := StyleBoxFlat.new()
	toast_bg.bg_color = col_card
	toast_bg.border_color = Color8(255, 180, 200)
	toast_bg.set_border_width_all(2)
	toast_bg.corner_radius_top_left = 22
	toast_bg.corner_radius_top_right = 22
	toast_bg.corner_radius_bottom_left = 22
	toast_bg.corner_radius_bottom_right = 22
	toast_panel.add_theme_stylebox_override("panel", toast_bg)

	status_label.add_theme_color_override("font_color", col_text_muted)
	status_label.add_theme_font_size_override("font_size", 16)

	var strip_style: StyleBoxFlat = UiTheme.modern_glass_card(18, 0.78)
	server_status_strip.add_theme_stylebox_override("panel", strip_style)

	_apply_status_dot_color(Color8(160, 160, 165))

	self.theme = theme_obj

	var wrapper_panel: StyleBoxFlat = UiTheme.modern_line_edit_normal(16)
	var u_wrap: PanelContainer = $MainCard/CardContent/InputArea/UsernameWrapper
	var p_wrap: PanelContainer = $MainCard/CardContent/InputArea/PasswordWrapper
	u_wrap.add_theme_stylebox_override("panel", wrapper_panel)
	p_wrap.add_theme_stylebox_override("panel", wrapper_panel.duplicate())

	$BgColor.color = col_bg

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
	_show_message("无法连接到服务器，请检查后端是否启动", true)

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
			_show_message("无法连接到服务器，请检查后端是否启动", true)

func _show_message(message: String, is_error: bool = false) -> void:
	toast_label.text = message
	toast_label.modulate = Color.WHITE
	toast_label.remove_theme_color_override("font_color")
	if is_error:
		toast_label.add_theme_color_override("font_color", Color8(210, 55, 85))
	else:
		toast_label.add_theme_color_override("font_color", Color8(40, 145, 75))
	toast_panel.visible = true

func _hide_message() -> void:
	toast_panel.visible = false
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
	get_tree().change_scene_to_file("res://Scenes/RegisterScreen.tscn")

func _on_forget_pwd_clicked() -> void:
	print("🔑 跳转忘记密码界面")
	_show_message("忘记密码功能开发中...", false)

func _focus_to_password() -> void:
	password_input.grab_focus()

func _on_login_success(token: String, user_data: Dictionary) -> void:
	_set_processing_request(false)
	GameAudio.ui_confirm()
	user_data["token"] = token
	ProjectSettings.set_setting("moe_world/api_base_url", auth_service.api_base_url)
	var name_hint := str(user_data.get("username", "")).strip_edges()
	var tip := "登录成功！欢迎回来～" if name_hint.is_empty() else ("登录成功！欢迎，%s" % name_hint)
	_show_message(tip, false)
	await get_tree().create_timer(1.6).timeout
	ProjectSettings.set_setting("moe_world/current_user", user_data)
	UserStorage.persist_current_session()
	login_success.emit()
	if not overlay_mode:
		get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")

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
