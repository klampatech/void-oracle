# test_meta_state.gd — Unit tests for MetaState
extends GutTest

var _meta_state: Node = null

func before_each() -> void:
	# Create MetaState instance
	_meta_state = load("res://scripts/autoloads/MetaState.gd").new()
	add_child(_meta_state)

func after_each() -> void:
	if _meta_state and is_instance_valid(_meta_state):
		_meta_state.queue_free()

	# Clean up test files if they exist
	_cleanup_test_file("user://void_oracle/meta_save.json")
	_cleanup_test_file("user://void_oracle/run_history.json")


func _cleanup_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var dir = DirAccess.open(path.get_base_dir())
		if dir:
			dir.remove(path)


# ── Test class has required methods ─────────────────────────
func test_has_load_data_method() -> void:
	assert_true(_meta_state.has_method("load_data"), "MetaState should have load_data method")

func test_has_save_data_method() -> void:
	assert_true(_meta_state.has_method("save_data"), "MetaState should have save_data method")

func test_has_record_run_method() -> void:
	assert_true(_meta_state.has_method("record_run"), "MetaState should have record_run method")

func test_has_get_void_shards_method() -> void:
	assert_true(_meta_state.has_method("get_void_shards"), "MetaState should have get_void_shards method")

func test_has_unlock_peg_method() -> void:
	assert_true(_meta_state.has_method("unlock_peg"), "MetaState should have unlock_peg method")

func test_has_complete_run_method() -> void:
	assert_true(_meta_state.has_method("complete_run"), "MetaState should have complete_run method")


# ── Test constants ───────────────────────────────────────
func test_save_version_constant() -> void:
	# SAVE_VERSION should be "1.0"
	assert_eq(_meta_state.SAVE_VERSION, "1.0", "SAVE_VERSION should be 1.0")


# ── Test record_run ────────────────────────────────────────
func test_record_run_creates_history() -> void:
	_meta_state.record_run(2, 15, false, "naturalist", 5)

	var history = _meta_state.get_run_history()
	assert_eq(history.size(), 1, "Should have 1 run recorded")

	var run = history[0]
	assert_eq(run.get("zone_reached"), 2, "Zone should be recorded")
	assert_eq(run.get("total_drops"), 15, "Drops should be recorded")
	assert_eq(run.get("is_victory"), false, "Should be defeat")
	assert_eq(run.get("oracle_class"), "naturalist", "Class should be recorded")
	assert_eq(run.get("void_essence"), 5, "Void essence should be recorded")


func test_record_run_victory() -> void:
	_meta_state.record_run(3, 20, true, "doomsayer", 10)

	var history = _meta_state.get_run_history()
	assert_eq(history.size(), 1, "Should have 1 run recorded")

	var run = history[0]
	assert_eq(run.get("is_victory"), true, "Should be victory")


func test_record_run_updates_best() -> void:
	# Record a losing run first
	_meta_state.record_run(1, 10, false, "wanderer", 0)

	# Record a winning run
	_meta_state.record_run(3, 25, true, "architect", 15)

	var best = _meta_state.get_best_run()
	assert_eq(best.get("zone_reached"), 3, "Best run should be zone 3")


func test_record_run_multiple_runs() -> void:
	_meta_state.record_run(1, 5, false, "wanderer", 0)
	_meta_state.record_run(2, 10, false, "naturalist", 0)
	_meta_state.record_run(3, 20, true, "doomsayer", 0)

	var history = _meta_state.get_run_history()
	assert_eq(history.size(), 3, "Should have 3 runs recorded")


# ── Test get methods ────────────────────────────────────────
func test_get_run_history() -> void:
	var history = _meta_state.get_run_history()
	assert_true(history is Array, "Should return an array")


func test_get_best_run() -> void:
	var best = _meta_state.get_best_run()
	assert_true(best is Dictionary, "Should return a dictionary")


func test_get_total_runs() -> void:
	# Runs completed should be tracked
	var total = _meta_state.get_total_runs()
	assert_eq(total, 0, "Should return 0 initially")


# ── Test get void shards ───────────────────────────────────
func test_get_void_shards() -> void:
	var shards = _meta_state.get_void_shards()
	assert_eq(shards, 0, "Should return 0 initially")
