extends Node2D

# ========== 导出配置（可在编辑器调整） ==========
@export var grid_cell_size: Vector2 = Vector2(64, 64)
@export var room_min_size: Vector2i = Vector2i(3, 3)
@export var room_max_size: Vector2i = Vector2i(5, 5)
@export var room_count: int = 4
@export var map_boundary: Rect2 = Rect2(0, 0, 1500, 1200)
@export var min_room_distance: float = 100.0  # 房间之间最小间距（可在编辑器调）

# ========== 内部变量 ==========
var rooms: Array[Dictionary] = []

# ========== 初始化 ==========
func _ready() -> void:
	print("🔍 MapGenerator 初始化，开始生成地图")
	generate_map()

# ========== 核心：生成随机地图（修复所有错误） ==========
func generate_map() -> void:
	print("🔍 开始生成地图，目标：%d个房间" % room_count)
	
	# 清空旧房间
	for room in rooms:
		if room["node"]:
			room["node"].queue_free()
	rooms.clear()
	
	var generated_count = 0
	var try_count = 0
	var max_try = 500  # 增加最大尝试次数，避免生成失败
	
	while generated_count < room_count and try_count < max_try:
		try_count += 1
		
		# 1. 随机房间大小（像素）
		var room_grid_width = randi() % (room_max_size.x - room_min_size.x + 1) + room_min_size.x
		var room_grid_height = randi() % (room_max_size.y - room_min_size.y + 1) + room_min_size.y
		var room_pixel_size = Vector2(
			room_grid_width * grid_cell_size.x,
			room_grid_height * grid_cell_size.y
		)
		
		# 2. 随机房间位置（限制在生成区域内）
		var room_x = randf_range(
			map_boundary.position.x,
			map_boundary.position.x + map_boundary.size.x - room_pixel_size.x
		)
		var room_y = randf_range(
			map_boundary.position.y,
			map_boundary.position.y + map_boundary.size.y - room_pixel_size.y
		)
		var room_rect = Rect2(room_x, room_y, room_pixel_size.x, room_pixel_size.y)
		
		# 3. 核心修复：检查是否重叠/间距过近（替换distance_to）
		var is_invalid = false
		for room in rooms:
			var existing_rect = room["rect"]  # 必须用字典键访问
			
			# 修复：用矩形中心点距离替代distance_to（Rect2无此方法）
			var existing_center = existing_rect.position + existing_rect.size / 2
			var new_center = room_rect.position + room_rect.size / 2
			var distance_between_centers = existing_center.distance_to(new_center)
			
			# 检测重叠 OR 中心点距离小于设定值
			if existing_rect.intersects(room_rect) or distance_between_centers < min_room_distance:
				is_invalid = true
				break
		
		# 4. 有效则创建房间
		if not is_invalid:
			var room_id = generated_count
			var room_node = _create_room_node(room_rect, room_id)
			var room_data = {
				"id": room_id,
				"rect": room_rect,
				"node": room_node,
				"bed_node": room_node.get_node("Bed"),
				"resource_node": room_node.get_node("Resource"),
				"door_node": room_node.get_node("Door"),
				"is_door_closed": false
			}
			add_child(room_node)
			rooms.append(room_data)
			generated_count += 1
			print("✅ 生成房间%d：位置(%d,%d) 大小(%d,%d)" % [
				room_id, room_x, room_y, room_pixel_size.x, room_pixel_size.y
			])
	
	print("📊 最终生成%d个房间（尝试%d次）" % [generated_count, try_count])
	if generated_count < room_count:
		print("⚠️ 建议调大 map_boundary 或减小 min_room_distance")

# ========== 辅助：纯代码创建单个房间（只负责创建，不做检测） ==========
func _create_room_node(room_rect: Rect2, room_id: int) -> Node2D:
	# 1. 创建房间根节点
	var room_node = Node2D.new()
	room_node.name = "Room_%d" % room_id
	
	# 2. 房间背景
	var room_bg = ColorRect.new()
	room_bg.name = "RoomBG"
	room_bg.size = room_rect.size
	room_bg.position = room_rect.position
	room_bg.color = Color(0.1, 0.5, 0.8, 0.4)
	room_bg.z_index = -1
	room_node.add_child(room_bg)
	
	# 3. 房间编号标签
	var id_label = Label.new()
	id_label.name = "RoomIDLabel"
	id_label.text = "房间 %d" % room_id
	id_label.position = room_rect.position + room_rect.size/2 - Vector2(30, 15)
	id_label.add_theme_font_size_override("font_size", 20)
	id_label.add_theme_color_override("font_color", Color(1, 1, 1))
	room_node.add_child(id_label)
	
	# 4. 床
	var bed_pos = room_rect.position + Vector2(grid_cell_size.x, room_rect.size.y - grid_cell_size.y)
	var bed_node = Node2D.new()
	bed_node.name = "Bed"
	bed_node.position = bed_pos
	var bed_visual = ColorRect.new()
	bed_visual.size = Vector2(48, 48)
	bed_visual.color = Color(1, 0.8, 0.2, 0.9)
	bed_node.add_child(bed_visual)
	room_node.add_child(bed_node)
	
	# 5. 资源点
	var res_pos = room_rect.position + Vector2(room_rect.size.x - grid_cell_size.x, room_rect.size.y - grid_cell_size.y)
	var res_node = Node2D.new()
	res_node.name = "Resource"
	res_node.position = res_pos
	var res_visual = ColorRect.new()
	res_visual.size = Vector2(48, 48)
	res_visual.color = Color(0, 1, 0, 0.9)
	res_node.add_child(res_visual)
	room_node.add_child(res_node)
	
	# 6. 门
	var door_pos = room_rect.position + Vector2(room_rect.size.x, room_rect.size.y/2)
	var door_node = Node2D.new()
	door_node.name = "Door"
	door_node.position = door_pos
	var door_visual = ColorRect.new()
	door_visual.size = Vector2(32, 64)
	door_visual.color = Color(1, 0.2, 0.2, 0.9)
	door_node.add_child(door_visual)
	room_node.add_child(door_node)
	
	return room_node

# ========== 玩家交互方法 ==========
func get_player_room_data(player_pos: Vector2) -> Dictionary:
	for room in rooms:
		if room["rect"].has_point(player_pos):  # 修复：用字典键访问
			return room
	return {}

func get_player_room(player_pos: Vector2) -> Dictionary:
	return get_player_room_data(player_pos)

func get_map_boundary() -> Rect2:
	return map_boundary

func get_rooms() -> Array[Dictionary]:
	return rooms

func is_point_in_player_room(player_pos: Vector2, target_pos: Vector2) -> bool:
	var player_room = get_player_room_data(player_pos)
	if not player_room:
		return false
	return player_room["rect"].has_point(target_pos)  # 修复：用字典键访问

func toggle_door(room_data: Dictionary) -> void:
	if not room_data:
		return
	room_data["is_door_closed"] = not room_data["is_door_closed"]  # 修复：用字典键访问
	var door_visual = room_data["door_node"].get_child(0) as ColorRect
	if door_visual:
		door_visual.color = Color(0.5, 0.1, 0.1, 0.9) if room_data["is_door_closed"] else Color(1, 0.2, 0.2, 0.9)
	print("🚪 房间门已%s" % ("关闭" if room_data["is_door_closed"] else "打开"))
