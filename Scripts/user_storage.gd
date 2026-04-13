extends Node

## 登录态写入 user://，避免运行时调用 ProjectSettings.save()（导出包无法写 project.godot）。

const CFG_PATH := "user://moe_world_session.cfg"


func _ready() -> void:
	restore_into_project_settings()


func restore_into_project_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(CFG_PATH) != OK:
		return
	var api := str(cf.get_value("session", "api_base_url", ""))
	var ujson := str(cf.get_value("session", "user_json", ""))
	if not api.is_empty():
		ProjectSettings.set_setting("moe_world/api_base_url", api)
	if not ujson.is_empty():
		var p := JSON.new()
		if p.parse(ujson) == OK and p.data is Dictionary:
			ProjectSettings.set_setting("moe_world/current_user", p.data)


func persist_current_session() -> void:
	var u: Variant = ProjectSettings.get_setting("moe_world/current_user", {})
	if not u is Dictionary:
		return
	var d: Dictionary = u
	if d.is_empty():
		clear_session_file()
		return
	var api := ""
	if ProjectSettings.has_setting("moe_world/api_base_url"):
		api = str(ProjectSettings.get_setting("moe_world/api_base_url"))
	_save_cfg(d, api)


func clear_session_file() -> void:
	if not FileAccess.file_exists(CFG_PATH):
		return
	var da := DirAccess.open("user://")
	if da:
		da.remove("moe_world_session.cfg")


func _save_cfg(user: Dictionary, api_base_url: String) -> void:
	var cf := ConfigFile.new()
	cf.set_value("session", "api_base_url", api_base_url)
	cf.set_value("session", "user_json", JSON.stringify(user))
	var err := cf.save(CFG_PATH)
	if err != OK:
		push_warning("UserStorage: save failed (%d)" % err)
