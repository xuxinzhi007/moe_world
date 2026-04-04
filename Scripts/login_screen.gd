extends Control

signal login_success()

@onready var login_panel: PanelContainer = $LoginPanel
@onready var title_label: Label = $LoginPanel/VBoxContainer/TitleLabel
@onready var username_input: LineEdit = $LoginPanel/VBoxContainer/FormContainer/UsernameInput
@onready var password_input: LineEdit = $LoginPanel/VBoxContainer/FormContainer/PasswordInput
@onready var login_button: Button = $LoginPanel/VBoxContainer/FormContainer/LoginButton
@onready var register_button: Button = $LoginPanel/VBoxContainer/FormContainer/RegisterButton
@onready var message_label: Label = $LoginPanel/VBoxContainer/MessageLabel
@onready var switch_mode_button: Button = $LoginPanel/VBoxContainer/SwitchModeButton

@onready var auth_service: Node = $AuthService

var is_login_mode: bool = true
var is_processing: bool = false

func _ready() -> void:
	auth_service.login_success.connect(_on_login_success)
	auth_service.login_failed.connect(_on_login_failed)
	auth_service.register_success.connect(_on_register_success)
	auth_service.register_failed.connect(_on_register_failed)
	
	login_button.pressed.connect(_on_login_clicked)
	register_button.pressed.connect(_on_register_clicked)
	switch_mode_button.pressed.connect(_on_switch_mode_clicked)
	
	_update_ui_for_mode()

func _update_ui_for_mode() -> void:
	if is_login_mode:
		title_label.text = "萌社区 - 登录"
		login_button.visible = true
		register_button.visible = false
		switch_mode_button.text = "没有账号？去注册"
	else:
		title_label.text = "萌社区 - 注册"
		login_button.visible = false
		register_button.visible = true
		switch_mode_button.text = "已有账号？去登录"

func _show_message(message: String, is_error: bool = false) -> void:
	message_label.text = message
	message_label.modulate = Color(1, 0, 0, 1) if is_error else Color(0, 0.8, 0, 1)
	message_label.visible = true

func _hide_message() -> void:
	message_label.visible = false

func _set_processing(processing: bool) -> void:
	is_processing = processing
	username_input.editable = not processing
	password_input.editable = not processing
	login_button.disabled = processing
	register_button.disabled = processing
	switch_mode_button.disabled = processing

func _on_login_clicked() -> void:
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if username.is_empty() or password.is_empty():
		_show_message("请输入用户名和密码！", true)
		return
	
	_hide_message()
	_set_processing(true)
	auth_service.login(username, password)

func _on_register_clicked() -> void:
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if username.is_empty() or password.is_empty():
		_show_message("请输入用户名和密码！", true)
		return
	
	if password.length() < 6:
		_show_message("密码至少需要6位！", true)
		return
	
	_hide_message()
	_set_processing(true)
	auth_service.register(username, password)

func _on_switch_mode_clicked() -> void:
	is_login_mode = not is_login_mode
	username_input.clear()
	password_input.clear()
	_hide_message()
	_update_ui_for_mode()

func _on_login_success(token: String, user_data: Dictionary) -> void:
	_set_processing(false)
	_show_message("登录成功！正在进入...", false)
	await get_tree().create_timer(1.0).timeout
	login_success.emit()
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_login_failed(error: String) -> void:
	_set_processing(false)
	_show_message(error, true)

func _on_register_success(message: String) -> void:
	_set_processing(false)
	_show_message("注册成功！请登录", false)
	is_login_mode = true
	_update_ui_for_mode()

func _on_register_failed(error: String) -> void:
	_set_processing(false)
	_show_message(error, true)
