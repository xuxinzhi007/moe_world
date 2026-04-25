extends Node

## 移动端友好的对话 UI（底栏卡片 + 大按钮），替代系统 AcceptDialog。
## 同时只允许一个对话框，并同步本地玩家的 is_in_dialog，防止连点叠多层。

var _active_dialog: Node = null


func is_dialog_open() -> bool:
	return is_instance_valid(_active_dialog)


func show_dialog(title: String, body: String) -> void:
	if is_dialog_open():
		return
	var dlg: Node = (preload("res://Scenes/MoeDialog.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(dlg)
	_active_dialog = dlg
	dlg.tree_exited.connect(_on_dialog_tree_exited, CONNECT_ONE_SHOT)
	if dlg.has_method("present"):
		dlg.present(title, body)
	GameAudio.ui_confirm()
	_notify_local_players_dialog(true)


func _on_dialog_tree_exited() -> void:
	_active_dialog = null
	_notify_local_players_dialog(false)


func _notify_local_players_dialog(opened: bool) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if not p.has_method("is_local_controllable"):
			continue
		if not p.is_local_controllable():
			continue
		if opened and p.has_method("start_dialog"):
			p.start_dialog()
		elif not opened and p.has_method("end_dialog"):
			p.end_dialog()
