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

@onready var label: Label = $Label
@onready var highlight: ColorRect = $Highlight


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	# 初始隐藏高亮
	if highlight:
		highlight.visible = false


func _process(delta: float) -> void:
	# 向上滚动
	position.y -= scroll_speed * delta
	
	# 检查是否离开屏幕顶部
	if position.y < -50:
		if is_target and not is_clicked:
			escaped.emit()
		queue_free()


func setup(ip: int, target: bool, speed: float) -> void:
	ip_address = ip
	is_target = target
	scroll_speed = speed
	_update_display()


func _update_display() -> void:
	if label == null:
		return
	
	var ip_str = BitwiseManager.int_to_ip(ip_address)
	var timestamp = Time.get_time_string_from_system()
	
	if is_target:
		# 目标 IP - 红色，带标记
		label.text = "[%s] > INCOMING: %s  <<<" % [timestamp, ip_str]
		label.add_theme_color_override("font_color", Color("#ac2c25"))
	else:
		# 普通流量 - 绿色
		label.text = "[%s]   TRAFFIC: %s" % [timestamp, ip_str]
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
				is_clicked = true
				clicked.emit(ip_address)
				_show_clicked_state()


func _show_clicked_state() -> void:
	if label:
		label.modulate.a = 0.3
	if highlight:
		highlight.visible = false
