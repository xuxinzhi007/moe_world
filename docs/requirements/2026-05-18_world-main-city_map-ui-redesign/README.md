# 需求包：主城地图与 UI 收口重构

- 标题：`WorldScene / world_main` 主城中心化、边缘交互重做、真实小地图首版
- 日期：2026-05-18
- 提出者：用户
- 负责人：AI 协作开发
- 当前状态：in_progress

## 文档清单

- `REQ_BRIEF.md`
- `TECH_DESIGN.md`
- `IMPLEMENTATION_TASKS.md`
- `QA_CHECKLIST.md`

## 本轮结论

- `WorldScene` 内的 `world_main` 视为玩家出生地图，同时也是主城主场景。
- `east_market`、`south_trail`、`coming_soon` 视为围绕主城的外部区域，不再承担中心地图职责。
- 地图边缘切换交互改为“靠近边缘出现提示，按交互键确认”，不再使用强制打断式弹窗作为默认入口。
- 右上角小地图不再继续做纯雷达，会改成“当前场景真实小地图”；全屏地图继续承担区域关系展示。

## 本轮实现边界

- 优先修复结构和交互一致性。
- 先不重做整套美术资源，不切到 3D 路线。
- `plaza` 保留为遗留候选区域，但不再作为当前主城语义中心。
