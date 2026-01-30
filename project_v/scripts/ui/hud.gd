## HUD
## 终端风格 HUD - 带日志滚动和视觉升级
extends CanvasLayer

const MAX_LOG_LINES := 5
const LOG_TYPE_INTERVAL := 0.03  # 打字机效果间隔

@onready var target_label: Label = $TargetPanel/VBox/TargetLabel
@onready var mask_label: Label = $MaskPanel/VBox/MaskLabel
@onready var alert_bar: ProgressBar = $AlertBar
@onready var score_label: Label = $ScoreLabel
@onready var combo_label: Label = $ComboLabel
@onready var log_container: VBoxContainer = $LogPanel/LogContainer

var log_lines: Array[String] = []
var pending_logs: Array[String] = []
var current_typing_log: String = ""
var current_typing_index: int = 0
var is_typing: bool = false


func _ready() -> void:
	# 连接 GameManager 信号
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.alert_changed.connect(_on_alert_changed)
	GameManager.mask_changed.connect(_on_mask_changed)
	GameManager.match_success.connect(_on_match_success)
	GameManager.match_failure.connect(_on_match_failure)
	
	# 初始化显示
	_update_target_display()
	_update_mask_display(GameManager.current_prefix)
	_on_score_changed(0)
	_on_alert_changed(0.0)


func _process(delta: float) -> void:
	# 打字机效果处理
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
		# 警报高时变红
		if new_value > 70:
			alert_bar.modulate = Color.RED
		elif new_value > 40:
			alert_bar.modulate = Color.YELLOW
		else:
			alert_bar.modulate = Color.WHITE


func _on_mask_changed(new_prefix: int) -> void:
	_update_mask_display(new_prefix)


func _on_match_success() -> void:
	_add_log("[OK] Packet filtered successfully")


func _on_match_failure() -> void:
	_add_log("[ERR] Anomaly detected - Trace +10%")


func _add_log(message: String) -> void:
	pending_logs.append(message)
	if not is_typing:
		_start_next_log()


func _start_next_log() -> void:
	if pending_logs.is_empty():
		is_typing = false
		return
	
	current_typing_log = pending_logs.pop_front()
	current_typing_index = 0
	is_typing = true
	
	# 如果日志容器存在，添加新行
	if log_container:
		var new_label = Label.new()
		new_label.add_theme_font_size_override("font_size", 12)
		new_label.add_theme_color_override("font_color", Color("#00ff41"))
		new_label.text = ""
		log_container.add_child(new_label)
		
		# 限制日志行数
		while log_container.get_child_count() > MAX_LOG_LINES:
			log_container.get_child(0).queue_free()


func _process_typing() -> void:
	if not is_typing or log_container == null:
		return
	
	if log_container.get_child_count() == 0:
		return
	
	var current_label = log_container.get_children()[-1] as Label
	if current_label == null:
		return
	
	# 每帧添加多个字符以加快速度
	for i in range(3):
		if current_typing_index < current_typing_log.length():
			current_typing_index += 1
			current_label.text = current_typing_log.substr(0, current_typing_index)
		else:
			is_typing = false
			_start_next_log()
			break
