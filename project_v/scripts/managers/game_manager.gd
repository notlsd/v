## GameManager
## 游戏核心管理器 - 处理判定逻辑、分数、掩码、连击
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

## 目标子网
var target_subnet: int = 0
var target_prefix: int = 24

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


func _ready() -> void:
	target_subnet = BitwiseManager.ip_to_int("192.168.1.0")
	target_prefix = 24
	print("[GameManager] Target subnet: %s/%d" % [BitwiseManager.int_to_ip(target_subnet), target_prefix])
	alert_changed.emit(alert_level)
	combo_changed.emit(combo)
	mask_type_changed.emit(current_mask_type)


func _process(delta: float) -> void:
	# 生命衰减
	if alert_level > 0:
		alert_level = max(0.0, alert_level - ALERT_DECAY_PER_SECOND * delta)
		alert_changed.emit(alert_level)
		
		if alert_level <= 0.0:
			_game_over()
	
	# /16 冷却倒计时
	if mask_16_cooldown > 0:
		mask_16_cooldown = max(0.0, mask_16_cooldown - delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mask_32"):
		set_mask_type(32)
	elif event.is_action_pressed("mask_24"):
		set_mask_type(24)
	elif event.is_action_pressed("mask_16"):
		set_mask_type(16)


## 设置掩码类型
func set_mask_type(mask_type: int) -> void:
	if mask_type == 16 and mask_16_cooldown > 0:
		print("[GameManager] /16 mask on cooldown: %.1fs" % mask_16_cooldown)
		return
	
	current_mask_type = mask_type
	mask_type_changed.emit(mask_type)
	print("[GameManager] Mask changed to /%d" % mask_type)


## 获取 /16 冷却剩余时间
func get_mask_16_cooldown() -> float:
	return mask_16_cooldown


## 检查掩码是否可用
func is_mask_available(mask_type: int) -> bool:
	if mask_type == 16:
		return mask_16_cooldown <= 0
	return true


func _on_data_block_clicked(ip: int) -> void:
	var mask := BitwiseManager.prefix_to_mask(current_mask_type)
	var result := BitwiseManager.apply_mask(ip, mask)
	var target_masked := BitwiseManager.apply_mask(target_subnet, mask)
	
	# 使用 /16 后进入冷却
	if current_mask_type == 16:
		mask_16_cooldown = MASK_16_COOLDOWN_TIME
	
	if result == target_masked:
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
	set_process(true)
	score_changed.emit(score)
	alert_changed.emit(alert_level)
	combo_changed.emit(combo)
	mask_type_changed.emit(current_mask_type)


func get_target_subnet_string() -> String:
	return "%s/%d" % [BitwiseManager.int_to_ip(target_subnet), target_prefix]
