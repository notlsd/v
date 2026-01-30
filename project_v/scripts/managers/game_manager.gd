## GameManager
## 游戏核心管理器 - 处理判定逻辑、分数、警报
extends Node

## 信号：分数改变
signal score_changed(new_score: int)

## 信号：警报值改变
signal alert_changed(new_value: float)

## 信号：掩码改变（转发自 PlayerCursor）
signal mask_changed(new_prefix: int)

## 信号：匹配成功
signal match_success()

## 信号：匹配失败
signal match_failure()

## 目标子网（整数形式，如 192.168.1.0 = 3232235776）
var target_subnet: int = 0

## 目标子网前缀
var target_prefix: int = 24

## 当前玩家选择的掩码前缀
var current_prefix: int = 24

## 分数
var score: int = 0

## 警报追踪度 (0-100)
var alert_level: float = 0.0

## 每次失误增加的警报值
const ALERT_INCREASE: float = 10.0

## 每次成功减少的警报值
const ALERT_DECREASE: float = 2.0

## PlayerCursor 引用（在 main 场景中设置）
var player_cursor: Node = null


func _ready() -> void:
	# 设置默认目标子网：192.168.1.0/24
	target_subnet = BitwiseManager.ip_to_int("192.168.1.0")
	target_prefix = 24
	print("[GameManager] Target subnet: %s/%d" % [BitwiseManager.int_to_ip(target_subnet), target_prefix])


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
	
	# 成功时降低警报
	alert_level = max(0.0, alert_level - ALERT_DECREASE)
	alert_changed.emit(alert_level)
	
	match_success.emit()
	
	# 销毁被点击的数据块（通过信号发送者处理）
	# DataBlock 自己会在收到点击后被销毁


## 匹配失败处理
func _on_match_failure(_ip: int) -> void:
	# 失误增加警报
	alert_level = min(100.0, alert_level + ALERT_INCREASE)
	alert_changed.emit(alert_level)
	
	match_failure.emit()
	
	if alert_level >= 100.0:
		_game_over()


## DataBlock 逃脱时的回调
func _on_data_block_escaped() -> void:
	# 数据块逃脱也增加警报（较少）
	alert_level = min(100.0, alert_level + ALERT_INCREASE * 0.5)
	alert_changed.emit(alert_level)


## 游戏结束
func _game_over() -> void:
	print("[GameManager] GAME OVER! Final score: %d" % score)
	# TODO: 显示游戏结束界面


## 重置游戏状态
func reset() -> void:
	score = 0
	alert_level = 0.0
	current_prefix = 24
	score_changed.emit(score)
	alert_changed.emit(alert_level)


## 获取目标子网的字符串表示
func get_target_subnet_string() -> String:
	return "%s/%d" % [BitwiseManager.int_to_ip(target_subnet), target_prefix]
