extends Control

signal chat_message_sent(message: String)
signal chat_message_received(player_name: String, message: String)

const CHAT_BUBBLE_SCENE := preload("res://Scenes/ChatBubble.tscn")
const MAX_CHAT_BUBBLES = 10
const BUBBLE_LIFETIME = 5.0

@onready var chat_toggle_btn: Button = $ChatToggleBtn
@onready var chat_panel: PanelContainer = $ChatPanel
@onready var messages_container: VBoxContainer = $ChatPanel/VBox/MessagesScroll/MessagesContainer
@onready var message_input: LineEdit = $ChatPanel/VBox/InputArea/MessageInput
@onready var send_btn: Button = $ChatPanel/VBox/InputArea/SendBtn
@onready var close_btn: Button = $ChatPanel/VBox/Header/HeaderContent/CloseBtn

var _chat_bubbles: Array[Node] = []
var _local_player: CharacterBody2D = null
var _is_chat_panel_open: bool = false

# 拖动和调整大小相关变量
var _is_dragging: bool = false
var _is_resizing: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _resize_start_pos: Vector2 = Vector2.ZERO
var _resize_start_size: Vector2 = Vector2.ZERO

const MIN_SIZE: Vector2 = Vector2(300, 200)
const MAX_SIZE: Vector2 = Vector2(600, 400)


func _ready() -> void:
	_apply_theme()
	_setup_connections()
	chat_panel.visible = false
	
	# 调整聊天窗口默认位置到屏幕居中偏下
	_update_chat_panel_position()
	
	print("💬 世界聊天系统已初始化")


func _update_chat_panel_position() -> void:
	if chat_panel:
		# get_viewport().size 在 4.x 静态分析里无法被 := 推断类型，需显式标注
		var screen_size: Vector2 = Vector2(get_viewport().get_visible_rect().size)
		chat_panel.position = Vector2(
			screen_size.x * 0.5 - chat_panel.size.x * 0.5,
			screen_size.y * 0.7 - chat_panel.size.y * 0.5
		)


func _input(event: InputEvent) -> void:
	_handle_drag(event)
	_handle_resize(event)


func _handle_drag(event: InputEvent) -> void:
	if not chat_panel or not _is_chat_panel_open:
		return
	
	# 检测是否点击头部区域（$ 节点为 Node，需收窄类型才能推断 Rect2）
	var header_rect: Rect2 = ($ChatPanel/VBox/Header as CanvasItem).get_global_rect()
	
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
	
	# 检测是否点击右下角调整大小
	var resize_area := Rect2(
		chat_panel.global_position + chat_panel.size - Vector2(20, 20),
		Vector2(20, 20)
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
		
		# 限制大小范围
		new_size.x = clamp(new_size.x, MIN_SIZE.x, MAX_SIZE.x)
		new_size.y = clamp(new_size.y, MIN_SIZE.y, MAX_SIZE.y)
		
		chat_panel.size = new_size


func _setup_connections() -> void:
	chat_toggle_btn.pressed.connect(_toggle_chat_panel)
	close_btn.pressed.connect(_close_chat_panel)
	send_btn.pressed.connect(_on_send_message)
	message_input.text_submitted.connect(_on_send_message)


func _toggle_chat_panel() -> void:
	if _is_chat_panel_open:
		_close_chat_panel()
	else:
		_open_chat_panel()


func _open_chat_panel() -> void:
	_is_chat_panel_open = true
	chat_panel.visible = true
	message_input.grab_focus()
	
	var tween := chat_panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(chat_panel, "offset_top", 0.0, 0.3)


func _close_chat_panel() -> void:
	_is_chat_panel_open = false
	
	var tween := chat_panel.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(chat_panel, "offset_top", chat_panel.size.y, 0.2)
	await tween.finished
	chat_panel.visible = false


func _on_send_message(text: String) -> void:
	var trimmed_text := text.strip_edges()
	if trimmed_text.is_empty():
		return
	
	print("💬 发送聊天消息: ", trimmed_text)
	chat_message_sent.emit(trimmed_text)
	message_input.clear()


func add_chat_message(player_name: String, message: String) -> void:
	_add_message_to_chat_panel(player_name, message)
	chat_message_received.emit(player_name, message)


func add_local_chat_bubble(player_name: String, message: String, player_node: CharacterBody2D) -> void:
	if not is_instance_valid(player_node):
		return
	
	var bubble: Node = CHAT_BUBBLE_SCENE.instantiate()
	
	var bubble_offset := Vector2(0, -60)
	var world_pos := player_node.global_position + bubble_offset
	
	if has_node("/root/WorldScene/MainCamera"):
		var camera: Camera2D = get_node("/root/WorldScene/MainCamera")
		var screen_pos: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
		var camera_offset := world_pos - camera.global_position
		screen_pos += camera_offset
		
		var canvas_layer := CanvasLayer.new()
		canvas_layer.layer = 100
		get_tree().root.add_child(canvas_layer)
		canvas_layer.add_child(bubble)
		
		canvas_layer.global_position = Vector2.ZERO
		bubble.setup(player_name, message, screen_pos)
		bubble.bubble_finished.connect(func(): _remove_bubble(canvas_layer))
		
		_chat_bubbles.append(bubble)
		_cleanup_old_bubbles()
	else:
		get_tree().root.add_child(bubble)
		bubble.setup(player_name, message, world_pos)
		bubble.bubble_finished.connect(func(): _remove_bubble(bubble))
		_chat_bubbles.append(bubble)
		_cleanup_old_bubbles()


func add_remote_chat_bubble(player_name: String, message: String, player_node: Node2D) -> void:
	if not is_instance_valid(player_node):
		return
	
	var bubble: Node = CHAT_BUBBLE_SCENE.instantiate()
	
	var world_pos := player_node.global_position + Vector2(0, -60)
	
	if has_node("/root/WorldScene/MainCamera"):
		var camera: Camera2D = get_node("/root/WorldScene/MainCamera")
		var screen_pos: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
		var camera_offset := world_pos - camera.global_position
		screen_pos += camera_offset
		
		var canvas_layer := CanvasLayer.new()
		canvas_layer.layer = 100
		get_tree().root.add_child(canvas_layer)
		canvas_layer.add_child(bubble)
		
		canvas_layer.global_position = Vector2.ZERO
		bubble.setup(player_name, message, screen_pos)
		bubble.bubble_finished.connect(func(): _remove_bubble(canvas_layer))
		
		_chat_bubbles.append(bubble)
		_cleanup_old_bubbles()
	else:
		get_tree().root.add_child(bubble)
		bubble.setup(player_name, message, world_pos)
		bubble.bubble_finished.connect(func(): _remove_bubble(bubble))
		_chat_bubbles.append(bubble)
		_cleanup_old_bubbles()


func _add_message_to_chat_panel(player_name: String, message: String) -> void:
	var message_row := HBoxContainer.new()
	message_row.layout_mode = 2
	
	var name_label := Label.new()
	name_label.text = player_name + ": "
	name_label.add_theme_color_override("font_color", Color8(255, 100, 150))
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.size_flags_horizontal = 0
	
	var content_label := RichTextLabel.new()
	content_label.text = message
	content_label.size_flags_horizontal = 3
	content_label.add_theme_color_override("default_color", Color8(75, 50, 62))
	content_label.add_theme_font_size_override("normal_font_size", 14)
	content_label.bbcode_enabled = true
	
	message_row.add_child(name_label)
	message_row.add_child(content_label)
	messages_container.add_child(message_row)
	
	messages_container.get_parent().scroll_following = true
	
	call_deferred("_scroll_to_bottom")


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	var scroll := $ChatPanel/VBox/MessagesScroll as ScrollContainer
	if scroll:
		scroll.scroll_vertical = scroll.get_node("MessagesContainer").size.y


func _cleanup_old_bubbles() -> void:
	while _chat_bubbles.size() > MAX_CHAT_BUBBLES:
		var oldest: Node = _chat_bubbles.pop_at(0)
		if is_instance_valid(oldest):
			if oldest is CanvasLayer:
				oldest.queue_free()
			else:
				oldest.queue_free()


func _remove_bubble(bubble: Node) -> void:
	var idx := _chat_bubbles.find(bubble)
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
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
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
	
	if has_node("ChatPanel"):
		chat_panel.add_theme_stylebox_override("panel", panel_style)
	
	if has_node("ChatPanel/VBox/Header"):
		var header_panel: PanelContainer = $ChatPanel/VBox/Header
		header_panel.add_theme_stylebox_override("panel", header_style)
