## GameOverScreen
## 游戏结束界面
extends CanvasLayer

@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var restart_button: Button = $Panel/VBox/RestartButton


func _ready() -> void:
	visible = false
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)


func show_game_over(final_score: int) -> void:
	if score_label:
		score_label.text = "FINAL SCORE: %d" % final_score
	visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	visible = false
