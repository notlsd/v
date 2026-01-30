## SpawnManager
## 敌人生成器 - 定时生成数据块
extends Node

## 数据块场景
const DataBlockScene := preload("res://scenes/entities/data_block.tscn")

## 生成间隔（秒）
@export var spawn_interval: float = 1.5

## 生成位置范围
const SPAWN_Y: float = -50.0
const SPAWN_X_MIN: float = 100.0
const SPAWN_X_MAX: float = 1820.0

## 目标子网内数据的比例 (60% 目标内，40% 干扰)
@export var target_ratio: float = 0.6

## 颜色定义
const COLOR_ENEMY := Color("#ac2c25")  # V 红 - 敌人
const COLOR_NOISE := Color("#666666")  # 灰色 - 干扰项

## 生成计时器
var spawn_timer: Timer


func _ready() -> void:
	# 创建并配置计时器
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	_spawn_data_block()


func _spawn_data_block() -> void:
	var data_block := DataBlockScene.instantiate()
	
	# 随机生成位置
	var spawn_x := randf_range(SPAWN_X_MIN, SPAWN_X_MAX)
	data_block.position = Vector2(spawn_x, SPAWN_Y)
	
	# 决定是目标子网内还是干扰项
	var is_target := randf() < target_ratio
	var ip: int
	
	if is_target:
		# 生成目标子网内的 IP
		ip = BitwiseManager.generate_random_ip_in_subnet(
			GameManager.target_subnet, 
			GameManager.target_prefix
		)
		data_block.set_color(COLOR_ENEMY)
	else:
		# 生成目标子网外的 IP（干扰项）
		ip = BitwiseManager.generate_random_ip_outside_subnet(
			GameManager.target_subnet,
			GameManager.target_prefix
		)
		data_block.set_color(COLOR_NOISE)
	
	data_block.set_ip(ip)
	
	# 连接信号到 GameManager
	data_block.clicked.connect(GameManager._on_data_block_clicked)
	data_block.escaped.connect(GameManager._on_data_block_escaped)
	
	# 添加到场景
	get_parent().add_child(data_block)


## 更新生成间隔（用于难度调整）
func set_spawn_interval(interval: float) -> void:
	spawn_interval = interval
	if spawn_timer:
		spawn_timer.wait_time = interval
