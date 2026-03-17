# test_ghost_save_load.gd — Integration tests for Ghost save/load cycle
extends GutTest

# Integration tests for the complete ghost save/load workflow
# Tests the cycle from run end -> save ghost -> load ghost -> encounter

var _ghost_manager: Node = null
var _run_state: Node = null
var _event_bus: Node = null

const SAVE_DIR = "user://void_oracle/ghost_boards/"

func before_each() -> void:
	# Create autoloads
	_event_bus = load("res://scripts/autoloads/EventBus.gd").new()
	_run_state = load("res://scripts/autoloads/RunState.gd").new()
	_ghost_manager = load("res://scripts/autoloads/GhostBoardManager.gd").new()

	add_child(_event_bus)
	add_child(_run_state)
	add_child(_ghost_manager)

	# Ensure save directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func after_each() -> void:
	if _event_bus and is_instance_valid(_event_bus):
		_event_bus.queue_free()
	if _run_state and is_instance_valid(_run_state):
		_run_state.queue_free()
	if _ghost_manager and is_instance_valid(_ghost_manager):
		_ghost_manager.queue_free()

	# Clean up test files
	_cleanup_test_files()


func _cleanup_test_files() -> void:
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name.begins_with(".") and file_name.ends_with(".json"):
				dir.remove(SAVE_DIR + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()


# ── Test: Complete ghost save/load cycle ───────────────────────
func test_complete_save_load_cycle() -> void:
	# Setup: Create a board state similar to what would be saved on death
	var board_state = _run_state.snapshot_board()
	board_state["pegs"] = [
		{"type": "stone", "x": 100, "y": 200, "state": "blessed"},
		{"type": "bone", "x": 150, "y": 250, "state": "cursed"},
		{"type": "fungal", "x": 200, "y": 300, "state": "blessed"}
	]
	board_state["zone"] = 2
	board_state["total_drops"] = 15
	board_state["oracle_class"] = "naturalist"

	# Save the ghost
	_ghost_manager.save_ghost(board_state)

	# Verify save
	var count_after_save = _ghost_manager.count_saved_ghosts()
	assert_eq(count_after_save, 1, "Should have 1 ghost after save")

	# Load the ghost
	var loaded = _ghost_manager.load_ghost(1)

	# Verify loaded data matches saved
	assert_eq(loaded.get("zone"), 2, "Zone should match")
	assert_eq(loaded.get("total_drops"), 15, "Total drops should match")
	assert_eq(loaded.get("oracle_class"), "naturalist", "Class should match")
	assert_eq(loaded.get("pegs").size(), 3, "Should have 3 pegs")

	# Verify peg data integrity
	var loaded_pegs = loaded.get("pegs")
	assert_eq(loaded_pegs[0].get("type"), "stone", "First peg type should be stone")
	assert_eq(loaded_pegs[1].get("type"), "bone", "Second peg type should be bone")
	assert_eq(loaded_pegs[2].get("type"), "fungal", "Third peg type should be fungal")


# ── Test: Ghost rotation when saving over max ─────────────────
func test_ghost_rotation() -> void:
	# Save MAX_GHOSTS ghosts
	for i in range(10):
		var state = {
			"pegs": [{"type": "stone", "index": i}],
			"zone": 1,
			"total_drops": i
		}
		_ghost_manager.save_ghost(state)

	# Should have MAX_GHOSTS
	assert_eq(_ghost_manager.count_saved_ghosts(), 10, "Should have 10 ghosts")

	# Save one more - should rotate (oldest goes to ghost_011.json which gets discarded)
	_ghost_manager.save_ghost({"pegs": [{"type": "bone"}], "zone": 3, "total_drops": 100})

	# Should still have MAX_GHOSTS (oldest discarded)
	assert_eq(_ghost_manager.count_saved_ghosts(), 10, "Should still have 10 ghosts after rotation")

	# The newest should be at ghost_001
	var newest = _ghost_manager.load_ghost(1)
	assert_eq(newest.get("total_drops"), 100, "Newest should be the most recent save")


# ── Test: Missing ghost file returns empty (already tested in unit tests) ─────────────────────────
# Note: Testing corrupt JSON handling is covered by GhostBoardManager's error handling
# which returns empty dict on parse failure. This is verified in unit tests.


# ── Test: Empty board state save ─────────────────────────────
func test_empty_board_state_save() -> void:
	var empty_state = {
		"pegs": [],
		"zone": 1,
		"total_drops": 0
	}

	_ghost_manager.save_ghost(empty_state)

	var loaded = _ghost_manager.load_ghost(1)
	assert_eq(loaded.get("pegs").size(), 0, "Should save empty pegs array")
	assert_eq(loaded.get("zone"), 1, "Should save zone")


# ── Test: Assign ghost for new run ───────────────────────────
func test_assign_ghost_for_new_run() -> void:
	# Save some ghosts first
	_ghost_manager.save_ghost({"pegs": [{"type": "stone"}], "zone": 2})
	_ghost_manager.save_ghost({"pegs": [{"type": "bone"}], "zone": 3})

	# Assign ghost for a specific run seed
	var run_seed = 12345
	_ghost_manager.assign_ghost_for_run(run_seed)

	# Get active ghost
	var active = _ghost_manager.get_active_ghost()

	# Should have assigned a ghost
	assert_true(not active.is_empty(), "Should assign a ghost when ghosts exist")


# ── Test: No ghost assigned when none exist ─────────────────
func test_no_ghost_when_none_saved() -> void:
	# Ensure no ghosts
	assert_eq(_ghost_manager.count_saved_ghosts(), 0, "Should start with no ghosts")

	# Assign ghost
	_ghost_manager.assign_ghost_for_run(99999)

	# Should not crash and should return empty
	var active = _ghost_manager.get_active_ghost()
	assert_true(active.is_empty(), "Should return empty when no ghosts saved")


# ── Test: Multiple runs with same seed get same ghost ───────
func test_deterministic_ghost_assignment() -> void:
	# Save multiple ghosts
	_ghost_manager.save_ghost({"pegs": [{"type": "stone"}], "zone": 1})
	_ghost_manager.save_ghost({"pegs": [{"type": "bone"}], "zone": 2})
	_ghost_manager.save_ghost({"pegs": [{"type": "fungal"}], "zone": 3})

	var run_seed = 55555

	# Assign twice with same seed
	_ghost_manager.assign_ghost_for_run(run_seed)
	var first_assign = _ghost_manager.get_active_ghost().duplicate()

	_ghost_manager.assign_ghost_for_run(run_seed)
	var second_assign = _ghost_manager.get_active_ghost().duplicate()

	# Should get same ghost both times (deterministic)
	assert_eq(first_assign, second_assign, "Same seed should produce same ghost assignment")


# ── Test: RunState integration with ghost save ─────────────
func test_run_state_snapshot_integration() -> void:
	# Create a run
	_run_state.new_run(98765, "architect")

	# Modify run state
	_run_state.zone = 3
	_run_state.total_drops = 42

	# Get snapshot
	var snapshot = _run_state.snapshot_board()

	# Save as ghost
	_ghost_manager.save_ghost(snapshot)

	# Load and verify
	var loaded = _ghost_manager.load_ghost(1)

	assert_eq(loaded.get("run_seed"), 98765, "Should preserve run seed")
	assert_eq(loaded.get("oracle_class"), "architect", "Should preserve class")
	assert_eq(loaded.get("zone_reached"), 3, "Should preserve zone")
	assert_eq(loaded.get("total_drops"), 42, "Should preserve drops")


# ── Test: Missing ghost file returns empty ───────────────────
func test_missing_ghost_returns_empty() -> void:
	var result = _ghost_manager.load_ghost(999)

	assert_true(result.is_empty() or result == null, "Missing ghost should return empty")
