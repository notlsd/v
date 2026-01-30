# project_v 48小时 Game Jam 执行计划

> **执行环境**: Google Antigravity Multi-agent IDE (Claude Opus 4.5)  
> **引擎**: Godot 4.x (GDScript)  
> **目标**: 在 48 小时内完成可发布的赛博朋克节奏逻辑射击游戏

---

## 0. 执行须知

### 0.1 文档使用规则

- 每个 Task 必须按顺序执行，前一个 Task 的 Review 通过后才能进入下一个
- Review 标准为 **Pass/Fail**：所有检查项必须全部通过
- 如果 Review 失败，必须修复后重新 Review，不得跳过
- 每个 Phase 结束时有阶段性验收，验收通过才能进入下一 Phase

### 0.2 项目上下文

**游戏核心概念**：玩家扮演数字幽灵 V，使用子网掩码作为武器，通过位运算过滤数据流，解放被压迫的民众数据。

**核心机制**：
1. 屏幕落下带有 IP 地址的数据块
2. 玩家选择掩码（/32, /24, /16）并点击数据块
3. 执行 `Result = Data_IP & Player_Mask`
4. 判定是否匹配目标子网

**技术约束**：
- 使用整数存储 IP 和掩码，仅在 UI 层转换为字符串
- 使用 `_unhandled_input()` 处理输入以降低延迟
- 所有视觉元素基于几何图形 + Shader，无复杂美术资产

---

## Phase 1: 原型验证 (0-12h)

> **目标**: 完成可玩的灰盒原型，验证核心玩法是否有趣

---

### Task 1.1: 项目初始化

**执行内容**：
1. 创建 Godot 4.x 项目，项目名 `project_v`
2. 设置项目分辨率为 1920x1080
3. 创建以下目录结构：
   ```
   project_v/
   ├── scenes/
   │   ├── main/
   │   ├── entities/
   │   └── ui/
   ├── scripts/
   │   ├── core/
   │   ├── entities/
   │   └── managers/
   ├── shaders/
   ├── audio/
   │   ├── bgm/
   │   └── sfx/
   ├── assets/
   │   ├── fonts/
   │   └── textures/
   └── resources/
   ```
4. 创建 `main.tscn` 作为主场景并设置为启动场景
5. 初始化 Git 仓库，创建 `.gitignore`（排除 `.godot/`, `*.import`）

**Review 标准** (全部 Pass 才算通过):

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 项目可在 Godot 4.x 中打开且无报错 | |
| 2 | 分辨率设置为 1920x1080 | |
| 3 | 目录结构完整存在 | |
| 4 | `main.tscn` 存在且已设置为启动场景 | |
| 5 | Git 仓库已初始化，`.gitignore` 正确配置 | |
| 6 | 按 F5 可运行项目（显示空白窗口即可） | |

---

### Task 1.2: 位运算核心模块

**执行内容**：
1. 创建 `scripts/core/bitwise_manager.gd` 作为 Autoload 单例
2. 实现以下功能：
   ```gdscript
   # IP 字符串转整数
   func ip_to_int(ip_string: String) -> int
   
   # 整数转 IP 字符串（用于 UI 显示）
   func int_to_ip(ip_int: int) -> String
   
   # 掩码前缀转整数（如 /24 -> 4294967040）
   func prefix_to_mask(prefix: int) -> int
   
   # 核心判定：执行位运算并返回结果
   func apply_mask(ip: int, mask: int) -> int
   
   # 判定是否匹配目标子网
   func check_match(ip: int, mask: int, target_subnet: int) -> bool
   ```
3. 在 Project Settings -> Autoload 中注册为 `BitwiseManager`

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `bitwise_manager.gd` 文件存在于正确路径 | |
| 2 | 已在 Autoload 中注册为 `BitwiseManager` | |
| 3 | `ip_to_int("192.168.1.1")` 返回 `3232235777` | |
| 4 | `int_to_ip(3232235777)` 返回 `"192.168.1.1"` | |
| 5 | `prefix_to_mask(24)` 返回 `4294967040` (即 255.255.255.0) | |
| 6 | `prefix_to_mask(16)` 返回 `4294901760` (即 255.255.0.0) | |
| 7 | `prefix_to_mask(32)` 返回 `4294967295` (即 255.255.255.255) | |
| 8 | `apply_mask(3232235777, 4294967040)` 返回 `3232235776` (192.168.1.0) | |
| 9 | `check_match(3232235777, 4294967040, 3232235776)` 返回 `true` | |
| 10 | `check_match(3232235777, 4294967040, 3232236032)` 返回 `false` | |

---

### Task 1.3: 玩家光标控制

**执行内容**：
1. 创建 `scenes/entities/player_cursor.tscn`
2. 节点结构：
   ```
   PlayerCursor (Area2D)
   ├── CollisionShape2D (CircleShape2D, radius=30)
   └── Sprite2D (或 ColorRect 作为占位)
   ```
3. 创建 `scripts/entities/player_cursor.gd`
4. 实现功能：
   - 光标跟随鼠标位置（每帧更新 `global_position = get_global_mouse_position()`）
   - 存储当前掩码值（默认 /24）
   - 按 Q/W/E 或滚轮切换掩码：
     - Q: /32 (精准狙击)
     - W: /24 (标准模式)  
     - E: /16 (范围清屏)
   - 发出信号 `mask_changed(new_prefix: int)`
5. 将 `player_cursor.tscn` 实例化到 `main.tscn`

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `player_cursor.tscn` 文件存在 | |
| 2 | 运行游戏时光标跟随鼠标移动 | |
| 3 | 按 Q 键切换到 /32 模式 | |
| 4 | 按 W 键切换到 /24 模式 | |
| 5 | 按 E 键切换到 /16 模式 | |
| 6 | 鼠标滚轮可循环切换掩码 | |
| 7 | 切换掩码时控制台打印当前掩码值（调试输出） | |

---

### Task 1.4: 数据块敌人

**执行内容**：
1. 创建 `scenes/entities/data_block.tscn`
2. 节点结构：
   ```
   DataBlock (Area2D)
   ├── CollisionShape2D (RectangleShape2D, size=80x40)
   ├── ColorRect (红色 #ac2c25，大小匹配碰撞体)
   └── Label (显示 IP 地址，白色等宽字体)
   ```
3. 创建 `scripts/entities/data_block.gd`
4. 实现功能：
   - 属性 `ip_address: int`（由生成器赋值）
   - 下落运动（`velocity.y = 200`，可配置）
   - 离开屏幕底部时自动销毁并发出信号 `escaped`
   - 被点击时的碰撞检测（使用 `input_event` 信号）
   - 发出信号 `clicked(ip_address: int)` 供外部处理判定

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `data_block.tscn` 文件存在 | |
| 2 | 手动实例化到场景中可正常显示红色方块 | |
| 3 | 方块上显示 IP 地址文本 | |
| 4 | 运行时方块向下移动 | |
| 5 | 方块离开屏幕底部时被销毁（不报错） | |
| 6 | 点击方块时控制台打印其 IP 地址（调试输出） | |

---

### Task 1.5: 敌人生成器

**执行内容**：
1. 创建 `scripts/managers/spawn_manager.gd`
2. 实现功能：
   - 定时生成数据块（初始间隔 1.5 秒）
   - 生成位置：屏幕顶部，X 随机（100 到 1820 之间）
   - 为每个数据块生成随机 IP（范围：192.168.0.0/16 内）
   - 可配置目标子网（如 192.168.1.0/24）
   - 生成的数据块中，约 60% 属于目标子网，40% 为干扰项
3. 在 `main.tscn` 中作为 Node 添加并绑定脚本

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `spawn_manager.gd` 文件存在 | |
| 2 | 运行游戏后数据块自动从屏幕顶部生成 | |
| 3 | 生成位置 X 坐标在合理范围内（不超出屏幕） | |
| 4 | 不同数据块的 IP 地址各不相同 | |
| 5 | 生成间隔约为 1.5 秒 | |
| 6 | 连续运行 30 秒无崩溃或内存泄漏 | |

---

### Task 1.6: 核心判定整合

**执行内容**：
1. 创建 `scripts/managers/game_manager.gd` 作为 Autoload
2. 实现功能：
   - 存储当前目标子网（如 `target_subnet = 3232235776` 即 192.168.1.0）
   - 存储当前掩码前缀（从 PlayerCursor 获取）
   - 监听数据块的 `clicked` 信号
   - 执行判定逻辑：
     ```gdscript
     func _on_data_block_clicked(ip: int):
         var mask = BitwiseManager.prefix_to_mask(current_prefix)
         var result = BitwiseManager.apply_mask(ip, mask)
         if result == target_subnet:
             _on_match_success()
         else:
             _on_match_failure()
     ```
   - 成功时：销毁数据块，打印 "MATCH!"
   - 失败时：打印 "MISMATCH!"，增加警报值
3. 在 Autoload 中注册

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `game_manager.gd` 已注册为 Autoload | |
| 2 | 点击属于目标子网的数据块，控制台显示 "MATCH!" | |
| 3 | 点击不属于目标子网的数据块，控制台显示 "MISMATCH!" | |
| 4 | 成功匹配后数据块被销毁 | |
| 5 | 使用不同掩码（/24 vs /16）影响判定结果 | |
| 6 | 切换到 /32 掩码后，只有精确 IP 匹配才成功 | |

---

### Task 1.7: 基础 HUD

**执行内容**：
1. 创建 `scenes/ui/hud.tscn`
2. 节点结构：
   ```
   HUD (CanvasLayer, layer=10)
   ├── TargetPanel (PanelContainer, 左上角)
   │   └── VBox
   │       ├── Label "TARGET SUBNET:"
   │       └── TargetLabel (显示目标子网，如 "192.168.1.0/24")
   ├── MaskPanel (PanelContainer, 右上角)
   │   └── VBox
   │       ├── Label "CURRENT MASK:"
   │       └── MaskLabel (显示当前掩码，如 "/24")
   └── AlertBar (ProgressBar, 底部，显示警报追踪度)
   ```
3. 创建 `scripts/ui/hud.gd`
4. 实现功能：
   - 监听 `PlayerCursor.mask_changed` 更新掩码显示
   - 监听 `GameManager` 更新警报条
   - 使用等宽字体（如 JetBrains Mono 或系统默认）
5. 实例化到 `main.tscn`

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `hud.tscn` 文件存在 | |
| 2 | 运行游戏可见目标子网显示 | |
| 3 | 运行游戏可见当前掩码显示 | |
| 4 | 切换掩码时 HUD 实时更新 | |
| 5 | 警报条可见且初始值为 0 | |
| 6 | 匹配失败时警报条增加 | |

---

### Task 1.8: 原型验证测试

**执行内容**：
1. 完整运行游戏 3 分钟
2. 记录以下体验指标：
   - 核心循环是否流畅（看IP -> 判断 -> 切掩码 -> 点击）
   - 点击响应是否即时
   - 难度是否合理（不会太简单或太难）
3. 如发现问题，调整以下参数：
   - 数据块下落速度
   - 生成间隔
   - 目标子网内数据块的比例
4. 创建 `docs/prototype_notes.md` 记录测试结论

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 游戏可连续运行 3 分钟无崩溃 | |
| 2 | 核心循环（看-判断-切-点）可在 2 秒内完成 | |
| 3 | 点击后判定响应延迟 < 100ms（主观感知） | |
| 4 | 新玩家可在 30 秒内理解玩法（假设性评估） | |
| 5 | `prototype_notes.md` 已创建并包含测试结论 | |

---

### Phase 1 验收

**Phase 1 完成标准**（全部 Pass 才能进入 Phase 2）:

| # | 验收项 | Pass/Fail |
|---|--------|-----------|
| 1 | 所有 Task 1.1-1.8 的 Review 均已通过 | |
| 2 | 按 F5 可启动完整可玩的灰盒原型 | |
| 3 | "看IP -> 切掩码 -> 点击"的核心循环可正常运行 | |
| 4 | 位运算判定逻辑正确（/32, /24, /16 各有不同效果） | |
| 5 | HUD 正确显示游戏状态 | |
| 6 | Git 提交当前进度，commit message: "Phase 1: Prototype Complete" | |

---

## Phase 2: 视觉风格与资产 (13-30h)

> **目标**: 替换占位素材，建立赛博朋克/CRT 视觉风格

---

### Task 2.1: 终端字体与配色

**执行内容**：
1. 下载并导入等宽字体（推荐：Fira Code, JetBrains Mono, 或 VT323）
2. 在 `resources/` 创建 `theme.tres` 主题资源
3. 定义配色常量（创建 `scripts/core/colors.gd`）：
   ```gdscript
   const BG_BLACK = Color("#000000")      # 背景
   const V_RED = Color("#ac2c25")         # V 的红色
   const PALE_WHITE = Color("#ddcebe")    # 面具苍白
   const MATRIX_GREEN = Color("#00ff41")  # 终端绿
   const ALERT_YELLOW = Color("#ffcc00")  # 警告
   ```
4. 更新 HUD 使用新主题
5. 更新数据块颜色：敌人红色，可救援数据绿色

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 等宽字体已导入且可在编辑器中使用 | |
| 2 | `theme.tres` 文件存在 | |
| 3 | `colors.gd` 包含所有规定的颜色常量 | |
| 4 | HUD 文本使用等宽字体 | |
| 5 | 游戏背景为纯黑 (#000000) | |
| 6 | 敌人数据块显示为红色 (#ac2c25) | |

---

### Task 2.2: CRT Shader 效果

**执行内容**：
1. 创建 `shaders/crt_effect.gdshader`
2. 实现以下效果：
   - 扫描线 (Scanlines)：水平黑色条纹，间隔 2-4 像素
   - 桶形畸变 (Barrel Distortion)：屏幕边缘轻微弯曲
   - 色差 (Chromatic Aberration)：边缘 RGB 通道分离
   - 可选：轻微的 Vignette 暗角
3. 创建 `scenes/ui/crt_overlay.tscn`：
   ```
   CRTOverlay (CanvasLayer, layer=100)
   └── ColorRect (全屏，应用 crt_effect shader)
   ```
4. 将 CRT Overlay 添加到 `main.tscn`
5. 提供 shader uniform 参数可在运行时调整强度

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `crt_effect.gdshader` 文件存在 | |
| 2 | 运行游戏可见扫描线效果 | |
| 3 | 屏幕边缘有轻微弯曲（桶形畸变） | |
| 4 | 屏幕边缘可见 RGB 分离（色差） | |
| 5 | 效果不影响游戏性能（保持 60fps） | |
| 6 | Shader 强度参数可调（如 scanline_opacity） | |

---

### Task 2.3: Glitch Shader 效果

**执行内容**：
1. 创建 `shaders/glitch_effect.gdshader`
2. 实现以下效果：
   - 水平撕裂：随机 UV 偏移
   - 颜色通道错位
   - 噪点干扰
3. 创建触发机制：
   - 匹配失败时触发 0.1 秒 glitch
   - 切换掩码时触发 0.05 秒 glitch
   - 受到伤害时触发更强烈的 glitch
4. 通过 shader uniform `glitch_intensity` 控制强度（0-1）
5. 创建 `scripts/managers/effect_manager.gd` 管理效果触发

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `glitch_effect.gdshader` 文件存在 | |
| 2 | 调用 `EffectManager.trigger_glitch(0.5)` 可见画面撕裂 | |
| 3 | 匹配失败时自动触发 glitch | |
| 4 | 切换掩码时触发短暂 glitch | |
| 5 | Glitch 效果持续时间可控 | |
| 6 | 效果结束后画面恢复正常 | |

---

### Task 2.4: 背景矩阵雨效果

**执行内容**：
1. 创建 `scenes/effects/matrix_rain.tscn`
2. 使用 GPUParticles2D 或自定义脚本实现：
   - 下落的 "0" 和 "1" 字符
   - 颜色：暗绿色 (#003b00 到 #00ff41 渐变)
   - 速度：比数据块慢，作为背景装饰
   - 随机生成，随机透明度
3. 放置于 CanvasLayer layer=-1（在数据块之后）
4. 性能优化：限制最大粒子数 < 200

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `matrix_rain.tscn` 文件存在 | |
| 2 | 运行游戏可见背景有绿色字符下落 | |
| 3 | 矩阵雨在数据块之后（视觉层级正确） | |
| 4 | 矩阵雨颜色为绿色系 | |
| 5 | FPS 保持在 60 以上（性能达标） | |
| 6 | 粒子效果不干扰游戏操作（纯装饰） | |

---

### Task 2.5: 数据块视觉升级

**执行内容**：
1. 重新设计 DataBlock 视觉：
   - 边框：1px 发光边框
   - 内部：IP 地址显示，带有微弱扫描动画
   - 类型区分：
     - 敌人 (Fingermen)：红色，显示攻击图标
     - 平民 (Civilian)：绿色，显示加密图标
     - 干扰项：灰色
2. 添加数据块类型枚举：
   ```gdscript
   enum DataType { ENEMY, CIVILIAN, NOISE }
   ```
3. 更新 SpawnManager 生成逻辑支持不同类型
4. 根据类型影响判定规则：
   - ENEMY：匹配成功 = 击杀，得分+
   - CIVILIAN：匹配成功 = 救援，得分++
   - NOISE：匹配成功 = 误杀，得分-

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 三种数据块类型有明显视觉区分 | |
| 2 | 敌人数据块为红色 | |
| 3 | 平民数据块为绿色 | |
| 4 | 干扰项数据块为灰色 | |
| 5 | 数据块有边框发光效果 | |
| 6 | 击杀敌人/救援平民/误杀各有不同分数反馈 | |

---

### Task 2.6: 玩家光标视觉升级

**执行内容**：
1. 重新设计 PlayerCursor：
   - 圆形掩码光圈，带有旋转的二进制刻度
   - 光圈大小反映当前掩码范围：
     - /32：小圆（半径 20）
     - /24：中圆（半径 40）
     - /16：大圆（半径 80）
   - 颜色：苍白色 (#ddcebe) 带发光
2. 添加切换掩码的过渡动画（Tween 缩放）
3. 点击时的脉冲反馈动画

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 光标显示为圆形光圈 | |
| 2 | /32 模式下光圈最小 | |
| 3 | /24 模式下光圈中等 | |
| 4 | /16 模式下光圈最大 | |
| 5 | 切换掩码有平滑过渡动画 | |
| 6 | 点击时有脉冲反馈 | |

---

### Task 2.7: 终端风格 HUD 升级

**执行内容**：
1. 重新设计 HUD 为复古终端风格：
   - 左上：目标子网显示（带闪烁光标）
   - 右上：当前掩码显示（带指示器）
   - 左侧：系统日志滚动显示（最近 5 条）
   - 底部：
     - 警报条（红色渐变）
     - 分数显示
     - 连击计数
2. 日志系统实现：
   - 匹配成功："[OK] Packet 192.168.1.x filtered"
   - 匹配失败："[ERR] Anomaly detected - Trace +10%"
   - 连击达到阈值："[SYS] Signal strength increasing..."
3. 日志使用打字机效果逐字显示

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | HUD 整体呈现终端风格 | |
| 2 | 系统日志区域可见且滚动显示 | |
| 3 | 操作会触发对应日志消息 | |
| 4 | 日志有打字机效果 | |
| 5 | 分数和连击计数正确显示 | |
| 6 | 所有 HUD 元素使用统一的配色方案 | |

---

### Task 2.8: 击杀特效 - V字斩痕

**执行内容**：
1. 创建 `scenes/effects/v_slash_effect.tscn`
2. 使用 GPUParticles2D 实现：
   - 敌人被消灭时，生成红色粒子
   - 粒子轨迹形成 "V" 字形状
   - 持续时间 0.3 秒
   - 带有拖尾效果
3. 创建 `scripts/effects/v_slash_effect.gd`
4. 在 DataBlock 被销毁时实例化特效

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `v_slash_effect.tscn` 文件存在 | |
| 2 | 击杀敌人时产生红色粒子效果 | |
| 3 | 粒子轨迹呈现 V 字形状（或近似） | |
| 4 | 特效持续约 0.3 秒后消失 | |
| 5 | 特效在正确位置生成（数据块位置） | |
| 6 | 连续击杀不会导致性能问题 | |

---

### Task 2.9: 音频系统基础

**执行内容**：
1. 创建 `scripts/managers/audio_manager.gd` 作为 Autoload
2. 实现基础音频播放：
   - BGM 播放（循环）
   - SFX 播放（一次性）
   - 音量控制
3. 占位音效（可用 Godot 内置或网络免费资源）：
   - 点击成功：短促的电子 "ping"
   - 点击失败：低沉的 "buzz"
   - 切换掩码：滋滋的调频声
4. 预留 BPM 同步接口（下一 Task 实现）

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `audio_manager.gd` 已注册为 Autoload | |
| 2 | 可播放背景音乐（即使是占位音乐） | |
| 3 | 点击成功有音效反馈 | |
| 4 | 点击失败有音效反馈 | |
| 5 | 切换掩码有音效反馈 | |
| 6 | 音量可通过代码调节 | |

---

### Task 2.10: BPM 同步系统

**执行内容**：
1. 扩展 `audio_manager.gd` 添加 BPM 同步：
   - 设置核心 BPM（120 或 128）
   - 计算每拍时长 `beat_duration = 60.0 / bpm`
   - 发出信号 `beat_hit` 每拍触发
2. 创建节拍可视化：
   - 屏幕边缘根据节拍脉动
   - HUD 元素根据节拍轻微闪烁
3. 连接 SpawnManager：
   - 敌人生成与节拍同步
   - 每 N 拍生成一个敌人（可配置）
4. 实现 Perfect 判定窗口：
   - 在节拍点 ±50ms 内点击为 "Perfect"
   - Perfect 提供额外分数加成

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | BPM 可配置且正确计算拍长 | |
| 2 | `beat_hit` 信号按节拍触发 | |
| 3 | 屏幕有节拍同步的视觉反馈 | |
| 4 | 敌人生成与节拍同步 | |
| 5 | Perfect 判定在节拍点 ±50ms 触发 | |
| 6 | Perfect 击中有明显的视觉/音效区分 | |

---

### Phase 2 验收

**Phase 2 完成标准**（全部 Pass 才能进入 Phase 3）:

| # | 验收项 | Pass/Fail |
|---|--------|-----------|
| 1 | 所有 Task 2.1-2.10 的 Review 均已通过 | |
| 2 | 游戏具有完整的 CRT/赛博朋克视觉风格 | |
| 3 | 扫描线、色差、Glitch 效果正常工作 | |
| 4 | 背景矩阵雨效果可见 | |
| 5 | 三种数据块类型视觉明确区分 | |
| 6 | 玩家光标根据掩码模式改变大小 | |
| 7 | HUD 为终端风格，日志滚动显示 | |
| 8 | 击杀特效（V 字斩）正常显示 | |
| 9 | 音效系统工作，点击/切换有反馈 | |
| 10 | BPM 同步系统工作，有节拍感 | |
| 11 | FPS 稳定在 55+ | |
| 12 | Git 提交，commit message: "Phase 2: Visual Style Complete" | |

---

## Phase 3: 打磨与调试 (31-42h)

> **目标**: 增加游戏性深度，调整难度曲线，添加"果汁感"

---

### Task 3.1: 屏幕震动系统

**执行内容**：
1. 创建 `scripts/effects/screen_shake.gd`
2. 实现功能：
   - 可配置强度和持续时间
   - 使用 Perlin Noise 或随机偏移
   - 平滑衰减
3. 触发时机：
   - Perfect 击中：轻微震动 (intensity=2, duration=0.05)
   - 匹配失败：中等震动 (intensity=5, duration=0.1)
   - 连击断裂：强烈震动 (intensity=10, duration=0.2)
4. 应用到主摄像机或 CanvasLayer

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `screen_shake.gd` 文件存在 | |
| 2 | Perfect 击中触发轻微震动 | |
| 3 | 匹配失败触发中等震动 | |
| 4 | 震动强度可通过参数控制 | |
| 5 | 震动有平滑衰减，不会突然停止 | |
| 6 | 震动不影响 UI 层（或 UI 层也震动但可接受） | |

---

### Task 3.2: 击中定格 (Hit Stop)

**执行内容**：
1. 在 GameManager 中实现时间缩放：
   ```gdscript
   func trigger_hitstop(duration: float = 0.05):
       Engine.time_scale = 0.1
       await get_tree().create_timer(duration * 0.1).timeout
       Engine.time_scale = 1.0
   ```
2. 触发时机：
   - Perfect 击中：定格 0.03 秒
   - 击杀精英敌人：定格 0.1 秒
   - 连击里程碑（10, 25, 50）：定格 0.05 秒
3. 确保 UI 元素和音频不受时间缩放影响

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | Perfect 击中时有短暂定格感 | |
| 2 | 定格期间游戏元素确实减速 | |
| 3 | 定格后游戏恢复正常速度 | |
| 4 | 连续触发定格不会累积卡死 | |
| 5 | UI 更新不受时间缩放影响 | |
| 6 | 音频播放不受时间缩放影响（或可接受的影响） | |

---

### Task 3.3: 连击系统完善

**执行内容**：
1. 扩展 GameManager 的连击系统：
   - 连击计数器 `combo_count`
   - 连击超时（2 秒无成功操作则重置）
   - 连击倍率：`score_multiplier = 1 + (combo / 10)`
2. 连击视觉反馈：
   - 连击数显示放大动画
   - 达到里程碑时特殊效果（10, 25, 50, 100）
   - 连击 > 10 时屏幕边缘发光加强
3. 连击音效：
   - 连击增加时音调递增
   - 连击断裂有特殊音效

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 连续成功操作增加连击数 | |
| 2 | 2 秒无操作或失败重置连击 | |
| 3 | 连击影响得分倍率 | |
| 4 | 连击数字有放大动画 | |
| 5 | 里程碑（10, 25, 50）有特殊反馈 | |
| 6 | 连击增加时音调有变化 | |

---

### Task 3.4: 动态难度调整 (TCP 滑动窗口)

**执行内容**：
1. 创建 `scripts/managers/difficulty_manager.gd`
2. 实现"窗口"机制：
   - `window_size`：影响难度的核心值
   - 玩家表现好（高连击）→ 窗口扩大
   - 玩家表现差（频繁失误）→ 窗口收缩
3. 窗口大小影响：
   - 敌人下落速度：基础 200 + window * 20
   - 生成频率：基础 1.5s - window * 0.1s
   - 同屏敌人数量上限
4. 平滑调整，避免难度骤变

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `difficulty_manager.gd` 文件存在 | |
| 2 | 连续成功后难度明显提升（更快/更多敌人） | |
| 3 | 连续失败后难度降低（给予喘息） | |
| 4 | 难度变化平滑，无突变 | |
| 5 | 难度有上下限保护 | |
| 6 | 当前难度可在 HUD 或调试中可见 | |

---

### Task 3.5: 特殊敌人 - 奇偶校验怪

**执行内容**：
1. 创建 `scenes/entities/data_block_parity.tscn`（继承 DataBlock）
2. 特殊行为：
   - IP 地址末位（主机位最后一位）在 0/1 之间闪烁
   - 闪烁周期：0.5 秒
   - 只有在特定状态（如偶数，末位=0）时点击才有效
3. 视觉区分：
   - 边框闪烁
   - 颜色在红/黄之间切换
4. 生成概率：5% 的敌人为奇偶校验怪

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 奇偶校验怪 IP 末位闪烁 | |
| 2 | 在正确状态点击才能成功 | |
| 3 | 在错误状态点击算失败 | |
| 4 | 视觉上与普通敌人有明显区别 | |
| 5 | 闪烁周期可被玩家预判 | |
| 6 | 正常游戏中有概率生成 | |

---

### Task 3.6: 特殊敌人 - 广播风暴

**执行内容**：
1. 创建 `scenes/entities/data_block_broadcast.tscn`
2. 特殊行为：
   - IP 地址以 `.255` 结尾（广播地址）
   - 如果到达屏幕底部，会分裂成 2-3 个普通敌人
   - 下落速度较慢，给玩家反应时间
3. 视觉区分：
   - 更大的体积
   - 发出脉冲波纹
   - 显示警告图标
4. 生成概率：10% 的敌人为广播风暴

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 广播风暴 IP 以 .255 结尾 | |
| 2 | 广播风暴下落较慢 | |
| 3 | 未被击中到达底部会分裂 | |
| 4 | 分裂产生的敌人正常运行 | |
| 5 | 视觉上明显可识别 | |
| 6 | 正常游戏中有概率生成 | |

---

### Task 3.7: Overdrive 模式

**执行内容**：
1. 在 GameManager 中实现 Overdrive：
   - 触发条件：连击达到 50 或"广播信号强度"满
   - 持续时间：10 秒
   - 效果：
     - 所有击中自动变为 Perfect
     - 分数倍率 x3
     - 视觉：屏幕边缘红色发光，V 面具轮廓闪现
2. 音频变化：
   - BGM 切换到更激烈的变奏（或调高音调）
   - 可选：引入《1812序曲》片段
3. 结束时平滑过渡回常规状态

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 达到触发条件时进入 Overdrive | |
| 2 | Overdrive 期间所有击中为 Perfect | |
| 3 | 分数倍率提升 | |
| 4 | 视觉效果明显（红色发光/V 面具） | |
| 5 | 音频有变化 | |
| 6 | 10 秒后正常结束并过渡 | |

---

### Task 3.8: 游戏结束条件

**执行内容**：
1. 实现游戏结束逻辑：
   - 失败条件：警报追踪度达到 100%
   - 胜利条件（可选）：存活指定时间或达到目标分数
2. 创建 `scenes/ui/game_over.tscn`：
   - 显示最终分数
   - 显示最高连击
   - 显示 V 的台词引用
   - 重新开始按钮
   - 返回主菜单按钮（如有）
3. 游戏结束动画：
   - 屏幕逐渐被 Glitch 覆盖
   - "CONNECTION LOST" 文字显示

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 警报满时游戏结束 | |
| 2 | Game Over 界面显示最终分数 | |
| 3 | Game Over 界面显示最高连击 | |
| 4 | 可点击重新开始 | |
| 5 | 重新开始后游戏状态完全重置 | |
| 6 | 游戏结束有过渡动画 | |

---

### Task 3.9: 教程/引导系统

**执行内容**：
1. 创建游戏开始时的简易教程：
   - 第 1 阶段：只生成目标子网内的敌人，提示 "Click to filter"
   - 第 2 阶段：引入子网外敌人，提示掩码概念
   - 第 3 阶段：教授掩码切换 (Q/W/E)
   - 第 4 阶段：正常游戏开始
2. 教程可通过首次启动触发或主菜单进入
3. 提示使用终端风格文本显示

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 新游戏开始有引导提示 | |
| 2 | 引导分阶段，逐步引入机制 | |
| 3 | 玩家可理解基本操作（点击过滤） | |
| 4 | 玩家可理解掩码切换 | |
| 5 | 教程提示风格与游戏一致 | |
| 6 | 教程完成后进入正常游戏 | |

---

### Task 3.10: 数值平衡调整

**执行内容**：
1. 创建 `resources/game_balance.tres` 资源文件存储所有数值
2. 可调参数清单：
   - 数据块下落基础速度
   - 生成间隔
   - 警报增加/减少量
   - 连击超时时间
   - 掩码切换冷却（如有）
   - Perfect 窗口大小
   - 各类敌人生成权重
3. 进行 5 轮测试游玩，每轮记录：
   - 平均存活时间
   - 最高连击
   - 主观难度感受（1-10）
4. 根据测试结果调整数值

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | `game_balance.tres` 文件存在且包含所有参数 | |
| 2 | 游戏代码从资源文件读取数值 | |
| 3 | 完成至少 3 轮测试游玩 | |
| 4 | 平均存活时间在 2-5 分钟（理想范围） | |
| 5 | 难度曲线平滑（开始容易，逐渐变难） | |
| 6 | 主观感受：具有挑战但不令人沮丧 | |

---

### Phase 3 验收

**Phase 3 完成标准**（全部 Pass 才能进入 Phase 4）:

| # | 验收项 | Pass/Fail |
|---|--------|-----------|
| 1 | 所有 Task 3.1-3.10 的 Review 均已通过 | |
| 2 | 屏幕震动和击中定格正常工作 | |
| 3 | 连击系统完整，有里程碑反馈 | |
| 4 | 动态难度调整平滑运行 | |
| 5 | 两种特殊敌人正常生成和工作 | |
| 6 | Overdrive 模式可触发且效果明显 | |
| 7 | 游戏有明确的结束条件和界面 | |
| 8 | 新玩家可通过教程理解玩法 | |
| 9 | 数值平衡合理，游戏有挑战但不沮丧 | |
| 10 | Git 提交，commit message: "Phase 3: Polish Complete" | |

---

## Phase 4: 打包与发布 (43-48h)

> **目标**: 确保游戏可稳定运行，打包并发布

---

### Task 4.1: 主菜单

**执行内容**：
1. 创建 `scenes/ui/main_menu.tscn`
2. 包含元素：
   - 游戏标题 "project_v" (大号，红色)
   - V 的面具图形或 ASCII Art
   - "START" 按钮
   - "HOW TO PLAY" 按钮（显示简要说明）
   - "QUIT" 按钮
3. 背景：使用矩阵雨效果
4. 添加一句 V 的名言作为副标题

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 主菜单场景存在 | |
| 2 | 标题清晰可见 | |
| 3 | START 按钮可进入游戏 | |
| 4 | HOW TO PLAY 显示操作说明 | |
| 5 | QUIT 按钮退出游戏 | |
| 6 | 主菜单风格与游戏一致 | |

---

### Task 4.2: 暂停菜单

**执行内容**：
1. 创建 `scenes/ui/pause_menu.tscn`
2. 按 ESC 键触发暂停
3. 暂停时：
   - 游戏时间停止
   - 显示半透明遮罩
   - 显示 "PAUSED" 文字
   - RESUME / RESTART / MAIN MENU 按钮
4. 恢复时平滑过渡

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 按 ESC 可暂停游戏 | |
| 2 | 暂停时游戏冻结 | |
| 3 | 暂停菜单显示所有按钮 | |
| 4 | RESUME 可恢复游戏 | |
| 5 | RESTART 重新开始游戏 | |
| 6 | MAIN MENU 返回主菜单 | |

---

### Task 4.3: 最终 Bug 检查

**执行内容**：
1. 创建 Bug 检查清单并逐一测试：
   - [ ] 游戏可从主菜单正常启动
   - [ ] 所有掩码模式工作正常
   - [ ] 点击判定准确无误点
   - [ ] 特殊敌人行为正确
   - [ ] 连击系统不会卡住或溢出
   - [ ] Overdrive 可触发且结束正常
   - [ ] 游戏结束可重新开始
   - [ ] 暂停/恢复无问题
   - [ ] 无内存泄漏（运行 10 分钟后检查）
   - [ ] 无明显的视觉 Glitch（非故意的）
2. 修复发现的所有 Bug

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | Bug 检查清单所有项均通过 | |
| 2 | 游戏可连续运行 10 分钟无崩溃 | |
| 3 | 无明显的卡顿或性能问题 | |
| 4 | 所有 UI 交互响应正常 | |
| 5 | 音频播放无破音或卡顿 | |
| 6 | 视觉效果正常，无意外的 artifact | |

---

### Task 4.4: HTML5 导出

**执行内容**：
1. 安装 HTML5 导出模板（如未安装）
2. 配置导出设置：
   - 分辨率：1920x1080（或 1280x720 作为备选）
   - 确保 WebGL 2.0 支持
   - 压缩设置：启用 VRAM 压缩
3. 导出到 `export/web/` 目录
4. 本地测试：使用 Python HTTP Server 或类似工具
5. 检查 Shader 兼容性（WebGL 可能与桌面版不同）

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | HTML5 导出成功生成文件 | |
| 2 | 在 Chrome 浏览器中可运行 | |
| 3 | 在 Firefox 浏览器中可运行 | |
| 4 | Shader 效果正常显示 | |
| 5 | 音频正常播放 | |
| 6 | 输入响应正常 | |

---

### Task 4.5: Windows 导出

**执行内容**：
1. 安装 Windows 导出模板（如未安装）
2. 配置导出设置：
   - 图标：V 面具图标（可选）
   - 窗口模式：Windowed, 可全屏
3. 导出到 `export/windows/` 目录
4. 测试运行 exe 文件

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | Windows 导出成功生成 exe | |
| 2 | 双击 exe 可启动游戏 | |
| 3 | 游戏运行正常无报错 | |
| 4 | 可切换全屏/窗口模式 | |
| 5 | 所有功能与编辑器内一致 | |

---

### Task 4.6: Itch.io 页面准备

**执行内容**：
1. 截取 3-5 张高质量截图
2. 录制 15-30 秒 GIF 动图展示游戏玩法
3. 撰写游戏描述（中英双语）：
   - 游戏概念（1-2 句）
   - 玩法说明
   - 操作指南
   - 制作背景（48h Game Jam）
4. 准备标签：cyberpunk, rhythm, puzzle, hacking, logic
5. 添加 V 的名言作为引用

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 截图清晰展示游戏画面 | |
| 2 | GIF 动图流畅展示核心玩法 | |
| 3 | 描述清楚说明游戏是什么 | |
| 4 | 包含操作指南 | |
| 5 | 文案风格与游戏主题一致 | |

---

### Task 4.7: 最终发布

**执行内容**：
1. 上传 HTML5 版本到 Itch.io（设置为可在浏览器中玩）
2. 上传 Windows 版本作为可下载备选
3. 设置页面：
   - 定价：免费
   - 可见性：公开
   - 标注 Game Jam 信息
4. 发布并获取链接
5. 最终测试：通过 Itch.io 链接玩一遍游戏

**Review 标准**:

| # | 检查项 | Pass/Fail |
|---|--------|-----------|
| 1 | 游戏已上传到 Itch.io | |
| 2 | HTML5 版可在浏览器中运行 | |
| 3 | Windows 版可下载 | |
| 4 | 页面信息完整 | |
| 5 | 游戏设置为公开 | |
| 6 | 通过公开链接可成功游玩 | |

---

### Phase 4 验收 (最终验收)

**Phase 4 完成标准**（全部 Pass 表示项目完成）:

| # | 验收项 | Pass/Fail |
|---|--------|-----------|
| 1 | 所有 Task 4.1-4.7 的 Review 均已通过 | |
| 2 | 主菜单和暂停菜单功能完整 | |
| 3 | 无已知的严重 Bug | |
| 4 | HTML5 版本可在主流浏览器运行 | |
| 5 | Windows 版本可正常运行 | |
| 6 | Itch.io 页面完整且游戏可公开访问 | |
| 7 | Git 最终提交，tag: "v1.0-gamejam-release" | |

---

## 附录 A: 文件清单

完成所有 Phase 后，项目应包含以下关键文件：

```
project_v/
├── project.godot
├── scenes/
│   ├── main/
│   │   └── main.tscn
│   ├── entities/
│   │   ├── player_cursor.tscn
│   │   ├── data_block.tscn
│   │   ├── data_block_parity.tscn
│   │   └── data_block_broadcast.tscn
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── main_menu.tscn
│   │   ├── pause_menu.tscn
│   │   ├── game_over.tscn
│   │   └── crt_overlay.tscn
│   └── effects/
│       ├── matrix_rain.tscn
│       └── v_slash_effect.tscn
├── scripts/
│   ├── core/
│   │   ├── bitwise_manager.gd
│   │   └── colors.gd
│   ├── entities/
│   │   ├── player_cursor.gd
│   │   └── data_block.gd
│   ├── managers/
│   │   ├── game_manager.gd
│   │   ├── spawn_manager.gd
│   │   ├── audio_manager.gd
│   │   ├── effect_manager.gd
│   │   └── difficulty_manager.gd
│   ├── ui/
│   │   └── hud.gd
│   └── effects/
│       └── screen_shake.gd
├── shaders/
│   ├── crt_effect.gdshader
│   └── glitch_effect.gdshader
├── resources/
│   ├── theme.tres
│   └── game_balance.tres
└── export/
    ├── web/
    └── windows/
```

---

## 附录 B: 快速参考

### 位运算速查

| 掩码 | 前缀 | 整数值 | 二进制 |
|------|------|--------|--------|
| 255.255.255.255 | /32 | 4294967295 | 全1 |
| 255.255.255.0 | /24 | 4294967040 | 24个1 + 8个0 |
| 255.255.0.0 | /16 | 4294901760 | 16个1 + 16个0 |

### 颜色速查

| 名称 | Hex | 用途 |
|------|-----|------|
| 背景黑 | #000000 | 背景 |
| V红 | #ac2c25 | 主色，敌人 |
| 面具白 | #ddcebe | 玩家，UI |
| 矩阵绿 | #00ff41 | 平民，背景 |
| 警告黄 | #ffcc00 | 警告 |

### 键位速查

| 按键 | 功能 |
|------|------|
| 鼠标左键 | 点击/确认 |
| Q | 切换到 /32 掩码 |
| W | 切换到 /24 掩码 |
| E | 切换到 /16 掩码 |
| 滚轮 | 循环切换掩码 |
| ESC | 暂停 |

---

## 附录 C: 时间预算

| Phase | 预计时长 | 累计 |
|-------|---------|------|
| Phase 1: 原型验证 | 12h | 12h |
| Phase 2: 视觉风格 | 17h | 29h |
| Phase 3: 打磨调试 | 12h | 41h |
| Phase 4: 打包发布 | 7h | 48h |

**风险缓冲**: 如果时间紧张，可砍掉的功能（按优先级）：
1. 特殊敌人（奇偶校验怪、广播风暴）
2. Overdrive 模式
3. 教程系统
4. Windows 导出（只发布 HTML5）

---

*文档版本: 1.0*  
*最后更新: 生成时*  
*"Remember, remember, the fifth of November..."*
