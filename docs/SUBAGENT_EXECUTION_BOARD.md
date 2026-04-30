# 子代理执行看板（持续更新）

> 目的：把子代理职责、当前结论、下一步任务统一到一个执行面板，便于你直接指挥和验收。

---

## 1) 子代理分工（当前生效）

- `godot-dev-lead`：总排期、任务拆分、优先级管理。
- `godot-architecture-auditor`：架构与场景契约、信号生命周期审计。
- `godot-gameplay-programmer`：玩法闭环与功能完整度推进。
- `godot-tech-troubleshooter`：启动稳定性、性能热点与低风险修复。
- `godot-ui-layout-engineer`：UI 结构、移动端交互与布局一致性。
- `godot-docs-maintainer`：文档同步、测试清单与版本记录。

### 执行总约束（对所有子代理）

- 统一遵守 `docs/AI_GAME_ENGINEERING_PROTOCOL.md`。  
- 禁止输出碎片代码任务，必须输出闭环任务（目标/范围/验收/风险）。  
- 优先修复主流程阻断与高风险回归，再做体验增强。

---

## 2) 本轮子代理结论摘要

### A. 架构审计（architecture-auditor）

- 高风险：`world_chat` 聊天气泡挂 root 可能跨场景残留。
- 高风险：世界与试炼核心战斗逻辑仍有分叉风险（同核异皮需持续收敛）。
- 中风险：信号 connect/disconnect 需保持全链路对称。

### B. 玩法审计（gameplay-programmer）

- 当前状态：已“可玩”，但完整闭环待增强（奖励、经济、成长联动）。
- 建议方向：优先补“世界失败结算 + 试炼奖励入背包 + 商店支付闭环”。

### C. 技术排障（tech-troubleshooter）

- 高价值低风险项：`SceneTransition` 防重入、`CharacterBuild` 延迟保存、小地图/雷达节流刷新。

---

## 3) 已落地执行（本次已完成）

- [x] `Scripts/meta/scene_transition.gd`
  - 增加切场景防重入锁 `_is_transitioning`。
  - 增加场景路径存在性检查与错误兜底。
- [x] `Scripts/autoload/character_build.gd`
  - 持久化改为 debounce（延迟批量保存），降低高频写盘抖动。
  - `_exit_tree()` 增加强制 flush，防止退出时丢保存。
- [x] `Scripts/world/world_minimap_drawer.gd`
  - 小地图改为 10Hz 刷新，缓存玩家/NPC/怪物引用，减少每帧查询。
- [x] `Scripts/world/world_radar_minimap.gd`
  - 雷达改为 10Hz 刷新，缓存实体引用，减少每帧查询。
- [x] `Scripts/world/world_chat.gd`
  - `_exit_tree()` 增加 `size_changed` 断连与气泡强制清理。
  - 相机获取优先通过 `world_root`，降低对 `/root/WorldScene` 路径依赖。
- [x] `Scripts/world/world_scene.gd`
  - 聊天模块初始化时注入 `world_root`，匹配 `world_chat` 新契约。

---

## 4) 下一批待执行（按优先级）

### P0（先做，稳定性）

- [ ] 世界失败结算层（死亡 -> 结算 -> 恢复/返回）补齐。
- [ ] 云端信号在 `world_scene` 离场时统一断开（避免重入回调）。

### P1（玩法完整度）

- [ ] 试炼奖励接入背包（至少 1~2 类材料）。
- [ ] 商店接入货币支付与余额校验。
- [ ] 掉落-背包-商店-成长消耗闭环打通。

### P2（体验打磨）

- [ ] 四职业反馈模板统一（命中/受击/冷却反馈标准化）。
- [ ] 世界/试炼参数继续同源化（减少双份逻辑漂移）。

---

## 5) 你的验收方式（建议）

- 每轮只验收 3~5 项，按严重级别优先。
- 使用 `docs/OPTIMIZATION_TEST_CHECKLIST.md` 回填测试结果。
- 你给“通过/不通过 + 复现步骤”，我按看板继续自动推进下一批。

