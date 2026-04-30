---
name: "moe-community-check"
description: "回归与质量门禁入口。用于修改后统一检查稳定性、性能和流程闭环。"
---

# Moe World 质量检查技能

## 检查目标

- 确保改动不破坏主流程
- 确保没有新增高风险回归
- 确保文档同步

## 必查清单

1. 场景流：大厅 -> 世界/试炼 -> 返回
2. 节点路径：脚本 `@onready` 与 `.tscn` 一致
3. 信号：无重复连接、离场断连完整
4. 性能：高频 `_process/_physics_process` 无明显新增热区
5. 文档：`docs/OPTIMIZATION_TEST_CHECKLIST.md` 已补测试点
6. API 真实性：无臆造 Godot API/项目接口/后端字段

## 输出格式

- 风险分级（高/中/低）
- 影响范围
- 最小修复建议
- 本轮冒烟步骤
- API 核验结论（通过/不通过 + 证据）
