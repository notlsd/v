## TutorialScreen
## 新手教程弹窗 - 游戏启动时显示，包含 ASCII 艺术布局说明
extends CanvasLayer

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()


func _create_ui() -> void:
	# 半透明背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# 滚动容器
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.set_anchor(SIDE_LEFT, 0.1)
	scroll.set_anchor(SIDE_RIGHT, 0.9)
	scroll.set_anchor(SIDE_TOP, 0.05)
	scroll.set_anchor(SIDE_BOTTOM, 0.95)
	bg.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(vbox)
	
	# ========== 标题 ==========
	var title = Label.new()
	title.text = "GREAT FIRE WALL SIMULATOR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#00ff41"))
	vbox.add_child(title)
	
	# ========== Game Jam 说明 ==========
	var jam_label = Label.new()
	jam_label.text = """━━━━━━━━━━━━━━━━━━━━ GAME JAM 2025 ━━━━━━━━━━━━━━━━━━━━

主题：MASK（面具）  ×  精准快速点击  ×  V字仇杀队

本作将 "Mask" 诠释为网络工程中的「子网掩码 Subnet Mask」
你扮演的是 V —— 在数据洪流中守护网络的匿名英雄
通过精准点击，过滤属于目标子网的 IP 流量

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"""
	jam_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jam_label.add_theme_font_size_override("font_size", 16)
	jam_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(jam_label)
	
	# ========== 核心公式 ==========
	var formula = Label.new()
	formula.text = """
┌─────────────────────────────────────────────────────┐
│                     核心公式                        │
│                                                     │
│           IP  &  MASK  =  TARGET                    │
│                                                     │
│   点击满足上述公式的 IP 地址即可得分！             │
└─────────────────────────────────────────────────────┘"""
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formula.add_theme_font_size_override("font_size", 20)
	formula.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(formula)
	
	# ========== 屏幕布局 ASCII ==========
	var layout = Label.new()
	layout.text = """
┌──────────────────────────────────────────────────────────────────────┐
│  ████████████████████████████████████████████████  ← 生命条          │
│                                                                      │
│  MASK: 255.255.255.0                              NEXT: 8.5s         │
│                                                   ↑ 目标切换倒计时   │
│  ↑ 当前掩码（QWER切换）                                              │
│                                                                      │
│                                                                      │
│               ┌─────────────────────────────┐                        │
│               │                             │                        │
│               │     192.168.1.0/24          │  ← TARGET 背景大字     │
│               │                             │    (目标子网)          │
│               └─────────────────────────────┘                        │
│                                                                      │
│     192.168.1.45        10.0.0.12         172.16.5.88               │
│         ↑                   ↑                  ↑                     │
│      正确IP              错误IP             错误IP                   │
│    (可点击)                                                          │
│                                                                      │
│                                                                      │
│  SCORE: 1200        COMBO: x5         Q:/8  W:/16  E:/24  R:/32      │
│      ↑                 ↑                        ↑                    │
│    得分              连击数                 按键提示                 │
└──────────────────────────────────────────────────────────────────────┘"""
	layout.add_theme_font_size_override("font_size", 14)
	layout.add_theme_color_override("font_color", Color("#00ff41"))
	vbox.add_child(layout)
	
	# ========== 按键说明 ==========
	var keys = Label.new()
	keys.text = """
┌─────────────────────── 掩码切换（等价表示） ───────────────────────┐
│                                                                    │
│   Q  =  255.0.0.0          (等价于 /8，匹配最少)                   │
│   W  =  255.255.0.0        (等价于 /16)                            │
│   E  =  255.255.255.0      (等价于 /24，最常用)                    │
│   R  =  255.255.255.255    (等价于 /32，精确匹配)                  │
│                                                                    │
│   选择正确的掩码，才能让公式成立！                                 │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘"""
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keys.add_theme_font_size_override("font_size", 16)
	keys.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(keys)
	
	# ========== 示例 ==========
	var example = Label.new()
	example.text = """
┌─────────────────────────── 判定示例 ───────────────────────────────┐
│                                                                    │
│   TARGET = 192.168.1.0/24                                          │
│   IP     = 192.168.1.55                                            │
│                                                                    │
│   按 E (255.255.255.0)：                                           │
│   192.168.1.55 & 255.255.255.0 = 192.168.1.0  ✓ 匹配成功！         │
│                                                                    │
│   按 W (255.255.0.0)：                                             │
│   192.168.1.55 & 255.255.0.0 = 192.168.0.0    ✗ 不匹配 TARGET      │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘"""
	example.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	example.add_theme_font_size_override("font_size", 16)
	example.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(example)
	
	# ========== 开始按钮 ==========
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	var btn_box = HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_box)
	
	var start_btn = Button.new()
	start_btn.text = "  ▶  开 始 游 戏  ▶  "
	start_btn.custom_minimum_size = Vector2(300, 60)
	start_btn.add_theme_font_size_override("font_size", 24)
	start_btn.pressed.connect(_on_start)
	btn_box.add_child(start_btn)
	
	# 暂停游戏
	get_tree().paused = true


func _on_start() -> void:
	get_tree().paused = false
	queue_free()
