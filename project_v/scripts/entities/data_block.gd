## DataBlock
## 数据块敌人 - 携带 IP 地址，下落并可被点击
extends Area2D

## 信号：被点击时发出
signal clicked(ip_address: int)

## 信号：逃脱屏幕底部时发出
signal escaped()

## IP 地址（整数形式）
var ip_address: int = 0

## 下落速度
@export var fall_speed: float = 200.0

## 屏幕底部边界
const SCREEN_BOTTOM: float = 1100.0

@onready var background: ColorRect = $Background
@onready var ip_label: Label = $IPLabel


func _ready() -> void:
	# 更新显示的 IP 地址
	_update_display()


func _process(delta: float) -> void:
	# 下落运动
	position.y += fall_speed * delta
	
	# 检查是否离开屏幕底部
	if position.y > SCREEN_BOTTOM:
		escaped.emit()
		queue_free()


## 被点击时由外部调用
func on_clicked() -> void:
	print("[DataBlock] Clicked: %s (%d)" % [BitwiseManager.int_to_ip(ip_address), ip_address])
	clicked.emit(ip_address)
	queue_free()


## 设置 IP 地址
func set_ip(ip: int) -> void:
	ip_address = ip
	if is_inside_tree():
		_update_display()


## 更新 IP 显示
func _update_display() -> void:
	if ip_label:
		ip_label.text = BitwiseManager.int_to_ip(ip_address)


## 设置颜色（用于区分敌人/平民/干扰项）
func set_color(color: Color) -> void:
	if background:
		background.color = color
