## DataBlock
## 数据块敌人 - 携带 IP 地址，下落并可被点击
## 视觉升级版本 - 带边框发光和类型区分
extends Area2D

## 信号：被点击时发出
signal clicked(ip_address: int)

## 信号：逃脱屏幕底部时发出
signal escaped()

## 数据类型枚举
enum DataType { ENEMY, CIVILIAN, NOISE }

## IP 地址（整数形式）
var ip_address: int = 0

## 数据块类型
var data_type: DataType = DataType.ENEMY

## 下落速度
@export var fall_speed: float = 200.0

## 屏幕底部边界
const SCREEN_BOTTOM: float = 1100.0

## 类型对应颜色
const TYPE_COLORS := {
	DataType.ENEMY: Color("#ac2c25"),    # V 红
	DataType.CIVILIAN: Color("#00ff41"), # 矩阵绿
	DataType.NOISE: Color("#666666")     # 灰色
}

@onready var background: ColorRect = $Background
@onready var border: ColorRect = $Border
@onready var ip_label: Label = $IPLabel


func _ready() -> void:
	_update_display()


func _process(delta: float) -> void:
	# 下落运动
	position.y += fall_speed * delta
	
	# 边框脉冲效果
	if border:
		var pulse = (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.5
		border.modulate.a = 0.5 + pulse * 0.5
	
	# 检查是否离开屏幕底部
	if position.y > SCREEN_BOTTOM:
		escaped.emit()
		queue_free()


## 被点击时由外部调用
func on_clicked() -> void:
	print("[DataBlock] Clicked: %s (%d) Type: %s" % [
		BitwiseManager.int_to_ip(ip_address), 
		ip_address,
		DataType.keys()[data_type]
	])
	clicked.emit(ip_address)
	queue_free()


## 设置 IP 地址
func set_ip(ip: int) -> void:
	ip_address = ip
	if is_inside_tree():
		_update_display()


## 设置数据类型
func set_data_type(type: DataType) -> void:
	data_type = type
	_update_color()


## 更新 IP 显示
func _update_display() -> void:
	if ip_label:
		ip_label.text = BitwiseManager.int_to_ip(ip_address)
	_update_color()


## 更新颜色
func _update_color() -> void:
	var color: Color = TYPE_COLORS.get(data_type, Color.RED)
	if background:
		background.color = color
	if border:
		border.color = color.lightened(0.3)


## 设置颜色（兼容旧接口）
func set_color(color: Color) -> void:
	if background:
		background.color = color
	if border:
		border.color = color.lightened(0.3)
