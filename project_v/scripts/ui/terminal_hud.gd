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


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.alert_changed.connect(_on_alert_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.combo_reward.connect(_on_combo_reward)
	GameManager.mask_type_changed.connect(_on_mask_type_changed)
	GameManager.target_changed.connect(_on_target_changed)
	
	_update_header()
	_on_score_changed(0)
	_on_alert_changed(100.0)
	_on_combo_changed(0)
	_on_mask_type_changed(24)


func _process(_delta: float) -> void:
	# 更新 /16 冷却显示
	var cooldown = GameManager.get_mask_16_cooldown()
	if cooldown_label:
		if cooldown > 0:
			cooldown_label.text = "/16 COOLDOWN: %.1fs" % cooldown
			cooldown_label.visible = true
		else:
			cooldown_label.visible = false
	
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
		header_label.text = "V-FILTER v1.0"
	if target_label:
		target_label.text = "TARGET: %s" % GameManager.get_target_subnet_string()


func _on_target_changed(new_target: String) -> void:
	if target_label:
		target_label.text = "TARGET: %s" % new_target
		_pulse_target()


func _pulse_target() -> void:
	if target_label == null:
		return
	
	if target_tween and target_tween.is_valid():
		target_tween.kill()
	
	# 闪烁效果
	target_label.modulate = Color.WHITE
	target_tween = create_tween()
	target_tween.tween_property(target_label, "modulate", Color("#00ff41"), 0.3)


func _on_mask_type_changed(mask_type: int) -> void:
	if mask_label:
		var mask_formats = {
			32: "255.255.255.255",
			24: "255.255.255.0",
			16: "255.255.0.0"
		}
		mask_label.text = "MASK: %s" % mask_formats.get(mask_type, "/%d" % mask_type)
		
		match mask_type:
			32:
				mask_label.add_theme_color_override("font_color", Color.CYAN)
			24:
				mask_label.add_theme_color_override("font_color", Color("#00ff41"))
			16:
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
