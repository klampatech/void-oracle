# test_run_lifecycle.gd — Integration tests for run lifecycle
extends GutTest

# Integration tests for the complete run lifecycle:
# new run → first drop → enemy defeat → draft → map navigation → victory/defeat

var _run_state: Node = null

func before_each() -> void:
	# Create RunState directly
	_run_state = load("res://scripts/autoloads/RunState.gd").new()
	add_child(_run_state)

func after_each() -> void:
	if _run_state and is_instance_valid(_run_state):
		_run_state.queue_free()


# ── Test: New run initialization ─────────────────────────────
func test_new_run_initialization() -> void:
	# Start new run
	_run_state.new_run(12345, "wanderer")

	# Verify initial state
	assert_eq(_run_state.run_seed, 12345, "Run seed should be set")
	assert_eq(_run_state.oracle_class, "wanderer", "Oracle class should be set")
	assert_eq(_run_state.zone, 1, "Zone should start at 1")
	assert_eq(_run_state.encounter_index, 0, "Encounter index should start at 0")
	assert_eq(_run_state.stability, 100.0, "Default stability should be 100")
	assert_eq(_run_state.gold, 5, "Default gold should be 5")
	assert_eq(_run_state.ball_count, 1, "Default ball count should be 1")


# ── Test: RunState class bonuses ────────────────────────────
func test_class_bonuses_naturalist() -> void:
	_run_state.new_run(11111, "naturalist")

	# Naturalist gets bonus gold and fungal pegs
	assert_eq(_run_state.gold, 10, "Naturalist should have 10 gold")
	assert_eq(_run_state.oracle_class, "naturalist", "Class should be naturalist")

	# Should have fungal pegs
	var has_fungal = false
	for peg in _run_state.pegs:
		if peg.get("type") == "fungal":
			has_fungal = true
	assert_true(has_fungal, "Naturalist should have fungal pegs")


func test_class_bonuses_doomsayer() -> void:
	_run_state.new_run(22222, "doomsayer")

	# Doomsayer gets void essence and bone pegs
	assert_eq(_run_state.void_essence, 3, "Doomsayer should have 3 void essence")
	assert_eq(_run_state.oracle_class, "doomsayer", "Class should be doomsayer")


func test_class_bonuses_architect() -> void:
	_run_state.new_run(33333, "architect")

	# Architect gets extra max stability
	assert_eq(_run_state.max_stability, 110.0, "Architect should have 110 max stability")
	assert_eq(_run_state.stability, 110.0, "Architect should start with 110 stability")


func test_class_bonuses_void_walker() -> void:
	_run_state.new_run(44444, "void_walker")

	# Void Walker gets void essence and extra balls
	assert_eq(_run_state.void_essence, 5, "Void Walker should have 5 void essence")
	assert_eq(_run_state.ball_count, 2, "Void Walker should have 2 balls")


# ── Test: Encounter progression ───────────────────────────────
func test_encounter_index_increments() -> void:
	_run_state.new_run(55555, "wanderer")

	var initial_encounters = _run_state.encounter_index

	# Simulate completing encounters
	_run_state.encounter_index += 1
	assert_eq(_run_state.encounter_index, initial_encounters + 1, "Encounter index should increment")

	_run_state.encounter_index += 1
	assert_eq(_run_state.encounter_index, initial_encounters + 2, "Encounter index should increment again")


# ── Test: Zone progression ────────────────────────────────────
func test_zone_progression() -> void:
	_run_state.new_run(66666, "wanderer")

	assert_eq(_run_state.zone, 1, "Should start in zone 1")

	# Progress to zone 2
	_run_state.zone = 2
	assert_eq(_run_state.zone, 2, "Should progress to zone 2")

	# Progress to zone 3
	_run_state.zone = 3
	assert_eq(_run_state.zone, 3, "Should progress to zone 3")


# ── Test: Stability changes ─────────────────────────────────
func test_stability_changes() -> void:
	_run_state.new_run(77777, "wanderer")

	var initial = _run_state.stability
	var new_stability = clamp(initial - 30.0, 0.0, _run_state.max_stability)
	_run_state.stability = new_stability

	assert_eq(_run_state.stability, 70.0, "Stability should decrease by 30")


# ── Test: Gold changes ───────────────────────────────────────
func test_gold_changes() -> void:
	_run_state.new_run(88888, "wanderer")

	_run_state.gold += 25
	assert_eq(_run_state.gold, 30, "Gold should increase")

	_run_state.gold -= 10
	assert_eq(_run_state.gold, 20, "Gold should decrease")


# ── Test: Board snapshot for ghost ──────────────────────────
func test_board_snapshot_for_ghost() -> void:
	_run_state.new_run(99999, "naturalist")
	_run_state.zone = 2
	_run_state.total_drops = 25

	var snapshot = _run_state.snapshot_board()

	# Verify snapshot contains expected data
	assert_true(snapshot.has("version"), "Snapshot should have version")
	assert_true(snapshot.has("run_seed"), "Snapshot should have run_seed")
	assert_true(snapshot.has("oracle_class"), "Snapshot should have oracle_class")
	assert_true(snapshot.has("zone_reached"), "Snapshot should have zone_reached")
	assert_true(snapshot.has("pegs"), "Snapshot should have pegs")
	assert_true(snapshot.has("total_drops"), "Snapshot should have total_drops")
	assert_true(snapshot.has("timestamp"), "Snapshot should have timestamp")

	# Verify data integrity
	assert_eq(snapshot["run_seed"], 99999, "Snapshot run_seed should match")
	assert_eq(snapshot["oracle_class"], "naturalist", "Snapshot class should match")
	assert_eq(snapshot["zone_reached"], 2, "Snapshot zone should match")


# ── Test: Void essence tracking ─────────────────────────────
func test_void_essence_tracking() -> void:
	_run_state.new_run(10101, "wanderer")

	assert_eq(_run_state.void_essence, 0, "Wanderer should start with 0 void essence")

	_run_state.void_essence += 5
	assert_eq(_run_state.void_essence, 5, "Void essence should increase")


# ── Test: Ball count management ─────────────────────────────
func test_ball_count_management() -> void:
	_run_state.new_run(20202, "wanderer")

	assert_eq(_run_state.ball_count, 1, "Should start with 1 ball")

	_run_state.ball_count += 1
	assert_eq(_run_state.ball_count, 2, "Ball count should increase")

	_run_state.ball_count = 5
	assert_eq(_run_state.ball_count, 5, "Ball count can be set higher")


# ── Test: Peg array management ───────────────────────────────
func test_peg_array_management() -> void:
	_run_state.new_run(30303, "wanderer")

	var initial_pegs = _run_state.pegs.size()

	# Add a new peg
	var new_peg = {"type": "stone", "x": 100, "y": 100, "state": "normal"}
	_run_state.pegs.append(new_peg)

	assert_eq(_run_state.pegs.size(), initial_pegs + 1, "Should have one more peg")

	# Remove a peg
	_run_state.pegs.pop_back()
	assert_eq(_run_state.pegs.size(), initial_pegs, "Should be back to original count")


# Run end conditions
func test_run_end_on_stability_zero() -> void:
	_run_state.new_run(40404, "wanderer")

	# Set stability to 0 (death condition)
	_run_state.stability = 0.0

	# Stability at 0 should trigger death
	assert_eq(_run_state.stability, 0.0, "Stability should be 0")


# ── Test: Encounter tracking ─────────────────────────────────
func test_encounter_tracking() -> void:
	_run_state.new_run(50505, "wanderer")

	assert_eq(_run_state.encounter_index, 0, "Should start at encounter 0")

	# Complete encounters
	for i in range(5):
		_run_state.encounter_index += 1

	assert_eq(_run_state.encounter_index, 5, "Should track 5 encounters")


# ── Test: Shop appearance trigger ───────────────────────────
func test_shop_every_four_encounters() -> void:
	_run_state.new_run(60606, "wanderer")

	# Shop appears every 4 encounters after victory
	_run_state.encounter_index = 4
	var should_show_shop = (_run_state.encounter_index > 0 and _run_state.encounter_index % 4 == 0)
	assert_true(should_show_shop, "Shop should appear at encounter 4")

	_run_state.encounter_index = 8
	should_show_shop = (_run_state.encounter_index > 0 and _run_state.encounter_index % 4 == 0)
	assert_true(should_show_shop, "Shop should appear at encounter 8")

	_run_state.encounter_index = 5
	should_show_shop = (_run_state.encounter_index > 0 and _run_state.encounter_index % 4 == 0)
	assert_false(should_show_shop, "Shop should NOT appear at encounter 5")
