# 项目文件结构说明（中文）

> 版本：按当前仓库状态整理  
> 目标：快速说明“每个目录/文件做什么”，便于协作、交接和后续重构。

---

## 1) 目录树视图（推荐先看）

```text
moe_world/
├── project.godot                      # Godot 工程配置（主场景/输入/Autoload）
├── README.md                          # 项目说明
├── Scenes/
│   ├── maps/                          # 地图入口（新结构）
│   │   ├── World_Main.tscn
│   │   └── Trial_Survivor_Main.tscn
│   ├── actors/                        # 角色/怪物入口（新结构）
│   │   ├── Player.tscn
│   │   ├── NPC.tscn
│   │   ├── Monster.tscn
│   │   └── DemonMonster.tscn
│   ├── projectiles/                   # 投射物入口（新结构）
│   │   └── ArcherArrowProjectile.tscn
│   ├── fx/                            # 特效入口（新结构）
│   │   ├── MeleeAttackFX.tscn
│   │   ├── MageSpellFX.tscn
│   │   ├── MageManaBlastFX.tscn
│   │   ├── PriestHealFX.tscn
│   │   ├── PriestHolyRayFX.tscn
│   │   ├── PriestDivinePrayerFX.tscn
│   │   ├── WarriorPowerStrikeFX.tscn
│   │   └── FloatingWorldText.tscn
│   ├── decor/                         # 装饰/掉落入口（新结构）
│   │   └── LootPickup.tscn
│   ├── ui/                            # UI 场景
│   │   ├── HallScene.tscn
│   │   ├── LoginScreen.tscn
│   │   ├── RegisterScreen.tscn
│   │   ├── ProfileScene.tscn
│   │   ├── CharacterBuildPanel.tscn
│   │   ├── BackpackOverlay.tscn
│   │   ├── WeaponShopOverlay.tscn
│   │   ├── WorldMapOverlay.tscn
│   │   ├── WorldChat.tscn
│   │   ├── ChatBubble.tscn
│   │   ├── MobileGameplayControls.tscn
│   │   ├── WorldGameplayHud.tscn
│   │   ├── MoeDialog.tscn
│   │   └── DialogSystem.tscn
│   └── *.tscn                         # 历史兼容场景（根目录旧副本）
├── Scripts/
│   ├── autoload/                      # 全局单例
│   ├── meta/                          # 场景控制/主题/过渡
│   ├── auth/                          # 登录注册
│   ├── world/                         # 大世界系统
│   ├── survivor/                      # 试炼系统
│   ├── player/                        # 玩家逻辑
│   ├── combat/                        # 战斗与特效逻辑
│   └── ui/                            # UI 功能逻辑
├── docs/                              # 产品/架构/测试/流程文档
├── .cursor/skills/                    # Cursor 技能
└── .trae/skills/                      # Trae 技能
```

---

## 2) 顶层关键文件

- `project.godot`：Godot 工程主配置（启动场景、输入映射、Autoload 单例等）。
- `README.md`：项目总览、运行说明、玩法和技术说明。
- `docs/`：产品、架构、测试、流程类文档。
- `Scenes/`：所有场景资源（地图、UI、角色、特效、投射物、装饰物）。
- `Scripts/`：GDScript 逻辑代码。
- `.cursor/skills/`：本地 Cursor 技能（开发流程与规范自动化）。
- `.trae/skills/`：Trae 兼容技能入口（轻量）。

---

## 3) Scripts 代码结构（按职责）

## 2.1 `Scripts/autoload/`（全局单例）

- `character_build.gd`：角色成长数据（职业、属性、HP、技能冷却、存档）。
- `game_audio.gd`：全局音频管理（BGM/音效触发）。
- `moe_dialog_bus.gd`：全局对话弹层总线。
- `player_inventory.gd`：本地背包/材料栈管理。
- `user_storage.gd`：本地用户会话持久化。
- `world_network.gd`：联机网络会话与云端事件。

## 2.2 `Scripts/meta/`（元系统/场景控制）

- `hall_scene.gd`：大厅主流程（进入世界、联机、信息面板、按钮交互）。
- `profile_scene.gd`：个人中心页面逻辑。
- `scene_transition.gd`：统一场景切换与过渡。
- `ui_theme.gd`：UI 主题样式与响应式尺寸工具。
- `moe_dialog.gd`：对话弹层逻辑。
- `sakura_particles.gd`：樱花粒子装饰逻辑。
- `bubble_particles.gd`：气泡粒子装饰逻辑。
- `global_state.gd`：全局状态缓存/中转（历史兼容用途）。

## 2.3 `Scripts/auth/`（账号鉴权）

- `auth_service.gd`：登录/注册请求与服务器状态检查。
- `login_screen.gd`：登录界面逻辑。
- `register_screen.gd`：注册界面逻辑。

## 2.4 `Scripts/world/`（大世界）

- `world_scene.gd`：大世界主控制器（玩家、怪物、掉落、UI、联机、传送门）。
- `world_monster.gd`：普通怪行为。
- `demon_monster.gd`：精英/恶魔怪行为。
- `npc.gd`：NPC 行为与对话触发。
- `survivor_portal.gd`：试炼传送门触发逻辑。
- `loot_pickup.gd`：掉落物拾取逻辑。
- `floating_world_text.gd`：世界飘字表现。
- `ground_tile_sprite.gd`：地面表现与地皮配置。
- `decoration_z_sort.gd`：装饰物 Z 排序。
- `world_region_zone.gd`：区域触发区（标题/副标题）。
- `world_region_toast.gd`：区域提示显示。
- `world_chat.gd`：世界聊天主面板。
- `chat_bubble.gd`：聊天气泡实例逻辑。
- `world_map_overlay.gd`：大地图面板逻辑。
- `world_minimap_drawer.gd`：小地图绘制逻辑。
- `world_radar_minimap.gd`：雷达小地图逻辑。
- `world_time_weather.gd`：时间天气与 HUD 时钟绑定。

## 2.5 `Scripts/survivor/`（试炼模式）

- `survivor_arena.gd`：试炼主控制（波次、结算、评级、奖励、返回世界）。

## 2.6 `Scripts/player/`（玩家）

- `player.gd`：玩家移动、攻击、交互、输入适配（键鼠/移动端）。

## 2.7 `Scripts/combat/`（战斗与特效）

- `archer_arrow_projectile.gd`：弓箭投射物。
- `archer_volley.gd`：弓手齐射技能逻辑。
- `mage_spell_fx.gd`：法师技能特效控制。
- `mage_mana_blast_fx.gd`：法师爆发特效控制。
- `priest_heal_fx.gd`：牧师治疗特效控制。
- `priest_holy_ray_fx.gd`：牧师圣光特效控制。
- `priest_divine_prayer_fx.gd`：牧师祷言特效控制。
- `warrior_power_strike_fx.gd`：战士强击特效控制。
- `melee_attack_fx.gd`：近战挥击特效控制。
- `attack_range_fx.gd`：攻击范围提示特效。
- `hit_flash.gd`：受击闪白反馈。

## 2.8 `Scripts/ui/`（UI 功能面板）

- `character_build_panel.gd`：成长面板（加点、技能、材料强化）。
- `backpack_overlay.gd`：背包面板。
- `weapon_shop_overlay.gd`：武器商店面板。
- `mobile_controls.gd`：移动端虚拟按键面板。

---

## 4) Scenes 场景结构（按类型分类）

> 当前采用“新分类入口 + 旧场景兼容”策略：  
> 新逻辑优先引用 `Scenes/maps|actors|fx|projectiles|decor`，旧 `Scenes/*.tscn` 暂保留。

## 3.1 `Scenes/maps/`（地图入口）

- `World_Main.tscn`：大世界统一入口（当前实例化旧 `WorldScene.tscn`）。
- `Trial_Survivor_Main.tscn`：试炼统一入口（当前实例化旧 `SurvivorArena.tscn`）。

## 3.2 `Scenes/actors/`（角色/怪物入口）

- `Player.tscn`：玩家入口。
- `NPC.tscn`：NPC 入口。
- `Monster.tscn`：普通怪入口。
- `DemonMonster.tscn`：精英怪入口。

## 3.3 `Scenes/projectiles/`（投射物入口）

- `ArcherArrowProjectile.tscn`：弓箭投射物入口。

## 3.4 `Scenes/fx/`（特效入口）

- `MeleeAttackFX.tscn`：近战挥击特效。
- `MageSpellFX.tscn`：法师技能特效。
- `MageManaBlastFX.tscn`：法师爆发特效。
- `PriestHealFX.tscn`：牧师治疗特效。
- `PriestHolyRayFX.tscn`：牧师圣光特效。
- `PriestDivinePrayerFX.tscn`：牧师祷言特效。
- `WarriorPowerStrikeFX.tscn`：战士强击特效。
- `FloatingWorldText.tscn`：通用飘字反馈。

## 3.5 `Scenes/decor/`（装饰/道具入口）

- `LootPickup.tscn`：掉落物场景入口。

## 3.6 `Scenes/ui/`（UI 场景）

- `HallScene.tscn`：大厅界面。
- `LoginScreen.tscn`：登录界面。
- `RegisterScreen.tscn`：注册界面。
- `ProfileScene.tscn`：个人中心界面。
- `CharacterBuildPanel.tscn`：成长面板。
- `BackpackOverlay.tscn`：背包面板。
- `WeaponShopOverlay.tscn`：商店面板。
- `WorldMapOverlay.tscn`：大地图面板。
- `WorldChat.tscn`：世界聊天面板。
- `ChatBubble.tscn`：聊天气泡。
- `MobileGameplayControls.tscn`：移动端战斗操作 UI。
- `WorldGameplayHud.tscn`：大世界 HUD 聚合界面。
- `MoeDialog.tscn`：通用对话框。
- `DialogSystem.tscn`：对话系统场景（历史兼容/实验）。

## 3.7 `Scenes/` 根目录（历史兼容）

- 历史保留了与 `Scenes/ui/`、`Scenes/fx/`、`Scenes/actors/` 对应的一批旧场景。
- 当前策略：**不立即删除**，待全部引用和文档迁移完成后再清理。

---

## 5) docs 文档结构

- `AI_GAME_ENGINEERING_PROTOCOL.md`：AI 工程交付协议（反碎片、先架构后功能）。
- `ARCHITECTURE.md`：架构说明与模块关系。
- `FLOW_UI_DESIGN_BLUEPRINT.md`：UI 流程与页面蓝图。
- `PRODUCT_MANAGER_GAME_WORLD_PLAN.md`：产品路线与版本规划。
- `SUBAGENT_EXECUTION_BOARD.md`：子代理执行看板。
- `OPTIMIZATION_TEST_CHECKLIST.md`：优化与回归测试清单。
- `GAME_STORY_BACKGROUND.md`：世界观与背景故事设定。
- `DESIGNER_SCENE_MAP_TASKS.md`：地图设计任务单。
- `SCENE_STRUCTURE_CLASSIFICATION.md`：场景分类与迁移规范。
- `PROJECT_FILE_STRUCTURE_CN.md`：本文件（结构总览与用途说明）。

---

## 6) 技能文件结构

## 5.1 `.cursor/skills/`

- 存放本项目 Cursor 技能（质量门禁、需求拆解、UI 实施、流程检查、提示词模板等）。
- 主要用于规范 AI 执行流程和稳定产出质量。

## 5.2 `.trae/skills/`

- Trae 侧兼容技能入口（`moe-community-*` 系列）。
- 主要作用：把规范入口统一指向当前 `docs/` 与项目真实结构。

---

## 7) 后续建议（结构治理）

- 继续把 `Scenes/` 根目录历史副本逐步迁移并下线。
- 新增文件一律按分类目录放置，避免回流到根目录。
- 每次分类迁移后同步更新：
  - `docs/SCENE_STRUCTURE_CLASSIFICATION.md`
  - `docs/ARCHITECTURE.md`
  - 本文档 `docs/PROJECT_FILE_STRUCTURE_CN.md`
