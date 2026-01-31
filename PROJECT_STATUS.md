# PROJECT_V 完整实施计划

> 从 Phase 1 到 Phase 5 的事无巨细清单
> ✅ = 已完成 | ⏳ = 进行中 | ❌ = 未开始

---

# Phase 1: 原型验证 ✅ COMPLETE

## 1.1 项目初始化 ✅
- [x] 创建 Godot 4.x 项目 `project_v`
- [x] 设置分辨率 1920x1080
- [x] 创建目录结构（scenes/, scripts/, assets/, audio/, shaders/, resources/, docs/）
- [x] 创建 main.tscn 作为启动场景
- [x] 初始化 Git 仓库
- [x] 创建 GitHub 仓库 notlsd/v

## 1.2 位运算核心模块 (BitwiseManager) ✅
- [x] `ip_to_int()`: String IP → 整数
- [x] `int_to_ip()`: 整数 → String IP
- [x] `prefix_to_mask()`: CIDR前缀 → 掩码整数
- [x] `apply_mask()`: 执行 IP & Mask 位运算
- [x] `check_match()`: 判断结果是否匹配目标子网
- [x] `generate_random_ip_in_subnet()`: 生成目标子网内随机IP
- [x] `generate_random_ip_outside_subnet()`: 生成干扰项IP
- [x] 注册为 Autoload 单例

## 1.3 游戏管理器 (GameManager) ✅
- [x] 目标子网追踪 (target_subnet, target_prefix)
- [x] 分数管理 (score)
- [x] 生命值管理 (alert_level)
- [x] 信号系统 (score_changed, alert_changed, match_success, match_failure, game_over)
- [x] 注册为 Autoload 单例

## 1.4 基础 HUD ✅
- [x] 显示分数
- [x] 显示生命条
- [x] 显示目标子网

---

# Phase 2: 视觉风格 ✅ COMPLETE

## 2.1 配色系统 ✅
- [x] 创建 colors.gd (class_name Colors)
- [x] 定义颜色常量 (BG_BLACK, V_RED, MATRIX_GREEN 等)

## 2.2 CRT Shader ✅
- [x] 扫描线效果
- [x] 桶形畸变
- [x] 色差
- [x] 暗角
- [x] 创建 crt_overlay.tscn

## 2.3 Glitch Shader ✅
- [x] 水平撕裂
- [x] 颜色通道错位
- [x] 噪点干扰
- [x] 创建 effect_manager.gd (Autoload)
- [x] 失误时触发 glitch

## 2.4 矩阵雨背景 ✅
- [x] 下落的 0/1 字符
- [x] 绿色渐变
- [x] 随机速度和透明度
- [x] 120 列密度

## 2.5 终端风格 ✅
- [x] IP 行向上滚动 (terminal_line.gd/tscn)
- [x] 多列布局（4列，每次1-3个IP）
- [x] 终端生成器 (terminal_spawner.gd)
- [x] 终端 HUD (terminal_hud.gd/tscn)

## 2.6 Game Over 界面 ✅
- [x] 显示最终分数
- [x] 显示存活时间
- [x] 显示最高 Combo
- [x] Restart 按钮

---

# Phase 3: 游戏性打磨 ✅ COMPLETE

## 3.1 连击系统 ✅
- [x] Combo 计数器
- [x] Max Combo 追踪
- [x] Combo 加成分数 (基础100 + combo*10)
- [x] Combo 奖励 (5连+5血, 10连+10血, 20连+20血)
- [x] HUD Combo 显示 + 脉冲动画

## 3.2 难度曲线 ✅
- [x] 速度每30秒 +10%
- [x] 生成间隔每30秒 -10% (最小0.6s)
- [x] game_time 追踪

## 3.3 音效反馈 ✅
- [x] AudioStreamGenerator 实时合成
- [x] 成功音效 (880Hz)
- [x] 失败音效 (220Hz)
- [x] Combo 奖励音效 (上升音阶)
- [x] Game Over 音效 (下降音阶)

## 3.4 游戏循环 ✅
- [x] ESC 暂停/继续 (pause_screen.gd/tscn)
- [x] Game Over 统计
- [x] Restart 重置所有状态

---

# Phase 4: 核心机制 ⏳ IN PROGRESS

## 4.1 掩码切换机制 ✅
- [x] Q 键 = /32 (255.255.255.255) 精准模式
- [x] W 键 = /24 (255.255.255.0) 标准模式
- [x] E 键 = /16 (255.255.0.0) 范围模式
- [x] /16 使用后 5 秒冷却
- [x] HUD 显示当前掩码
- [x] HUD 显示冷却倒计时
- [ ] **待验证**: 判定逻辑是否正确

## 4.2 节奏同步 (BPM) ❌
- [ ] IP 生成与节拍对齐
- [ ] Perfect 判定窗口 (±50ms)
- [ ] Perfect 额外加分
- [ ] Perfect 视觉反馈 (Glitch 震动)
- [ ] Overdrive 模式（可选）

## 4.3 动态难度 (滑动窗口) ❌
- [ ] 连续成功 → 速度加快
- [ ] 连续失败 → 速度减慢
- [ ] 速度范围限制 (0.5x ~ 2.0x)

## 4.4 多目标子网 ❌
- [ ] 目标子网动态变化
- [ ] 每 60 秒添加新目标
- [ ] 不同目标颜色区分
- [ ] HUD 显示多个目标

## 4.5 特殊敌人类型 ❌
- [ ] 奇偶校验怪 (IP 末位闪烁)
- [ ] 广播风暴 (.255 结尾，自我复制)
- [ ] 加密盾 (需要双击)

---

# Phase 5: 打包发布 ❌ NOT STARTED

## 5.1 优化
- [ ] 节点池 (对象复用)
- [ ] 性能测试

## 5.2 菜单系统
- [ ] 开始菜单
- [ ] 设置菜单 (音量等)
- [ ] 最高分存储

## 5.3 打包
- [ ] macOS 导出
- [ ] Windows 导出
- [ ] 图标和元数据

## 5.4 发布
- [ ] GitHub Release
- [ ] itch.io (可选)

---

# 当前状态总结

| Phase | 状态 | 完成度 |
|-------|------|--------|
| Phase 1 | ✅ 完成 | 100% |
| Phase 2 | ✅ 完成 | 100% |
| Phase 3 | ✅ 完成 | 100% |
| Phase 4 | ⏳ 进行中 | 20% (仅4.1) |
| Phase 5 | ❌ 未开始 | 0% |

---

**下一步建议**: 测试 4.1 掩码切换，然后决定 4.2-4.5 的优先级。
