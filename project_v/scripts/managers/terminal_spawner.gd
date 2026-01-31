## TerminalSpawner
## 终端行生成器 - 在屏幕底部生成向上滚动的 IP 行
extends Control

const TerminalLineScene = preload("res://scenes/entities/terminal_line.tscn")

## 生成间隔（秒）
@export var spawn_interval: float = 1.5

## 滚动速度
@export var scroll_speed: float = 50.0

## 目标 IP 比例
@export var target_ratio: float = 0.4

## 生成位置 Y
const SPAWN_Y: float = 900.0

var spawn_timer: Timer = null


func _ready() -> void:
	# 设置为全屏容器
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 创建定时器
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_line)
	add_child(spawn_timer)
	spawn_timer.start()
	
	print("[TerminalSpawner] Started, interval: %s, speed: %s" % [spawn_interval, scroll_speed])
	
	# 立即生成一行作为测试
	_spawn_line()


func _spawn_line() -> void:
	var line = TerminalLineScene.instantiate()
	
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
	
	# 先添加到场景树，再设置（因为 @onready 需要在树中才能初始化）
	add_child(line)
	line.position = Vector2(0, SPAWN_Y)
	line.setup(ip, is_target, scroll_speed)
	
	# 连接信号
	line.clicked.connect(_on_line_clicked)
	line.escaped.connect(_on_line_escaped)
	
	print("[TerminalSpawner] Spawned: %s, target=%s" % [BitwiseManager.int_to_ip(ip), is_target])


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
