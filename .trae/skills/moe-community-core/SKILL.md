---
name: "moe-community-core"
description: "项目核心信息与开发原则。用于开始任何任务前统一上下文，避免使用过期结构。"
---

# Moe World 核心信息技能

## 项目基线

- 引擎：Godot 4.4
- 语言：GDScript
- 项目根目录：当前工作区（不要写死本机绝对路径）

## 先读文档（Source of Truth）

1. `docs/AI_GAME_ENGINEERING_PROTOCOL.md`
2. `docs/ARCHITECTURE.md`
3. `docs/FLOW_UI_DESIGN_BLUEPRINT.md`
4. `docs/SUBAGENT_EXECUTION_BOARD.md`
5. `docs/SCENE_STRUCTURE_CLASSIFICATION.md`
6. `docs/PROJECT_FILE_STRUCTURE_CN.md`

## 执行原则

- 不输出碎片代码
- 不凭空重建平行架构
- 每个任务必须有：目标/范围/步骤/验收/风险
- 每次修改后补充测试清单或执行看板
- Godot API 必须基于 4.4 官方文档；项目/后端接口必须先在当前仓库或文档中确认

## 典型失败原因（必须规避）

- 使用过期路径/过期节点树
- 写死本机 Windows 路径
- 只做功能片段，不做流程闭环
- 臆造 API、信号、字段或接口路径
