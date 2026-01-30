## HUD
## 基础 HUD - 显示目标子网、当前掩码、警报条
extends CanvasLayer

@onready var target_label: Label = $TargetPanel/VBox/TargetLabel
@onready var mask_label: Label = $MaskPanel/VBox/MaskLabel
@onready var alert_bar: ProgressBar = $AlertBar
@onready var score_label: Label = $ScoreLabel


func _ready() -> void:
	# 连接 GameManager 信号
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.alert_changed.connect(_on_alert_changed)
	GameManager.mask_changed.connect(_on_mask_changed)
	
	# 初始化显示
	_update_target_display()
	_update_mask_display(GameManager.current_prefix)
	_on_score_changed(0)
	_on_alert_changed(0.0)


func _update_target_display() -> void:
	if target_label:
		target_label.text = GameManager.get_target_subnet_string()


func _update_mask_display(prefix: int) -> void:
	if mask_label:
		mask_label.text = "/%d" % prefix


func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "SCORE: %d" % new_score


func _on_alert_changed(new_value: float) -> void:
	if alert_bar:
		alert_bar.value = new_value


func _on_mask_changed(new_prefix: int) -> void:
	_update_mask_display(new_prefix)
