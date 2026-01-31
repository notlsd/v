## EffectManager
## 管理视觉效果触发 - Glitch、屏幕震动等
extends Node

## Glitch overlay 引用
var glitch_material: ShaderMaterial = null

## 当前 glitch 强度
var current_glitch_intensity: float = 0.0

## Glitch tween
var glitch_tween: Tween = null


func _ready() -> void:
	# 连接 GameManager 信号
	GameManager.match_failure.connect(_on_match_failure)
	GameManager.mask_type_changed.connect(_on_mask_changed)


## 设置 Glitch 材质引用
func set_glitch_material(material: ShaderMaterial) -> void:
	glitch_material = material


## 触发 glitch 效果
func trigger_glitch(intensity: float = 0.5, duration: float = 0.1) -> void:
	if glitch_material == null:
		return
	
	# 停止之前的 tween
	if glitch_tween and glitch_tween.is_valid():
		glitch_tween.kill()
	
	# 设置强度并渐变归零
	glitch_material.set_shader_parameter("intensity", intensity)
	
	glitch_tween = create_tween()
	glitch_tween.tween_method(_set_glitch_intensity, intensity, 0.0, duration)


func _set_glitch_intensity(value: float) -> void:
	if glitch_material:
		glitch_material.set_shader_parameter("intensity", value)


## 匹配失败时触发 glitch
func _on_match_failure() -> void:
	trigger_glitch(0.6, 0.15)


## 切换掩码时触发轻微 glitch
func _on_mask_changed(_new_prefix: int) -> void:
	trigger_glitch(0.3, 0.05)
