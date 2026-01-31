## GameManager
## 游戏核心管理器 - 处理判定逻辑、分数、警报
extends Node

## 信号：分数改变
signal score_changed(new_score: int)

## 信号：警报值改变（现在是剩余时间/生命）
signal alert_changed(new_value: float)

## 信号：掩码改变（转发自 PlayerCursor）
signal mask_changed(new_prefix: int)

## 信号：匹配成功
signal match_success()

## 信号：匹配失败
signal match_failure()

## 信号：游戏结束
signal game_over(final_score: int)

## 目标子网（整数形式，如 192.168.1.0 = 3232235776）
var target_subnet: int = 0

## 目标子网前缀
var target_prefix: int = 24

## 当前玩家选择的掩码前缀
var current_prefix: int = 24

## 分数
var score: int = 0

## 剩余生命/时间 (100-0，归零游戏结束)
var alert_level: float = 100.0

## 每次失误减少的生命值
const ALERT_DECREASE_ON_FAIL: float = 10.0

## 每次成功恢复的生命值
const ALERT_INCREASE_ON_SUCCESS: float = 2.0

## PlayerCursor 引用（在 main 场景中设置）
var player_cursor: Node = null

## 每秒自动减少的生命值
const ALERT_DECAY_PER_SECOND: float = 2.0


func _ready() -> void:
	# 设置默认目标子网：192.168.1.0/24
	target_subnet = BitwiseManager.ip_to_int("192.168.1.0")
	target_prefix = 24
	print("[GameManager] Target subnet: %s/%d" % [BitwiseManager.int_to_ip(target_subnet), target_prefix])
	
	# 发送初始状态
	alert_changed.emit(alert_level)


func _process(delta: float) -> void:
	# 持续减少生命值，形成时间压力
	if alert_level > 0:
		alert_level = max(0.0, alert_level - ALERT_DECAY_PER_SECOND * delta)
		alert_changed.emit(alert_level)
		
		if alert_level <= 0.0:
			_game_over()


## 连接 PlayerCursor 的信号
func connect_player_cursor(cursor: Node) -> void:
	player_cursor = cursor
	if cursor.has_signal("mask_changed"):
		cursor.mask_changed.connect(_on_player_mask_changed)


## PlayerCursor 掩码改变回调
func _on_player_mask_changed(new_prefix: int) -> void:
	current_prefix = new_prefix
	mask_changed.emit(new_prefix)


## DataBlock 被点击时的回调
func _on_data_block_clicked(ip: int) -> void:
	var mask := BitwiseManager.prefix_to_mask(current_prefix)
	var result := BitwiseManager.apply_mask(ip, mask)
	
	var ip_str := BitwiseManager.int_to_ip(ip)
	var result_str := BitwiseManager.int_to_ip(result)
	var target_str := BitwiseManager.int_to_ip(target_subnet)
	
	if result == target_subnet:
		_on_match_success(ip)
		print("[GameManager] MATCH! %s & /%d = %s (target: %s)" % [ip_str, current_prefix, result_str, target_str])
	else:
		_on_match_failure(ip)
		print("[GameManager] MISMATCH! %s & /%d = %s (target: %s)" % [ip_str, current_prefix, result_str, target_str])


## 匹配成功处理
func _on_match_success(_ip: int) -> void:
	score += 100
	score_changed.emit(score)
	
	# 成功时恢复生命
	alert_level = min(100.0, alert_level + ALERT_INCREASE_ON_SUCCESS)
	alert_changed.emit(alert_level)
	
	match_success.emit()


## 匹配失败处理
func _on_match_failure(_ip: int) -> void:
	# 失误减少生命
	alert_level = max(0.0, alert_level - ALERT_DECREASE_ON_FAIL)
	alert_changed.emit(alert_level)
	
	match_failure.emit()
	
	if alert_level <= 0.0:
		_game_over()


## DataBlock 逃脱时的回调
func _on_data_block_escaped() -> void:
	# 目标逃脱减少生命
	alert_level = max(0.0, alert_level - ALERT_DECREASE_ON_FAIL * 0.5)
	alert_changed.emit(alert_level)
	
	if alert_level <= 0.0:
		_game_over()


## 游戏结束
func _game_over() -> void:
	if alert_level > 0:  # 防止重复触发
		return
	print("[GameManager] GAME OVER! Final score: %d" % score)
	set_process(false)  # 停止自动衰减
	game_over.emit(score)


## 重置游戏状态
func reset() -> void:
	score = 0
	alert_level = 100.0  # 从满格开始
	current_prefix = 24
	score_changed.emit(score)
	alert_changed.emit(alert_level)


## 获取目标子网的字符串表示
func get_target_subnet_string() -> String:
	return "%s/%d" % [BitwiseManager.int_to_ip(target_subnet), target_prefix]
