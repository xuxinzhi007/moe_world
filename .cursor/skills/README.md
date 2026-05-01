# 项目技能索引

本目录是项目级技能（`.cursor/skills/`），用于让 AI 在本项目里更稳定地自动调用标准流程。

## 已创建技能

- `godot-ui-page-implementation`  
  用于页面实现、布局调整、线框落地、响应式适配。

- `godot-flow-consistency-check`  
  用于检查大厅/登录/世界/试炼的流程闭环与状态一致性。

- `godot-world-trial-shared-core`  
  用于坚持“世界与试炼同核异皮”，避免维护两套玩法逻辑。

- `godot-asset-integration-checklist`  
  用于美术/音频资源接入与替换时的标准检查。

- `godot-bugfix-regression-loop`  
  用于 bug 修复与回归闭环（复现-定位-最小修复-回归）。

- `godot-ui-style-token-enforcer`  
  用于统一 UI 风格规范（字号、间距、圆角、按钮规格）。

- `godot-code-quality-gate`  
  用于提交前质量门禁（契约、节点路径、输入映射、分支风险）。

- `godot-prompt-playbook`  
  用于复用高质量提示词模板，内含 `prompts.md`。

- `natural-language-requirement-clarifier`  
  用于把用户自然语言需求先做拆解、润色、确认，再进入开发执行。

- `requirement-option-confirmation`  
  用于把模糊需求转成结构化选项，让用户先确认关键分歧。

- `requirement-to-execution-brief`  
  用于将需求整理为执行任务单（目标/范围/步骤/验收/风险）。

- `godot-subagent-dev-orchestrator`  
  用于子代理协调开发，按模块并行推进地图、角色、背景、任务、材料图标、音频、动作、怪物，并统一契约与回归门禁。

## 执行协议（新增）

- 统一遵循 `docs/AI_GAME_ENGINEERING_PROTOCOL.md`：  
  先架构后功能、先闭环后扩展、禁止碎片化代码与平行系统。
- 场景与目录结构遵循：
  - `docs/SCENE_STRUCTURE_CLASSIFICATION.md`
  - `docs/PROJECT_FILE_STRUCTURE_CN.md`

## 子代理协调开发（更新）

- 推荐由 `godot-subagent-dev-orchestrator` 作为总控入口，先做“只读盘点”再进入实现。
- 模块映射建议：
  - 地图/背景：`godot-map-background-planner`
  - 角色/动作：`godot-character-action-designer`
  - 任务：`godot-quest-progression-designer`
  - 材料图标：`godot-material-icon-pipeline`
  - 音频：`godot-audio-event-designer`
  - 怪物：`godot-monster-encounter-designer`
  - 落地实现：`godot-ui-layout-engineer` + `godot-gameplay-programmer`
  - 风险兜底：`godot-architecture-auditor` + `godot-tech-troubleshooter`
- 每轮都要经过：能力盘点 -> 契约统一 -> 最小实现 -> 跨模块回归 -> 文档收口。
