## TerminalSpawner
## 终端行生成器 - 多列布局，IP地址在列中对齐
extends Control

const TerminalLineScene = preload("res://scenes/entities/terminal_line.tscn")

## 生成间隔（秒）
@export var spawn_interval: float = 1.5

## 滚动速度
@export var scroll_speed: float = 50.0

## 目标 IP 比例
@export var target_ratio: float = 0.4

## 生成位置 Y
const SPAWN_Y: float = 1000.0

## 列配置
const NUM_COLUMNS: int = 4
const SCREEN_WIDTH: float = 1920.0
const COLUMN_WIDTH: float = SCREEN_WIDTH / NUM_COLUMNS  # 480
const LINE_WIDTH: float = 450.0  # 每个IP块的宽度，留点间距

var spawn_timer: Timer = null
var column_positions: Array[float] = []


func _ready() -> void:
	# 设置为全屏容器
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 计算每列的 X 起始位置
	for i in range(NUM_COLUMNS):
		var x_pos = i * COLUMN_WIDTH + (COLUMN_WIDTH - LINE_WIDTH) / 2
		column_positions.append(x_pos)
	
	# 创建定时器
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_lines)
	add_child(spawn_timer)
	spawn_timer.start()
	
	print("[TerminalSpawner] Columns: %s" % column_positions)
	
	# 立即生成一行作为测试
	_spawn_lines()


func _spawn_lines() -> void:
	# 随机决定这一行生成几个IP（1-3个）
	var num_ips = randi_range(1, 3)
	
	# 随机选择列（不重复）
	var available_columns = range(NUM_COLUMNS)
	available_columns.shuffle()
	
	for i in range(num_ips):
		if i >= available_columns.size():
			break
		_spawn_single_line(available_columns[i])


func _spawn_single_line(column_index: int) -> void:
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
	
	# 先添加到场景树
	add_child(line)
	
	# 设置位置（使用列的X位置）
	var x_pos = column_positions[column_index]
	line.position = Vector2(x_pos, SPAWN_Y)
	line.setup(ip, is_target, scroll_speed)
	
	# 连接信号
	line.clicked.connect(_on_line_clicked)
	line.escaped.connect(_on_line_escaped)


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
