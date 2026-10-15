extends Node

const SAMPLE_RATE: int = 22050

var enabled: bool = true

func play_sfx(name: String) -> void:
	if not enabled:
		return
	var spec: Dictionary = _spec_for(name)
	var stream: AudioStreamWAV = _build_sound(
		float(spec.get("frequency", 440.0)),
		float(spec.get("duration", 0.10)),
		float(spec.get("volume", 0.28)),
		float(spec.get("slide", 1.0)),
		float(spec.get("noise", 0.0))
	)
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = float(spec.get("volume_db", -5.0))
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _spec_for(name: String) -> Dictionary:
	match name:
		"flip": return {"frequency": 270.0, "duration": 0.075, "volume": 0.27, "slide": 1.65, "volume_db": -7.0}
		"coin": return {"frequency": 980.0, "duration": 0.095, "volume": 0.24, "slide": 1.32, "volume_db": -5.0}
		"perfect": return {"frequency": 680.0, "duration": 0.15, "volume": 0.24, "slide": 1.48, "volume_db": -5.0}
		"rush": return {"frequency": 190.0, "duration": 0.32, "volume": 0.25, "slide": 4.2, "noise": 0.025, "volume_db": -6.0}
		"hit": return {"frequency": 92.0, "duration": 0.24, "volume": 0.31, "slide": 0.58, "noise": 0.22, "volume_db": -3.0}
		"shield": return {"frequency": 520.0, "duration": 0.18, "volume": 0.22, "slide": 1.72, "volume_db": -6.0}
		"power": return {"frequency": 410.0, "duration": 0.16, "volume": 0.22, "slide": 2.1, "volume_db": -6.0}
		"win": return {"frequency": 520.0, "duration": 0.34, "volume": 0.22, "slide": 1.92, "volume_db": -5.0}
		"button": return {"frequency": 720.0, "duration": 0.055, "volume": 0.18, "slide": 1.18, "volume_db": -9.0}
		_: return {"frequency": 440.0, "duration": 0.08, "volume": 0.18, "slide": 1.0, "volume_db": -8.0}

func _build_sound(frequency: float, duration: float, volume: float, slide: float, noise_amount: float) -> AudioStreamWAV:
	var sample_count: int = maxi(1, int(float(SAMPLE_RATE) * duration))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(frequency * 101.0 + duration * 10000.0)
	for i in range(sample_count):
		var progress: float = float(i) / float(maxi(1, sample_count - 1))
		var current_frequency: float = frequency * lerpf(1.0, slide, progress)
		phase += TAU * current_frequency / float(SAMPLE_RATE)
		var attack: float = minf(1.0, progress / 0.07)
		var release: float = pow(1.0 - progress, 1.7)
		var envelope: float = attack * release
		var harmonic: float = sin(phase) * 0.78 + sin(phase * 2.01) * 0.16 + sin(phase * 3.02) * 0.06
		var noise: float = rng.randf_range(-1.0, 1.0) * noise_amount
		var sample_value: float = clampf((harmonic + noise) * volume * envelope, -1.0, 1.0)
		data.encode_s16(i * 2, int(sample_value * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
