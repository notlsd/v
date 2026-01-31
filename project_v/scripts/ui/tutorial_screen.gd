## TutorialScreen
## 新手教程弹窗 - 直接使用效果图 + 矩阵雨背景
extends CanvasLayer

const MatrixRain = preload("res://scenes/effects/matrix_rain.tscn")

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()


func _create_ui() -> void:
	# 全屏黑色背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.BLACK
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# 矩阵雨效果 (在背景之上，图片之下)
	var rain = MatrixRain.instantiate()
	add_child(rain)
	
	# 半透明遮罩，使矩阵雨不太亮
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	# 居中容器
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# 加载并显示效果图
	var texture = load("res://assets/images/tutorial_screen.png")
	var image_rect = TextureRect.new()
	image_rect.texture = texture
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center.add_child(image_rect)
	
	# 暂停游戏
	get_tree().paused = true


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			get_tree().paused = false
			queue_free()
