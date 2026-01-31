## TerminalLine
## 终端中的一行 IP 地址 - 可点击，向上滚动
extends Control

signal clicked(ip_address: int)
signal escaped()

## IP 地址
var ip_address: int = 0

## 是否是目标（需要点击）
var is_target: bool = false

## 滚动速度
var scroll_speed: float = 50.0

## 是否已被点击
var is_clicked: bool = false

## 是否已通知 GameManager
var notified_remove: bool = false

@onready var label: Label = $Label
@onready var highlight: ColorRect = $Highlight


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	# 初始隐藏高亮
	if highlight:
		highlight.visible = false
	
	# 如果是目标，通知 GameManager
	if is_target:
		GameManager.add_valid_ip()


func _process(delta: float) -> void:
	# 向上滚动
	position.y -= scroll_speed * delta
	
	# 检查是否离开屏幕顶部
	if position.y < -50:
		if is_target and not is_clicked and not notified_remove:
			notified_remove = true
			GameManager.remove_valid_ip()
			escaped.emit()
		queue_free()


func setup(ip: int, target: bool, speed: float) -> void:
	ip_address = ip
	is_target = target
	scroll_speed = speed
	_update_display()
	
	# 如果在 setup 时已经 ready，需要手动添加
	if is_target and is_inside_tree():
		GameManager.add_valid_ip()


func _update_display() -> void:
	if label == null:
		return
	
	var ip_str = BitwiseManager.int_to_ip(ip_address)
	
	# 所有 IP 看起来一样 - 玩家需要自己判断
	label.text = "  %s" % ip_str
	label.add_theme_color_override("font_color", Color("#00ff41"))


func _on_mouse_entered() -> void:
	if highlight and not is_clicked:
		highlight.visible = true


func _on_mouse_exited() -> void:
	if highlight:
		highlight.visible = false


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_clicked:
				# 先检查是否匹配
				var is_match = GameManager.check_ip_match(ip_address)
				
				if is_match:
					# 匹配成功 - 标记已点击，发送信号，销毁
					is_clicked = true
					if is_target and not notified_remove:
						notified_remove = true
						GameManager.remove_valid_ip()
					clicked.emit(ip_address)
					queue_free()
				else:
					# 匹配失败 - 标红，不销毁，仍发送信号触发扣分等
					clicked.emit(ip_address)
					_show_wrong_click()


func _show_clicked_state() -> void:
	if label:
		label.modulate.a = 0.3
	if highlight:
		highlight.visible = false


## 点击错误 - 标红
func _show_wrong_click() -> void:
	if label and label.label_settings:
		# 克隆设置以避免影响其他行
		var new_settings = label.label_settings.duplicate()
		new_settings.font_color = Color.RED
		label.label_settings = new_settings
	if highlight:
		highlight.visible = false
	# 允许再次点击（如果玩家改变掩码后重新尝试）
	is_clicked = false

