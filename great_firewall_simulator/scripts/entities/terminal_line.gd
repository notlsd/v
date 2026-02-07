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
	
	# 检查是否是 mask 错误（IP 本来是正确的）
	_check_and_show_mask_hint()


## 检查并显示 mask 提示
func _check_and_show_mask_hint() -> void:
	# 检查这个 IP 使用目标 prefix 是否匹配
	var correct_mask := BitwiseManager.prefix_to_mask(GameManager.target_prefix)
	var result := BitwiseManager.apply_mask(ip_address, correct_mask)
	
	if result == GameManager.target_subnet:
		# IP 本来是正确的，但玩家用错了 mask - 显示提示
		_show_mask_hint(GameManager.target_prefix)


## 在 IP 旁边显示 mask 提示
func _show_mask_hint(correct_prefix: int) -> void:
	# 根据 prefix 确定对应的键位
	var key_hint = ""
	match correct_prefix:
		8:
			key_hint = "Q:/8"
		16:
			key_hint = "W:/16"
		24:
			key_hint = "E:/24"
		32:
			key_hint = "R:/32"
	
	# 创建提示标签（与 IP 字体大小一致）
	var hint_label = Label.new()
	hint_label.text = "  " + key_hint
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 与 IP 相同的字体大小，半透明红色
	var settings = LabelSettings.new()
	settings.font_size = 32
	settings.font_color = Color(1, 0.3, 0.3, 0.6)  # 半透明红色
	hint_label.label_settings = settings
	
	# 位置：在 IP 右侧紧挨着
	hint_label.position = Vector2(280, 0)
	hint_label.size = Vector2(100, 40)
	
	add_child(hint_label)
	
	# 动画：淡入淡出
	hint_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(hint_label, "modulate:a", 1.0, 0.1)
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tween.tween_callback(func(): hint_label.queue_free())
