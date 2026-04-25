extends Node2D

## 简单可交互 NPC：进入 Area2D 范围后玩家可按交互键或手机「E」对话。

@export var npc_display_name: String = "萌系店员"
@export_multiline var dialog_message: String = "欢迎光临 moe world～今天也要开心哦！"
## 立绘在场景里的大致高度（像素），大图会自动缩小。
@export_range(32.0, 200.0, 2.0) var portrait_target_height: float = 88.0

@onready var interact_area: Area2D = $InteractArea
@onready var portrait: Sprite2D = $Portrait


func _ready() -> void:
	z_as_relative = false
	if is_instance_valid(portrait) and portrait.texture != null:
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var h: float = maxf(1.0, float(portrait.texture.get_height()))
		var s: float = clampf(portrait_target_height / h, 0.02, 2.0)
		portrait.scale = Vector2.ONE * s
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	z_index = int(floor(global_position.y))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.add_nearby_npc(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.remove_nearby_npc(self)


func try_interact() -> void:
	if MoeDialogBus.is_dialog_open():
		return
	MoeDialogBus.show_dialog(npc_display_name, dialog_message)
