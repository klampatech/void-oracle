# SynergyChecker.gd — Watches board state, activates/deactivates synergies.
# Add to AutoLoad in Project Settings as "SynergyChecker"
extends Node

# Synergy definitions: id -> {required_tags, min_count, curse_risk}
const SYNERGIES = {
	"necrotic_bloom": { "tags": ["death", "growth"], "min": 3 },
	"cursed_flame":   { "tags": ["fire", "cursed"],  "min": 3 },
	"void_choir":     { "tags": ["void"],             "min": 3 },
	"bleeding_arch":  { "tags": ["blood", "foundation"], "min": 3 },
	"profane_eye":    { "tags": ["void", "death"],    "min": 3 },
}

var _tag_counts: Dictionary = {}
var _active: Dictionary = {}   # synergy_id -> peg_count

func _ready() -> void:
	EventBus.peg_state_changed.connect(_on_peg_state_changed)
	EventBus.peg_spawned.connect(_on_peg_spawned)
	EventBus.peg_destroyed.connect(_on_peg_destroyed)

func recount_from_board(pegs: Array) -> void:
	_tag_counts.clear()
	for peg in pegs:
		for tag in peg.get("tags", []):
			_tag_counts[tag] = _tag_counts.get(tag, 0) + 1
	_evaluate_all()

func _on_peg_state_changed(_peg, _old, _new) -> void:
	recount_from_board(RunState.pegs)

func _on_peg_spawned(_peg, _pos) -> void:
	recount_from_board(RunState.pegs)

func _on_peg_destroyed(_peg) -> void:
	recount_from_board(RunState.pegs)

func _evaluate_all() -> void:
	for id in SYNERGIES:
		var def = SYNERGIES[id]
		var count = _min_tag_count(def["tags"])
		var was_active = _active.has(id)
		if count >= def["min"]:
			if not was_active:
				EventBus.synergy_activated.emit(id, count)
			elif _active[id] != count:
				EventBus.synergy_scaled.emit(id, count)
			_active[id] = count
		else:
			if was_active:
				_active.erase(id)
				EventBus.synergy_broken.emit(id)

	# Debug: print active synergies to console
	_debug_print_synergies()


func _debug_print_synergies() -> void:
	if _active.is_empty():
		print("[SynergyChecker] No active synergies")
	else:
		var active_list: Array[String] = []
		for id in _active:
			active_list.append("%s(%d)" % [id, _active[id]])
		print("[SynergyChecker] Active synergies: ", ", ".join(active_list))

func _min_tag_count(tags: Array) -> int:
	var min_count = INF
	for tag in tags:
		min_count = min(min_count, _tag_counts.get(tag, 0))
	return int(min_count) if min_count != INF else 0
