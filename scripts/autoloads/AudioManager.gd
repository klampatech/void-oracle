# AudioManager.gd — Per-peg tone system + ambient layering.
# Add to AutoLoad in Project Settings as "AudioManager"
extends Node

## AudioManager handles all game audio:
## - Per-peg tones on collision
## - Ambient music by zone
## - Boss music layering
## - UI sound effects

# Map peg type -> tone frequency (Hz) — tuned to a pentatonic scale for harmonics
const PEG_TONES: Dictionary = {
	"stone":   261.6,   # C4
	"bone":    293.7,   # D4
	"fungal":  329.6,   # E4
	"ember":   392.0,   # G4
	"eye":     440.0,   # A4
	"heart":   523.3,   # C5
	"void_rift": 130.8, # C3 (deep)
	"oracle":  659.3,   # E5 (high)
}

# Pitch modifier by peg state
const STATE_PITCH_MOD: Dictionary = {
	"dormant":  1.0,
	"blessed":  1.2,
	"cursed":   0.85,
	"mutant":   1.05,
	"void":     0.5,
	"shattered": 0.6,
}

# Pool of audio players for polyphonic playback
const POOL_SIZE := 16
var _player_pool: Array[AudioStreamPlayer] = []
var _next_player := 0

# Volume settings
var _master_volume := 0.8
var _sfx_volume := 1.0
var _music_volume := 0.7
var _ambient_volume := 0.5

# Music players
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _boss_player: AudioStreamPlayer

# Track current zone for music
var _current_zone := 1
var _is_boss_encounter := false

# Audio bus indices
var _bus_master := 0
var _bus_sfx := 0
var _bus_music := 0
var _bus_ambient := 0

# Pre-generated tone samples for each peg type
var _tone_samples: Dictionary = {}

func _ready() -> void:
	_generate_tone_samples()
	_setup_audio_buses()
	_setup_player_pool()
	_setup_music_players()
	_connect_signals()
	_load_settings()

func _generate_tone_samples() -> void:
	# Generate procedural sine wave samples for each peg type
	for peg_type in PEG_TONES.keys():
		var freq: float = PEG_TONES[peg_type] as float
		var sample: AudioStreamWAV = _create_tone_sample(freq, 0.15)
		_tone_samples[peg_type] = sample

func _create_tone_sample(freq: float, duration: float) -> AudioStreamWAV:
	var sample := AudioStreamWAV.new()
	var sample_rate := 44100
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()

	# Generate sine wave with envelope (attack/decay)
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = 1.0

		# Quick attack, exponential decay
		var attack_time := 0.005
		var decay_time := duration - 0.02
		if t < attack_time:
			envelope = t / attack_time
		elif t > decay_time:
			envelope = (duration - t) / (duration - decay_time)
		envelope = clampf(envelope, 0.0, 1.0)

		# Add slight harmonics for richness
		var value: float = sin(2.0 * PI * freq * t)
		value += 0.3 * sin(2.0 * PI * freq * 2.0 * t)  # 2nd harmonic
		value += 0.1 * sin(2.0 * PI * freq * 3.0 * t)  # 3rd harmonic

		# Convert to 16-bit integer
		var int_value: int = int(value * envelope * 32767.0 * 0.5)
		int_value = clampi(int_value, -32768, 32767)
		data.append((int_value & 0xFF))
		data.append(((int_value >> 8) & 0xFF))

	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.data = data
	sample.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return sample

func _setup_audio_buses() -> void:
	_bus_master = AudioServer.get_bus_index("Master")
	_bus_sfx = AudioServer.get_bus_index("SFX")
	_bus_music = AudioServer.get_bus_index("Music")
	_bus_ambient = AudioServer.get_bus_index("Ambient")

	# Fallback to master if buses don't exist
	if _bus_master == -1:
		_bus_master = 0
	if _bus_sfx == -1:
		_bus_sfx = _bus_master
	if _bus_music == -1:
		_bus_music = _bus_master
	if _bus_ambient == -1:
		_bus_ambient = _bus_master

func _setup_player_pool() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "SFX"
		player.volume_db = -80.0
		add_child(player)
		_player_pool.append(player)

func _setup_music_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	_music_player.volume_db = -80.0
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.bus = "Ambient"
	_ambient_player.volume_db = -80.0
	add_child(_ambient_player)

	_boss_player = AudioStreamPlayer.new()
	_boss_player.name = "BossPlayer"
	_boss_player.bus = "Music"
	_boss_player.volume_db = -80.0
	add_child(_boss_player)

func _connect_signals() -> void:
	EventBus.peg_hit.connect(_on_peg_hit)
	EventBus.zone_completed.connect(_on_zone_completed)
	EventBus.boss_phase_changed.connect(_on_boss_phase_changed)
	EventBus.encounter_started.connect(_on_encounter_started)
	EventBus.encounter_ended.connect(_on_encounter_ended)

func _load_settings() -> void:
	var settings_path := "user://void_oracle/settings.json"
	if FileAccess.file_exists(settings_path):
		var file := FileAccess.open(settings_path, FileAccess.READ)
		if file:
			var json := JSON.new()
			var err := json.parse(file.get_as_text())
			if err == OK:
				var settings: Dictionary = json.data as Dictionary
				_master_volume = settings.get("master_volume", 0.8)
				_sfx_volume = settings.get("sfx_volume", 1.0)
				_music_volume = settings.get("music_volume", 0.7)
				_ambient_volume = settings.get("ambient_volume", 0.5)
				_apply_volume_settings()

func _apply_volume_settings() -> void:
	AudioServer.set_bus_volume_db(_bus_master, linear_to_db(_master_volume))
	AudioServer.set_bus_volume_db(_bus_sfx, linear_to_db(_sfx_volume))
	AudioServer.set_bus_volume_db(_bus_music, linear_to_db(_music_volume))
	AudioServer.set_bus_volume_db(_bus_ambient, linear_to_db(_ambient_volume))

func _on_peg_hit(peg: Node, ball: Node) -> void:
	# Get peg type as string
	var peg_type_key: String = _get_peg_type_string(peg)
	# Get peg state as string
	var peg_state_key: String = _get_peg_state_string(peg)
	# Get ball velocity for volume
	var velocity: float = 0.0
	if ball and ball.get("linear_velocity"):
		velocity = ball.linear_velocity.length()

	play_peg_tone(peg_type_key, peg_state_key, velocity)

func _get_peg_type_string(peg: Node) -> String:
	if peg.has_method("get_peg_type_string"):
		return peg.get_peg_type_string()

	var peg_type_names := ["stone", "bone", "fungal", "ember", "eye", "heart", "oracle", "void_rift"]
	if peg.get("peg_type") != null:
		var peg_type_idx: int = peg.get("peg_type") as int
		if peg_type_idx >= 0 and peg_type_idx < peg_type_names.size():
			return peg_type_names[peg_type_idx]
	return "stone"

func _get_peg_state_string(peg: Node) -> String:
	var peg_state_names := ["dormant", "blessed", "cursed", "mutant", "void"]
	if peg.get("peg_state") != null:
		var peg_state_idx: int = peg.get("peg_state") as int
		if peg_state_idx >= 0 and peg_state_idx < peg_state_names.size():
			return peg_state_names[peg_state_idx]
	return "dormant"

func play_peg_tone(peg_type: String, state: String, velocity: float = 200.0) -> void:
	# Get base frequency for peg type
	var base_freq: float = PEG_TONES.get(peg_type, 261.6) as float
	# Apply state pitch modifier
	var pitch_mod: float = STATE_PITCH_MOD.get(state, 1.0) as float
	var target_freq: float = base_freq * pitch_mod

	# Get next available player from pool
	var player: AudioStreamPlayer = _get_next_player()
	if player == null:
		return

	# Get the pre-generated sample for this peg type
	var sample: AudioStreamWAV = _tone_samples.get(peg_type, _tone_samples.get("stone")) as AudioStreamWAV
	player.stream = sample
	player.play()

	# Calculate volume based on ball velocity
	# Velocity typically ranges from 0 to 500+, normalize to 0.1-1.0
	var normalized_velocity: float = clampf(velocity / 500.0, 0.1, 1.0)
	var volume: float = -20.0 + (normalized_velocity * 20.0)  # -20 to 0 dB

	# State-based volume modifier
	var state_volume_mod: float = 1.0
	if state == "blessed":
		state_volume_mod = 1.2  # Slightly louder, clearer
	elif state == "cursed":
		state_volume_mod = 0.7  # Quieter, bassy
	elif state == "void":
		state_volume_mod = 0.5  # Very quiet

	player.volume_db = volume * state_volume_mod

	# Apply pitch
	player.pitch_scale = target_freq / base_freq

func _get_next_player() -> AudioStreamPlayer:
	# Find a non-playing player
	for i in range(POOL_SIZE):
		_next_player = (_next_player + 1) % POOL_SIZE
		var player: AudioStreamPlayer = _player_pool[_next_player]
		if not player.playing:
			return player

	# All players busy, force steal the oldest
	_next_player = (_next_player + 1) % POOL_SIZE
	var busy_player: AudioStreamPlayer = _player_pool[_next_player]
	busy_player.stop()
	busy_player.volume_db = -80.0
	return busy_player

# Music system
func _on_zone_completed(zone: int) -> void:
	_current_zone = zone + 1
	_play_zone_music(_current_zone)

func _on_encounter_started(node_type: String, _data: Dictionary) -> void:
	if node_type == "boss":
		_is_boss_encounter = true
		_start_boss_music()
	else:
		_is_boss_encounter = false

func _on_encounter_ended(_result: String) -> void:
	_is_boss_encounter = false
	_stop_boss_music()

func _on_boss_phase_changed(_phase: int) -> void:
	if _is_boss_encounter:
		# Boss music intensity adjustment would happen here
		pass

func _play_zone_music(zone: int) -> void:
	# Zone music loading from res://assets/audio/music/zone%d.ogg
	_current_zone = zone
	print("[AudioManager] Playing zone %d music" % zone)
	# Crossfade implementation would go here

func _start_boss_music() -> void:
	print("[AudioManager] Starting boss music")
	# Would load res://assets/audio/music/boss.ogg with phase layers

func _stop_boss_music() -> void:
	print("[AudioManager] Stopping boss music")
	# Fade out boss track

# Volume control API
func set_master_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(_bus_master, linear_to_db(_master_volume))
	_save_settings()

func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(_bus_sfx, linear_to_db(_sfx_volume))
	_save_settings()

func set_music_volume(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(_bus_music, linear_to_db(_music_volume))
	_save_settings()

func set_ambient_volume(value: float) -> void:
	_ambient_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(_bus_ambient, linear_to_db(_ambient_volume))
	_save_settings()

func _save_settings() -> void:
	var settings := {
		"master_volume": _master_volume,
		"sfx_volume": _sfx_volume,
		"music_volume": _music_volume,
		"ambient_volume": _ambient_volume,
	}
	var settings_path := "user://void_oracle/settings.json"
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))
		file.close()

# Debug/test function
func test_peg_tones() -> void:
	var types := ["stone", "bone", "fungal", "ember", "eye", "heart", "void_rift", "oracle"]
	var states := ["dormant", "blessed", "cursed", "mutant", "void"]

	for peg_type in types:
		for state in states:
			play_peg_tone(peg_type, state, 300.0)
			await get_tree().create_timer(0.1).timeout
