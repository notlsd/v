## PlayerCursor
## 玩家光标控制 - 跟随鼠标移动，提供掩码切换功能
## 注意：这是 Node2D 不是 Area2D，不参与物理查询
extends Node2D

## 信号：掩码改变时发出
signal mask_changed(new_prefix: int)

## 当前掩码前缀值
var current_prefix: int = 24

## 可用的掩码前缀列表
const MASK_PREFIXES: Array[int] = [32, 24, 16]

## 光标半径（根据掩码变化）
const CURSOR_RADIUS: Dictionary = {
	32: 20,   # 精准狙击 - 最小
	24: 40,   # 标准模式 - 中等
	16: 80    # 范围清屏 - 最大
}

@onready var visual: ColorRect = $Visual


func _ready() -> void:
	# 隐藏系统鼠标光标
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_update_cursor_visual()


func _process(_delta: float) -> void:
	# 光标跟随鼠标位置
	global_position = get_global_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	# 使用 _unhandled_input 获得更低延迟
	
	# 键盘切换掩码
	if event.is_action_pressed("mask_32"):
		_set_mask_prefix(32)
	elif event.is_action_pressed("mask_24"):
		_set_mask_prefix(24)
	elif event.is_action_pressed("mask_16"):
		_set_mask_prefix(16)
	
	# 滚轮循环切换
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_cycle_mask(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_cycle_mask(1)


func _set_mask_prefix(prefix: int) -> void:
	if current_prefix != prefix:
		current_prefix = prefix
		_update_cursor_visual()
		mask_changed.emit(current_prefix)
		print("[PlayerCursor] Mask changed to /%d" % current_prefix)


func _cycle_mask(direction: int) -> void:
	var current_index := MASK_PREFIXES.find(current_prefix)
	var new_index := (current_index + direction) % MASK_PREFIXES.size()
	_set_mask_prefix(MASK_PREFIXES[new_index])


func _update_cursor_visual() -> void:
	var radius: float = CURSOR_RADIUS.get(current_prefix, 40)
	
	# 更新视觉显示
	if visual:
		visual.size = Vector2(radius * 2, radius * 2)
		visual.position = Vector2(-radius, -radius)


func get_current_mask() -> int:
	return BitwiseManager.prefix_to_mask(current_prefix)
