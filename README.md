# moe_world（萌社区 · 大世界客户端）

基于 **Godot 4.4** 的 2D 大世界探索客户端：账号登录、大厅、个人中心、单机/云端多人同屏、移动端虚拟摇杆与对话 UI。可与自建后端 **moe_social**（REST + WebSocket）联调。

**工程目录与各文件职责**见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

## 技术栈

| 项 | 说明 |
|----|------|
| 引擎 | Godot **4.4**（`project.godot` 中标记 Mobile 特性） |
| 语言 | **GDScript**（工程含 `[dotnet]` 段，可按需使用 C#） |
| 渲染 | OpenGL 3 / `gl_compatibility`（便于部分安卓设备） |
| 网络 | HTTP（登录与配置）+ **WebSocket**（`/ws/world` 房间同步） |
| 会话持久化 | `user://moe_world_session.cfg`（**UserStorage**），避免运行时写 `project.godot` |

## 功能概览

- **登录 / 注册**：对接后端 API；支持从远程拉取 `client-config`（如 GitHub 上的 `moe_api.json`）解析 `api_base_url`。
- **大厅**：单机进入世界、云端房间（约定房间名）、个人中心、设置、退出登录；**不提供**试炼入口（试炼从大世界进入）。
- **大世界（WorldScene）**：`CharacterBody2D` 移动、相机跟随、NPC 对话（底栏 **MoeDialog**）、野怪与掉落、武器店 / 背包 / 成长面板、地图与雷达等。
- **云端多人**：同一房间内的玩家位置与昵称同步；头顶显示用户名（`world_profile` / `world_peer_profile`）。
- **移动端**：左下摇杆 + 右下攻击 / 强击 / 对话；**对话仅建议用按钮或键盘 E**（`interact` 未绑定鼠标左键，避免触屏与摇杆冲突）。

### 单机战斗与成长

- **职业**：战士 / 弓箭 / 法师 / 牧师（`CharacterBuild` 持久化到 `user://character_build.cfg`）。
- **战斗等级与经验**：击杀怪物获得经验；升级所需经验由 **`CharacterBuild.combat_xp_to_next_level()`** 统一计算（大世界与试炼共用），整体节奏比早期版本更缓。
- **成长面板**：`Scenes/CharacterBuildPanel.tscn`；大世界从顶栏「成长」打开。试炼内升级时会自动弹出，且为**试炼专用交互**（点遮罩不会关、可「稍后再加点」保留未分配点、点数为 0 时自动关闭）——见 `Scripts/ui/character_build_panel.gd` 中 `open_panel_survivor_trial()`。

### 生存试炼（吸血鬼幸存者式副本）

- **入口**：仅在大世界 **`Playfield`** 下的传送门 **`SurvivorTrialPortal`**（`Scripts/world/survivor_portal.gd` + `传送门.png`），走进 `Area2D` 即切到 `Scenes/SurvivorArena.tscn`。**联机云端**下传送门不触发。
- **出口**：顶栏「返回大世界」或战斗倒地（试炼内怪近身会扣血）；回到 **`WorldScene`**，倒地回城前会满血以免带着 0 血进大世界。
- **场景脚本**：`Scripts/survivor/survivor_arena.gd` — 怪潮、波次、与主世界对齐的职业与冷却、**挂载与大世界相同的** `Scenes/ui/MobileGameplayControls.tscn`（宽屏也有摇杆/攻击）、试炼内成长面板、`MageSpellFX` 等。
- **注意**：试炼是独立场景，不加载整张大世界装饰；四角有简单树木占位；玩家与怪物的绘制顺序已调整，避免整层怪盖住角色。

### 法师 AOE 序列帧

- **场景**：`Scenes/MageSpellFX.tscn` — 根节点 `MageSpellFX`，子节点 **`SpellAnim`（AnimatedSprite2D）**。
- **动画名**：SpriteFrames 中仅保留一套 **`mage_aoe`**；在编辑器中打开该场景，选中 `SpellAnim` 即可改 Atlas 区域与帧序列。
- **逻辑**：`Scripts/combat/mage_spell_fx.gd` 的 `play_aoe(圆心, 半径)` 按 AOE 半径缩放播放，结束后自销毁。大世界与试炼均在 `_spawn_mage_aoe_fx` 里实例化（**已不再绘制**早期的紫色 `Polygon2D` 占位圈）。

### 战斗特效与其它场景

- **近战挥击**：`Scenes/MeleeAttackFX.tscn` + `Scripts/combat/melee_attack_fx.gd`（可选序列帧或单图）。
- **移动端脚本**：`Scripts/ui/mobile_controls.gd` — 由 **`WorldGameplayHud`** 引用的 `MobileGameplayControls.tscn` 与 **`SurvivorArena`** 试炼内实例共用；`_ready` 里在 `await` 之后会检测是否仍在场景树，避免切场景时 `get_viewport()` 为空报错。

## 运行要求

- 安装 **Godot 4.4.x**（与 `config/features` 一致）。
- 若使用完整账号与云端联机，需可访问的 **moe_social** 后端（HTTPS/WSS 或本地 HTTP/WS）。

## 快速开始

1. 用 Godot 打开本仓库根目录（含 `project.godot`）。
2. 主场景为 **HallScene**（`project.godot` → `run/main_scene`）；登录/注册为子场景切换。
3. 运行（F5）：在编辑器内可先用默认或配置好的 `api_base_url` 登录。

### 导出 Android

- 工程内已有 `export_presets.cfg` 时，在编辑器中检查 **Internet** 等权限。
- 登录态写入 `user://`，无需可写安装目录。

## 后端配合说明

### API 基址（登录与健康检查）

- **优先内置线上**：冷启动使用 **`DEFAULT_API_BASE_URL`**（`auth_service.gd` 内，当前 `http://47.106.175.49:8888/api`）。本地缓存若含 **ngrok** 等旧隧道域名会被丢弃并改回该地址。
- **GitHub**：仍会周期性请求 [`moe_api.json`](https://raw.githubusercontent.com/xuxinzhi007/moe_social/main/lib/config/moe_api.json)，但默认 **`GITHUB_URL_MAY_OVERRIDE_PRIMARY = false`**，不会用远程 JSON 覆盖当前 API，避免远程未更新时抢回 ngrok。若将来要改回「以 GitHub 为准」，在 `auth_service.gd` 将该常量改为 `true` 即可。
- **本地单机**：把 **`DEFAULT_API_BASE_URL`** 改为 `http://127.0.0.1:8888/api` 即可连本机容器。
- **后端**：`moe_social/backend/config/config.yaml` 中 `app_client.public_api_base_url` 与对外端口一致（如 `http://47.106.175.49:8888`，`docker-compose.yml` API **8888:8888**）。

云端大世界依赖后端 WebSocket 路由（go-zero 示例路径）：

- **URL**：`{api_origin}/ws/world?token={JWT}&room={房间名}`  
  - `api_origin` 由 `api_base_url` 去掉末尾 `/api` 后，将 `http→ws`、`https→wss` 得到。
- **房间名**：`[a-zA-Z0-9_-]{1,48}`，默认可与好友约定同一串，例如 `default`。
- **消息类型**（JSON 文本帧）：`world_welcome`、`world_move`、`world_profile`、`world_peer_joined` / `world_peer_left` / `world_peer_profile`、`ping`/`pong` 等。

服务端对 **同一 WebSocket 连接** 的写入需串行化（例如每连接一把写锁），并对 `world_move` 做适度 **广播节流**，避免高并发下 fan-out 压力过大。

客户端侧 **WorldNetwork** 对上行位置有 **距离 + 频率** 节流（可在编辑器中调整 `WorldNetwork` 的 export 参数）。

## 自动加载（Autoload）

| 名称 | 脚本 | 作用 |
|------|------|------|
| **UserStorage** | `Scripts/autoload/user_storage.gd` | 启动时恢复会话到 `ProjectSettings` 内存；登录后持久化到 `user://` |
| **WorldNetwork** | `Scripts/autoload/world_network.gd` | 云端会话、WebSocket 轮询、移动/昵称发送与信号 |
| **MoeDialogBus** | `Scripts/autoload/moe_dialog_bus.gd` | 全局唯一对话层，防止叠多层对话框 |
| **GameAudio** | `Scripts/autoload/game_audio.gd` | 全局 BGM / 音效 |
| **PlayerInventory** | `Scripts/autoload/player_inventory.gd` | 背包数据与持久化 |
| **CharacterBuild** | `Scripts/autoload/character_build.gd` | 职业、战斗等级与经验、战斗数值 |

## 目录结构（摘要）

```
Scenes/          # WorldScene、SurvivorArena、Player、Monster、特效等；界面与叠加层在 Scenes/ui/
Scripts/         # 已分子目录：autoload / world / combat / survivor / ui / auth / player / meta（详见 docs/ARCHITECTURE.md）
Assets/          # 角色图、传送门、魔法序列帧等资源（中文文件名已在关键处用 preload 规避动态加载问题）
apk/             # 若存在，多为本地导出产物（勿误提交敏感签名）
export_presets.cfg
project.godot
```

与试炼 / 法师特效直接相关的文件示例：

| 路径 | 说明 |
|------|------|
| `Scripts/survivor/survivor_arena.gd` | 试炼主逻辑、HUD、成长面板实例、法师 `_spawn_mage_aoe_fx` |
| `Scripts/world/survivor_portal.gd` | 大世界传送门进试炼 |
| `Scenes/MageSpellFX.tscn` | 法师 AOE 序列帧 |
| `Scripts/combat/mage_spell_fx.gd` | `play_aoe` 播放与缩放 |
| `Scripts/autoload/character_build.gd` | `combat_xp_to_next_level`、职业、血量、强击等 |
| `Scripts/ui/character_build_panel.gd` | 成长 UI；`open_panel` / `open_panel_survivor_trial` |
| `Scripts/ui/mobile_controls.gd` | 虚拟摇杆与按钮 |

## 配置与隐私

- **不要在仓库中提交** 真实 token、生产数据库连接或私人 `export_presets` 密钥；`project.godot` 里 `[moe_world]` 下若存有调试用户数据，提交前宜清理或使用本地覆盖。
- 远程 API 基址优先来自 **登录前拉取的配置** 或 **UserStorage**；编辑器内 `ProjectSettings` 中的 `moe_world/*` 多用于开发期默认值。

## 已知边界（产品级前需评估）

- 位置同步为 **客户端上报 + 服务端转发**，无服务端权威校验与反作弊。
- 无兴趣管理（AOI）；人数增多时需分服、分区或降频策略。
- 联机仅 **云端 WebSocket** 路径；局域网 ENet 主机/加入已移除。

## 许可证

若未单独指定，以仓库内 LICENSE 为准；无 LICENSE 文件时请自行补充。
