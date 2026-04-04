extends CanvasLayer

signal dialog_closed()

@onready var dialog_panel: PanelContainer = $DialogPanel
@onready var npc_name_label: Label = $DialogPanel/NameLabel
@onready var message_text: RichTextLabel = $DialogPanel/VBoxContainer/MessageContainer/MessageText
@onready var input_container: HBoxContainer = $DialogPanel/VBoxContainer/InputContainer
@onready var input_line: LineEdit = $DialogPanel/VBoxContainer/InputContainer/InputLine
@onready var send_button: Button = $DialogPanel/VBoxContainer/InputContainer/SendButton
@onready var close_button: Button = $DialogPanel/CloseButton
@onready var typing_label: Label = $DialogPanel/VBoxContainer/TypingLabel

var current_npc: Node2D
var ai_service: Node
var is_typing: bool = false
var conversation_history: Array = []

func _ready() -> void:
	hide_dialog()
	send_button.pressed.connect(_on_send_button_pressed)
	input_line.text_submitted.connect(_on_input_submitted)
	close_button.pressed.connect(_on_close_button_pressed)

func set_ai_service(service: Node) -> void:
	ai_service = service
	if ai_service:
		ai_service.ai_response_received.connect(_on_ai_response)
		ai_service.ai_error_occurred.connect(_on_ai_error)

func show_dialog(npc: Node2D, npc_name: String, greeting: String = "") -> void:
	current_npc = npc
	npc_name_label.text = npc_name
	conversation_history = []
	
	dialog_panel.visible = true
	input_line.clear()
	input_line.grab_focus()
	
	message_text.clear()
	if not greeting.is_empty():
		_add_message(npc_name, greeting)
	else:
		_add_message(npc_name, "你好呀~ 有什么想聊的吗？")

func hide_dialog() -> void:
	dialog_panel.visible = false
	current_npc = null
	dialog_closed.emit()

func _add_message(sender: String, text: String) -> void:
	var is_player = sender == "玩家"
	var color = "#4CAF50" if is_player else "#2196F3"
	var prefix = "[%s] " % sender if not is_player else ""
	
	message_text.append_text("[color=%s]%s%s[/color]\n\n" % [color, prefix, text])
	conversation_history.append({"sender": sender, "text": text})
	
	var scroll_container = message_text.get_parent() as ScrollContainer
	if scroll_container:
		await get_tree().process_frame
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _send_message() -> void:
	if is_typing:
		return
	
	var text = input_line.text.strip_edges()
	if text.is_empty():
		return
	
	input_line.clear()
	_add_message("玩家", text)
	_show_typing(true)
	
	if ai_service and current_npc:
		var npc_name = npc_name_label.text
		ai_service.request_ai_response(text, npc_name)
	else:
		_add_message(npc_name_label.text, "嗯嗯，好的~")
		_show_typing(false)

func _show_typing(show: bool) -> void:
	is_typing = show
	typing_label.visible = show
	input_container.disabled = show

func _on_send_button_pressed() -> void:
	_send_message()

func _on_input_submitted(text: String) -> void:
	_send_message()

func _on_close_button_pressed() -> void:
	hide_dialog()

func _on_ai_response(response: String) -> void:
	_show_typing(false)
	_add_message(npc_name_label.text, response)

func _on_ai_error(error: String) -> void:
	_show_typing(false)
	_add_message(npc_name_label.text, "哎呀，我现在有点忙，稍后再聊吧~")
	print("AI错误: %s" % error)
