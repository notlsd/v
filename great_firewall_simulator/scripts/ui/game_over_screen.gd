## GameOverScreen
## 游戏结束界面 - 显示统计和重启按钮
extends CanvasLayer

@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var time_label: Label = $Panel/VBox/TimeLabel
@onready var combo_label: Label = $Panel/VBox/ComboLabel
@onready var restart_button: Button = $Panel/VBox/RestartButton

var terminal_spawner: Node = null


func _ready() -> void:
	visible = false
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)


func show_game_over(final_score: int) -> void:
	# 获取统计数据
	var max_combo = GameManager.max_combo
	var game_time = 0.0
	
	# 尝试获取 TerminalSpawner 的游戏时间
	if terminal_spawner and terminal_spawner.has_method("get_game_time"):
		game_time = terminal_spawner.get_game_time()
	
	# 更新显示
	if score_label:
		score_label.text = "SCORE: %d" % final_score
	if time_label:
		var minutes = int(game_time) / 60
		var seconds = int(game_time) % 60
		time_label.text = "TIME: %02d:%02d" % [minutes, seconds]
	if combo_label:
		combo_label.text = "MAX COMBO: x%d" % max_combo
	
	visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_game()
	
	# 重置 TerminalSpawner
	if terminal_spawner and terminal_spawner.has_method("reset"):
		terminal_spawner.reset()
	
	visible = false


func set_spawner(spawner: Node) -> void:
	terminal_spawner = spawner
