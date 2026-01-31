## GameManager
## 游戏核心管理器 - 处理判定逻辑、分数、警报、连击
extends Node

## 信号：分数改变
signal score_changed(new_score: int)

## 信号：警报值改变（剩余生命）
signal alert_changed(new_value: float)

## 信号：掩码改变（转发自 PlayerCursor）
signal mask_changed(new_prefix: int)

## 信号：匹配成功
signal match_success()

## 信号：匹配失败
signal match_failure()

## 信号：游戏结束
signal game_over(final_score: int)

## 信号：连击改变
signal combo_changed(new_combo: int)

## 信号：连击奖励触发
signal combo_reward(reward_type: String)

## 目标子网
var target_subnet: int = 0
var target_prefix: int = 24

## 当前掩码
var current_prefix: int = 24

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
const COMBO_TIER_1: int = 5   # 恢复 5 生命
const COMBO_TIER_2: int = 10  # 恢复 10 生命 + 减速
const COMBO_TIER_3: int = 20  # 恢复 20 生命 + 清屏

var player_cursor: Node = null


func _ready() -> void:
	target_subnet = BitwiseManager.ip_to_int("192.168.1.0")
	target_prefix = 24
	print("[GameManager] Target subnet: %s/%d" % [BitwiseManager.int_to_ip(target_subnet), target_prefix])
	alert_changed.emit(alert_level)
	combo_changed.emit(combo)


func _process(delta: float) -> void:
	if alert_level > 0:
		alert_level = max(0.0, alert_level - ALERT_DECAY_PER_SECOND * delta)
		alert_changed.emit(alert_level)
		
		if alert_level <= 0.0:
			_game_over()


func connect_player_cursor(cursor: Node) -> void:
	player_cursor = cursor
	if cursor.has_signal("mask_changed"):
		cursor.mask_changed.connect(_on_player_mask_changed)


func _on_player_mask_changed(new_prefix: int) -> void:
	current_prefix = new_prefix
	mask_changed.emit(new_prefix)


func _on_data_block_clicked(ip: int) -> void:
	var mask := BitwiseManager.prefix_to_mask(current_prefix)
	var result := BitwiseManager.apply_mask(ip, mask)
	
	if result == target_subnet:
		_on_match_success(ip)
	else:
		_on_match_failure(ip)


func _on_match_success(_ip: int) -> void:
	# 增加连击
	combo += 1
	if combo > max_combo:
		max_combo = combo
	combo_changed.emit(combo)
	
	# 检查连击奖励
	_check_combo_rewards()
	
	# 分数（基础100 + combo加成）
	var combo_bonus = min(combo * 10, 100)
	score += 100 + combo_bonus
	score_changed.emit(score)
	
	# 恢复生命
	alert_level = min(100.0, alert_level + ALERT_INCREASE_ON_SUCCESS)
	alert_changed.emit(alert_level)
	
	match_success.emit()


func _on_match_failure(_ip: int) -> void:
	# 重置连击
	combo = 0
	combo_changed.emit(combo)
	
	# 减少生命
	alert_level = max(0.0, alert_level - ALERT_DECREASE_ON_FAIL)
	alert_changed.emit(alert_level)
	
	match_failure.emit()
	
	if alert_level <= 0.0:
		_game_over()


func _on_data_block_escaped() -> void:
	# 漏掉目标也重置连击
	combo = 0
	combo_changed.emit(combo)
	
	alert_level = max(0.0, alert_level - ALERT_DECREASE_ON_FAIL * 0.5)
	alert_changed.emit(alert_level)
	
	if alert_level <= 0.0:
		_game_over()


func _check_combo_rewards() -> void:
	if combo == COMBO_TIER_1:
		# 5连：恢复5生命
		alert_level = min(100.0, alert_level + 5.0)
		alert_changed.emit(alert_level)
		combo_reward.emit("tier1")
		print("[GameManager] COMBO x5! +5 HP")
	
	elif combo == COMBO_TIER_2:
		# 10连：恢复10生命
		alert_level = min(100.0, alert_level + 10.0)
		alert_changed.emit(alert_level)
		combo_reward.emit("tier2")
		print("[GameManager] COMBO x10! +10 HP")
	
	elif combo == COMBO_TIER_3:
		# 20连：恢复20生命
		alert_level = min(100.0, alert_level + 20.0)
		alert_changed.emit(alert_level)
		combo_reward.emit("tier3")
		print("[GameManager] COMBO x20! +20 HP")


func _game_over() -> void:
	if alert_level > 0:
		return
	print("[GameManager] GAME OVER! Score: %d, Max Combo: %d" % [score, max_combo])
	set_process(false)
	game_over.emit(score)


func reset() -> void:
	score = 0
	alert_level = 100.0
	current_prefix = 24
	combo = 0
	max_combo = 0
	set_process(true)
	score_changed.emit(score)
	alert_changed.emit(alert_level)
	combo_changed.emit(combo)


func get_target_subnet_string() -> String:
	return "%s/%d" % [BitwiseManager.int_to_ip(target_subnet), target_prefix]
