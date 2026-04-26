extends Control

signal chat_message_sent(message: String)
signal chat_message_received(player_name: String, message: String)

const UiTheme := preload("res://Scripts/meta/ui_theme.gd")
const CHAT_BUBBLE_SCENE := preload("res://Scenes/ui/ChatBubble.tscn")
const MAX_CHAT_BUBBLES = 10
const BUBBLE_LIFETIME = 5.0

@onready var chat_toggle_btn: Button = $Overlay/ChatToggleBtn
@onready var chat_panel: PanelContainer = $Overlay/ChatPanel
@onready var messages_container: VBoxContainer = $Overlay/ChatPanel/VBox/MessagesScroll/MessagesContainer
@onready var message_input: LineEdit = $Overlay/ChatPanel/VBox/InputArea/MessageInput
@onready var send_btn: Button = $Overlay/ChatPanel/VBox/InputArea/SendBtn
@onready var close_btn: Button = $Overlay/ChatPanel/VBox/Header/HeaderContent/CloseBtn

var _chat_bubbles: Array[Node] = []
var _local_player: CharacterBody2D = null
var _is_chat_panel_open: bool = false

# 拖动和调整大小相关变量
var _is_dragging: bool = false
var _is_resizing: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _resize_start_pos: Vector2 = Vector2.ZERO
var _resize_start_size: Vector2 = Vector2.ZERO

var _chat_min_size: Vector2 = Vector2(320, 220)
var _chat_max_size: Vector2 = Vector2(900, 680)


func _ready() -> void:
	_apply_theme()
	_setup_connections()
	get_tree().root.size_changed.connect(_layout_chat_overlay)
	_layout_chat_overlay()
	chat_panel.visible = false
	chat_panel.modulate.a = 1.0
	print("💬 世界聊天系统已初始化")


func _layout_chat_overlay() -> void:
	var s: Vector2 = get_viewport().get_visible_rect().size
	_chat_min_size = Vector2(clampf(s.x * 0.34, 240.0, 420.0), clampf(s.y * 0.18, 150.0, 300.0))
	_chat_max_size = Vector2(clampf(s.x * 0.92, 520.0, 1000.0), clampf(s.y * 0.8, 400.0, 780.0))
	var mobile_chat: bool = mini(s.x, s.y) < 760 or s.y > s.x * 1.02
	if not _is_chat_panel_open:
		var hw: float = clampf(s.x * 0.22, 240.0, minf(_chat_max_size.x * 0.5, s.x * 0.46))
		chat_panel.offset_left = -hw
		chat_panel.offset_right = hw
		var bottom_m: float = clampf(s.y * 0.055, 32.0, 84.0)
		var panel_span: float = clampf(s.y * 0.52, 300.0, minf(_chat_max_size.y + 140.0, s.y * 0.74))
		if mobile_chat:
			bottom_m = clampf(s.y * 0.14, 96.0, 160.0)
			panel_span = clampf(s.y * 0.48, 280.0, minf(_chat_max_size.y + 120.0, s.y * 0.62))
		chat_panel.offset_top = -panel_span
		chat_panel.offset_bottom = -bottom_m
	var pad: float = UiTheme.responsive_pad_x(s.x)
	var toggle_w: float = clampf(s.x * 0.15, 168.0, 280.0)
	var toggle_h: float = clampf(88.0 + s.y * 0.04, 72.0, 128.0)
	if mobile_chat:
		chat_toggle_btn.anchor_left = 0.0
		chat_toggle_btn.anchor_right = 0.0
		chat_toggle_btn.anchor_top = 0.0
		chat_toggle_btn.anchor_bottom = 0.0
		chat_toggle_btn.offset_left = pad
		chat_toggle_btn.offset_top = clampf(72.0, 56.0, 96.0)
		chat_toggle_btn.offset_right = chat_toggle_btn.offset_left + mini(toggle_w, 200.0)
		chat_toggle_btn.offset_bottom = chat_toggle_btn.offset_top + mini(toggle_h, 72.0)
		chat_toggle_btn.text = "聊天"
	else:
		chat_toggle_btn.anchor_left = 0.0
		chat_toggle_btn.anchor_right = 0.0
		chat_toggle_btn.anchor_top = 1.0
		chat_toggle_btn.anchor_bottom = 1.0
		chat_toggle_btn.offset_left = pad
		chat_toggle_btn.offset_right = pad + toggle_w
		chat_toggle_btn.offset_top = -clampf(s.y * 0.34, 240.0, 500.0)
		chat_toggle_btn.offset_bottom = chat_toggle_btn.offset_top + toggle_h
		chat_toggle_btn.text = "世界聊天"
	if _is_chat_panel_open:
		chat_panel.size = Vector2(
			clampf(chat_panel.size.x, _chat_min_size.x, _chat_max_size.x),
			clampf(chat_panel.size.y, _chat_min_size.y, _chat_max_size.y)
		)


func _input(event: InputEvent) -> void:
	_handle_drag(event)
	_handle_resize(event)


func _handle_drag(event: InputEvent) -> void:
	if not chat_panel or not _is_chat_panel_open:
		return
	
	var header_rect: Rect2 = ($Overlay/ChatPanel/VBox/Header as CanvasItem).get_global_rect()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if header_rect.has_point(event.global_position):
					_is_dragging = true
					_drag_start_pos = event.global_position - chat_panel.global_position
			else:
				_is_dragging = false
	
	elif event is InputEventMouseMotion and _is_dragging:
		chat_panel.global_position = event.global_position - _drag_start_pos


func _handle_resize(event: InputEvent) -> void:
	if not chat_panel or not _is_chat_panel_open:
		return
	
	var resize_area: Rect2 = Rect2(
		chat_panel.global_position + chat_panel.size - Vector2(24, 24),
		Vector2(24, 24)
	)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if resize_area.has_point(event.global_position):
					_is_resizing = true
					_resize_start_pos = event.global_position
					_resize_start_size = chat_panel.size
			else:
				_is_resizing = false
	
	elif event is InputEventMouseMotion and _is_resizing:
		var motion := event as InputEventMouseMotion
		var delta: Vector2 = motion.global_position - _resize_start_pos
		var new_size: Vector2 = _resize_start_size + delta
		
		new_size.x = clampf(new_size.x, _chat_min_size.x, _chat_max_size.x)
		new_size.y = clampf(new_size.y, _chat_min_size.y, _chat_max_size.y)
		
		chat_panel.size = new_size


func _setup_connections() -> void:
	chat_toggle_btn.tooltip_text = "打开世界聊天；窗口可拖标题移动、右下角缩放"
	chat_toggle_btn.pressed.connect(_toggle_chat_panel)
	close_btn.pressed.connect(_close_chat_panel)
	send_btn.pressed.connect(func() -> void: _submit_from_input())
	message_input.text_submitted.connect(_on_send_message)


func _submit_from_input() -> void:
	_on_send_message(message_input.text)


func _toggle_chat_panel() -> void:
	if _is_chat_panel_open:
		_close_chat_panel()
	else:
		_open_chat_panel()


func _open_chat_panel() -> void:
	_is_chat_panel_open = true
	chat_panel.visible = true
	chat_panel.modulate.a = 0.0
	var tw: Tween = chat_panel.create_tween()
	tw.tween_property(chat_panel, "modulate:a", 1.0, 0.16)
	message_input.call_deferred("grab_focus")


func _close_chat_panel() -> void:
	_is_chat_panel_open = false
	_is_dragging = false
	_is_resizing = false
	var tw: Tween = chat_panel.create_tween()
	tw.tween_property(chat_panel, "modulate:a", 0.0, 0.14)
	await tw.finished
	chat_panel.visible = false
	chat_panel.modulate.a = 1.0


func _on_send_message(text: String) -> void:
	var trimmed_text: String = text.strip_edges()
	if trimmed_text.is_empty():
		return
	GameAudio.ui_click()
	print("💬 发送聊天消息: ", trimmed_text)
	chat_message_sent.emit(trimmed_text)
	message_input.clear()


func add_chat_message(player_name: String, message: String) -> void:
	_add_message_to_chat_panel(player_name, message)
	chat_message_received.emit(player_name, message)


func _resolve_world_camera() -> Camera2D:
	var c: Camera2D = get_node_or_null("/root/WorldScene/Playfield/MainCamera") as Camera2D
	if c == null:
		c = get_node_or_null("/root/WorldScene/MainCamera") as Camera2D
	if is_instance_valid(c):
		return c
	var v: Camera2D = get_viewport().get_camera_2d()
	if is_instance_valid(v):
		return v
	return null


## 气泡根节点必须是 Control（如 PanelContainer）；由独立 CanvasLayer 承载叠在画面上。
func _mount_bubble_screen_overlay(bubble: Control, player_name: String, message: String, screen_pos: Vector2) -> void:
	if bubble == null or not is_instance_valid(bubble):
		push_warning("WorldChat: 聊天气泡实例无效")
		return
	if not bubble.has_method("setup"):
		push_warning("WorldChat: ChatBubble 缺少 setup，已丢弃实例")
		bubble.queue_free()
		return
	if not bubble.has_signal("bubble_finished"):
		push_warning("WorldChat: ChatBubble 缺少 bubble_finished 信号")
		bubble.queue_free()
		return
	var host := CanvasLayer.new()
	host.layer = 100
	get_tree().root.add_child(host)
	host.add_child(bubble)
	bubble.call_deferred("setup", player_name, message, screen_pos)
	bubble.bubble_finished.connect(func(): _remove_bubble(host))
	_chat_bubbles.append(host)
	_cleanup_old_bubbles()


func _instantiate_chat_bubble_control() -> Control:
	var root_node: Node = CHAT_BUBBLE_SCENE.instantiate()
	var bubble: Control = root_node as Control
	if bubble == null:
		if is_instance_valid(root_node):
			root_node.queue_free()
		push_warning(
			"WorldChat: ChatBubble 场景根节点必须是 Control（如 PanelContainer），不能是 CanvasLayer。"
			+ " 请确认 res://Scenes/ui/ChatBubble.tscn 根节点与 chat_bubble.gd 的 extends 一致。"
		)
	return bubble


func add_local_chat_bubble(player_name: String, message: String, player_node: CharacterBody2D) -> void:
	if not is_instance_valid(player_node):
		return
	var bubble: Control = _instantiate_chat_bubble_control()
	if bubble == null:
		return
	var bubble_offset := Vector2(0, -60)
	var world_pos: Vector2 = player_node.global_position + bubble_offset
	var camera: Camera2D = _resolve_world_camera()
	if camera != null:
		var screen_pos: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
		screen_pos += world_pos - camera.global_position
		_mount_bubble_screen_overlay(bubble, player_name, message, screen_pos)
	else:
		var center: Vector2 = get_viewport().get_visible_rect().size * 0.5
		push_warning("WorldChat: 未找到 MainCamera，气泡将显示在视口中心")
		_mount_bubble_screen_overlay(bubble, player_name, message, center)


func add_remote_chat_bubble(player_name: String, message: String, player_node: Node2D) -> void:
	if not is_instance_valid(player_node):
		return
	var bubble: Control = _instantiate_chat_bubble_control()
	if bubble == null:
		return
	var world_pos: Vector2 = player_node.global_position + Vector2(0, -60)
	var camera: Camera2D = _resolve_world_camera()
	if camera != null:
		var screen_pos: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
		screen_pos += world_pos - camera.global_position
		_mount_bubble_screen_overlay(bubble, player_name, message, screen_pos)
	else:
		var center: Vector2 = get_viewport().get_visible_rect().size * 0.5
		push_warning("WorldChat: 未找到 MainCamera，气泡将显示在视口中心")
		_mount_bubble_screen_overlay(bubble, player_name, message, center)


func _add_message_to_chat_panel(player_name: String, message: String) -> void:
	var message_row := HBoxContainer.new()
	
	var name_label := Label.new()
	name_label.text = player_name + ": "
	name_label.add_theme_color_override("font_color", Color8(255, 100, 150))
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.size_flags_horizontal = 0
	
	var content_label := RichTextLabel.new()
	content_label.text = message
	content_label.size_flags_horizontal = 3
	content_label.add_theme_color_override("default_color", Color8(75, 50, 62))
	content_label.add_theme_font_size_override("normal_font_size", 15)
	content_label.bbcode_enabled = true
	
	message_row.add_child(name_label)
	message_row.add_child(content_label)
	messages_container.add_child(message_row)
	
	messages_container.get_parent().scroll_following = true
	
	call_deferred("_scroll_to_bottom")


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	var scroll: ScrollContainer = $Overlay/ChatPanel/VBox/MessagesScroll as ScrollContainer
	if scroll:
		var mc: Control = scroll.get_node("MessagesContainer") as Control
		if mc:
			scroll.scroll_vertical = int(mc.size.y)


func _cleanup_old_bubbles() -> void:
	while _chat_bubbles.size() > MAX_CHAT_BUBBLES:
		var oldest: Node = _chat_bubbles.pop_at(0)
		if is_instance_valid(oldest):
			if oldest is CanvasLayer:
				oldest.queue_free()
			else:
				oldest.queue_free()


func _remove_bubble(bubble: Node) -> void:
	var idx: int = _chat_bubbles.find(bubble)
	if idx >= 0:
		_chat_bubbles.remove_at(idx)
	
	if bubble is CanvasLayer:
		bubble.queue_free()
	elif bubble is Node:
		bubble.queue_free()


func set_local_player(player: CharacterBody2D) -> void:
	_local_player = player


func _apply_theme() -> void:
	var theme_obj := Theme.new()
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color8(255, 102, 153)
	btn_style.corner_radius_top_left = 20
	btn_style.corner_radius_top_right = 20
	btn_style.corner_radius_bottom_left = 20
	btn_style.corner_radius_bottom_right = 20
	btn_style.content_margin_left = 20
	btn_style.content_margin_top = 14
	btn_style.content_margin_right = 20
	btn_style.content_margin_bottom = 14
	theme_obj.set_stylebox("normal", "Button", btn_style)
	
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color8(255, 130, 175)
	theme_obj.set_stylebox("hover", "Button", btn_hover)
	
	var btn_pressed := btn_style.duplicate()
	btn_pressed.bg_color = Color8(230, 85, 130)
	theme_obj.set_stylebox("pressed", "Button", btn_pressed)
	
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color.WHITE
	input_style.border_color = Color8(255, 200, 210)
	input_style.set_border_width_all(2)
	input_style.corner_radius_top_left = 20
	input_style.corner_radius_top_right = 20
	input_style.corner_radius_bottom_left = 20
	input_style.corner_radius_bottom_right = 20
	input_style.content_margin_left = 16
	input_style.content_margin_top = 12
	input_style.content_margin_right = 16
	input_style.content_margin_bottom = 12
	theme_obj.set_stylebox("normal", "LineEdit", input_style)
	theme_obj.set_stylebox("focus", "LineEdit", input_style)
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1, 0.96, 0.98, 0.97)
	panel_style.border_color = Color8(255, 180, 200)
	panel_style.set_border_width_all(3)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.shadow_color = Color(0, 0, 0, 0.2)
	panel_style.shadow_size = 15
	panel_style.shadow_offset = Vector2(0, -5)
	
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color8(255, 220, 235)
	header_style.corner_radius_top_left = 24
	header_style.corner_radius_top_right = 24
	header_style.corner_radius_bottom_left = 0
	header_style.corner_radius_bottom_right = 0
	
	theme_obj.set_stylebox("panel", "PanelContainer", panel_style)
	
	theme_obj.set_color("font_color", "Button", Color.WHITE)
	theme_obj.set_color("font_color", "Label", Color8(75, 50, 62))
	theme_obj.set_color("font_color", "LineEdit", Color8(75, 50, 62))
	theme_obj.set_color("placeholder_font_color", "LineEdit", Color8(160, 130, 145))
	
	chat_toggle_btn.theme = theme_obj
	send_btn.theme = theme_obj
	close_btn.theme = theme_obj
	
	chat_toggle_btn.add_theme_font_size_override("font_size", 20)
	send_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_font_size_override("font_size", 20)
	message_input.add_theme_font_size_override("font_size", 17)
	
	var title: Label = $Overlay/ChatPanel/VBox/Header/HeaderContent/TitleLabel
	title.add_theme_font_size_override("font_size", 20)
	
	chat_panel.add_theme_stylebox_override("panel", panel_style)
	
	var header_panel: PanelContainer = $Overlay/ChatPanel/VBox/Header
	header_panel.add_theme_stylebox_override("panel", header_style)
