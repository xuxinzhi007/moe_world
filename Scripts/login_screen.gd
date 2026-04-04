extends Control

signal login_success()

@onready var main_card: PanelContainer = $MainCard
@onready var title_label: Label = $MainCard/HBoxContainer/RightContainer/TitleLabel
@onready var username_input: LineEdit = $MainCard/HBoxContainer/RightContainer/UsernameInput
@onready var password_input: LineEdit = $MainCard/HBoxContainer/RightContainer/PasswordInput
@onready var login_btn: Button = $MainCard/HBoxContainer/RightContainer/LoginBtn
@onready var register_btn: LinkButton = $MainCard/HBoxContainer/RightContainer/BottomLinks/RegisterBtn
@onready var forget_pwd_label: Label = $MainCard/HBoxContainer/RightContainer/BottomLinks/ForgetPwdLabel
@onready var message_label: Label = $MessageLabel
@onready var auth_service: Node = $AuthService

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
	
	_set_processing_request(true)
	_show_message("正在连接服务器...", false)
	
	login_btn.pressed.connect(_on_login_clicked)
	register_btn.pressed.connect(_on_register_clicked)
	
	username_input.text_submitted.connect(_focus_to_password)
	password_input.text_submitted.connect(_on_login_clicked)

func _apply_theme() -> void:
	var theme_obj = Theme.new()
	
	var line_edit_style = StyleBoxFlat.new()
	line_edit_style.bg_color = Color(1, 1, 1)
	line_edit_style.border_color = Color(0.8, 0.8, 0.8)
	line_edit_style.border_width_left = 2
	line_edit_style.border_width_top = 2
	line_edit_style.border_width_right = 2
	line_edit_style.border_width_bottom = 2
	line_edit_style.corner_radius_top_left = 32
	line_edit_style.corner_radius_top_right = 32
	line_edit_style.corner_radius_bottom_left = 32
	line_edit_style.corner_radius_bottom_right = 32
	line_edit_style.content_margin_left = 16
	line_edit_style.content_margin_top = 16
	line_edit_style.content_margin_right = 16
	line_edit_style.content_margin_bottom = 16
	theme_obj.set_stylebox("normal", "LineEdit", line_edit_style)
	theme_obj.set_stylebox("focus", "LineEdit", line_edit_style)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(1, 0.4, 0.6)
	btn_style.corner_radius_top_left = 32
	btn_style.corner_radius_top_right = 32
	btn_style.corner_radius_bottom_left = 32
	btn_style.corner_radius_bottom_right = 32
	btn_style.content_margin_left = 16
	btn_style.content_margin_top = 16
	btn_style.content_margin_right = 16
	btn_style.content_margin_bottom = 16
	theme_obj.set_stylebox("normal", "Button", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(1, 0.5, 0.7)
	theme_obj.set_stylebox("hover", "Button", btn_hover)
	
	var btn_pressed = btn_style.duplicate()
	btn_pressed.bg_color = Color(0.9, 0.3, 0.5)
	theme_obj.set_stylebox("pressed", "Button", btn_pressed)
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.9, 0.9)
	card_style.corner_radius_top_left = 64
	card_style.corner_radius_top_right = 64
	card_style.corner_radius_bottom_left = 64
	card_style.corner_radius_bottom_right = 64
	theme_obj.set_stylebox("panel", "PanelContainer", card_style)
	
	theme_obj.set_color("font_color", "Button", Color(1, 1, 1))
	theme_obj.set_color("font_color", "Label", Color(0.2, 0.2, 0.2))
	
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(1, 0.4, 0.6))
	
	self.theme = theme_obj

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

func _show_message(message: String, is_error: bool = false) -> void:
	message_label.text = message
	message_label.modulate = Color(1, 0, 0, 1) if is_error else Color(0, 0.8, 0, 1)
	message_label.visible = true

func _hide_message() -> void:
	message_label.visible = false

func _set_processing_request(processing: bool) -> void:
	is_processing_request = processing
	username_input.editable = not processing
	password_input.editable = not processing
	login_btn.disabled = processing
	register_btn.disabled = processing

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
	print("跳转注册界面")

func _focus_to_password() -> void:
	password_input.grab_focus()

func _on_login_success(_token: String, user_data: Dictionary) -> void:
	_set_processing_request(false)
	_show_message("登录成功！正在进入...", false)
	await get_tree().create_timer(1.0).timeout
	login_success.emit()
	ProjectSettings.set_setting("moe_world/current_user", user_data)
	ProjectSettings.save()
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
