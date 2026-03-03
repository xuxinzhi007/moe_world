extends PanelContainer

# ========== 配置参数 ==========
@export var menu_offset: Vector2 = Vector2(10, 10)  # 菜单相对于鼠标的偏移
@export var turret_build_cost: int = 50  # 炮台建造成本

# ========== 核心引用 ==========
var player: CharacterBody2D
var grid_manager: Node2D
var current_grid_pos: Vector2i = Vector2i(-1, -1)

# ========== 按钮引用 ==========
@onready var btn_build_turret: Button = $ButtonContainer/BtnBuildTurret
@onready var btn_upgrade_bed: Button = $ButtonContainer/BtnUpgradeBed

# ========== 初始化 ==========
func init(_player: CharacterBody2D, _grid_manager: Node2D) -> void:
	player = _player
	grid_manager = _grid_manager
	
	# 绑定按钮事件（这次只绑定，不做任何拦截）
	if btn_build_turret:
		btn_build_turret.pressed.connect(_on_build_turret_click)
	if btn_upgrade_bed:
		btn_upgrade_bed.pressed.connect(_on_upgrade_bed_click)
	
	# 强制默认隐藏
	visible = false
	print("✅ 菜单初始化完成，默认隐藏")

# ========== 显示/隐藏菜单（纯功能，无拦截） ==========
func show_menu(mouse_pos: Vector2, grid_pos: Vector2i) -> void:
	current_grid_pos = grid_pos
	# 菜单位置 = 鼠标位置 + 偏移，且不超出屏幕
	var target_pos = mouse_pos + menu_offset
	target_pos.x = clamp(target_pos.x, 0, get_viewport_rect().size.x - size.x)
	target_pos.y = clamp(target_pos.y, 0, get_viewport_rect().size.y - size.y)
	position = target_pos
	
	# 更新按钮状态（灰显不可用选项）
	_update_buttons()
	visible = true

func hide_menu() -> void:
	visible = false
	current_grid_pos = Vector2i(-1, -1)

# ========== 检查鼠标是否在菜单内 ==========
func is_mouse_inside() -> bool:
	if not visible:
		return false
	# 获取鼠标全局位置，判断是否在菜单矩形内
	var mouse_global = get_viewport().get_mouse_position()
	return get_global_rect().has_point(mouse_global)

# ========== 更新按钮状态 ==========
func _update_buttons() -> void:
	# 建造炮台按钮
	if btn_build_turret and player and grid_manager:
		var can_build = player.current_gold >= turret_build_cost and grid_manager.is_grid_available(current_grid_pos)
		btn_build_turret.disabled = not can_build
		btn_build_turret.text = "建造炮台（%d金币）" % turret_build_cost + ("" if can_build else "（不可用）")
	
	# 升级床按钮
	if btn_upgrade_bed and player and player.bed_node:
		var can_upgrade = player.current_gold >= player.bed_node.upgrade_cost and player.is_near_bed
		btn_upgrade_bed.disabled = not can_upgrade
		btn_upgrade_bed.text = "升级床（%d金币）" % player.bed_node.upgrade_cost + ("" if can_upgrade else "（不可用）")

# ========== 按钮点击逻辑 ==========
func _on_build_turret_click() -> void:
	if not player or not grid_manager or current_grid_pos.x < 0:
		hide_menu()
		return
	
	if player.current_gold >= turret_build_cost and grid_manager.is_grid_available(current_grid_pos):
		# 扣金币+建造
		player.current_gold -= turret_build_cost
		player.gold_label.text = "金币: %d" % player.current_gold
		grid_manager.build_turret(current_grid_pos)
		print("✅ 建造炮台成功")
	else:
		print("❌ 无法建造炮台")
	
	hide_menu()  # 点击后关闭菜单

func _on_upgrade_bed_click() -> void:
	if not player or not player.bed_node or not player.is_near_bed:
		hide_menu()
		return
	
	var success = player.bed_node.upgrade(player.current_gold)
	if success:
		player.current_gold -= int(player.bed_node.upgrade_cost / 1.5)
		player.gold_label.text = "金币: %d" % player.current_gold
		player.gold_per_second = player.bed_node.get_current_gold_per_second()
		print("✅ 床升级成功")
	
	hide_menu()  # 点击后关闭菜单
