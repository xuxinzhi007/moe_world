extends Node

signal login_success(token: String, user_data: Dictionary)
signal login_failed(error: String)
signal register_success(message: String)
signal register_failed(error: String)

const API_BASE_URL = "http://localhost:8080/api"

var current_request: HTTPRequest
var is_processing: bool = false

func _ready() -> void:
	print("🔐 认证服务已初始化，地址: %s" % API_BASE_URL)

func login(username: String, password: String) -> void:
	if is_processing:
		print("⚠️  上一个请求还在处理中")
		return
	
	is_processing = true
	_make_request("/auth/login", {"username": username, "password": password}, _on_login_response)

func register(username: String, password: String, email: String = "") -> void:
	if is_processing:
		print("⚠️  上一个请求还在处理中")
		return
	
	is_processing = true
	var data = {"username": username, "password": password}
	if not email.is_empty():
		data["email"] = email
	_make_request("/auth/register", data, _on_register_response)

func _make_request(endpoint: String, data: Dictionary, callback: Callable) -> void:
	current_request = HTTPRequest.new()
	add_child(current_request)
	
	current_request.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		_on_request_completed(result, response_code, headers, body, callback)
	)
	
	var headers = ["Content-Type: application/json"]
	var json_string = JSON.stringify(data)
	var url = API_BASE_URL + endpoint
	var error = current_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		print("❌ 请求失败: %d" % error)
		is_processing = false
		callback.call(false, "请求发送失败")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, callback: Callable) -> void:
	is_processing = false
	
	if current_request:
		current_request.queue_free()
		current_request = null
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("❌ 网络请求失败，结果: %d" % result)
		callback.call(false, "网络请求失败")
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("❌ JSON解析失败")
		callback.call(false, "数据解析失败")
		return
	
	var response_data = json.data as Dictionary
	callback.call(true, response_code, response_data)

func _on_login_response(success: bool, response_code_or_error: Variant, response_data: Dictionary = {}) -> void:
	if not success:
		var error = response_code_or_error as String
		login_failed.emit(error)
		return
	
	var response_code = response_code_or_error as int
	if response_code == 200:
		var token = response_data.get("token", "")
		var user_data = response_data.get("user", {})
		print("✅ 登录成功！")
		login_success.emit(token, user_data)
	else:
		var error_msg = response_data.get("message", "登录失败")
		print("❌ 登录失败: %s" % error_msg)
		login_failed.emit(error_msg)

func _on_register_response(success: bool, response_code_or_error: Variant, response_data: Dictionary = {}) -> void:
	if not success:
		var error = response_code_or_error as String
		register_failed.emit(error)
		return
	
	var response_code = response_code_or_error as int
	if response_code == 200 or response_code == 201:
		var message = response_data.get("message", "注册成功！")
		print("✅ 注册成功！")
		register_success.emit(message)
	else:
		var error_msg = response_data.get("message", "注册失败")
		print("❌ 注册失败: %s" % error_msg)
		register_failed.emit(error_msg)
