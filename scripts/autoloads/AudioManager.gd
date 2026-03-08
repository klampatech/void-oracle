# AudioManager.gd — Per-peg tone system + ambient layering.
# Add to AutoLoad in Project Settings as "AudioManager"
extends Node

# Map peg type -> tone frequency (Hz) — tuned to a pentatonic scale for harmonics
const PEG_TONES = {
	"stone":   261.6,   # C4
	"bone":    293.7,   # D4
	"fungal":  329.6,   # E4
	"ember":   392.0,   # G4
	"eye":     440.0,   # A4
	"heart":   523.3,   # C5
	"void_rift": 130.8, # C3 (deep)
	"oracle":  659.3,   # E5 (high)
}

const STATE_PITCH_MOD = {
	"dormant":  1.0,
	"blessed":  1.2,
	"cursed":   0.85,
	"mutant":   1.05,
	"void":     0.5,
	"shattered": 0.6,
}

func _ready() -> void:
	EventBus.peg_hit.connect(_on_peg_hit)

func _on_peg_hit(peg: Node, _ball: Node) -> void:
	# Get peg type as string (enum -> string conversion)
	var peg_type_key: String = "stone"
	if peg.has_method("get_peg_type_string"):
		peg_type_key = peg.get_peg_type_string()
	elif peg.get("peg_type") != null:
		# Convert enum index to string key
		var peg_type_idx = peg.get("peg_type") as int
		var peg_type_names = ["stone", "bone", "fungal", "ember", "eye", "heart", "oracle", "void_rift"]
		if peg_type_idx >= 0 and peg_type_idx < peg_type_names.size():
			peg_type_key = peg_type_names[peg_type_idx]

	# Get peg state as string (enum -> string conversion)
	var peg_state_key: String = "dormant"
	if peg.get("peg_state") != null:
		var peg_state_idx = peg.get("peg_state") as int
		var peg_state_names = ["dormant", "blessed", "cursed", "mutant", "void"]
		if peg_state_idx >= 0 and peg_state_idx < peg_state_names.size():
			peg_state_key = peg_state_names[peg_state_idx]

	play_peg_tone(peg_type_key, peg_state_key)

func play_peg_tone(peg_type: String, state: String) -> void:
	var freq = PEG_TONES.get(peg_type, 261.6)
	var pitch_mod = STATE_PITCH_MOD.get(state, 1.0)
	# TODO: Replace with actual AudioStreamPlayer + AudioStreamGenerator
	# or load pre-generated tone samples from assets/audio/sfx/pegs/
	print("TONE: %s Hz (peg: %s, state: %s)" % [freq * pitch_mod, peg_type, state])
