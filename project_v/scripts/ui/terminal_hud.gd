## TerminalHUD
## 终端风格 HUD - 显示分数、连击、掩码、目标、进度条
extends CanvasLayer

@onready var header_label: Label = $Header/HeaderLabel
@onready var target_label: Label = $Header/TargetLabel
@onready var mask_label: Label = $Header/MaskLabel
@onready var target_timer_label: Label = $Header/TargetTimerLabel
@onready var score_label: Label = $Footer/ScoreLabel
@onready var combo_label: Label = $Footer/ComboLabel
@onready var cooldown_label: Label = $Footer/CooldownLabel
@onready var alert_bar: ProgressBar = $AlertBar

var combo_tween: Tween = null
var target_tween: Tween = null
var perfect_label: Label = null
var bg_target_layer: CanvasLayer = null
var bg_target_label: Label = null


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.alert_changed.connect(_on_alert_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.combo_reward.connect(_on_combo_reward)
	GameManager.mask_changed.connect(_on_mask_changed)
	GameManager.target_changed.connect(_on_target_changed)
	
	_update_header()
	_on_score_changed(0)
	_on_alert_changed(100.0)
	_on_combo_changed(0)
	_on_mask_changed(GameManager.get_current_mask_decimal())
	
	# 创建背景目标层
	_create_bg_target_display()
	
	# Perfect 标签
	_create_perfect_label()
	
	# 连接 Perfect 信号
	AudioManager.perfect_hit.connect(_on_perfect_hit)
	
	# 隐藏左下角提示（不再固定显示）
	if cooldown_label:
		cooldown_label.visible = false


func _process(_delta: float) -> void:
	# 更新目标切换倒计时
	if target_timer_label:
		var time_left = GameManager.get_time_until_target_change()
		target_timer_label.text = "NEXT: %.1fs" % time_left
		
		# 最后3秒高亮警告
		if time_left <= 3.0:
			target_timer_label.add_theme_color_override("font_color", Color.RED)
		else:
			target_timer_label.add_theme_color_override("font_color", Color.YELLOW)


func _update_header() -> void:
	if header_label:
		header_label.text = "Great Fire Wall Simulator"
	if target_label:
		target_label.text = "TARGET: %s" % GameManager.get_target_subnet_string()
		target_label.visible = false  # 隐藏右上角 target


func _on_target_changed(new_target: String) -> void:
	if target_label:
		target_label.text = "TARGET: %s" % new_target
		_pulse_target()
	
	# 更新背景目标
	if bg_target_label:
		bg_target_label.text = new_target
		_pulse_bg_target()


func _pulse_target() -> void:
	if target_label == null:
		return
	
	if target_tween and target_tween.is_valid():
		target_tween.kill()
	
	# 闪烁效果
	target_label.modulate = Color.WHITE
	target_tween = create_tween()
	target_tween.tween_property(target_label, "modulate", Color("#00ff41"), 0.3)


func _pulse_bg_target() -> void:
	if bg_target_label == null:
		return
	
	# 闪烁效果（使用固定值避免累积问题）
	bg_target_label.modulate = Color(1, 1, 1, 1.5)  # 闪亮
	var tween = create_tween()
	tween.tween_property(bg_target_label, "modulate", Color(1, 1, 1, 1.0), 0.5)



func _on_mask_changed(mask_decimal: String) -> void:
	if mask_label:
		mask_label.text = "MASK: %s" % mask_decimal
		
		# 根据掩码类型设置颜色
		match mask_decimal:
			"255.255.255.255":
				mask_label.add_theme_color_override("font_color", Color.CYAN)
			"255.255.255.0":
				mask_label.add_theme_color_override("font_color", Color("#00ff41"))
			"255.255.0.0":
				mask_label.add_theme_color_override("font_color", Color.YELLOW)
			"255.0.0.0":
				mask_label.add_theme_color_override("font_color", Color.RED)


func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "SCORE: %d" % new_score


func _on_combo_changed(new_combo: int) -> void:
	if combo_label:
		if new_combo > 0:
			combo_label.text = "COMBO x%d" % new_combo
			combo_label.visible = true
			_pulse_combo()
		else:
			combo_label.visible = false


func _on_combo_reward(reward_type: String) -> void:
	if combo_label:
		match reward_type:
			"tier1":
				combo_label.add_theme_color_override("font_color", Color.YELLOW)
			"tier2":
				combo_label.add_theme_color_override("font_color", Color.ORANGE)
			"tier3":
				combo_label.add_theme_color_override("font_color", Color.RED)
		
		_big_pulse_combo()


func _pulse_combo() -> void:
	if combo_label == null:
		return
	
	if combo_tween and combo_tween.is_valid():
		combo_tween.kill()
	
	combo_label.scale = Vector2(1.2, 1.2)
	combo_tween = create_tween()
	combo_tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.15)


func _big_pulse_combo() -> void:
	if combo_label == null:
		return
	
	if combo_tween and combo_tween.is_valid():
		combo_tween.kill()
	
	combo_label.scale = Vector2(2.0, 2.0)
	combo_tween = create_tween()
	combo_tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.3)


func _on_alert_changed(new_value: float) -> void:
	if alert_bar:
		alert_bar.value = new_value
		if new_value < 30:
			alert_bar.modulate = Color.RED
		elif new_value < 60:
			alert_bar.modulate = Color.YELLOW
		else:
			alert_bar.modulate = Color("#00ff41")


## 创建 Perfect 标签
func _create_perfect_label() -> void:
	perfect_label = Label.new()
	perfect_label.text = "PERFECT"
	perfect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perfect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	perfect_label.visible = false
	
	# 终端风格样式
	var settings = LabelSettings.new()
	settings.font_size = 48
	settings.font_color = Color("#00ff41")  # 终端绿
	settings.shadow_size = 8
	settings.shadow_color = Color(0, 1, 0.3, 0.5)
	perfect_label.label_settings = settings
	
	# 全屏填充，文字自动居中
	perfect_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	perfect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	add_child(perfect_label)


## Perfect 命中 - 酷炫动画
func _on_perfect_hit() -> void:
	if perfect_label == null:
		return
	
	# 设置初始状态
	perfect_label.visible = true
	perfect_label.modulate = Color("#00ff41")
	perfect_label.modulate.a = 1.0
	
	# 弹跳 + 淡出动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 颜色闪烁：绿 -> 青 -> 白 -> 绿
	tween.tween_property(perfect_label, "modulate", Color.CYAN, 0.1)
	tween.chain().tween_property(perfect_label, "modulate", Color.WHITE, 0.1)
	tween.chain().tween_property(perfect_label, "modulate", Color("#00ff41"), 0.1)
	# 淡出
	tween.chain().tween_property(perfect_label, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tween.chain().tween_callback(func(): perfect_label.visible = false)
	
	# 屏幕边缘闪光效果
	_flash_screen_edge()

## 屏幕边缘闪光效果
func _flash_screen_edge() -> void:
	# 创建一个短暂的边缘发光效果
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0, 1, 0.3, 0.3)  # 半透明绿色
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	# 快速淡出
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.15)
	tween.tween_callback(func(): flash.queue_free())


## 创建背景目标显示
func _create_bg_target_display() -> void:
	# 创建底层 CanvasLayer（在矩阵雨之上，终端行之下）
	bg_target_layer = CanvasLayer.new()
	bg_target_layer.layer = 1
	add_child(bg_target_layer)
	
	# 创建容器
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_target_layer.add_child(container)
	
	# 创建巨大的目标标签
	bg_target_label = Label.new()
	bg_target_label.text = GameManager.get_target_subnet_string()
	bg_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg_target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bg_target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 样式：超大字体，半透明
	var settings = LabelSettings.new()
	settings.font_size = 200  # 巨大字体
	settings.font_color = Color(0, 1, 0.3, 0.25)  # 半透明绿色（更亮）
	bg_target_label.label_settings = settings
	
	# 全屏
	bg_target_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	container.add_child(bg_target_label)
	print("[HUD] Background target display created: %s" % bg_target_label.text)

