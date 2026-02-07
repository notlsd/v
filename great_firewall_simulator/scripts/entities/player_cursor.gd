## PlayerCursor
## 玩家光标控制 - 跟随鼠标移动，提供掩码切换功能
## 视觉升级版本 - 带 Tween 动画
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

## 掩码显示文本
const MASK_LABELS: Dictionary = {
	32: "/32",
	24: "/24",
	16: "/16"
}

@onready var visual: ColorRect = $Visual
@onready var mask_label: Label = $MaskLabel
var size_tween: Tween = null


func _ready() -> void:
	# 隐藏系统鼠标光标
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_update_cursor_visual(false)


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
		_update_cursor_visual(true)
		mask_changed.emit(current_prefix)
		print("[PlayerCursor] Mask changed to /%d" % current_prefix)


func _cycle_mask(direction: int) -> void:
	var current_index := MASK_PREFIXES.find(current_prefix)
	var new_index := (current_index + direction) % MASK_PREFIXES.size()
	_set_mask_prefix(MASK_PREFIXES[new_index])


func _update_cursor_visual(animate: bool) -> void:
	var radius: float = CURSOR_RADIUS.get(current_prefix, 40)
	var target_size := Vector2(radius * 2, radius * 2)
	var target_pos := Vector2(-radius, -radius)
	
	# 更新掩码标签
	if mask_label:
		mask_label.text = MASK_LABELS.get(current_prefix, "/24")
	
	# 更新视觉显示
	if visual:
		if animate:
			# 使用 Tween 平滑过渡
			if size_tween and size_tween.is_valid():
				size_tween.kill()
			
			size_tween = create_tween()
			size_tween.set_parallel(true)
			size_tween.tween_property(visual, "size", target_size, 0.15).set_ease(Tween.EASE_OUT)
			size_tween.tween_property(visual, "position", target_pos, 0.15).set_ease(Tween.EASE_OUT)
		else:
			visual.size = target_size
			visual.position = target_pos


func get_current_mask() -> int:
	return BitwiseManager.prefix_to_mask(current_prefix)
