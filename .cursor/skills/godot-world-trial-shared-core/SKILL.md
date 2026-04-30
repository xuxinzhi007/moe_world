---
name: godot-world-trial-shared-core
description: 维护“大世界与试炼同核异皮”实现原则，推动共用移动、战斗、成长与输入逻辑。用户提到“试炼和世界一致、共用系统、避免两套逻辑”时使用。
---

# 世界/试炼同核异皮

## 原则

- 同一玩法核心：移动、攻击、成长、职业、移动端控件尽量共用。
- 场景规则差异：地形、刷怪、胜负条件、结算流程可不同。
- 避免复制：优先抽公共方法或参数配置，不复制整段逻辑。

## 执行步骤

1. 识别“重复逻辑”与“模式差异逻辑”。
2. 将共用逻辑放入公共函数或可复用脚本。
3. 将差异改为参数（World/Trial 模式值）。
4. 校验两边手感一致（攻速、技能反馈、UI入口）。

## 重点文件

- `Scripts/world/world_scene.gd`
- `Scripts/survivor/survivor_arena.gd`
- `Scripts/player/player.gd`
- `Scripts/autoload/character_build.gd`
- `Scenes/ui/MobileGameplayControls.tscn`

## 输出格式

- 共用逻辑列表
- 差异参数列表
- 回归测试（世界与试炼各一遍）

## 防回归提示

- 修改试炼逻辑时，同步检查大世界。
- 修改职业/成长逻辑时，必须双场景验证。
