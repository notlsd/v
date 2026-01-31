## TerminalHUD
## 终端风格 HUD - 显示分数、连击、进度条
extends CanvasLayer

@onready var header_label: Label = $Header/HeaderLabel
@onready var target_label: Label = $Header/TargetLabel
@onready var score_label: Label = $Footer/ScoreLabel
@onready var combo_label: Label = $Footer/ComboLabel
@onready var alert_bar: ProgressBar = $AlertBar

var combo_tween: Tween = null


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.alert_changed.connect(_on_alert_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.combo_reward.connect(_on_combo_reward)
	
	_update_header()
	_on_score_changed(0)
	_on_alert_changed(100.0)
	_on_combo_changed(0)


func _update_header() -> void:
	if header_label:
		header_label.text = "V-FILTER v1.0"
	if target_label:
		target_label.text = "TARGET: %s" % GameManager.get_target_subnet_string()


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
	# 连击奖励视觉反馈
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
