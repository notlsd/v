# Great Firewall Simulator - 项目档案

> **原代号**: Project V  
> **引擎**: Godot 4.6 (GDScript)  
> **开发周期**: 2026-01-30 ~ 2026-02-07

---

## 功能实现状态 (基于代码审计)

### ✅ 已完成

#### 核心机制
| 功能 | 文件 | 说明 |
|------|------|------|
| IP/掩码位运算 | `bitwise_manager.gd` | `ip_to_int`, `prefix_to_mask`, `check_match` |
| QWER 掩码切换 | `game_manager.gd` | Q=/8, W=/16, E=/24, R=/32 |
| 目标子网轮换 | `game_manager.gd` | 10s→5s递减, 全清时即时切换 |
| 分数/连击系统 | `game_manager.gd` | 5/10/20阶梯奖励 |
| 生命值衰减 | `game_manager.gd` | 2/s自然衰减, 成功+5, 失败-5 |

#### 视觉效果
| 功能 | 文件 | 说明 |
|------|------|------|
| CRT 后处理 | `crt_effect.gdshader` | 扫描线/桶形畸变/色差/暗角 |
| Glitch 故障 | `glitch_effect.gdshader` | 水平撕裂/颜色通道错位/噪点 |
| 矩阵雨背景 | `matrix_rain.tscn` | 120列随机字符下落 |
| 自定义光标 | `player_cursor.gd` | 鼠标跟随, Tween尺寸动画 |

#### UI/反馈
| 功能 | 文件 | 说明 |
|------|------|------|
| 终端风格HUD | `terminal_hud.gd` | 分数/连击/掩码/目标/进度条 |
| 背景目标显示 | `terminal_hud.gd` | 200px巨型半透明目标 |
| Perfect动画 | `terminal_hud.gd` | 颜色闪烁+屏幕边缘闪光 |
| 错误点击反馈 | `terminal_line.gd` | 标红+掩码提示(Q/W/E/R) |
| Game Over | `game_over_screen.gd` | 显示分数/时间/最高连击 |
| 暂停界面 | `pause_screen.gd` | ESC切换 |

#### 音频
| 功能 | 文件 | 说明 |
|------|------|------|
| BGM播放 | `audio_manager.gd` | 随机选曲 |
| BPM节拍检测 | `audio_manager.gd` | 低频能量峰值检测 |
| Perfect判定 | `audio_manager.gd` | ±100ms窗口 |
| 程序化音效 | `audio_manager.gd` | 正弦波合成(成功/失败/连击) |

#### 生成系统
| 功能 | 文件 | 说明 |
|------|------|------|
| 多列布局 | `terminal_spawner.gd` | 4列, 1-4个IP/次 |
| IP去重 | `terminal_spawner.gd` | 同屏无重复IP |
| 难度曲线 | `terminal_spawner.gd` | 每30s速度+10%, 间隔-10% |
| 音乐强度同步 | `terminal_spawner.gd` | 强度高→生成更多 |

---

### ❌ 未实现

| 计划功能 | 原因 |
|----------|------|
| `difficulty_manager.gd` | 文件不存在, 难度逻辑内置于 `terminal_spawner.gd` |
| BPM同步敌人生成 | 使用音乐强度而非节拍点触发 |
| 特殊敌人类型 | 奇偶校验/广播风暴/加密盾 未实现 |

> **注**：/8掩码(Q键)已在`game_manager.gd`中实现，`player_cursor.gd`光标尺寸仅包含/16/24/32是视觉简化。

---

## 开发历史

| 日期 | 时长 | 内容 |
|------|------|------|
| 2026-01-30 | 55min | Phase 1 原型验证 + Phase 2 视觉风格 |
| 2026-01-31 AM | 2h | Bug修复 + 终端风格重做 + 多列布局 |
| 2026-01-31 PM | 1.5h | Phase 3 连击/难度/音效/暂停 |
| 2026-01-31 EVE | 2h | Phase 4.1 掩码切换 + 4.4 多目标 + 错误反馈 |
| 2026-02-02 | 1h | 导出Windows/macOS/Linux |
| 2026-02-06 | 30min | 文档整理 + 项目重命名 |

---

## 文件结构

```
great_firewall_simulator/
├── scenes/
│   ├── main/main.tscn
│   ├── entities/
│   │   ├── terminal_line.tscn
│   │   ├── player_cursor.tscn
│   │   └── data_block.tscn
│   ├── ui/
│   │   ├── terminal_hud.tscn
│   │   ├── game_over_screen.tscn
│   │   ├── pause_screen.tscn
│   │   └── crt_overlay.tscn
│   └── effects/
│       └── matrix_rain.tscn
├── scripts/
│   ├── core/
│   │   ├── bitwise_manager.gd
│   │   └── colors.gd
│   ├── managers/
│   │   ├── game_manager.gd
│   │   ├── terminal_spawner.gd
│   │   ├── effect_manager.gd
│   │   └── audio_manager.gd
│   ├── entities/
│   │   ├── terminal_line.gd
│   │   ├── player_cursor.gd
│   │   └── data_block.gd
│   └── ui/
│       ├── terminal_hud.gd
│       ├── game_over_screen.gd
│       ├── pause_screen.gd
│       └── tutorial_screen.gd
├── shaders/
│   ├── crt_effect.gdshader
│   └── glitch_effect.gdshader
├── assets/
├── bgm_track_01.mp3
└── bgm_track_02.mp3
```

## Autoload 单例

| 名称 | 路径 |
|------|------|
| BitwiseManager | `res://scripts/core/bitwise_manager.gd` |
| GameManager | `res://scripts/managers/game_manager.gd` |
| EffectManager | `res://scripts/managers/effect_manager.gd` |
| AudioManager | `res://scripts/managers/audio_manager.gd` |

---

## 已修复的 Bug

1. **白屏**: CRT/Glitch shader 使用 `hint_screen_texture`
2. **卡死**: HUD日志 `queue_free()` 循环问题
3. **点击检测**: Control节点必须在CanvasLayer下
4. **/32除零**: `generate_random_ip_in_subnet` 特殊处理
5. **LabelSettings颜色**: 克隆后修改避免影响其他行
