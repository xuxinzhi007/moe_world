# 工程架构整改清单

## 背景判断

当前工程已经超过“边写边加功能”的舒适区，主要症状是：

- 巨型脚本承担过多职责，典型如 `Scripts/world/world_scene.gd`、`Scripts/survivor/survivor_arena.gd`、`Scripts/meta/hall_scene.gd`
- 运行态会话数据仍通过 `ProjectSettings` 在多个模块直接读写
- 场景目录迁移未收口，存在 `Scenes/` 根目录 legacy 入口和新分类目录并存
- 2D 主流程、3D 分支、UI 运行时生成逻辑交织
- 数据、流程、表现层边界不清，新增功能容易继续堆在已有大文件中

这份清单的目标不是重写工程，而是先固定一版可持续维护的架构，并分批迁移。

## 架构目标

### 1. 固定顶层分层

- `Scripts/autoload/`
  - 仅保留稳定全局服务，不放具体玩法
- `Scripts/features/`
  - 按功能拆分业务流程
- `Scripts/entities/`
  - 放玩家、NPC、怪物、投射物、拾取物等实体行为
- `Scripts/shared/`
  - 放共用 UI、FX、工具、基础组件
- `Scripts/data/`
  - 放配置资源读取、静态表、构建数据入口

### 2. 固定 autoload 职责

允许保留：

- `UserStorage` / `SessionService`
- `WorldNetwork`
- `SceneTransition`
- `SceneRouter`
- `GameAudio`
- `CharacterBuild`
- `QuestManager`

要求：

- 只能提供稳定 API
- 不允许继续把具体场景逻辑塞进 autoload
- 场景脚本不允许随意直接写 `ProjectSettings`

### 3. 固定场景脚本职责

- 一个场景脚本只负责当前场景生命周期和编排
- 战斗、刷怪、地图切换、HUD、网络同步拆成子控制器
- 正式 UI 布局尽量写在 `.tscn`，代码只绑定行为
- 临时视觉对象可以运行时生成

## 必修问题清单

### P0：先修，继续开发前必须处理

- 统一会话状态入口
  - 当前用户
  - token
  - api base url
  - session login unix
- 清理 `project.godot` 中的运行态数据
- 明确正式场景入口和 legacy 场景入口
- 停止继续扩写 `world_scene.gd`、`survivor_arena.gd`、`hall_scene.gd`

### P1：第一阶段重构

- 拆 `world_scene.gd`
  - `world_combat_controller`
  - `world_spawn_controller`
  - `world_region_controller`
  - `world_hud_controller`
  - `world_cloud_sync_controller`
- 拆 `survivor_arena.gd`
  - 波次
  - 战斗
  - HUD
  - 结算/返回
- 拆 `hall_scene.gd`
  - 用户信息
  - 云端房间入口
  - 大厅动效
  - 登录弹层/资料入口

### P2：第二阶段重构

- 把怪物、职业、武器、地图元数据外置成配置资源
- 统一 NPC、怪物、掉落、弹道的基础类或组件
- 把共用 UI 动画/样式工具收口到 shared
- 将 3D 分支明确隔离为独立 feature

## 推荐目录方案

```text
Scripts/
  autoload/
  features/
    auth/
    hall/
    world_2d/
    world_3d/
    survivor/
    inventory/
    character_build/
    chat/
    quest/
  entities/
    player/
    npc/
    monsters/
    projectiles/
    pickups/
  shared/
    ui/
    fx/
    utils/
    components/
  data/
    configs/
    loaders/
```

## 场景目录收口规则

- `Scenes/actors/` 作为实体正式入口
- `Scenes/fx/` 作为特效正式入口
- `Scenes/projectiles/` 作为投射物正式入口
- `Scenes/maps/` 作为地图正式入口
- `Scenes/ui/` 作为正式 UI 场景入口
- `Scenes/` 根目录下现存旧入口逐步迁移到 `Scenes/legacy/`

## 编码规则

- 单文件建议不超过 400 到 600 行
- 超过 800 行默认进入拆分候选
- 不允许在多个模块里重复读写同一份业务状态
- 不允许继续新增新的 legacy 场景壳
- 新增功能优先“加模块”，不是“往已有巨型脚本里继续塞”

## 执行计划

### 第一批：已完成

- 建立本清单文档
- 将会话存储统一到 `UserStorage`
- 关键入口改为走统一会话 API
- 清理 `project.godot` 中已提交的运行态用户数据

### 第二批：进行中

- 新建 `Scenes/legacy/`
- 将根目录旧场景迁移为 legacy
- 建立 `Scripts/features/world_2d/` 子控制器骨架
- 从 `world_scene.gd` 抽出第一个控制器
- 抽离世界静态配置到独立脚本
- 建立素材统一规范与 prompt 模板

当前状态：
- 已完成：世界静态配置已抽离到 `Scripts/world/world_scene_config.gd`
- 已完成：首轮玩法闭环状态已集中到 `QuestManager`，大厅 / 大世界 / 试炼不再各自拼接主线进度
- 进行中：`world_scene.gd`、`survivor_arena.gd`、`hall_scene.gd` 仍然偏大，下一步需要继续拆控制器而不是继续堆逻辑

相关素材规范见 [ASSET_STYLE_GUIDE_CN.md](</D:/godot_data/moe_world/docs/ASSET_STYLE_GUIDE_CN.md>).

### 第三批：持续推进

- 抽数据资源
- 抽实体公共基类/组件
- 收口 2D/3D 分支

## 当前阶段验收标准

- 运行态会话不再依赖提交到仓库的 `project.godot` 数据
- 用户、大厅、网络入口统一通过 `UserStorage` 访问会话
- 文档明确了目录规则、拆分原则、下一阶段顺序
- 工程在行为不变前提下开始去耦，而不是继续堆功能

补充说明：
- 当前优先级仍是先把“大厅 -> 世界 -> 主线 -> 试炼 -> 返回大厅”的闭环做实，再继续做大规模目录迁移
- 下一轮结构整改建议优先拆 `world_hud_controller` 或 `survivor_result_controller`，因为这两块已经开始形成稳定边界
