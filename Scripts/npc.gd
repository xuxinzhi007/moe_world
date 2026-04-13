extends Node2D

## 简单可交互 NPC：进入 Area2D 范围后玩家可按交互键或手机「E」对话。

@export var npc_display_name: String = "萌系店员"
@export_multiline var dialog_message: String = "欢迎光临 moe world～今天也要开心哦！"

@onready var interact_area: Area2D = $InteractArea


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.add_nearby_npc(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.remove_nearby_npc(self)


func try_interact() -> void:
	var dlg := AcceptDialog.new()
	dlg.title = npc_display_name
	dlg.dialog_text = dialog_message
	dlg.ok_button_text = "好的"
	get_tree().root.add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(func(): dlg.queue_free())
	dlg.canceled.connect(func(): dlg.queue_free())
