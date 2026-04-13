extends Node

## 大世界联机（ENet）：主机监听端口，客户端填入局域网 IP 加入。
## 生产环境建议独立专用服务器 + 鉴权；当前为可运行的局域网演示。

enum Mode { OFFLINE, HOST, CLIENT }

const DEFAULT_PORT := 17777
const MAX_CLIENTS := 16

var mode: Mode = Mode.OFFLINE
var port: int = DEFAULT_PORT

func reset_offline() -> void:
	_close_peer()
	mode = Mode.OFFLINE


func start_host() -> int:
	_close_peer()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	return OK


func start_client(address: String) -> int:
	_close_peer()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address.strip_edges(), port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	return OK


func _close_peer() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


func leave_session() -> void:
	_close_peer()
	mode = Mode.OFFLINE


func is_network_world() -> bool:
	return mode != Mode.OFFLINE and multiplayer.multiplayer_peer != null


func is_server() -> bool:
	return is_network_world() and multiplayer.is_server()


func get_visible_peer_count() -> int:
	if not is_network_world():
		return 1
	if multiplayer.is_server():
		return multiplayer.get_peers().size() + 1
	return multiplayer.get_peers().size() + 1
