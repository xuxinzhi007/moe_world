extends Node

## 移动端友好的对话 UI（底栏卡片 + 大按钮），替代系统 AcceptDialog。


func show_dialog(title: String, body: String) -> void:
	var dlg: Node = (preload("res://Scenes/MoeDialog.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(dlg)
	if dlg.has_method("present"):
		dlg.present(title, body)
