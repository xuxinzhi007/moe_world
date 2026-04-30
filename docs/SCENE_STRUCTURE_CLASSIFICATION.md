# 场景目录分类规范（过渡版）

## 目标

- 按类型归档场景，降低查找与维护成本。
- 保持老路径兼容，避免一次性迁移导致引用断裂。

## 当前分类

- `Scenes/maps/`：地图与地图入口场景
  - `World_Main.tscn`
  - `Trial_Survivor_Main.tscn`
- `Scenes/actors/`：角色与怪物实体入口
  - `Player.tscn`
  - `NPC.tscn`
  - `Monster.tscn`
  - `DemonMonster.tscn`
- `Scenes/fx/`：战斗特效与反馈入口
  - `MeleeAttackFX.tscn`
  - `MageSpellFX.tscn`
  - `MageManaBlastFX.tscn`
  - `PriestHealFX.tscn`
  - `PriestHolyRayFX.tscn`
  - `PriestDivinePrayerFX.tscn`
  - `WarriorPowerStrikeFX.tscn`
  - `FloatingWorldText.tscn`
- `Scenes/projectiles/`：投射物入口
  - `ArcherArrowProjectile.tscn`
- `Scenes/decor/`：装饰/场景道具入口
  - `LootPickup.tscn`
- `Scenes/ui/`：界面与叠层场景
- `Scenes/`（根目录）：历史场景与通用实体场景（后续逐步迁移）

## 入口约定

- 大世界统一入口：`res://Scenes/maps/World_Main.tscn`
- 试炼统一入口：`res://Scenes/maps/Trial_Survivor_Main.tscn`

## 迁移策略

1. 先新增分类入口并更新脚本引用（已执行）。
2. 保留旧场景文件一段时间用于兼容。
3. 后续再把根目录老场景分批迁移到：
   - `Scenes/maps/`（地图）
   - `Scenes/actors/`（Player/NPC/Monster 等）
   - `Scenes/fx/`（战斗特效、反馈）
   - `Scenes/projectiles/`（投射物）
   - `Scenes/decor/`（装饰/道具）
   - `Scenes/ui/`（已存在，继续收敛）

## 设计师提交约束

- 新地图一律提交到 `Scenes/maps/`。
- 命名建议：`World_*.tscn`、`Trial_*.tscn`。
- 不要在 `Scenes/` 根目录新增地图文件。
