# FungalPeg.gd — Fungal peg type
extends BasePeg

## Distance threshold for adjacent slots (in pixels, ~2 peg distances)
const ADJACENT_DISTANCE := 100.0

## Chance to spawn sprout
const SPROUT_CHANCE := 0.25


func _ready() -> void:
	peg_type = PegType.FUNGAL
	super._ready()

	# Connect to drop ended signal to trigger growth
	EventBus.drop_ended.connect(_on_drop_ended)


func _on_drop_ended(_results: Dictionary) -> void:
	# Check if this is the 3rd drop (every 3 drops)
	if RunState.total_drops % 3 != 0:
		return

	# 25% chance to spawn sprout
	if randf() > SPROUT_CHANCE:
		return

	# Find adjacent empty slots
	var empty_slots := _find_empty_adjacent_slots()

	if empty_slots.is_empty():
		return

	# Pick random empty slot
	var spawn_pos: Vector2 = empty_slots.pick_random()

	# Spawn a new Sprout peg
	_spawn_sprout(spawn_pos)


func _find_empty_adjacent_slots() -> Array[Vector2]:
	var empty_slots: Array[Vector2] = []

	# Get all pegs in the 'peg' group
	var all_pegs := get_tree().get_nodes_in_group("peg")

	# Check positions around this peg
	var check_positions := [
		global_position + Vector2(ADJACENT_DISTANCE, 0),
		global_position + Vector2(-ADJACENT_DISTANCE, 0),
		global_position + Vector2(0, ADJACENT_DISTANCE),
		global_position + Vector2(0, -ADJACENT_DISTANCE),
		global_position + Vector2(ADJACENT_DISTANCE * 0.7, ADJACENT_DISTANCE * 0.7),
		global_position + Vector2(-ADJACENT_DISTANCE * 0.7, ADJACENT_DISTANCE * 0.7),
		global_position + Vector2(ADJACENT_DISTANCE * 0.7, -ADJACENT_DISTANCE * 0.7),
		global_position + Vector2(-ADJACENT_DISTANCE * 0.7, -ADJACENT_DISTANCE * 0.7),
	]

	for pos in check_positions:
		# Check if any peg is too close to this position
		var is_occupied := false
		for peg in all_pegs:
			if pos.distance_to(peg.global_position) < ADJACENT_DISTANCE * 0.5:
				is_occupied = true
				break

		if not is_occupied:
			empty_slots.append(pos)

	return empty_slots


func _spawn_sprout(position: Vector2) -> void:
	# Emit the signal to indicate a new peg would spawn
	EventBus.peg_spawned.emit(self, position)
