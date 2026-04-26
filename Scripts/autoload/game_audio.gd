extends Node

## 程序化短音效（16-bit 单声道 PCM），不依赖外部资源；走 Master 总线，与设置里的主音量一致。

const _POOL := 12
const _SR := 22050

var _players: Array[AudioStreamPlayer] = []
var _ui_click: AudioStreamWAV
var _ui_confirm: AudioStreamWAV
var _melee_swing: AudioStreamWAV
var _melee_hit: AudioStreamWAV
var _xp_tick: AudioStreamWAV
var _level_up: AudioStreamWAV
var _monster_death: AudioStreamWAV
var _heal_chime: AudioStreamWAV


func _ready() -> void:
	_ui_click = _stream_noise_burst(0.035, 0.18, 0.55)
	_ui_confirm = _stream_tone(0.1, 660.0, 0.22, 1.0)
	_melee_swing = _stream_swoosh(0.09, 0.28)
	_melee_hit = _stream_tone(0.07, 140.0, 0.42, 0.65)
	_xp_tick = _stream_tone(0.08, 880.0, 0.2, 0.88)
	_level_up = _stream_level_fanfare()
	_monster_death = _stream_tone(0.22, 95.0, 0.38, 0.45)
	_heal_chime = _stream_tone(0.11, 520.0, 0.2, 0.55)
	for i in _POOL:
		var p := AudioStreamPlayer.new()
		p.name = "SfxPlayer_%d" % i
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func ui_click() -> void:
	_play(_ui_click, -10.0, randf_range(0.96, 1.08))


func ui_confirm() -> void:
	_play(_ui_confirm, -6.0, randf_range(0.98, 1.04))


func melee_swing() -> void:
	_play(_melee_swing, -8.0, randf_range(0.92, 1.1))


func melee_hit() -> void:
	_play(_melee_hit, -4.0, randf_range(0.94, 1.12))


func xp_tick() -> void:
	_play(_xp_tick, -9.0, randf_range(0.97, 1.06))


func level_up() -> void:
	_play(_level_up, -3.0, 1.0)


func monster_death() -> void:
	_play(_monster_death, -5.0, randf_range(0.88, 1.05))


func heal_chime() -> void:
	_play(_heal_chime, -10.0, randf_range(1.0, 1.12))


func _play(stream: AudioStreamWAV, volume_db: float, pitch: float) -> void:
	if stream == null:
		return
	var p := _pick_player()
	if p == null:
		return
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func _pick_player() -> AudioStreamPlayer:
	for pl in _players:
		if not pl.playing:
			return pl
	return _players[0]


static func _pcm_mono_i16(duration_sec: float, sample_fn: Callable) -> PackedByteArray:
	var n: int = maxi(8, int(_SR * duration_sec))
	var raw := PackedByteArray()
	raw.resize(n * 2)
	for i in n:
		var t: float = float(i) / float(_SR)
		var env: float = pow(1.0 - float(i) / float(maxf(1, n - 1)), 1.35)
		var s: float = float(sample_fn.call(t, env, i, n))
		s = clampf(s, -1.0, 1.0)
		var si: int = int(s * 32000.0)
		si = clampi(si, -32768, 32767)
		var off: int = i * 2
		raw[off] = si & 0xFF
		raw[off + 1] = (si >> 8) & 0xFF
	return raw


func _stream_from_pcm(pcm: PackedByteArray) -> AudioStreamWAV:
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = _SR
	st.stereo = false
	st.data = pcm
	return st


func _stream_noise_burst(duration: float, amp: float, hf_bias: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pcm := _pcm_mono_i16(duration, func(t: float, env: float, _i: int, _n: int) -> float:
		var x: float = rng.randf() * 2.0 - 1.0
		var f: float = hf_bias * (1.0 + sin(TAU * 420.0 * t) * 0.15)
		return x * amp * env * f
	)
	return _stream_from_pcm(pcm)


func _stream_tone(duration: float, freq_hz: float, amp: float, freq_decay: float) -> AudioStreamWAV:
	var pcm := _pcm_mono_i16(duration, func(t: float, env: float, _i: int, _n: int) -> float:
		var f: float = freq_hz * lerpf(1.0, freq_decay, t / duration)
		return sin(TAU * f * t) * amp * env
	)
	return _stream_from_pcm(pcm)


func _stream_swoosh(duration: float, amp: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pcm := _pcm_mono_i16(duration, func(t: float, env: float, _i: int, _n: int) -> float:
		var f: float = lerpf(1200.0, 180.0, t / duration)
		var nse: float = (rng.randf() * 2.0 - 1.0) * 0.35
		return (sin(TAU * f * t) * 0.65 + nse) * amp * env
	)
	return _stream_from_pcm(pcm)


func _stream_level_fanfare() -> AudioStreamWAV:
	var freqs: Array = [392.0, 493.88, 587.33, 698.46, 783.99]
	var pcm := _pcm_mono_i16(0.52, func(t: float, env: float, i: int, n: int) -> float:
		var nk: int = maxi(1, freqs.size())
		var k: int = clampi(int(floor(float(i) * float(nk) / float(maxi(1, n)))), 0, freqs.size() - 1)
		var freq: float = freqs[k]
		return sin(TAU * freq * t) * 0.24 * env
	)
	return _stream_from_pcm(pcm)
