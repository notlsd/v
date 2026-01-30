## AudioManager
## 音频管理器 - BGM 和 SFX 播放
extends Node

## BPM 设置 (用于节拍同步)
var bpm: float = 120.0
var beat_duration: float = 0.5  # 60/120

## 音频播放器
var bgm_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []

## 信号：节拍触发
signal beat_hit()

## 节拍计时
var beat_timer: float = 0.0
var beat_count: int = 0


func _ready() -> void:
	# 创建 BGM 播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# 创建 SFX 播放器池
	for i in range(8):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)
	
	# 计算节拍时长
	beat_duration = 60.0 / bpm
	
	# 连接 GameManager 信号
	GameManager.match_success.connect(_on_match_success)
	GameManager.match_failure.connect(_on_match_failure)
	GameManager.mask_changed.connect(_on_mask_changed)


func _process(delta: float) -> void:
	# 节拍计时
	beat_timer += delta
	if beat_timer >= beat_duration:
		beat_timer -= beat_duration
		beat_count += 1
		beat_hit.emit()


## 设置 BPM
func set_bpm(new_bpm: float) -> void:
	bpm = new_bpm
	beat_duration = 60.0 / bpm


## 播放 SFX (找到空闲播放器)
func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return


## 播放 BGM
func play_bgm(stream: AudioStream, volume_db: float = -10.0) -> void:
	if bgm_player:
		bgm_player.stream = stream
		bgm_player.volume_db = volume_db
		bgm_player.play()


## 停止 BGM
func stop_bgm() -> void:
	if bgm_player:
		bgm_player.stop()


## 匹配成功音效提示 (占位)
func _on_match_success() -> void:
	# TODO: 播放成功音效
	pass


## 匹配失败音效提示 (占位)
func _on_match_failure() -> void:
	# TODO: 播放失败音效
	pass


## 切换掩码音效提示 (占位)
func _on_mask_changed(_prefix: int) -> void:
	# TODO: 播放切换音效
	pass


## 检查是否在节拍窗口内 (用于 Perfect 判定)
func is_in_beat_window(window_ms: float = 50.0) -> bool:
	var window_sec = window_ms / 1000.0
	var time_since_beat = beat_timer
	var time_to_next_beat = beat_duration - beat_timer
	return time_since_beat < window_sec or time_to_next_beat < window_sec
