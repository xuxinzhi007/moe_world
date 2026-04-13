extends Node

## 联机：仅 WebSocket JSON（后端 /ws/world）。单机不经过本节点会话。

enum Mode { OFFLINE, CLOUD }

signal cloud_ready
signal cloud_connection_failed(reason: String)
signal cloud_peer_joined(user_id: String, pos: Vector2, username: String)
signal cloud_peer_left(user_id: String)
signal cloud_peer_moved(user_id: String, pos: Vector2)
signal cloud_peer_profile(user_id: String, username: String)

var mode: Mode = Mode.OFFLINE

var cloud_room: String = "default"
var cloud_my_user_id: String = ""
var cloud_spawn: Vector2 = Vector2(640, 360)
var cloud_initial_peers: Array = []

var _ws: WebSocketPeer
var _ws_open: bool = false
var _cloud_connecting: bool = false
var _cloud_ping_accum: float = 0.0


func reset_offline() -> void:
	_close_peer()
	mode = Mode.OFFLINE


## 连接后端大世界 WebSocket。需 ProjectSettings：moe_world/api_base_url、moe_world/current_user.token
func start_cloud(room: String) -> int:
	_close_peer()
	var token := _get_saved_token()
	if token.is_empty():
		return ERR_UNAUTHORIZED
	var base := _get_api_origin()
	if base.is_empty():
		return ERR_DOES_NOT_EXIST
	var rid := room.strip_edges()
	if rid.is_empty():
		rid = "default"
	if not _is_valid_room_id(rid):
		return ERR_INVALID_PARAMETER
	cloud_room = rid
	cloud_my_user_id = ""
	cloud_spawn = Vector2(640, 360)
	cloud_initial_peers.clear()
	_ws = WebSocketPeer.new()
	var url := "%s/ws/world?token=%s&room=%s" % [base, token.uri_encode(), rid.uri_encode()]
	var err: int = _ws.connect_to_url(url)
	if err != OK:
		_ws = null
		return err
	_ws.outbound_buffer_size = 262144
	_ws.inbound_buffer_size = 262144
	mode = Mode.CLOUD
	_cloud_connecting = true
	_ws_open = false
	set_process(true)
	return OK


func send_cloud_move(pos: Vector2) -> void:
	if mode != Mode.CLOUD or not _ws_open or _ws == null:
		return
	var payload := JSON.stringify({"type": "world_move", "x": pos.x, "y": pos.y})
	_ws.send_text(payload)


func send_cloud_username(username: String) -> void:
	if mode != Mode.CLOUD or not _ws_open or _ws == null:
		return
	var u := username.strip_edges()
	if u.length() > 24:
		u = u.substr(0, 24)
	_ws.send_text(JSON.stringify({"type": "world_profile", "username": u}))


func is_cloud() -> bool:
	return mode == Mode.CLOUD


func _close_peer() -> void:
	_cloud_connecting = false
	_ws_open = false
	if _ws != null:
		_ws.close()
		_ws = null
	cloud_my_user_id = ""
	cloud_spawn = Vector2(640, 360)
	cloud_initial_peers.clear()


func leave_session() -> void:
	mode = Mode.OFFLINE
	_close_peer()


func _process(delta: float) -> void:
	if mode != Mode.CLOUD or _ws == null:
		return
	_ws.poll()
	var st := _ws.get_ready_state()
	if st == WebSocketPeer.STATE_CLOSED:
		if _cloud_connecting or _ws_open:
			cloud_connection_failed.emit("连接已关闭")
		_cleanup_cloud_session()
		return
	if st != WebSocketPeer.STATE_OPEN:
		return
	if not _ws_open:
		_ws_open = true
		_cloud_connecting = false
	_cloud_ping_accum += delta
	if _cloud_ping_accum >= 25.0:
		_cloud_ping_accum = 0.0
		_ws.send_text(JSON.stringify({"type": "ping"}))
	while _ws.get_available_packet_count() > 0:
		var pkt := _ws.get_packet().get_string_from_utf8()
		_handle_cloud_packet(pkt)


func _handle_cloud_packet(text: String) -> void:
	var j := JSON.new()
	if j.parse(text) != OK:
		return
	var d: Variant = j.data
	if typeof(d) != TYPE_DICTIONARY:
		return
	var msg: Dictionary = d
	var t: String = str(msg.get("type", ""))
	match t:
		"world_welcome":
			cloud_my_user_id = str(msg.get("user_id", ""))
			cloud_spawn = Vector2(float(msg.get("x", 640.0)), float(msg.get("y", 360.0)))
			cloud_initial_peers = msg.get("peers", []) as Array
			cloud_ready.emit()
			call_deferred("_deferred_send_local_username")
		"world_peer_joined":
			cloud_peer_joined.emit(
				str(msg.get("user_id", "")),
				Vector2(float(msg.get("x", 0.0)), float(msg.get("y", 0.0))),
				str(msg.get("username", ""))
			)
		"world_peer_left":
			cloud_peer_left.emit(str(msg.get("user_id", "")))
		"world_move":
			cloud_peer_moved.emit(str(msg.get("user_id", "")), Vector2(float(msg.get("x", 0.0)), float(msg.get("y", 0.0))))
		"world_peer_profile":
			cloud_peer_profile.emit(str(msg.get("user_id", "")), str(msg.get("username", "")))
		_:
			pass


func _deferred_send_local_username() -> void:
	if mode != Mode.CLOUD or not _ws_open:
		return
	var uname := ""
	if ProjectSettings.has_setting("moe_world/current_user"):
		var u: Variant = ProjectSettings.get_setting("moe_world/current_user")
		if u is Dictionary:
			uname = str((u as Dictionary).get("username", "")).strip_edges()
	send_cloud_username(uname)


func _cleanup_cloud_session() -> void:
	_ws_open = false
	_cloud_connecting = false
	if _ws != null:
		_ws = null
	if mode == Mode.CLOUD:
		cloud_my_user_id = ""
		cloud_initial_peers.clear()
		mode = Mode.OFFLINE


func _get_saved_token() -> String:
	if not ProjectSettings.has_setting("moe_world/current_user"):
		return ""
	var u: Variant = ProjectSettings.get_setting("moe_world/current_user")
	if u is Dictionary:
		return str((u as Dictionary).get("token", "")).strip_edges()
	return ""


func _get_api_origin() -> String:
	var api := ""
	if ProjectSettings.has_setting("moe_world/api_base_url"):
		api = str(ProjectSettings.get_setting("moe_world/api_base_url")).strip_edges()
	while api.ends_with("/"):
		api = api.substr(0, api.length() - 1)
	if api.ends_with("/api"):
		api = api.substr(0, api.length() - 4)
	while api.ends_with("/"):
		api = api.substr(0, api.length() - 1)
	if api.begins_with("https://"):
		return "wss://" + api.substr(8)
	if api.begins_with("http://"):
		return "ws://" + api.substr(7)
	return ""


func _is_valid_room_id(rid: String) -> bool:
	if rid.length() < 1 or rid.length() > 48:
		return false
	for i in rid.length():
		var c := rid.unicode_at(i)
		var ok := (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95 or c == 45
		if not ok:
			return false
	return true
