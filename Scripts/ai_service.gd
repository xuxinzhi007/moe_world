extends Node

signal ai_response_received(response: String)
signal ai_error_occurred(error: String)

const AI_API_URL = "http://localhost:11434/api/generate"

var current_request: HTTPRequest
var is_requesting: bool = false

func _ready() -> void:
	print("🤖 AI服务已初始化，地址: %s" % AI_API_URL)

func request_ai_response(prompt: String, npc_name: String = "NPC", system_prompt: String = "") -> void:
	if is_requesting:
		print("⚠️  上一个请求还在处理中")
		return

	is_requesting = true

	current_request = HTTPRequest.new()
	add_child(current_request)

	current_request.request_completed.connect(_on_request_completed)

	var headers = ["Content-Type: application/json"]

	var system_msg = system_prompt if not system_prompt.is_empty() else \
		"你是萌社区里的%s，一个友好、活泼、可爱的角色。请用简短、亲切、自然的语气和玩家聊天。" % npc_name

	var request_body = {
		"model": "llama2",
		"prompt": "%s\n\n玩家说: %s\n\n你的回答:" % [system_msg, prompt],
		"stream": false,
		"temperature": 0.7,
		"max_tokens": 200
	}

	var json_string = JSON.stringify(request_body)
	var error = current_request.request(AI_API_URL, headers, HTTPClient.METHOD_POST, json_string)

	if error != OK:
		print("❌ AI请求失败: %d" % error)
		is_requesting = false
		ai_error_occurred.emit("请求发送失败")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	is_requesting = false

	if current_request:
		current_request.queue_free()
		current_request = null

	if result != HTTPRequest.RESULT_SUCCESS:
		print("❌ AI请求失败，结果: %d" % result)
		ai_error_occurred.emit("网络请求失败")
		return

	if response_code != 200:
		print("❌ AI服务器返回错误: %d" % response_code)
		ai_error_occurred.emit("服务器错误 %d" % response_code)
		return

	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())

	if parse_result != OK:
		print("❌ JSON解析失败")
		ai_error_occurred.emit("数据解析失败")
		return

	var response_data = json.data as Dictionary

	if response_data.has("response"):
		var ai_response = response_data["response"] as String
		ai_response = ai_response.strip_edges()
		print("🤖 AI回复: %s" % ai_response)
		ai_response_received.emit(ai_response)
	else:
		print("❌ 响应格式错误")
		ai_error_occurred.emit("响应格式错误")
