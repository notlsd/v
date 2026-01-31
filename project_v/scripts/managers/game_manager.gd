## GameManager
## 游戏核心管理器 - 处理判定逻辑、分数、掩码、连击、目标轮换
extends Node

## 信号
signal score_changed(new_score: int)
signal alert_changed(new_value: float)
signal mask_type_changed(mask_type: int)
signal match_success()
signal match_failure()
signal game_over(final_score: int)
signal combo_changed(new_combo: int)
signal combo_reward(reward_type: String)
signal target_changed(new_target: String)

## 目标子网
var target_subnet: int = 0
var target_prefix: int = 24

## 目标轮换系统
var target_change_timer: float = 0.0
var game_time: float = 0.0
const BASE_TARGET_INTERVAL: float = 10.0
const MIN_TARGET_INTERVAL: float = 5.0
const INTERVAL_DECREASE_RATE: float = 0.05  # 每30秒减少5%

## 当前掩码类型 (32, 24, 16)
var current_mask_type: int = 24

## /16 冷却系统
var mask_16_cooldown: float = 0.0
const MASK_16_COOLDOWN_TIME: float = 5.0

## 分数
var score: int = 0

## 剩余生命 (100-0)
var alert_level: float = 100.0

## 连击计数
var combo: int = 0
var max_combo: int = 0

## 常量
const ALERT_DECREASE_ON_FAIL: float = 10.0
const ALERT_INCREASE_ON_SUCCESS: float = 2.0
const ALERT_DECAY_PER_SECOND: float = 2.0

## Combo 奖励阈值
const COMBO_TIER_1: int = 5
const COMBO_TIER_2: int = 10
const COMBO_TIER_3: int = 20

## 前缀权重表 (匹配范围宽的少，窄的多)
const PREFIX_WEIGHTS = {
	0: 1,    # 5% - 全部
	8: 2,    # 10% - A类
	24: 10,  # 50% - C类
	32: 7    # 35% - 单个
}

## 当前屏幕上的有效IP数量
var valid_ip_count: int = 0


func _ready() -> void:
	_generate_random_target()
	alert_changed.emit(alert_level)
	combo_changed.emit(combo)
	mask_type_changed.emit(current_mask_type)


func _process(delta: float) -> void:
	game_time += delta
	
	# 生命衰减
	if alert_level > 0:
		alert_level = max(0.0, alert_level - ALERT_DECAY_PER_SECOND * delta)
		alert_changed.emit(alert_level)
		
		if alert_level <= 0.0:
			_game_over()
	
	# /16 冷却倒计时
	if mask_16_cooldown > 0:
		mask_16_cooldown = max(0.0, mask_16_cooldown - delta)
	
	# 目标轮换计时
	target_change_timer += delta
	if target_change_timer >= _get_current_target_interval():
		target_change_timer = 0.0
		_generate_random_target()


## 获取当前目标切换间隔（随时间减少）
func _get_current_target_interval() -> float:
	var multiplier = 1.0 - (game_time / 30.0) * INTERVAL_DECREASE_RATE
	multiplier = max(MIN_TARGET_INTERVAL / BASE_TARGET_INTERVAL, multiplier)
	return BASE_TARGET_INTERVAL * multiplier


## 生成随机目标子网（随机前缀）
func _generate_random_target() -> void:
	# 随机选择前缀（加权）
	target_prefix = _weighted_random_prefix()
	
	# 根据前缀生成子网
	var a = randi() % 224 + 1
	var b = randi() % 256
	var c = randi() % 256
	var d = randi() % 256
	
	match target_prefix:
		0:
			target_subnet = 0  # 匹配所有
		8:
			target_subnet = BitwiseManager.ip_to_int("%d.0.0.0" % a)
		24:
			target_subnet = BitwiseManager.ip_to_int("%d.%d.%d.0" % [a, b, c])
		32:
			target_subnet = BitwiseManager.ip_to_int("%d.%d.%d.%d" % [a, b, c, d])
	
	valid_ip_count = 0  # 重置有效IP计数
	var target_str = get_target_subnet_string()
	print("[GameManager] New target: %s" % target_str)
	target_changed.emit(target_str)


## 加权随机选择前缀
func _weighted_random_prefix() -> int:
	var total_weight = 0
	for w in PREFIX_WEIGHTS.values():
		total_weight += w
	
	var roll = randi() % total_weight
	var cumulative = 0
	for prefix in PREFIX_WEIGHTS:
		cumulative += PREFIX_WEIGHTS[prefix]
		if roll < cumulative:
			return prefix
	return 24  # 默认


## 有效IP增加（生成时调用）
func add_valid_ip() -> void:
	valid_ip_count += 1


## 有效IP减少（消除/逃脱时调用）
func remove_valid_ip() -> void:
	valid_ip_count -= 1
	if valid_ip_count <= 0:
		valid_ip_count = 0
		# 所有有效IP被消除，自动切换目标
		target_change_timer = 0.0
		_generate_random_target()
		print("[GameManager] All valid IPs cleared! Target switched.")


## 获取目标切换剩余时间
func get_time_until_target_change() -> float:
	return max(0.0, _get_current_target_interval() - target_change_timer)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mask_32"):
		set_mask_type(32)
	elif event.is_action_pressed("mask_24"):
		set_mask_type(24)
	elif event.is_action_pressed("mask_16"):
		set_mask_type(16)


func set_mask_type(mask_type: int) -> void:
	if mask_type == 16 and mask_16_cooldown > 0:
		print("[GameManager] /16 mask on cooldown: %.1fs" % mask_16_cooldown)
		return
	
	current_mask_type = mask_type
	mask_type_changed.emit(mask_type)


func get_mask_16_cooldown() -> float:
	return mask_16_cooldown


func is_mask_available(mask_type: int) -> bool:
	if mask_type == 16:
		return mask_16_cooldown <= 0
	return true


## 检查 IP 是否匹配当前目标（不触发任何效果）
func check_ip_match(ip: int) -> bool:
	var mask := BitwiseManager.prefix_to_mask(current_mask_type)
	var result := BitwiseManager.apply_mask(ip, mask)
	var target_masked := BitwiseManager.apply_mask(target_subnet, mask)
	return result == target_masked


func _on_data_block_clicked(ip: int) -> void:
	var mask := BitwiseManager.prefix_to_mask(current_mask_type)
	var result := BitwiseManager.apply_mask(ip, mask)
	var target_masked := BitwiseManager.apply_mask(target_subnet, mask)
	
	if result == target_masked:
		# /16 冷却只在成功时触发
		if current_mask_type == 16:
			mask_16_cooldown = MASK_16_COOLDOWN_TIME
		_on_match_success(ip)
	else:
		_on_match_failure(ip)


func _on_match_success(_ip: int) -> void:
	combo += 1
	if combo > max_combo:
		max_combo = combo
	combo_changed.emit(combo)
	
	_check_combo_rewards()
	
	var combo_bonus = min(combo * 10, 100)
	score += 100 + combo_bonus
	score_changed.emit(score)
	
	alert_level = min(100.0, alert_level + ALERT_INCREASE_ON_SUCCESS)
	alert_changed.emit(alert_level)
	
	match_success.emit()


func _on_match_failure(_ip: int) -> void:
	combo = 0
	combo_changed.emit(combo)
	
	alert_level = max(0.0, alert_level - ALERT_DECREASE_ON_FAIL)
	alert_changed.emit(alert_level)
	
	match_failure.emit()
	
	if alert_level <= 0.0:
		_game_over()


func _on_data_block_escaped() -> void:
	combo = 0
	combo_changed.emit(combo)
	
	alert_level = max(0.0, alert_level - ALERT_DECREASE_ON_FAIL * 0.5)
	alert_changed.emit(alert_level)
	
	if alert_level <= 0.0:
		_game_over()


func _check_combo_rewards() -> void:
	if combo == COMBO_TIER_1:
		alert_level = min(100.0, alert_level + 5.0)
		alert_changed.emit(alert_level)
		combo_reward.emit("tier1")
	elif combo == COMBO_TIER_2:
		alert_level = min(100.0, alert_level + 10.0)
		alert_changed.emit(alert_level)
		combo_reward.emit("tier2")
	elif combo == COMBO_TIER_3:
		alert_level = min(100.0, alert_level + 20.0)
		alert_changed.emit(alert_level)
		combo_reward.emit("tier3")


func _game_over() -> void:
	if alert_level > 0:
		return
	print("[GameManager] GAME OVER! Score: %d, Max Combo: %d" % [score, max_combo])
	set_process(false)
	game_over.emit(score)


func reset() -> void:
	score = 0
	alert_level = 100.0
	current_mask_type = 24
	mask_16_cooldown = 0.0
	combo = 0
	max_combo = 0
	game_time = 0.0
	target_change_timer = 0.0
	valid_ip_count = 0
	set_process(true)
	_generate_random_target()
	score_changed.emit(score)
	alert_changed.emit(alert_level)
	combo_changed.emit(combo)
	mask_type_changed.emit(current_mask_type)


func get_target_subnet_string() -> String:
	return "%s/%d" % [BitwiseManager.int_to_ip(target_subnet), target_prefix]
