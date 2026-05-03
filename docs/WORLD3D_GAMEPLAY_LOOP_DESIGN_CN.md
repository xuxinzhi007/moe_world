# Godot 4.4 3D 玩法闭环设计文档

## 1. 目标与范围

本文针对当前项目 `Scenes/maps/world3d/World3D_Main.tscn` 的 3D 模式，定义一套在 **Godot 4.4 + GDScript** 下可直接落地的 MVP 闭环：

- 进入 3D 世界 -> 战斗清怪 -> 获得奖励（金币/晶核/经验）-> 强化成长（等级/属性点）-> 继续挑战更高波次 -> 返回大厅/2D 消费成长收益。
- 控制统一：
  - PC：鼠标控制视角/转向（第三人称绕角色），键盘负责移动与战斗按键。
  - 移动端：左侧摇杆移动，右侧屏幕滑动控制视角/转向，技能按钮可并行操作。

## 2. 现状分析（当前代码）

### 2.1 已有能力

- 3D 入口与切换已打通：大厅可进入 3D，3D 可返回 2D/大厅。
- 角色已有基础能力：移动、跳跃、闪避（`player_3d.gd`）。
- 3D 战斗雏形：普攻/技能/怪物接触伤害/重生（`world_3d_main.gd`）。
- 移动端输入雏形：左侧移动触摸区、右侧 look touch id。

### 2.2 核心缺口

- 缺少“阶段目标+奖励统计+成长反馈+失败恢复”的完整回环。
- PC 端视角转向未形成正式鼠标控制工作流。
- 3D 战斗收益与全局成长（`CharacterBuild`、`PlayerInventory`）关联不完整。
- 信息反馈不足：玩家无法清晰看到当前阶段目标、收益、进度。

## 3. 闭环设计（MVP）

### 3.1 核心回环

1. **进入场景**：初始化角色状态、当前战斗等级、阶段目标。  
2. **战斗阶段**：击败怪物获取 XP + 金币 + 晶核；怪物随波次提升强度。  
3. **阶段推进**：达到击杀目标后自动升阶段，提高怪物密度和强度。  
4. **失败恢复**：玩家 HP 归零后原地复位（或出生点复位），扣减少量阶段进度，不中断整局。  
5. **结算回流**：返回 2D/大厅前同步 `CharacterBuild` 战斗等级进度，保留 `PlayerInventory` 掉落收益。  

### 3.2 输入设计

- **PC**
  - 鼠标移动：更新 `_camera_yaw`（捕获鼠标）。
  - `ESC`：切换鼠标锁定/释放。
  - `WASD`：相对当前相机朝向移动。
  - `J/攻击键`、`K/技能键`、`Shift/闪避`。
- **移动端**
  - 左半屏拖拽：移动摇杆输入。
  - 右半屏拖拽：转向/视角控制。
  - 右下按钮：攻击/技能/闪避/跳跃，允许并行输入。

## 4. 技术实现方案（Godot 4.4）

### 4.1 输入与相机

- `world_3d_main.gd`
  - 新增 PC 鼠标 look：`Input.mouse_mode = CAPTURED` + `InputEventMouseMotion` 更新 `_camera_yaw`。
  - 保留移动端右半屏拖拽逻辑。
  - 每帧将 `_camera_yaw` 同步给 `player_3d.gd`，确保移动方向始终按当前视角解释。

- `player_3d.gd`
  - 新增 `set_camera_yaw()`。
  - 将 `Input.get_vector()` 的输入转为“相机相对方向”的世界向量，再参与速度和闪避计算。

### 4.2 战斗与成长

- 在 `world_3d_main.gd` 增加：
  - `_combat_level/_combat_xp/_combat_xp_next`。
  - `_stage_index/_stage_kills/stage_goal_kills`。
  - 击杀奖励：金币（coin）+ 晶核（trial_core）+ XP。
  - 升级时调用 `CharacterBuild.grant_points_for_levels()`。
  - 实时同步 `CharacterBuild.set_runtime_combat_progress()`。

### 4.3 怪物阶段化

- 每次生成怪物按阶段和等级缩放：
  - `max_hp`
  - `move_speed`
  - `contact_damage`
- 保持固定刷新点体系，动态调整目标存活数（base -> cap）。

### 4.4 失败恢复

- 玩家血量为 0 时：
  - 立即 `full_heal_player()`。
  - 玩家复位到出生点。
  - 阶段击杀进度小幅回退，避免挫败感过强。

### 4.5 HUD 与反馈

- 新增运行 HUD（动态 Label）：
  - 当前阶段、阶段目标进度、等级 XP、HP、总击杀、局内收益、用时。
- 原 `StatusLabel` 仍承担短时战斗反馈（命中/受伤/阶段提升）。

## 5. 数据契约

- `CharacterBuild`（已存在）
  - 读：`runtime_combat_level/runtime_combat_xp/get_player_hp/get_max_hp`
  - 写：`set_runtime_combat_progress/grant_points_for_levels/full_heal_player`
- `PlayerInventory`（已存在）
  - 掉落：`coin`、`trial_core`

## 6. 验收标准（MVP）

1. PC 端可用鼠标稳定控制转向；`ESC` 可释放/重新捕获鼠标。  
2. 移动端左移右转同时可操作，不互相抢输入。  
3. 击败怪物后可见阶段进度增长，达到阈值后自动升阶段。  
4. 局内奖励可累计到背包（金币、晶核），并在返回大厅/2D 后保留。  
5. 玩家死亡后自动恢复，不会卡死流程。  
6. 全流程在 Godot 4.4 运行无脚本报错。  

## 7. 后续扩展（不阻塞当前）

- 技能树/职业分支在 3D 模式下独立参数化。
- 3D 专属怪物行为树（远程、冲锋、AOE 警示圈）。
- 3D 掉落实体化拾取（当前为直接发放）。
- 章节化地图和 2D/3D 跨模式任务联动。
