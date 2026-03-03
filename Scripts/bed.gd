extends StaticBody2D

# ========== 可配置参数（编辑器调整） ==========
@export var base_gold_per_second: int = 1  # 初始每秒金币
@export var initial_upgrade_cost: int = 10  # 初始升级成本
@export var cost_growth_rate: float = 1.5  # 升级成本递增倍率（可微调）
@export var max_level: int = 10  # 床最大等级（避免无限升级）
@export var level_bonus: int = 1  # 每级额外增加的金币产量（可扩展）

# ========== 核心数据 ==========
var level: int = 1  # 床等级
var upgrade_cost: int  # 实时升级成本（动态计算）
var is_max_level: bool = false  # 是否达到满级

# ========== 初始化 ==========
func _ready() -> void:
	# 初始化升级成本
	upgrade_cost = initial_upgrade_cost
	# 检测是否初始就满级（防呆）
	_check_max_level()
	print("✅ 床初始化完成！当前等级：%d，每秒产金币：%d，升级成本：%d" % [level, get_current_gold_per_second(), upgrade_cost])

# ========== 核心功能：获取当前每秒金币产量（增强扩展） ==========
func get_current_gold_per_second() -> int:
	# 基础产量 = 初始产量 × 等级 + 等级额外奖励（可灵活调整成长曲线）
	return base_gold_per_second * level + (level - 1) * level_bonus

# ========== 核心功能：升级床（增强容错+限制） ==========
func upgrade(player_gold: int) -> bool:
	# 容错1：玩家金币为负数/无效值
	if player_gold < 0:
		print("❌ 升级失败：玩家金币为无效值！")
		return false
	
	# 容错2：已达满级
	if is_max_level:
		print("❌ 床已达满级（%d级），无法继续升级！" % max_level)
		return false
	
	# 容错3：升级成本计算异常
	if upgrade_cost <= 0:
		upgrade_cost = initial_upgrade_cost
		print("⚠️ 升级成本异常，已重置为初始值：%d" % initial_upgrade_cost)
	
	# 检查金币是否足够
	if player_gold >= upgrade_cost:
		# 升级等级
		level += 1
		# 检查是否满级
		_check_max_level()
		
		# 计算新的升级成本（未满级时才递增）
		if not is_max_level:
			upgrade_cost = int(upgrade_cost * cost_growth_rate)
			# 防呆：成本不能为0/负数
			upgrade_cost = max(upgrade_cost, initial_upgrade_cost)
		
		# 打印升级信息
		var tip = "✅ 床升级到%d级！" % level
		tip += " 每秒产金币：%d" % get_current_gold_per_second()
		if not is_max_level:
			tip += "，下次升级需要%d金币" % upgrade_cost
		else:
			tip += "（已满级）"
		print(tip)
		return true
	else:
		print("❌ 金币不足！升级需要%d，当前：%d" % [upgrade_cost, player_gold])
		return false

# ========== 辅助功能：检查是否满级 ==========
func _check_max_level() -> void:
	is_max_level = level >= max_level
	if is_max_level:
		level = max_level  # 强制限制等级不超限
		upgrade_cost = 999999  # 满级后设置极高成本，防止误升级

# ========== 扩展功能：降级/重置（方便测试/扩展） ==========
func reset_level() -> void:
	level = 1
	upgrade_cost = initial_upgrade_cost
	is_max_level = false
	print("✅ 床已重置为初始状态！等级：1，升级成本：%d" % initial_upgrade_cost)

func downgrade() -> bool:
	if level <= 1:
		print("❌ 床已为1级，无法降级！")
		return false
	
	level -= 1
	upgrade_cost = int(upgrade_cost / cost_growth_rate)  # 降级后成本降低
	upgrade_cost = max(upgrade_cost, initial_upgrade_cost)
	is_max_level = false
	print("✅ 床降级到%d级！下次升级需要%d金币" % [level, upgrade_cost])
	return true

# ========== 扩展功能：获取床的完整信息（方便UI显示） ==========
func get_bed_info() -> Dictionary:
	return {
		"level": level,
		"max_level": max_level,
		"is_max_level": is_max_level,
		"gold_per_second": get_current_gold_per_second(),
		"upgrade_cost": upgrade_cost,
		"next_level_gold": get_current_gold_per_second() + level_bonus + base_gold_per_second  # 下一级产量
	}
