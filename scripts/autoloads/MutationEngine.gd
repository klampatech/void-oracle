# MutationEngine.gd — Tracks peg hit counts, manages blessed/cursed axis transitions.
# Add to AutoLoad in Project Settings as "MutationEngine"
extends Node

# How many hits before a peg can mutate
const MUTATION_THRESHOLD = 5
# Chance per hit (once threshold met) to shift state
const MUTATION_CHANCE = 0.15

func _ready() -> void:
	EventBus.peg_hit.connect(_on_peg_hit)

func _on_peg_hit(peg: Node, _ball: Node) -> void:
	if not peg.has_method("get_hit_count"):
		return
	var hits = peg.get_hit_count()
	if hits < MUTATION_THRESHOLD:
		return
	if randf() < MUTATION_CHANCE:
		_try_mutate(peg)

func _try_mutate(peg: Node) -> void:
	var current = peg.get("peg_state") if peg.get("peg_state") else "dormant"
	var new_state = _next_state(current, peg)
	if new_state != current:
		var old = current
		peg.set("peg_state", new_state)
		# Update shader uniforms based on new state
		_update_peg_shader(peg, new_state)
		EventBus.peg_state_changed.emit(peg, old, new_state)


func _update_peg_shader(peg: Node, state: String) -> void:
	# Update shader uniforms based on state
	match state:
		"dormant":
			peg.set_corruption_level(0.5)
			peg.set_mutation_pulse(0.0)
			peg.set_void_factor(0.0)
		"blessed":
			peg.set_corruption_level(0.0)
			peg.set_mutation_pulse(0.0)
			peg.set_void_factor(0.0)
		"cursed":
			peg.set_corruption_level(1.0)
			peg.set_mutation_pulse(0.0)
			peg.set_void_factor(0.0)
		"mutant":
			peg.set_corruption_level(0.5)
			peg.set_mutation_pulse(1.0)
			peg.set_void_factor(0.0)
		"void":
			peg.set_corruption_level(1.0)
			peg.set_mutation_pulse(0.5)
			peg.set_void_factor(1.0)

func _next_state(current: String, peg: Node) -> String:
	match current:
		"dormant":
			# Environmental pressure determines direction
			var corruption_pressure = _get_local_corruption(peg)
			return "cursed" if corruption_pressure > 0.5 else "blessed"
		"blessed":
			return "mutant" if randf() < 0.3 else "blessed"
		"cursed":
			return "mutant" if randf() < 0.4 else "cursed"
		"mutant":
			return "void" if randf() < 0.1 else "mutant"
	return current

func _get_local_corruption(peg: Node) -> float:
	# TODO: Sample nearby pegs' states and return corruption ratio 0.0-1.0
	return 0.3  # placeholder
