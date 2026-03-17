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

	# Default values
	max_stability = 100.0
	stability = max_stability
	gold = 5  # Small starting gold
	void_essence = 0
	ball_count = 1
	pegs = []
	active_synergies = []
	relics = []
	total_drops = 0
	total_damage_dealt = 0
	enemies_defeated = 0
	ghost_board_encountered = false

	# Apply class-specific bonuses
	_apply_class_bonuses(class_id)

	# Emit event that run started
	EventBus.run_started.emit(oracle_class)


## Apply class-specific starting bonuses
func _apply_class_bonuses(class_id: String) -> void:
	match class_id:
		"naturalist":
			# The Naturalist: 4 Fungal pegs, Growth bias
			_add_starting_peg("fungal")
			_add_starting_peg("fungal")
			_add_starting_peg("fungal")
			_add_starting_peg("fungal")
			gold = 10  # More gold for growth synergy needs

		"doomsayer":
			# The Doomsayer: 2 Bone + 1 Cursed, Death/Void bias
			_add_starting_peg("bone")
			_add_starting_peg("bone")
			_add_starting_peg("bone")  # Third bone for synergy
			void_essence = 3  # Starting void essence
			gold = 3

		"architect":
			# The Architect: +10 Stability, Foundation/Fire bias
			max_stability = 110.0
			stability = max_stability
			_add_starting_peg("stone")
			_add_starting_peg("stone")
			_add_starting_peg("ember")
			gold = 8

		"void_walker":
			# The Void-Walker: 1 Void Rift, Void/Eye bias
			_add_starting_peg("void_rift")
			_add_starting_peg("eye")
			_add_starting_peg("eye")
			void_essence = 5  # Starting void essence
			ball_count = 2  # Extra ball
			gold = 3

		_:
			# Wanderer (none): Just 2 random basic pegs
			_add_starting_peg("stone")
			_add_starting_peg("stone")


## Add a starting peg at a default position
func _add_starting_peg(peg_type: String) -> void:
	# Generate a unique ID
	var peg_id := "peg_" + str(pegs.size())

	# Default position - spread across top of board
	# Board is 600 wide, start with some distribution
	var base_x := 100.0 + (pegs.size() * 120.0)
	base_x = clamp(base_x, 80.0, 520.0)

	pegs.append({
		"id": peg_id,
		"type": peg_type,
		"position": Vector2(base_x, 200.0),
		"state": "blessed",
		"hit_count": 0,
		"mutation_level": 0.0
	})

func modify_stability(delta: float) -> void:
	stability = clamp(stability + delta, 0.0, max_stability)
	EventBus.player_stability_changed.emit(stability, delta)
	if stability <= 0.0:
		EventBus.run_ended.emit("stability_depleted", snapshot_board())

func modify_gold(delta: int) -> void:
	var old_gold := gold
	gold = max(0, gold + delta)
	EventBus.gold_changed.emit(gold, gold - old_gold)

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
