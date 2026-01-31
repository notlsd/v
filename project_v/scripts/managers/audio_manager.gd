## AudioManager
## 音频管理器 - BGM、SFX 和程序生成音效
extends Node

## BPM 设置 (用于节拍同步)
var bpm: float = 120.0
var beat_duration: float = 0.5

## 音频播放器
var bgm_player: AudioStreamPlayer = null
var tone_player: AudioStreamPlayer = null
var generator: AudioStreamGenerator = null
var playback: AudioStreamGeneratorPlayback = null

## 信号：节拍触发
signal beat_hit()

## 节拍计时
var beat_timer: float = 0.0
var beat_count: int = 0

## 音效队列
var pending_tone: Dictionary = {}


func _ready() -> void:
	# 创建 BGM 播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# 创建音调生成器
	generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.5
	
	tone_player = AudioStreamPlayer.new()
	tone_player.stream = generator
	tone_player.bus = "Master"
	tone_player.volume_db = -5.0
	add_child(tone_player)
	
	# 计算节拍时长
	beat_duration = 60.0 / bpm
	
	# 连接 GameManager 信号
	GameManager.match_success.connect(_on_match_success)
	GameManager.match_failure.connect(_on_match_failure)
	GameManager.combo_reward.connect(_on_combo_reward)
	GameManager.game_over.connect(_on_game_over)


func _process(delta: float) -> void:
	# 节拍计时
	beat_timer += delta
	if beat_timer >= beat_duration:
		beat_timer -= beat_duration
		beat_count += 1
		beat_hit.emit()
	
	# 处理音调生成
	_process_tone_generation()


func _process_tone_generation() -> void:
	if not tone_player.playing:
		return
	
	if playback == null:
		playback = tone_player.get_stream_playback()
	
	if playback == null:
		return
	
	var frames_available = playback.get_frames_available()
	if frames_available <= 0:
		return
	
	if pending_tone.is_empty():
		tone_player.stop()
		return
	
	var freq = pending_tone.get("freq", 440.0)
	var phase = pending_tone.get("phase", 0.0)
	var samples_left = pending_tone.get("samples_left", 0)
	var total_samples = pending_tone.get("total_samples", 1)
	var sweep_end = pending_tone.get("sweep_end", freq)
	
	var sample_rate = generator.mix_rate
	var frames_to_fill = min(frames_available, samples_left)
	
	for i in range(frames_to_fill):
		var progress = 1.0 - (float(samples_left - i) / total_samples)
		var current_freq = freq + (sweep_end - freq) * progress
		var amplitude = 0.3 * (1.0 - progress * 0.7)
		
		var sample = sin(phase) * amplitude
		phase += 2.0 * PI * current_freq / sample_rate
		
		playback.push_frame(Vector2(sample, sample))
	
	pending_tone["phase"] = phase
	pending_tone["samples_left"] = samples_left - frames_to_fill
	
	if pending_tone["samples_left"] <= 0:
		pending_tone.clear()


## 播放音调
func _play_tone(frequency: float, duration: float, sweep_end_freq: float = -1.0) -> void:
	var sample_rate = generator.mix_rate
	var total_samples = int(sample_rate * duration)
	
	pending_tone = {
		"freq": frequency,
		"phase": 0.0,
		"samples_left": total_samples,
		"total_samples": total_samples,
		"sweep_end": sweep_end_freq if sweep_end_freq > 0 else frequency
	}
	
	if not tone_player.playing:
		tone_player.play()
		playback = tone_player.get_stream_playback()


## 播放成功音效
func play_success_sfx() -> void:
	_play_tone(880.0, 0.08)


## 播放失败音效
func play_fail_sfx() -> void:
	_play_tone(220.0, 0.15)


## 播放 Combo 奖励音效
func play_combo_sfx(tier: int) -> void:
	var start_freq = 440.0 + tier * 220.0
	var end_freq = start_freq * 2.0
	_play_tone(start_freq, 0.12, end_freq)


## 播放 Game Over 音效
func play_game_over_sfx() -> void:
	_play_tone(880.0, 0.4, 110.0)


## 信号回调
func _on_match_success() -> void:
	play_success_sfx()


func _on_match_failure() -> void:
	play_fail_sfx()


func _on_combo_reward(reward_type: String) -> void:
	match reward_type:
		"tier1":
			play_combo_sfx(1)
		"tier2":
			play_combo_sfx(2)
		"tier3":
			play_combo_sfx(3)


func _on_game_over(_final_score: int) -> void:
	play_game_over_sfx()


## BPM 相关
func set_bpm(new_bpm: float) -> void:
	bpm = new_bpm
	beat_duration = 60.0 / bpm


func is_in_beat_window(window_ms: float = 50.0) -> bool:
	var window_sec = window_ms / 1000.0
	var time_since_beat = beat_timer
	var time_to_next_beat = beat_duration - beat_timer
	return time_since_beat < window_sec or time_to_next_beat < window_sec
