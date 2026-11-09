extends Node
## Autoload "Sfx": chiptune sound effects synthesised as square waves at
## startup, so the project ships no audio files. Muting is done on the master
## bus by Settings.

const MIX_RATE := 22050
const VOICES := 6

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	# Each sound is a list of [frequency Hz, duration s] notes.
	_streams["step"] = _square([[660.0, 0.025]], 0.12)
	_streams["bump"] = _square([[98.0, 0.08]], 0.35)
	_streams["move"] = _square([[440.0, 0.03]], 0.25)
	_streams["select"] = _square([[523.0, 0.05], [784.0, 0.08]], 0.3)
	_streams["new"] = _square([[392.0, 0.05], [523.0, 0.05], [659.0, 0.08]], 0.25)
	_streams["win"] = _square([[523.0, 0.09], [659.0, 0.09], [784.0, 0.09], [1047.0, 0.3]], 0.3)
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound: String) -> void:
	var stream: AudioStreamWAV = _streams.get(sound)
	if stream == null:
		push_warning("unknown sound: %s" % sound)
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.play()


func _square(notes: Array, volume: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	for note in notes:
		var freq: float = note[0]
		var samples := int(MIX_RATE * float(note[1]))
		var period := MIX_RATE / freq
		for i in samples:
			var high := fmod(float(i), period) < period * 0.5
			var envelope := lerpf(1.0, 0.15, float(i) / samples)  # plucky decay
			var value := int((1.0 if high else -1.0) * volume * envelope * 127.0)
			data.append(value & 0xFF)  # signed 8-bit PCM
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
