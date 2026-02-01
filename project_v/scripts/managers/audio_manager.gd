## AudioManager
## 音频管理器 - BGM、SFX、节拍检测
extends Node

## 信号
signal beat_hit()
signal perfect_hit()
signal intensity_changed(intensity: float)  # 音乐强度变化 (0.0 - 1.0)

## 音频播放器
var bgm_player: AudioStreamPlayer = null
var tone_player: AudioStreamPlayer = null
var generator: AudioStreamGenerator = null
var playback: AudioStreamGeneratorPlayback = null

## 频谱分析
var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance = null
const BASS_FREQ_MIN = 60.0
const BASS_FREQ_MAX = 250.0

## 节拍检测
var last_energy: float = 0.0
var energy_history: Array[float] = []
const ENERGY_HISTORY_SIZE = 43  # 约1秒的历史（假设60fps）
const BEAT_THRESHOLD = 1.3  # 能量峰值阈值（降低以提高检测灵敏度）
const BEAT_COOLDOWN = 0.2  # 两次节拍之间的最小间隔
var beat_cooldown_timer: float = 0.0
var beats_detected: Array[float] = []  # 记录最近节拍时间
var estimated_bpm: float = 120.0
var bgm_playing: bool = false
var current_intensity: float = 0.0  # 当前音乐强度 (0.0 - 1.0)

## BPM 手动设置（备用）
var bpm: float = 120.0
var beat_duration: float = 0.5
var beat_timer: float = 0.0
var beat_count: int = 0

## 音效队列
var pending_tone: Dictionary = {}


func _ready() -> void:
	# 创建频谱分析 Bus
	_setup_spectrum_analyzer()
	
	# 创建 BGM 播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "BGM"
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


func _setup_spectrum_analyzer() -> void:
	# 检查是否存在 BGM Bus，如果没有则创建
	var bgm_bus_idx = AudioServer.get_bus_index("BGM")
	if bgm_bus_idx == -1:
		AudioServer.add_bus()
		bgm_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bgm_bus_idx, "BGM")
		AudioServer.set_bus_send(bgm_bus_idx, "Master")
	
	# 添加频谱分析器效果
	var has_analyzer = false
	for i in range(AudioServer.get_bus_effect_count(bgm_bus_idx)):
		if AudioServer.get_bus_effect(bgm_bus_idx, i) is AudioEffectSpectrumAnalyzer:
			spectrum_analyzer = AudioServer.get_bus_effect_instance(bgm_bus_idx, i)
			has_analyzer = true
			break
	
	if not has_analyzer:
		var analyzer = AudioEffectSpectrumAnalyzer.new()
		analyzer.buffer_length = 0.1
		analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
		AudioServer.add_bus_effect(bgm_bus_idx, analyzer)
		spectrum_analyzer = AudioServer.get_bus_effect_instance(bgm_bus_idx, AudioServer.get_bus_effect_count(bgm_bus_idx) - 1)


func _process(delta: float) -> void:
	# 更新节拍冷却
	if beat_cooldown_timer > 0:
		beat_cooldown_timer -= delta
	
	# 如果 BGM 正在播放，使用频谱分析检测节拍
	if bgm_playing and spectrum_analyzer:
		_detect_beat_from_spectrum()
	else:
		# 备用：使用固定 BPM 节拍
		beat_timer += delta
		if beat_timer >= beat_duration:
			beat_timer -= beat_duration
			beat_count += 1
			beat_hit.emit()
	
	# 处理音调生成
	_process_tone_generation()


## 检测节拍（通过低频能量）
func _detect_beat_from_spectrum() -> void:
	if spectrum_analyzer == null:
		return
	
	# 获取低频能量
	var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(BASS_FREQ_MIN, BASS_FREQ_MAX)
	var energy = (magnitude.x + magnitude.y) / 2.0
	
	# 添加到历史
	energy_history.append(energy)
	if energy_history.size() > ENERGY_HISTORY_SIZE:
		energy_history.pop_front()
	
	# 计算平均能量
	var avg_energy = 0.0
	for e in energy_history:
		avg_energy += e
	avg_energy /= max(1, energy_history.size())
	
	# 计算归一化强度 (0.0 - 1.0) - 用于节奏同步生成
	var new_intensity = clamp(energy / max(0.001, avg_energy * 2.0), 0.0, 1.0)
	if abs(new_intensity - current_intensity) > 0.05:  # 只在变化明显时更新
		current_intensity = new_intensity
		intensity_changed.emit(current_intensity)
	
	# 检测能量峰值
	if energy > avg_energy * BEAT_THRESHOLD and beat_cooldown_timer <= 0:
		beat_cooldown_timer = BEAT_COOLDOWN
		beat_count += 1
		beat_hit.emit()
		
		# 记录节拍时间用于 BPM 估算
		var current_time = Time.get_ticks_msec() / 1000.0
		beats_detected.append(current_time)
		
		# 只保留最近 16 个节拍
		while beats_detected.size() > 16:
			beats_detected.pop_front()
		
		# 估算 BPM
		_estimate_bpm()
	
	last_energy = energy


## 估算 BPM
func _estimate_bpm() -> void:
	if beats_detected.size() < 4:
		return
	
	# 计算节拍间隔
	var intervals: Array[float] = []
	for i in range(1, beats_detected.size()):
		intervals.append(beats_detected[i] - beats_detected[i - 1])
	
	# 计算平均间隔
	var avg_interval = 0.0
	for interval in intervals:
		avg_interval += interval
	avg_interval /= intervals.size()
	
	# 转换为 BPM
	if avg_interval > 0:
		estimated_bpm = 60.0 / avg_interval
		# 限制在合理范围
		estimated_bpm = clamp(estimated_bpm, 60.0, 200.0)


## 播放背景音乐
func play_bgm(music_path: String) -> void:
	var stream = load(music_path)
	if stream:
		bgm_player.stream = stream
		bgm_player.play()
		bgm_playing = true
		energy_history.clear()
		beats_detected.clear()
		print("[AudioManager] Playing BGM: %s" % music_path)
	else:
		push_error("[AudioManager] Failed to load BGM: %s" % music_path)


## 停止背景音乐
func stop_bgm() -> void:
	bgm_player.stop()
	bgm_playing = false


## 检查是否在 Perfect 窗口内
func is_in_beat_window(window_ms: float = 50.0) -> bool:
	var window_sec = window_ms / 1000.0
	
	# DEBUG: 输出当前状态
	print("[Perfect Debug] ====== 检查 Perfect 窗口 ======")
	print("[Perfect Debug] bgm_playing=%s, bgm_player=%s, bgm_player.playing=%s" % [
		bgm_playing,
		bgm_player != null,
		bgm_player.playing if bgm_player else "N/A"
	])
	print("[Perfect Debug] window_ms=%s, window_sec=%s" % [window_ms, window_sec])
	print("[Perfect Debug] estimated_bpm=%s, default_bpm=%s" % [estimated_bpm, bpm])
	print("[Perfect Debug] beats_detected.size()=%s" % beats_detected.size())
	
	# 优先使用 BGM 播放时间进行节拍判定（最可靠）
	if bgm_playing and bgm_player and bgm_player.playing:
		var playback_position = bgm_player.get_playback_position()
		# 使用估算的 BPM，如果没有则使用默认值
		var current_bpm = estimated_bpm if estimated_bpm > 60.0 else bpm
		var beat_interval = 60.0 / current_bpm
		var time_in_beat = fmod(playback_position, beat_interval)
		var time_to_next = beat_interval - time_in_beat
		
		print("[Perfect Debug] [BGM方式] playback_pos=%.3f, bpm=%.1f, beat_interval=%.3f" % [
			playback_position, current_bpm, beat_interval
		])
		print("[Perfect Debug] [BGM方式] time_in_beat=%.3f, time_to_next=%.3f" % [
			time_in_beat, time_to_next
		])
		print("[Perfect Debug] [BGM方式] 判定: time_in_beat(%.3f) < window(%.3f) = %s" % [
			time_in_beat, window_sec, time_in_beat < window_sec
		])
		print("[Perfect Debug] [BGM方式] 判定: time_to_next(%.3f) < window(%.3f) = %s" % [
			time_to_next, window_sec, time_to_next < window_sec
		])
		
		# 检查是否接近节拍点（周期开始或即将结束）
		if time_in_beat < window_sec or time_to_next < window_sec:
			print("[Perfect Debug] >>> 结果: PERFECT! <<<")
			return true
		else:
			print("[Perfect Debug] [BGM方式] 不在窗口内")
	else:
		print("[Perfect Debug] BGM 未播放，跳过 BGM 方式")
	
	# 备用方案：使用节拍检测历史
	if not beats_detected.is_empty():
		var current_time = Time.get_ticks_msec() / 1000.0
		var last_beat = beats_detected.back()
		var time_since_beat = current_time - last_beat
		
		print("[Perfect Debug] [备用方式] current_time=%.3f, last_beat=%.3f, time_since=%.3f" % [
			current_time, last_beat, time_since_beat
		])
		
		if time_since_beat < window_sec:
			print("[Perfect Debug] >>> 结果: PERFECT (备用-刚过节拍)! <<<")
			return true
		
		var beat_interval = 60.0 / max(60.0, estimated_bpm)
		var time_to_next = beat_interval - fmod(time_since_beat, beat_interval)
		print("[Perfect Debug] [备用方式] beat_interval=%.3f, time_to_next=%.3f" % [
			beat_interval, time_to_next
		])
		if time_to_next < window_sec:
			print("[Perfect Debug] >>> 结果: PERFECT (备用-接近下个节拍)! <<<")
			return true
	else:
		print("[Perfect Debug] beats_detected 为空，跳过备用方式")
	
	print("[Perfect Debug] >>> 结果: NOT PERFECT <<<")
	return false


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


## 播放 Perfect 音效
func play_perfect_sfx() -> void:
	_play_tone(1320.0, 0.05)


## 信号回调
func _on_match_success() -> void:
	print("\n[AudioManager] ========== _on_match_success 被调用 ==========")
	# 检查是否 Perfect（窗口增大到 100ms 提高触发率）
	var is_perfect = is_in_beat_window(100.0)
	print("[AudioManager] is_perfect = %s" % is_perfect)
	if is_perfect:
		print("[AudioManager] >>> 触发 PERFECT! 播放音效并发射信号 <<<")
		play_perfect_sfx()
		perfect_hit.emit()
	else:
		print("[AudioManager] 普通成功，播放普通音效")
		play_success_sfx()
	print("[AudioManager] ==========================================\n")


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
	stop_bgm()


## BPM 相关
func set_bpm(new_bpm: float) -> void:
	bpm = new_bpm
	beat_duration = 60.0 / bpm


func get_estimated_bpm() -> float:
	return estimated_bpm


## 获取当前音乐强度 (0.0 - 1.0)
func get_current_intensity() -> float:
	return current_intensity
