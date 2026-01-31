## TerminalSpawner
## 终端行生成器 - 在屏幕底部生成向上滚动的 IP 行
extends Node

const TerminalLineScene = preload("res://scenes/entities/terminal_line.tscn")

## 生成间隔（秒）
@export var spawn_interval: float = 1.5

## 滚动速度
@export var scroll_speed: float = 50.0

## 目标 IP 比例
@export var target_ratio: float = 0.4

## 生成位置 Y
const SPAWN_Y: float = 1000.0

var spawn_timer: Timer = null
var line_container: Control = null


func _ready() -> void:
	# 创建容器
	line_container = Control.new()
	line_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	line_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().add_child.call_deferred(line_container)
	
	# 创建定时器
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_line)
	add_child(spawn_timer)
	spawn_timer.start()


func _spawn_line() -> void:
	if line_container == null:
		return
	
	var line = TerminalLineScene.instantiate()
	line.position = Vector2(0, SPAWN_Y)
	
	# 决定是否为目标
	var is_target = randf() < target_ratio
	var ip: int
	
	if is_target:
		ip = BitwiseManager.generate_random_ip_in_subnet(
			GameManager.target_subnet,
			GameManager.target_prefix
		)
	else:
		ip = BitwiseManager.generate_random_ip_outside_subnet(
			GameManager.target_subnet,
			GameManager.target_prefix
		)
	
	line.setup(ip, is_target, scroll_speed)
	
	# 连接信号
	line.clicked.connect(_on_line_clicked)
	line.escaped.connect(_on_line_escaped)
	
	line_container.add_child(line)


func _on_line_clicked(ip: int) -> void:
	GameManager._on_data_block_clicked(ip)


func _on_line_escaped() -> void:
	GameManager._on_data_block_escaped()


## 调整难度
func set_difficulty(speed: float, interval: float) -> void:
	scroll_speed = speed
	spawn_interval = interval
	if spawn_timer:
		spawn_timer.wait_time = interval
