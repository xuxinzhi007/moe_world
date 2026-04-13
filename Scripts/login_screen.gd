extends Control

signal login_success()

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

var is_login_mode: bool = true
var is_processing_request: bool = false
var api_ready: bool = false

func _ready() -> void:
	_apply_theme()
	
	auth_service.login_success.connect(_on_login_success)
	auth_service.login_failed.connect(_on_login_failed)
	auth_service.register_success.connect(_on_register_success)
	auth_service.register_failed.connect(_on_register_failed)
	auth_service.config_fetched.connect(_on_config_fetched)
	auth_service.config_failed.connect(_on_config_failed)
	auth_service.server_status_changed.connect(_on_server_status_changed)
	
	_set_processing_request(true)
	_show_message("正在连接服务器...", false)
	
	login_btn.pressed.connect(_on_login_clicked)
	register_btn.pressed.connect(_on_register_clicked)
	forget_pwd_btn.pressed.connect(_on_forget_pwd_clicked)
	
	username_input.text_submitted.connect(_focus_to_password)
	password_input.text_submitted.connect(_on_login_clicked)

func _apply_theme() -> void:
	# 规范色：背景 #FFF3C4、卡片 #FFE6E6、主按钮 #FF6699
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

	var line_edit_style = StyleBoxFlat.new()
	line_edit_style.bg_color = Color8(255, 255, 255)
	line_edit_style.border_color = Color8(255, 200, 210)
	line_edit_style.border_width_left = 2
	line_edit_style.border_width_top = 2
	line_edit_style.border_width_right = 2
	line_edit_style.border_width_bottom = 2
	line_edit_style.corner_radius_top_left = 20
	line_edit_style.corner_radius_top_right = 20
	line_edit_style.corner_radius_bottom_left = 20
	line_edit_style.corner_radius_bottom_right = 20
	line_edit_style.content_margin_left = 16
	line_edit_style.content_margin_top = 12
	line_edit_style.content_margin_right = 16
	line_edit_style.content_margin_bottom = 12
	theme_obj.set_stylebox("normal", "LineEdit", line_edit_style)
	theme_obj.set_stylebox("focus", "LineEdit", line_edit_style)
	theme_obj.set_stylebox("read_only", "LineEdit", line_edit_style)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = col_btn
	btn_style.corner_radius_top_left = 28
	btn_style.corner_radius_top_right = 28
	btn_style.corner_radius_bottom_left = 28
	btn_style.corner_radius_bottom_right = 28
	btn_style.content_margin_left = 20
	btn_style.content_margin_top = 16
	btn_style.content_margin_right = 20
	btn_style.content_margin_bottom = 16
	theme_obj.set_stylebox("normal", "Button", btn_style)

	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = col_btn_hover
	theme_obj.set_stylebox("hover", "Button", btn_hover)

	var btn_pressed = btn_style.duplicate()
	btn_pressed.bg_color = col_btn_pressed
	theme_obj.set_stylebox("pressed", "Button", btn_pressed)

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = col_card
	card_style.corner_radius_top_left = 48
	card_style.corner_radius_top_right = 48
	card_style.corner_radius_bottom_left = 48
	card_style.corner_radius_bottom_right = 48
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

	var strip_style := StyleBoxFlat.new()
	strip_style.bg_color = col_card
	strip_style.border_color = Color8(255, 200, 210)
	strip_style.set_border_width_all(1)
	strip_style.corner_radius_top_left = 20
	strip_style.corner_radius_top_right = 20
	strip_style.corner_radius_bottom_left = 20
	strip_style.corner_radius_bottom_right = 20
	server_status_strip.add_theme_stylebox_override("panel", strip_style)

	_apply_status_dot_color(Color8(160, 160, 165))

	self.theme = theme_obj

	var wrapper_panel := StyleBoxFlat.new()
	wrapper_panel.bg_color = Color8(255, 255, 255)
	wrapper_panel.corner_radius_top_left = 20
	wrapper_panel.corner_radius_top_right = 20
	wrapper_panel.corner_radius_bottom_left = 20
	wrapper_panel.corner_radius_bottom_right = 20
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
		# 接口正常：醒目绿色圆点 + 绿色文案
		_apply_status_dot_color(Color8(46, 204, 113))
		status_label.text = "服务器在线"
		status_label.add_theme_color_override("font_color", Color8(34, 150, 72))
	else:
		_apply_status_dot_color(Color8(235, 87, 87))
		status_label.text = "服务器离线"
		status_label.add_theme_color_override("font_color", Color8(200, 65, 75))

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
	user_data["token"] = token
	ProjectSettings.set_setting("moe_world/api_base_url", auth_service.api_base_url)
	var name_hint := str(user_data.get("username", "")).strip_edges()
	var tip := "登录成功！欢迎回来～" if name_hint.is_empty() else ("登录成功！欢迎，%s" % name_hint)
	_show_message(tip, false)
	await get_tree().create_timer(1.6).timeout
	login_success.emit()
	ProjectSettings.set_setting("moe_world/current_user", user_data)
	UserStorage.persist_current_session()
	get_tree().change_scene_to_file("res://Scenes/HallScene.tscn")

func _on_login_failed(error: String) -> void:
	_set_processing_request(false)
	_show_message(error, true)

func _on_register_success(user_data: Dictionary) -> void:
	_set_processing_request(false)
	var username = user_data.get("username", "用户")
	_show_message("注册成功！%s，请登录" % username, false)

func _on_register_failed(error: String) -> void:
	_set_processing_request(false)
	_show_message(error, true)
