## TerminalHUD
## 终端风格 HUD - 显示在终端顶部和底部
extends CanvasLayer

@onready var header_label: Label = $Header/HeaderLabel
@onready var target_label: Label = $Header/TargetLabel
@onready var score_label: Label = $Footer/ScoreLabel
@onready var alert_bar: ProgressBar = $AlertBar


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.alert_changed.connect(_on_alert_changed)
	
	_update_header()
	_on_score_changed(0)
	_on_alert_changed(0.0)


func _update_header() -> void:
	if header_label:
		header_label.text = "V-FILTER v1.0 - NETWORK DEFENSE SYSTEM"
	if target_label:
		target_label.text = "FILTER TARGET: %s" % GameManager.get_target_subnet_string()


func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "FILTERED: %d" % new_score


func _on_alert_changed(new_value: float) -> void:
	if alert_bar:
		alert_bar.value = new_value
		# 高时绿色(安全)，低时红色(危险)
		if new_value < 30:
			alert_bar.modulate = Color.RED
		elif new_value < 60:
			alert_bar.modulate = Color.YELLOW
		else:
			alert_bar.modulate = Color("#00ff41")
