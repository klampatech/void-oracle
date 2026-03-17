# test_ghost_board_manager.gd — Unit tests for GhostBoardManager
extends GutTest

var _ghost_manager: Node = null

func before_each() -> void:
	# Create GhostBoardManager instance
	_ghost_manager = load("res://scripts/autoloads/GhostBoardManager.gd").new()
	add_child(_ghost_manager)

	# Create test directory (same as actual save dir)
	DirAccess.make_dir_recursive_absolute("user://void_oracle/ghost_boards/")

func after_each() -> void:
	if _ghost_manager and is_instance_valid(_ghost_manager):
		_ghost_manager.queue_free()

	# Clean up test files
	_cleanup_test_files()


func _cleanup_test_files() -> void:
	var dir = DirAccess.open("user://void_oracle/ghost_boards/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name.begins_with("."):
				dir.remove("user://void_oracle/ghost_boards/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()


# ── Test class exists and has required methods ─────────────
func test_ghost_manager_has_save_method() -> void:
	assert_true(_ghost_manager.has_method("save_ghost"), "GhostBoardManager should have save_ghost method")

func test_ghost_manager_has_load_method() -> void:
	assert_true(_ghost_manager.has_method("load_ghost"), "GhostBoardManager should have load_ghost method")

func test_ghost_manager_has_count_method() -> void:
	assert_true(_ghost_manager.has_method("count_saved_ghosts"), "GhostBoardManager should have count_saved_ghosts method")

func test_ghost_manager_has_assign_method() -> void:
	assert_true(_ghost_manager.has_method("assign_ghost_for_run"), "GhostBoardManager should have assign_ghost_for_run method")


# ── Test constants ─────────────────────────────────────────
func test_max_ghosts_constant() -> void:
	# MAX_GHOSTS should be 10
	assert_eq(_ghost_manager.MAX_GHOSTS, 10, "MAX_GHOSTS should be 10")


# ── Test save_ghost writes valid JSON ─────────────────────
func test_save_ghost_writes_valid_json() -> void:
	var test_board_state = {
		"pegs": [
			{"type": "stone", "x": 100, "y": 200},
			{"type": "bone", "x": 150, "y": 250}
		],
		"zone": 2,
		"total_drops": 10
	}

	# Save ghost
	_ghost_manager.save_ghost(test_board_state)

	# Verify file was created
	var file_exists = FileAccess.file_exists("user://void_oracle/ghost_boards/ghost_001.json")
	assert_true(file_exists, "Ghost file should be created")

	# Verify JSON is valid
	var file = FileAccess.open("user://void_oracle/ghost_boards/ghost_001.json", FileAccess.READ)
	assert_not_null(file, "Should be able to open ghost file")

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	assert_eq(parse_result, OK, "JSON should be valid")

	var loaded_data = json.get_data()
	assert_true(loaded_data.has("pegs"), "Loaded data should have pegs")


# ── Test load_ghost returns stored data ────────────────────
func test_load_ghost_returns_stored_data() -> void:
	var original_state = {
		"pegs": [
			{"type": "ember", "x": 300, "y": 400},
			{"type": "fungal", "x": 350, "y": 450}
		],
		"zone": 3,
		"total_drops": 25,
		"oracle_class": "doomsayer"
	}

	# Save then load
	_ghost_manager.save_ghost(original_state)
	var loaded_state = _ghost_manager.load_ghost(1)

	assert_eq(loaded_state.get("zone"), 3, "Should load zone")
	assert_eq(loaded_state.get("total_drops"), 25, "Should load drops")
	assert_eq(loaded_state.get("oracle_class"), "doomsayer", "Should load class")
	assert_eq(loaded_state.get("pegs").size(), 2, "Should load pegs")


# ── Test load_ghost returns empty for missing file ─────────
func test_load_ghost_returns_empty_for_missing() -> void:
	var result = _ghost_manager.load_ghost(999)

	assert_true(result.is_empty(), "Should return empty dict for missing file")


# ── Test count_saved_ghosts ────────────────────────────────
func test_count_saved_ghosts_initial() -> void:
	# Should start with 0
	var count = _ghost_manager.count_saved_ghosts()
	assert_eq(count, 0, "Should start with 0 ghosts")


func test_count_saved_ghosts_after_save() -> void:
	var test_state = {"pegs": []}

	_ghost_manager.save_ghost(test_state)

	var count = _ghost_manager.count_saved_ghosts()
	assert_eq(count, 1, "Should count 1 ghost after save")


func test_count_saved_ghosts_multiple_saves() -> void:
	# Save multiple ghosts
	var test_state = {"pegs": []}

	for i in range(5):
		_ghost_manager.save_ghost(test_state)

	var count = _ghost_manager.count_saved_ghosts()
	assert_eq(count, 5, "Should count 5 ghosts")


# ── Test assign_ghost_for_run ─────────────────────────────
func test_assign_ghost_for_run() -> void:
	# First save a ghost
	var test_state = {
		"pegs": [{"type": "stone"}],
		"zone": 2
	}
	_ghost_manager.save_ghost(test_state)

	# Assign ghost for a run
	_ghost_manager.assign_ghost_for_run(12345)

	var active = _ghost_manager.get_active_ghost()
	assert_true(not active.is_empty(), "Should assign an active ghost")


func test_assign_ghost_for_run_no_ghosts() -> void:
	# Assign ghost when none exist - should not crash
	_ghost_manager.assign_ghost_for_run(12345)

	var active = _ghost_manager.get_active_ghost()
	assert_true(active.is_empty(), "Should return empty when no ghosts exist")


# ── Test ghost path format ─────────────────────────────────
func test_ghost_path_format() -> void:
	# Verify the save path format is correct
	var test_state = {"test": true}
	_ghost_manager.save_ghost(test_state)

	# Check that ghost_001.json exists
	assert_true(FileAccess.file_exists("user://void_oracle/ghost_boards/ghost_001.json"), "Ghost path format should be ghost_XXX.json")


# ── Test active ghost getter ───────────────────────────────
func test_get_active_ghost() -> void:
	var active = _ghost_manager.get_active_ghost()
	# Should return empty dict initially
	assert_true(active.is_empty(), "Should return empty dict when no active ghost")
