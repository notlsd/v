## HUD
## 终端风格 HUD - 带日志滚动和视觉升级
extends CanvasLayer

const MAX_LOG_LINES := 5

@onready var target_label: Label = $TargetPanel/VBox/TargetLabel
@onready var mask_label: Label = $MaskPanel/VBox/MaskLabel
@onready var alert_bar: ProgressBar = $AlertBar
@onready var score_label: Label = $ScoreLabel
@onready var combo_label: Label = $ComboLabel
@onready var log_container: VBoxContainer = $LogPanel/LogContainer

var pending_logs: Array[String] = []
var current_typing_log: String = ""
var current_typing_index: int = 0
var is_typing: bool = false


func _ready() -> void:
	# 连接 GameManager 信号
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.alert_changed.connect(_on_alert_changed)
	GameManager.mask_type_changed.connect(_on_mask_changed)
	GameManager.match_success.connect(_on_match_success)
	GameManager.match_failure.connect(_on_match_failure)
	
	# 初始化显示
	_update_target_display()
	_update_mask_display(GameManager.current_prefix)
	_on_score_changed(0)
	_on_alert_changed(0.0)


func _process(_delta: float) -> void:
	_process_typing()


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
		if new_value > 70:
			alert_bar.modulate = Color.RED
		elif new_value > 40:
			alert_bar.modulate = Color.YELLOW
		else:
			alert_bar.modulate = Color.WHITE


func _on_mask_changed(new_prefix: int) -> void:
	_update_mask_display(new_prefix)


func _on_match_success() -> void:
	_add_log("[OK] Packet filtered")


func _on_match_failure() -> void:
	_add_log("[ERR] Trace +10%")


func _add_log(message: String) -> void:
	if log_container == null:
		return
	
	# 直接添加完整的日志行（移除打字机效果避免卡顿）
	var new_label = Label.new()
	new_label.add_theme_font_size_override("font_size", 12)
	new_label.add_theme_color_override("font_color", Color("#00ff41"))
	new_label.text = message
	log_container.add_child(new_label)
	
	# 限制日志行数 - 使用计数器避免无限循环
	var remove_count = log_container.get_child_count() - MAX_LOG_LINES
	for i in range(remove_count):
		if log_container.get_child_count() > 0:
			var child = log_container.get_child(0)
			log_container.remove_child(child)
			child.queue_free()


func _process_typing() -> void:
	# 打字机效果已移除以提高稳定性
	pass
