# PROJECT_V 开发会话记录

## Session ID
`acefafdb-466b-4677-90fc-98f0a78dc811`

## 会话历史

### 会话 1: 2026-01-30 23:17 - 00:12 (约55分钟)
- Phase 1 原型验证完成
- Phase 2 视觉风格初版完成

### 会话 2: 2026-01-31 07:51 - 09:52 (约2小时)
- 修复多个 Bug（白屏、卡死、点击检测）
- 终端风格重做：IP行向上滚动
- 进度条优化：全屏、倒计时、自动衰减
- Game Over 界面
- 多列布局（4列，每次1-3个IP）
- 矩阵雨密度增加（40→120列）

---

# 当前状态

## Phase 1: 原型验证 ✅ COMPLETE

## Phase 2: 视觉风格 ✅ COMPLETE

### 终端风格重做 ✅
- 移除旧的下落方块系统
- 新增 terminal_line.gd/tscn: 可点击IP行，向上滚动
- 新增 terminal_spawner.gd: 终端行生成器
- 新增 terminal_hud.gd/tscn: 终端风格HUD

### 多列布局 ✅
- 屏幕分为 4 列，每列宽度 480px
- 每次生成 1-3 个 IP，随机分布在不同列
- IP 块宽度 450px，在列内居中对齐

### 进度条优化 ✅
- 全屏宽度
- 倒计时逻辑（100→0，归零Game Over）
- 自动衰减（每秒-2）
- 颜色变化：绿(>60) → 黄(30-60) → 红(<30)

### Game Over 界面 ✅
- game_over_screen.gd/tscn
- 显示最终分数
- Restart 按钮

### 视觉效果 ✅
- 矩阵雨密度：120列
- 字体大小：32px（终端行）、36px（HUD）、64px（Game Over）
- CRT/Glitch shader

---

# 已修复的 Bug

1. **白屏问题**：CRT/Glitch shader 使用 `hint_screen_texture` 采样屏幕
2. **卡死问题**：HUD 日志 `queue_free()` 循环问题，简化为直接添加
3. **点击检测**：
   - Control 节点必须在 CanvasLayer 下才能渲染
   - `add_child()` 必须在 `setup()` 之前（@onready 初始化顺序）
   - 子节点 `mouse_filter=IGNORE` 让点击穿透
   - 行高适配字体（32px 字体 → 40px 行高）
   - 点击后 `queue_free()` 立即销毁

---

# Phase 3 计划（待展开）

- 变速 + 音乐绑定（BPM 同步）
- 多目标子网机制
- 难度曲线
- 性能优化
- 最终打磨

---

# 文件结构

```
project_v/
├── scenes/
│   ├── main/main.tscn
│   ├── entities/
│   │   ├── terminal_line.tscn (NEW)
│   │   ├── player_cursor.tscn (unused)
│   │   └── data_block.tscn (unused)
│   ├── ui/
│   │   ├── terminal_hud.tscn (NEW)
│   │   ├── game_over_screen.tscn (NEW)
│   │   ├── hud.tscn (unused)
│   │   └── crt_overlay.tscn
│   └── effects/
│       └── matrix_rain.tscn
├── scripts/
│   ├── core/
│   │   ├── bitwise_manager.gd
│   │   └── colors.gd
│   ├── managers/
│   │   ├── game_manager.gd
│   │   ├── terminal_spawner.gd (NEW)
│   │   ├── spawn_manager.gd (unused)
│   │   ├── effect_manager.gd
│   │   └── audio_manager.gd
│   ├── entities/
│   │   ├── terminal_line.gd (NEW)
│   │   ├── player_cursor.gd (unused)
│   │   └── data_block.gd (unused)
│   └── ui/
│       ├── terminal_hud.gd (NEW)
│       ├── game_over_screen.gd (NEW)
│       └── hud.gd (unused)
└── shaders/
    ├── crt_effect.gdshader
    └── glitch_effect.gdshader
```

---

# Autoload 单例

| 名称 | 路径 |
|------|------|
| BitwiseManager | res://scripts/core/bitwise_manager.gd |
| GameManager | res://scripts/managers/game_manager.gd |
| EffectManager | res://scripts/managers/effect_manager.gd |
| AudioManager | res://scripts/managers/audio_manager.gd |

---

# 恢复命令

继续开发时，告诉 AI：
> 继续 PROJECT_V 开发，Session ID: acefafdb-466b-4677-90fc-98f0a78dc811
