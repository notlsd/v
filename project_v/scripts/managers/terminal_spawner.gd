## TerminalSpawner
## 终端行生成器 - 多列布局，固定间隔，带难度曲线
extends Control

const TerminalLineScene = preload("res://scenes/entities/terminal_line.tscn")

## 基础配置
@export var base_spawn_interval: float = 1.2  # 固定生成间隔
@export var base_scroll_speed: float = 50.0
@export var target_ratio: float = 0.4

## 音乐路径
const BGM_TRACKS = [
	"res://bgm_track_01.mp3",
	"res://bgm_track_02.mp3"
]

## 生成位置 Y
const SPAWN_Y: float = 1000.0

## 列配置
const NUM_COLUMNS: int = 4
const SCREEN_WIDTH: float = 1920.0
const COLUMN_WIDTH: float = SCREEN_WIDTH / NUM_COLUMNS
const LINE_WIDTH: float = 450.0

## 难度曲线配置
const DIFFICULTY_INCREASE_INTERVAL: float = 30.0  # 每30秒增加难度
const SPEED_INCREASE_RATE: float = 0.1  # 每次速度增加10%
const INTERVAL_DECREASE_RATE: float = 0.1  # 间隔减少率
const MIN_SPAWN_INTERVAL: float = 0.6  # 最小生成间隔

## 运行时变量
var spawn_timer: Timer = null
var column_positions: Array[float] = []
var game_time: float = 0.0
var current_scroll_speed: float = 50.0
var current_spawn_interval: float = 1.2


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	current_scroll_speed = base_scroll_speed
	current_spawn_interval = base_spawn_interval
	
	# 计算每列的 X 起始位置
	for i in range(NUM_COLUMNS):
		var x_pos = i * COLUMN_WIDTH + (COLUMN_WIDTH - LINE_WIDTH) / 2
		column_positions.append(x_pos)
	
	# 创建定时器（固定间隔生成）
	spawn_timer = Timer.new()
	spawn_timer.wait_time = current_spawn_interval
	spawn_timer.timeout.connect(_spawn_lines)
	add_child(spawn_timer)
	spawn_timer.start()
	
	# 开始播放 BGM
	AudioManager.play_bgm(BGM_TRACKS.pick_random())
	
	print("[TerminalSpawner] Started with fixed interval: %.1fs" % current_spawn_interval)
	
	# 立即生成一行
	_spawn_lines()


func _process(delta: float) -> void:
	game_time += delta
	_update_difficulty()


func _update_difficulty() -> void:
	# 计算难度倍率（每30秒增加一级）
	var difficulty_level = floor(game_time / DIFFICULTY_INCREASE_INTERVAL)
	var difficulty_multiplier = 1.0 + difficulty_level * SPEED_INCREASE_RATE
	
	# 更新速度
	current_scroll_speed = base_scroll_speed * difficulty_multiplier
	
	# 更新生成间隔（难度越高间隔越短）
	var new_interval = base_spawn_interval / difficulty_multiplier
	current_spawn_interval = max(MIN_SPAWN_INTERVAL, new_interval)
	
	# 更新定时器
	if spawn_timer and abs(spawn_timer.wait_time - current_spawn_interval) > 0.01:
		spawn_timer.wait_time = current_spawn_interval


func _spawn_lines() -> void:
	var num_ips = randi_range(1, 3)
	
	var available_columns = range(NUM_COLUMNS)
	available_columns.shuffle()
	
	for i in range(num_ips):
		if i >= available_columns.size():
			break
		_spawn_single_line(available_columns[i])


func _spawn_single_line(column_index: int) -> void:
	var line = TerminalLineScene.instantiate()
	
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
	
	add_child(line)
	
	var x_pos = column_positions[column_index]
	line.position = Vector2(x_pos, SPAWN_Y)
	line.setup(ip, is_target, current_scroll_speed)
	
	line.clicked.connect(_on_line_clicked)
	line.escaped.connect(_on_line_escaped)


func _on_line_clicked(ip: int) -> void:
	GameManager._on_data_block_clicked(ip)


func _on_line_escaped() -> void:
	GameManager._on_data_block_escaped()


func get_game_time() -> float:
	return game_time


func get_difficulty_level() -> int:
	return int(floor(game_time / DIFFICULTY_INCREASE_INTERVAL))


func reset() -> void:
	# 清除所有现有的行
	for child in get_children():
		if child != spawn_timer:
			child.queue_free()
	
	# 重置时间和速度
	game_time = 0.0
	current_scroll_speed = base_scroll_speed
	current_spawn_interval = base_spawn_interval
	
	if spawn_timer:
		spawn_timer.wait_time = current_spawn_interval
	
	# 重新播放 BGM
	AudioManager.play_bgm(BGM_TRACKS.pick_random())
