# RunState.gd — All mutable state for the current run.
# Add to AutoLoad in Project Settings as "RunState"
extends Node

# ── Run Meta ─────────────────────────────────────────────
var run_seed: int = 0
var run_id: String = ""
var zone: int = 1
var encounter_index: int = 0
var oracle_class: String = "none"

# ── Resources ────────────────────────────────────────────
var stability: float = 100.0
var max_stability: float = 100.0
var gold: int = 0
var void_essence: int = 0
var ball_count: int = 1           # balls available for next drop
var max_balls: int = 5

# ── Board State ──────────────────────────────────────────
var pegs: Array[Dictionary] = []  # [{id, type, position, state, hit_count, mutation_level}]
var active_synergies: Array[String] = []
var relics: Array[String] = []

# ── Run Stats ────────────────────────────────────────────
var total_drops: int = 0
var total_damage_dealt: int = 0
var enemies_defeated: int = 0
var ghost_board_encountered: bool = false

func new_run(seed: int, class_id: String = "none") -> void:
	run_seed = seed
	run_id = str(seed) + "_" + str(Time.get_unix_time_from_system())
	oracle_class = class_id
	zone = 1
	encounter_index = 0
	stability = 100.0
	gold = 0
	void_essence = 0
	ball_count = 1
	pegs = []
	active_synergies = []
	relics = []
	total_drops = 0

func modify_stability(delta: float) -> void:
	stability = clamp(stability + delta, 0.0, max_stability)
	EventBus.player_stability_changed.emit(stability, delta)
	if stability <= 0.0:
		EventBus.run_ended.emit("stability_depleted", snapshot_board())

func snapshot_board() -> Dictionary:
	return {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"run_seed": run_seed,
		"oracle_class": oracle_class,
		"zone_reached": zone,
		"pegs": pegs.duplicate(true),
		"active_synergies": active_synergies.duplicate(),
		"relics": relics.duplicate(),
		"stability_at_death": stability,
		"total_drops": total_drops,
	}
