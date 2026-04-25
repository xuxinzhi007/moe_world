extends Control

const AuthService = preload("res://Scripts/auth_service.gd")
const UiTheme := preload("res://Scripts/ui_theme.gd")

@onready var main_card: PanelContainer = $MainCard
@onready var title_main: Label = $MainCard/CardContent/TitleArea/TitleMain
@onready var title_sub: Label = $MainCard/CardContent/TitleArea/TitleSub
@onready var username_input: LineEdit = $MainCard/CardContent/InputArea/UsernameWrapper/UsernameInput
@onready var email_input: LineEdit = $MainCard/CardContent/InputArea/EmailWrapper/EmailInput
@onready var password_input: LineEdit = $MainCard/CardContent/InputArea/PasswordWrapper/PasswordInput
@onready var confirm_input: LineEdit = $MainCard/CardContent/InputArea/ConfirmWrapper/ConfirmInput
@onready var register_btn: Button = $MainCard/CardContent/RegisterBtn
@onready var login_link_btn: Button = $MainCard/CardContent/BottomLinks/LoginLinkBtn
@onready var toast_panel: Panel = $ToastPanel
@onready var toast_label: Label = $ToastPanel/ToastLabel
@onready var auth_service: Node = $AuthService
@onready var bg_gradient: ColorRect = $BgGradient
@onready var username_wrapper: PanelContainer = $MainCard/CardContent/InputArea/UsernameWrapper
@onready var email_wrapper: PanelContainer = $MainCard/CardContent/InputArea/EmailWrapper
@onready var password_wrapper: PanelContainer = $MainCard/CardContent/InputArea/PasswordWrapper
@onready var confirm_wrapper: PanelContainer = $MainCard/CardContent/InputArea/ConfirmWrapper

var api_ready: bool = false
var is_processing_request: bool = false

var username_focused: bool = false
var email_focused: bool = false
var password_focused: bool = false
var confirm_focused: bool = false
var register_btn_hovered: bool = false


func _ready() -> void:
	_apply_theme()

	auth_service.register_success.connect(_on_register_success)
	auth_service.register_failed.connect(_on_register_failed)
	auth_service.config_fetched.connect(_on_config_fetched)
	auth_service.config_failed.connect(_on_config_failed)
	
	if AuthService.global_has_fetched_config:
		api_ready = true
		_set_processing_request(false)
		print("🔄 注册页面：使用已缓存的配置")
	else:
		_set_processing_request(true)
		_show_message("正在连接服务器...", false)

	register_btn.pressed.connect(_submit_register)
	login_link_btn.pressed.connect(_on_login_link_pressed)

	username_input.text_submitted.connect(_focus_email)
	email_input.text_submitted.connect(_focus_password)
	password_input.text_submitted.connect(_focus_confirm)
	confirm_input.text_submitted.connect(_on_confirm_submitted)
	
	username_input.focus_entered.connect(func(): _on_input_focus_enter(username_wrapper))
	username_input.focus_exited.connect(func(): _on_input_focus_exit(username_wrapper))
	email_input.focus_entered.connect(func(): _on_input_focus_enter(email_wrapper))
	email_input.focus_exited.connect(func(): _on_input_focus_exit(email_wrapper))
	password_input.focus_entered.connect(func(): _on_input_focus_enter(password_wrapper))
	password_input.focus_exited.connect(func(): _on_input_focus_exit(password_wrapper))
	confirm_input.focus_entered.connect(func(): _on_input_focus_enter(confirm_wrapper))
	confirm_input.focus_exited.connect(func(): _on_input_focus_exit(confirm_wrapper))
	
	register_btn.mouse_entered.connect(_on_register_btn_hover_enter)
	register_btn.mouse_exited.connect(_on_register_btn_hover_exit)
	
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()
	
	_play_intro_animation()


func _on_input_focus_enter(wrapper: PanelContainer) -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(wrapper, "scale", Vector2(1.02, 1.02), 0.2)


func _on_input_focus_exit(wrapper: PanelContainer) -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(wrapper, "scale", Vector2(1.0, 1.0), 0.2)


func _on_register_btn_hover_enter() -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(register_btn, "scale", Vector2(1.05, 1.05), 0.2)


func _on_register_btn_hover_exit() -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(register_btn, "scale", Vector2(1.0, 1.0), 0.2)


func _play_intro_animation() -> void:
	main_card.modulate.a = 0.0
	main_card.position.y += 50
	title_main.modulate.a = 0.0
	title_sub.modulate.a = 0.0
	username_wrapper.modulate.a = 0.0
	email_wrapper.modulate.a = 0.0
	password_wrapper.modulate.a = 0.0
	confirm_wrapper.modulate.a = 0.0
	register_btn.modulate.a = 0.0
	
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
	tween.tween_property(email_wrapper, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.1).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(password_wrapper, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.1).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(confirm_wrapper, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.1).timeout
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(register_btn, "modulate:a", 1.0, 0.4)

func _on_window_resized() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var he: Vector2 = UiTheme.responsive_auth_card_half_extents(screen_size, true)
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
	email_input.add_theme_font_size_override("font_size", input_size)
	password_input.add_theme_font_size_override("font_size", input_size)
	confirm_input.add_theme_font_size_override("font_size", input_size)
	register_btn.add_theme_font_size_override("font_size", btn_size)
	login_link_btn.add_theme_font_size_override("font_size", int(18 * font_scale))
	toast_label.add_theme_font_size_override("font_size", int(20 * font_scale))


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

	var theme_obj := Theme.new()

	var line_edit_style: StyleBoxFlat = UiTheme.modern_line_edit_normal(16)
	theme_obj.set_stylebox("normal", "LineEdit", line_edit_style)
	theme_obj.set_stylebox("read_only", "LineEdit", line_edit_style)
	theme_obj.set_stylebox("focus", "LineEdit", UiTheme.modern_line_edit_focus(16))

	theme_obj.set_stylebox("normal", "Button", UiTheme.modern_primary_button_normal(24))
	theme_obj.set_stylebox("hover", "Button", UiTheme.modern_primary_button_hover(24))
	theme_obj.set_stylebox("pressed", "Button", UiTheme.modern_primary_button_pressed(24))

	var card_style: StyleBoxFlat = UiTheme.modern_glass_card(30, 0.94)
	theme_obj.set_stylebox("panel", "PanelContainer", card_style)

	theme_obj.set_color("font_color", "Button", Color8(255, 255, 255))
	theme_obj.set_color("font_color", "Label", col_text_main)
	theme_obj.set_color("font_color", "LineEdit", col_input_text)
	theme_obj.set_color("caret_color", "LineEdit", col_btn)
	theme_obj.set_color("selection_color", "LineEdit", Color(col_btn.r, col_btn.g, col_btn.b, 0.35))
	theme_obj.set_color("placeholder_font_color", "LineEdit", col_placeholder)

	title_main.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_main.add_theme_font_size_override("font_size", 56)
	title_main.add_theme_color_override("font_color", col_btn)
	title_sub.add_theme_font_size_override("font_size", 24)
	title_sub.add_theme_color_override("font_color", col_text_muted)

	var line_size := 20
	username_input.add_theme_font_size_override("font_size", line_size)
	email_input.add_theme_font_size_override("font_size", line_size)
	password_input.add_theme_font_size_override("font_size", line_size)
	confirm_input.add_theme_font_size_override("font_size", line_size)
	register_btn.add_theme_font_size_override("font_size", 24)
	login_link_btn.add_theme_font_size_override("font_size", 18)

	var flat_clear := StyleBoxEmpty.new()
	login_link_btn.flat = true
	login_link_btn.add_theme_stylebox_override("normal", flat_clear)
	login_link_btn.add_theme_stylebox_override("hover", flat_clear)
	login_link_btn.add_theme_stylebox_override("pressed", flat_clear)
	login_link_btn.add_theme_stylebox_override("focus", flat_clear)
	login_link_btn.add_theme_color_override("font_color", col_link)
	login_link_btn.add_theme_color_override("font_hover_color", col_link_hover)
	login_link_btn.add_theme_color_override("font_pressed_color", col_link_hover)

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

	self.theme = theme_obj

	var wrapper_panel: StyleBoxFlat = UiTheme.modern_line_edit_normal(16)
	var u_wrap: PanelContainer = $MainCard/CardContent/InputArea/UsernameWrapper
	var e_wrap: PanelContainer = $MainCard/CardContent/InputArea/EmailWrapper
	var p_wrap: PanelContainer = $MainCard/CardContent/InputArea/PasswordWrapper
	var c_wrap: PanelContainer = $MainCard/CardContent/InputArea/ConfirmWrapper
	u_wrap.add_theme_stylebox_override("panel", wrapper_panel)
	e_wrap.add_theme_stylebox_override("panel", wrapper_panel.duplicate())
	p_wrap.add_theme_stylebox_override("panel", wrapper_panel.duplicate())
	c_wrap.add_theme_stylebox_override("panel", wrapper_panel.duplicate())


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
	email_input.editable = not processing
	password_input.editable = not processing
	confirm_input.editable = not processing
	register_btn.disabled = processing
	login_link_btn.disabled = processing


func _focus_email(_new_text: String) -> void:
	email_input.grab_focus()


func _focus_password(_new_text: String) -> void:
	password_input.grab_focus()


func _focus_confirm(_new_text: String) -> void:
	confirm_input.grab_focus()


func _on_confirm_submitted(_new_text: String) -> void:
	_submit_register()


func _on_login_link_pressed() -> void:
	if is_processing_request:
		return
	get_tree().change_scene_to_file("res://Scenes/LoginScreen.tscn")


func _submit_register() -> void:
	if not api_ready:
		_show_message("正在连接服务器，请稍候...", true)
		return

	var username := username_input.text.strip_edges()
	var email := email_input.text.strip_edges()
	var password := password_input.text.strip_edges()
	var confirm := confirm_input.text.strip_edges()

	if username.is_empty() or email.is_empty() or password.is_empty() or confirm.is_empty():
		_show_message("请填写用户名、邮箱和密码", true)
		return

	if not email.contains("@"):
		_show_message("请输入有效的邮箱地址", true)
		return

	if password != confirm:
		_show_message("两次输入的密码不一致", true)
		return

	_hide_message()
	_set_processing_request(true)
	auth_service.register(username, password, email)


func _on_register_success(_user_data: Dictionary) -> void:
	_set_processing_request(false)
	_show_message("注册成功！请返回登录", false)
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://Scenes/LoginScreen.tscn")


func _on_register_failed(error: String) -> void:
	_set_processing_request(false)
	_show_message(error, true)
