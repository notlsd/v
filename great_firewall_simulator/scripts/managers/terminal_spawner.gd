## TerminalSpawner
## 终端行生成器 - 多列布局，固定间隔，带难度曲线
extends Control

const TerminalLineScene = preload("res://scenes/entities/terminal_line.tscn")

## 基础配置
@export var base_spawn_interval: float = 1.2  # 固定生成间隔
@export var base_scroll_speed: float = 50.0

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

## IP 去重系统
var active_ips: Dictionary = {}  # IP (int) -> line reference


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
	# 定时器不自动启动，等游戏开始后启动
	
	print("[TerminalSpawner] Ready, waiting for game to unpause...")


var game_started: bool = false

func _process(delta: float) -> void:
	# 等待游戏取消暂停后启动
	if not game_started and not get_tree().paused:
		game_started = true
		spawn_timer.start()
		AudioManager.play_bgm(BGM_TRACKS.pick_random())
		_spawn_lines()
		print("[TerminalSpawner] Game started!")
	
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


## 根据 target prefix 调整生成比例
## /8: 约 16M 个可能 IP → 生成更多 target
## /32: 1 个精确 IP → 生成更少
func _get_target_ratio_for_prefix(prefix: int) -> float:
	match prefix:
		8: return 0.6   # 更多 target
		16: return 0.5
		24: return 0.4
		32: return 0.3  # 更少但确保有
	return 0.4


## 基于音乐强度和游戏时间计算生成数量
func _calculate_spawn_count(intensity: float) -> int:
	var base_count = 1
	# 音乐强度加成 (0-2)
	var intensity_bonus = int(intensity * 2)
	# 时间加成：每分钟 +1，最多 +2
	var time_bonus = mini(2, int(game_time / 60.0))
	return clampi(base_count + intensity_bonus + time_bonus, 1, 4)


func _spawn_lines() -> void:
	# 根据音乐强度和游戏时间动态调整生成数量
	var intensity = AudioManager.get_current_intensity()
	var num_ips = _calculate_spawn_count(intensity)
	
	var available_columns = range(NUM_COLUMNS)
	available_columns.shuffle()
	
	for i in range(num_ips):
		if i >= available_columns.size():
			break
		_spawn_single_line(available_columns[i])


func _spawn_single_line(column_index: int) -> void:
	var line = TerminalLineScene.instantiate()
	
	# 根据 prefix 调整 target 比例
	var target_ratio = _get_target_ratio_for_prefix(GameManager.target_prefix)
	var is_target = randf() < target_ratio
	
	# 生成不重复的 IP
	var ip = _generate_unique_ip(is_target)
	if ip == -1:
		# 无法生成唯一 IP，跳过
		line.queue_free()
		return
	
	add_child(line)
	
	var x_pos = column_positions[column_index]
	line.position = Vector2(x_pos, SPAWN_Y)
	line.setup(ip, is_target, current_scroll_speed)
	
	# 追踪活跃 IP
	active_ips[ip] = line
	
	# 连接信号
	line.clicked.connect(_on_line_clicked)
	line.escaped.connect(_on_line_escaped)
	line.tree_exiting.connect(_on_line_removed.bind(ip))


## 生成唯一的 IP（不与当前活跃 IP 重复）
func _generate_unique_ip(is_target: bool) -> int:
	var max_attempts = 20
	
	for _attempt in range(max_attempts):
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
		
		# 检查是否重复
		if ip not in active_ips:
			return ip
	
	# 尝试多次仍有重复，返回 -1 表示失败
	return -1


## 当 line 被移除时，从活跃 IP 列表中删除
func _on_line_removed(ip: int) -> void:
	active_ips.erase(ip)


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
	
	# 清空活跃 IP
	active_ips.clear()
	
	# 重置时间和速度
	game_time = 0.0
	current_scroll_speed = base_scroll_speed
	current_spawn_interval = base_spawn_interval
	
	if spawn_timer:
		spawn_timer.wait_time = current_spawn_interval
	
	# 重新播放 BGM
	AudioManager.play_bgm(BGM_TRACKS.pick_random())

