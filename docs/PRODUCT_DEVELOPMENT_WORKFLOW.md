# 游戏功能产品化开发流程（小步执行版）

## 目标

- 把“临时改功能”改为“需求 -> 方案 -> 开发 -> 验收”的固定流程。
- 每次只做一个小功能闭环，减少返工和混乱。

## 标准流程

1. 需求简报（你提需求，我先拆解）
2. 产品方案（功能范围与流程）
3. 技术方案（Godot 场景/脚本改动点）
4. 实施任务单（按步骤可执行）
5. 验收与回归（PC + 移动端）

## 文档组织（需求包）

- 每次新需求都在 `docs/requirements/` 下创建独立目录。
- 目录命名：`YYYY-MM-DD_<slug>`
- 标准文件：
  - `README.md`
  - `REQ_BRIEF.md`
  - `PRD.md`
  - `TECH_DESIGN.md`
  - `IMPLEMENTATION_TASKS.md`
  - `QA_CHECKLIST.md`

## 模板文件

- `docs/templates/REQ_BRIEF_TEMPLATE.md`
- `docs/templates/PRD_TEMPLATE.md`
- `docs/templates/TECH_DESIGN_TEMPLATE.md`
- `docs/templates/IMPLEMENTATION_TASKS_TEMPLATE.md`
- `docs/templates/QA_CHECKLIST_TEMPLATE.md`

## 执行约定

- 小步提交：每次只实现一个明确功能闭环。
- 先文档后开发：文档未确认，不进入编码。
- 不新增平行系统：优先复用现有 `Scripts/`、`Scenes/`、Autoload。
- 涉及世界/试炼改动时，默认双场景回归验证。
- 需求文档不散落在 `docs/` 根目录，统一放入对应需求包目录。

## 当前状态

- 本文件已建立（流程主文档）。
- 已建立模板：`docs/templates/`。
- 已建立需求包目录规范：`docs/requirements/README.md`。
