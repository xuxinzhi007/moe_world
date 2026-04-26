# 项目架构与文件说明

本文档说明 **moe_world（萌社区）** 客户端的工程分层、运行时入口、自动加载与各目录/文件职责，便于新人定位代码。

- **引擎**：Godot 4.4（`project.godot` → `config/features`）
- **主场景**：`run/main_scene` 当前为 `res://Scenes/ui/HallScene.tscn`（大厅为游戏启动后的根界面）

---

## 1. 场景流（从启动到玩法）

```
HallScene（大厅）
    ├→ LoginScreen / RegisterScreen（若从大厅进入登录注册）
    ├→ WorldScene（2D 大世界：单机或带 WebSocket 联机）
    ├→ ProfileScene（个人中心）
    └→ SurvivorArena（生存试炼：仅建议从大世界传送门进入）
```

- **大厅**：房间名、单机进世界、个人中心、设置、退出等。
- **大世界**：移动、战斗、NPC、商店、背包、成长、地图、聊天、传送门进试炼等。
- **试炼**：独立场景，逻辑在 `survivor_arena.gd`；返回时切回 `WorldScene`。

---

## 2. 自动加载（Autoload）

在 `project.godot` 的 `[autoload]` 中注册，全局单例，任意脚本可通过名称访问。

| 单例名 | 脚本 | 职责摘要 |
|--------|------|----------|
| **UserStorage** | `Scripts/autoload/user_storage.gd` | 会话与 `moe_world` 相关配置持久化到 `user://`，启动时恢复到内存 |
| **WorldNetwork** | `Scripts/autoload/world_network.gd` | 云端房间 WebSocket、上行移动/资料节流、信号分发 |
| **MoeDialogBus** | `Scripts/autoload/moe_dialog_bus.gd` | 全局对话层调度，避免多层对话框叠加冲突 |
| **GameAudio** | `Scripts/autoload/game_audio.gd` | 全局 BGM / 音效入口；启动时从 `user://moe_world_ui_settings.cfg` 恢复主音量（若存在） |
| **PlayerInventory** | `Scripts/autoload/player_inventory.gd` | 玩家背包数据与持久化（与武器店等联动） |
| **CharacterBuild** | `Scripts/autoload/character_build.gd` | 职业、属性点、战斗等级与经验曲线、血量与强击等战斗数值 |

---

## 3. 顶层目录

| 路径 | 含义 |
|------|------|
| `Scenes/` | 可实例化的 `.tscn`：世界与玩法实体、特效等（**界面与叠加层**见 `Scenes/ui/`） |
| `Scenes/ui/` | 大厅、登录注册、个人中心、大世界 HUD、聊天/背包/地图/成长等 UI 专用场景 |
| `Scripts/` | 与场景或其它节点绑定的 `.gd` 逻辑（**已分子目录**，见下表） |
| `Assets/` | 图片、音频、图集等静态资源（含中文文件名资源时注意用 `preload` 等固定路径） |
| `export_presets.cfg` | 导出预设（Android 等） |
| `project.godot` | 工程配置、输入映射、`[moe_world]` 调试字段等 |

### 3.1 `Scripts/` 子目录（第一版）

| 子目录 | 内容 |
|--------|------|
| `Scripts/autoload/` | 上述 6 个 Autoload 单例脚本 |
| `Scripts/world/` | `WorldScene`、野怪/NPC/掉落/区域/地图/聊天/地面/传送门/飘字/气泡等 |
| `Scripts/combat/` | 箭矢、万箭齐发、`AttackRangeFx`、法师/近战攻击 FX |
| `Scripts/survivor/` | `survivor_arena.gd`（试炼主逻辑） |
| `Scripts/ui/` | 背包、武器店、设置、成长面板、移动端控件 |
| `Scripts/auth/` | 登录、注册、`auth_service` |
| `Scripts/player/` | `player.gd` |
| `Scripts/meta/` | 大厅、个人中心、对话、UI 主题、粒子装饰、`global_state` |

---

## 4. Scenes 与主脚本对照

下列为主流程与玩法相关场景及其根节点/常用脚本（与 `.tscn` 中 `ExtResource` 一致）。

| 场景 | 主脚本 | 说明 |
|------|--------|------|
| `ui/HallScene.tscn` | `Scripts/meta/hall_scene.gd` | 启动主场景；含粒子子节点 `bubble_particles.gd`、`sakura_particles.gd`（均在 `meta/`） |
| `ui/LoginScreen.tscn` | `Scripts/auth/login_screen.gd`、`Scripts/auth/auth_service.gd` | 登录 UI 与鉴权请求 |
| `ui/RegisterScreen.tscn` | `Scripts/auth/register_screen.gd`、`Scripts/auth/auth_service.gd` | 注册 |
| `WorldScene.tscn` | `Scripts/world/world_scene.gd` | 大世界总控：玩家、怪、UI、联机、传送门等 |
| `ui/WorldGameplayHud.tscn` | （多子场景与脚本） | 大世界 `UI` 实例：顶栏、雷达、聊天、背包、商店、地图、成长、`MobileGameplayControls` 等 |
| `WorldScene.tscn`（子系统） | `Scripts/world/ground_tile_sprite.gd` | 地面/瓦片表现 |
| | `Scripts/world/world_region_zone.gd` | 区域判定（多块区域节点） |
| | `Scripts/world/survivor_portal.gd` | 生存试炼传送门 |
| | `Scripts/world/world_time_weather.gd` | 时间与天气 |
| | `Scripts/world/world_region_toast.gd` | 区域切换提示 |
| | `Scripts/world/world_radar_minimap.gd` | 雷达小地图 |
| | `Scripts/ui/mobile_controls.gd` | 内嵌移动端摇杆/攻击（`MobileControls` 实例为 `ui/MobileGameplayControls.tscn`） |
| `Player.tscn` | `Scripts/player/player.gd` | 玩家 `CharacterBody2D` 移动与战斗输入 |
| `Monster.tscn` | `Scripts/world/world_monster.gd` | 野怪 AI 与受击 |
| `NPC.tscn` | `Scripts/world/npc.gd` | NPC 与对话触发 |
| `LootPickup.tscn` | `Scripts/world/loot_pickup.gd` | 掉落物拾取 |
| `SurvivorArena.tscn` | `Scripts/survivor/survivor_arena.gd` | 试炼波次、HUD、与世界对齐的职业技能 |
| `ui/MobileGameplayControls.tscn` | `Scripts/ui/mobile_controls.gd` | 虚拟摇杆与战斗键（由 `WorldGameplayHud` 引用；试炼场景亦实例化同一份） |
| `ui/MoeDialog.tscn` | `Scripts/meta/moe_dialog.gd` | 底栏对话 UI |
| `ui/CharacterBuildPanel.tscn` | `Scripts/ui/character_build_panel.gd` | 成长/加点面板（含试炼模式差异） |
| `ui/BackpackOverlay.tscn` | `Scripts/ui/backpack_overlay.gd` | 背包叠加层 |
| `ui/WeaponShopOverlay.tscn` | `Scripts/ui/weapon_shop_overlay.gd` | 武器店叠加层 |
| `ui/WorldMapOverlay.tscn` | `Scripts/world/world_map_overlay.gd`、`Scripts/world/world_minimap_drawer.gd` | 大地图与绘制 |
| `ui/WorldChat.tscn` | `Scripts/world/world_chat.gd` | 大世界聊天 UI |
| `ui/ProfileScene.tscn` | `Scripts/meta/profile_scene.gd` | 个人中心（含粒子子节点） |
| `ui/ChatBubble.tscn` | `Scripts/world/chat_bubble.gd` | 头顶聊天气泡 |
| `FloatingWorldText.tscn` | `Scripts/world/floating_world_text.gd` | 飘字（伤害等） |
| `MeleeAttackFX.tscn` | `Scripts/combat/melee_attack_fx.gd` | 近战挥击特效 |
| `MageSpellFX.tscn` | `Scripts/combat/mage_spell_fx.gd` | 法师 AOE 序列帧特效 |
| `ArcherArrowProjectile.tscn` | `Scripts/combat/archer_arrow_projectile.gd` | 弓箭弹射物 |

---

## 5. Scripts 索引（按职责分组）

未在表中列出的脚本多为上表子节点或仅被动态 `load`/`preload` 使用。

### 5.1 账户与大厅（`Scripts/auth/`、`Scripts/meta/`）

| 文件 | 职责 |
|------|------|
| `auth/auth_service.gd` | HTTP 登录、注册、拉取配置等与后端交互 |
| `auth/login_screen.gd` | 登录界面逻辑 |
| `auth/register_screen.gd` | 注册界面逻辑 |
| `meta/hall_scene.gd` | 大厅流程与进世界/进个人中心等 |

### 5.2 大世界与玩法核心（`Scripts/world/`、`Scripts/player/`）

| 文件 | 职责 |
|------|------|
| `world/world_scene.gd` | 大世界生命周期、刷怪、掉落、商店/面板实例化、联机同步、法师特效生成等 |
| `player/player.gd` | 玩家移动、攻击、技能与动画侧表现 |
| `world/world_monster.gd` | 怪物行为与死亡掉落 |
| `world/npc.gd` | NPC 交互与对话数据驱动 |
| `world/loot_pickup.gd` | 掉落物碰撞与拾取 |
| `world/survivor_portal.gd` | 试炼传送门：靠近后顶栏/飘字提示，按 E 或点「对话」确认后进本（联机不触发） |

### 5.3 试炼（`Scripts/survivor/`）

| 文件 | 职责 |
|------|------|
| `survivor/survivor_arena.gd` | 试炼专属波次、经验、HUD、返回大世界、法师 AOE 表现等 |

### 5.4 UI 叠加与移动端（`Scripts/ui/`）

| 文件 | 职责 |
|------|------|
| `ui/character_build_panel.gd` | 属性点分配、大世界/试炼两种打开模式 |
| `ui/backpack_overlay.gd` | 背包 UI |
| `ui/weapon_shop_overlay.gd` | 武器店 UI |
| `world/world_map_overlay.gd` | 大地图容器与交互 |
| `world/world_minimap_drawer.gd` | 小地图/缩略图绘制逻辑 |
| `world/world_chat.gd` | 聊天窗口与消息展示 |
| `ui/mobile_controls.gd` | 虚拟摇杆、攻击键；注意切场景时的 viewport 安全 |

### 5.5 世界氛围与辅助表现（`Scripts/world/`、`Scripts/meta/`）

| 文件 | 职责 |
|------|------|
| `world/world_time_weather.gd` | 昼夜或天气相关逻辑 |
| `world/world_region_zone.gd` | 进入区域事件 |
| `world/world_region_toast.gd` | 区域名等 Toast |
| `world/world_radar_minimap.gd` | 雷达 UI |
| `world/ground_tile_sprite.gd` | 地面精灵/滚动相关 |
| `world/chat_bubble.gd` | 气泡跟随与文本 |
| `world/floating_world_text.gd` | 世界空间飘字 |
| `meta/bubble_particles.gd`、`meta/sakura_particles.gd` | 大厅等处的粒子装饰 |

### 5.6 网络、对话、全局状态（`Scripts/autoload/`、`Scripts/meta/`）

| 文件 | 职责 |
|------|------|
| `autoload/world_network.gd` | WebSocket 协议与房间状态（见 Autoload） |
| `meta/moe_dialog.gd` | 单例对话 UI 实例上的展示逻辑 |
| `autoload/moe_dialog_bus.gd` | 打开/关闭对话的全局总线 |
| `autoload/user_storage.gd` | 读写 `user://` 配置（见 Autoload） |
| `meta/global_state.gd` | API 是否就绪、服务器是否在线等轻量全局状态（非 Autoload，由登录流程等使用） |

### 5.7 数值、背包、音频（`Scripts/autoload/`）

| 文件 | 职责 |
|------|------|
| `autoload/character_build.gd` | 职业、战斗等级、`combat_xp_to_next_level` 等（见 Autoload） |
| `autoload/player_inventory.gd` | 背包与装备数据（见 Autoload） |
| `autoload/game_audio.gd` | 音频总线封装（见 Autoload） |

### 5.8 战斗特效（`Scripts/combat/`）

| 文件 | 职责 |
|------|------|
| `combat/melee_attack_fx.gd` | 近战特效播放与回收 |
| `combat/mage_spell_fx.gd` | 法师 AOE 圆心与半径对齐的序列帧播放 |
| `combat/archer_arrow_projectile.gd` | 弓箭弹射物飞行与碰撞 |
| `combat/archer_volley.gd` | 「万箭齐发」径向多箭 |
| `combat/attack_range_fx.gd` | 近战/法师范围提示线框 |

### 5.9 其它（`Scripts/meta/`）

| 文件 | 职责 |
|------|------|
| `meta/profile_scene.gd` | 个人中心页 |
| `meta/ui_theme.gd` | 共享 UI 主题或颜色常量（若被各 Overlay 引用） |

---

## 6. 与 README 的关系

产品功能、后端 WebSocket 约定、隐私与导出说明见仓库根目录 **`README.md`**。本文档侧重 **代码与文件拓扑**，与 README 互补。

---

## 7. 维护提示

- 修改 **`project.godot`** 中的 `run/main_scene` 会改变启动首屏；发布前请与策划/运营约定一致。
- 新增 **Autoload** 必须在 `project.godot` 注册，否则无法作为全局单例访问。
- 资源路径含中文或空格时，优先 **`preload("res://...")`**，避免运行时字符串拼接路径失败。
