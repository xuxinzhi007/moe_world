# 需求文档包目录规范

## 目录命名

- 统一格式：`YYYY-MM-DD_<slug>`
- 示例：`2026-05-03_gameplay-refresh_ui-icon-system_phase1`

## 每个需求包的标准结构

- `README.md`（需求包元信息与状态）
- `REQ_BRIEF.md`
- `PRD.md`
- `TECH_DESIGN.md`
- `IMPLEMENTATION_TASKS.md`
- `QA_CHECKLIST.md`

## 元信息建议字段

- 标题
- 日期
- 提出者（用户）
- 负责人（产品/开发）
- 当前状态（draft / approved / in_progress / done）
- 关联需求（可选）

## 执行规则

- 新需求必须先建需求包目录，再写文档。
- 不再把单次需求文档散落在 `docs/` 根目录。
- 若历史文档在根目录，逐步迁移到 `docs/requirements/`。
