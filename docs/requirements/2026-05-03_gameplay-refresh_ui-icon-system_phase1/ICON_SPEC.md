# ICON SPEC（阶段一）

## 目录规范

- 主目录：`Assets/ui/`
- 统一图标子目录：`Assets/ui/icons/`

## 命名规范

- 格式：`<area>_<feature>.svg` 或 `<feature>.png`
- 示例：
  - `topbar_growth.svg`
  - `topbar_shop.svg`
  - `topbar_map.svg`
  - `topbar_settings.svg`

## 尺寸规范

- 移动端战斗按钮图标：48px（脚本统一缩放）
- 顶栏按钮图标：32px（脚本统一缩放）
- 暂停菜单按钮图标：24px（脚本统一缩放）

## 映射规则（本轮）

- 职业攻击图标：
  - 战士：`upg_sword.png`
  - 弓手：`bow.png`
  - 法师：`upg_wand.png`
  - 牧师：`icons/attack_priest.svg`
- 顶栏图标：
  - 成长：`icons/topbar_growth.svg`
  - 背包：`backpack.png`
  - 商店：`icons/topbar_shop.svg`
  - 地图：`icons/topbar_map.svg`
- 设置菜单图标：
  - 设置：`icons/topbar_settings.svg`

## 异常回退

- 图标缺失时使用默认后备图（移动端攻击图）并输出一次性诊断日志。
- 所有缺图日志按路径去重，避免刷屏。
