## GameManager
## 游戏核心管理器 - 处理判定逻辑、分数、掩码、连击、目标轮换
extends Node

## 信号
signal score_changed(new_score: int)
signal alert_changed(new_value: float)
signal mask_changed(mask_decimal: String)
signal match_success()
signal match_failure()
signal wrong_mask_hint(correct_prefix: int)  # 提示玩家应该使用的正确 mask
signal game_over(final_score: int)
signal combo_changed(new_combo: int)
signal combo_reward(reward_type: String)
signal target_changed(new_target: String)

## 目标子网（使用 / 表示法）
var target_subnet: int = 0
var target_prefix: int = 24

## 目标轮换系统
var target_change_timer: float = 0.0
var game_time: float = 0.0
const BASE_TARGET_INTERVAL: float = 10.0
const MIN_TARGET_INTERVAL: float = 5.0
const INTERVAL_DECREASE_RATE: float = 0.05

## 玩家掩码系统（使用点分十进制表示法）
## Q = /8, W = /16, E = /24, R = /32
const MASK_CONFIGS = {
	8: "255.0.0.0",
	16: "255.255.0.0",
	24: "255.255.255.0",
	32: "255.255.255.255"
}
var current_mask_prefix: int = 24  # 当前选择的掀码前缀
var mask_selected: bool = false  # 玩家是否已按键选择 mask

## 分数
var score: int = 0

## 剩余生命 (100-0)
var alert_level: float = 100.0

## 连击计数
var combo: int = 0
var max_combo: int = 0

## 常量
const ALERT_DECREASE_ON_FAIL: float = 5.0
const ALERT_INCREASE_ON_SUCCESS: float = 5.0
const ALERT_DECAY_PER_SECOND: float = 2.0

## Combo 奖励阈值
const COMBO_TIER_1: int = 5
const COMBO_TIER_2: int = 10
const COMBO_TIER_3: int = 20

## 前缀权重表
const PREFIX_WEIGHTS = {
	8: 2,
	16: 3,
	24: 10,
	32: 5
}

## 当前屏幕上的有效IP数量
var valid_ip_count: int = 0


func _ready() -> void:
	_generate_random_target()
	alert_changed.emit(alert_level)
	combo_changed.emit(combo)
	mask_changed.emit(MASK_CONFIGS[current_mask_prefix])


func _process(delta: float) -> void:
	game_time += delta
	
	# 生命衰减
	if alert_level > 0:
		alert_level = max(0.0, alert_level - ALERT_DECAY_PER_SECOND * delta)
		alert_changed.emit(alert_level)
		
		if alert_level <= 0:
			_trigger_game_over()
	
	# 目标轮换计时
	target_change_timer += delta
	var current_interval = _get_current_target_interval()
	if target_change_timer >= current_interval:
		target_change_timer = 0.0
		_generate_random_target()


func _get_current_target_interval() -> float:
	var multiplier = 1.0 - (game_time / 30.0) * INTERVAL_DECREASE_RATE
	multiplier = max(MIN_TARGET_INTERVAL / BASE_TARGET_INTERVAL, multiplier)
	return BASE_TARGET_INTERVAL * multiplier


## 生成随机目标子网（使用 / 表示法）
func _generate_random_target() -> void:
	# 随机选择前缀
	var total_weight = 0
	for w in PREFIX_WEIGHTS.values():
		total_weight += w
	
	var roll = randi() % total_weight
	var cumulative = 0
	for prefix in PREFIX_WEIGHTS.keys():
		cumulative += PREFIX_WEIGHTS[prefix]
		if roll < cumulative:
			target_prefix = prefix
			break
	
	# 生成随机子网地址
	var a = randi() % 224 + 1
	var b = randi() % 256
	var c = randi() % 256
	var d = randi() % 256
	
	# 根据前缀清零对应位
	match target_prefix:
		8:
			b = 0; c = 0; d = 0
		16:
			c = 0; d = 0
		24:
			d = 0
		32:
			pass  # 保持全部
	
	target_subnet = BitwiseManager.ip_to_int("%d.%d.%d.%d" % [a, b, c, d])
	
	var target_str = get_target_subnet_string()
	target_changed.emit(target_str)
	print("[GameManager] New target: %s" % target_str)


func get_target_subnet_string() -> String:
	return "%s/%d" % [BitwiseManager.int_to_ip(target_subnet), target_prefix]


func add_valid_ip() -> void:
	valid_ip_count += 1


func remove_valid_ip() -> void:
	valid_ip_count = max(0, valid_ip_count - 1)
	if valid_ip_count == 0:
		target_change_timer = 0.0
		_generate_random_target()
		print("[GameManager] All valid IPs cleared! Target switched.")


func get_time_until_target_change() -> float:
	return max(0.0, _get_current_target_interval() - target_change_timer)


## 按键输入处理 - QWER 对应四种掩码
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mask_8"):
		set_mask(8)
	elif event.is_action_pressed("mask_16"):
		set_mask(16)
	elif event.is_action_pressed("mask_24"):
		set_mask(24)
	elif event.is_action_pressed("mask_32"):
		set_mask(32)


func set_mask(prefix: int) -> void:
	if prefix in MASK_CONFIGS:
		current_mask_prefix = prefix
		mask_selected = true  # 标记已选择 mask
		mask_changed.emit(MASK_CONFIGS[prefix])


func get_current_mask_decimal() -> String:
	return MASK_CONFIGS.get(current_mask_prefix, "255.255.255.0")


## 检查 IP 是否匹配当前目标
func check_ip_match(ip: int) -> bool:
	# 必须先按键选择 mask
	if not mask_selected:
		return false
	
	var mask := BitwiseManager.prefix_to_mask(current_mask_prefix)
	var result := BitwiseManager.apply_mask(ip, mask)
	return result == target_subnet and current_mask_prefix == target_prefix


func _on_data_block_clicked(ip: int) -> void:
	var is_match = check_ip_match(ip)
	
	if is_match:
		_on_match_success(ip)
	else:
		# 检查是否是 IP 正确但 mask 错误的情况
		_check_wrong_mask_hint(ip)
		_on_match_failure(ip)


## 检查玩家是否点击了正确 IP 但使用了错误 mask
func _check_wrong_mask_hint(ip: int) -> void:
	# 检查这个 IP 使用目标 prefix 是否匹配
	var correct_mask := BitwiseManager.prefix_to_mask(target_prefix)
	var result := BitwiseManager.apply_mask(ip, correct_mask)
	
	if result == target_subnet:
		# IP 本来是正确的，但玩家用错了 mask
		wrong_mask_hint.emit(target_prefix)


func _on_match_success(_ip: int) -> void:
	# 重置 mask 选择状态，要求玩家重新按键
	mask_selected = false
	
	combo += 1
	if combo > max_combo:
		max_combo = combo
	
	combo_changed.emit(combo)
	
	# Combo 奖励
	if combo == COMBO_TIER_1:
		combo_reward.emit("tier1")
	elif combo == COMBO_TIER_2:
		combo_reward.emit("tier2")
	elif combo == COMBO_TIER_3:
		combo_reward.emit("tier3")
	
	# 加分
	var base_score = 100
	var combo_bonus = min(combo, 20) * 10
	score += base_score + combo_bonus
	score_changed.emit(score)
	
	# 恢复生命
	alert_level = min(100.0, alert_level + ALERT_INCREASE_ON_SUCCESS)
	alert_changed.emit(alert_level)
	
	match_success.emit()


func _on_match_failure(_ip: int) -> void:
	combo = 0
	combo_changed.emit(combo)
	
	alert_level = max(0.0, alert_level - ALERT_DECREASE_ON_FAIL)
	alert_changed.emit(alert_level)
	
	if alert_level <= 0:
		_trigger_game_over()
	
	match_failure.emit()


func _on_data_block_escaped() -> void:
	combo = 0
	combo_changed.emit(combo)
	
	alert_level = max(0.0, alert_level - ALERT_DECREASE_ON_FAIL)
	alert_changed.emit(alert_level)
	
	if alert_level <= 0:
		_trigger_game_over()


func _trigger_game_over() -> void:
	game_over.emit(score)


func reset_game() -> void:
	score = 0
	alert_level = 100.0
	combo = 0
	max_combo = 0
	game_time = 0.0
	target_change_timer = 0.0
	current_mask_prefix = 24
	valid_ip_count = 0
	
	_generate_random_target()
	score_changed.emit(score)
	alert_changed.emit(alert_level)
	combo_changed.emit(combo)
	mask_changed.emit(MASK_CONFIGS[current_mask_prefix])
