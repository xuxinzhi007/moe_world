extends Node3D

@export var npc_display_name: String = "萌系店员"
@export_multiline var dialog_message: String = "欢迎光临 moe world～今天也要开心哦！"
@export var portrait_pixel_size: float = 0.0028

@onready var interact_area: Area3D = $InteractArea
@onready var portrait: Sprite3D = $Portrait


func _ready() -> void:
	if is_instance_valid(portrait) and portrait.texture != null:
		portrait.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		portrait.pixel_size = portrait_pixel_size
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("add_nearby_npc"):
		body.add_nearby_npc(self)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("remove_nearby_npc"):
		body.remove_nearby_npc(self)


func try_interact() -> void:
	if MoeDialogBus.is_dialog_open():
		return
	MoeDialogBus.show_dialog(npc_display_name, dialog_message)
