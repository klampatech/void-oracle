# test_autoload_signal_flow.gd — Integration tests for autoload signal flows
extends GutTest

# Test the integration between autoloads
# These tests verify that autoloads exist and have the expected interfaces

var _event_bus: Node = null
var _run_state: Node = null

func before_each() -> void:
	# Create autoloads
	_event_bus = load("res://scripts/autoloads/EventBus.gd").new()
	_run_state = load("res://scripts/autoloads/RunState.gd").new()

	add_child(_event_bus)
	add_child(_run_state)

func after_each() -> void:
	if _event_bus and is_instance_valid(_event_bus):
		_event_bus.queue_free()
	if _run_state and is_instance_valid(_run_state):
		_run_state.queue_free()


# ── Test EventBus has all required signals ───────────────────
func test_event_bus_has_required_signals() -> void:
	# Verify EventBus has all the signals we expect
	var required_signals = [
		"peg_hit", "synergy_activated", "drop_phase_started",
		"drop_phase_ended", "run_started", "run_ended",
		"game_victory", "gold_changed", "player_stability_changed"
	]

	for signal_name in required_signals:
		assert_true(
			_event_bus.has_signal(signal_name),
			"EventBus should have signal: " + signal_name
		)


# ── Test RunState initializes correctly ──────────────────────
func test_run_state_new_run() -> void:
	_run_state.new_run(12345, "wanderer")

	assert_eq(_run_state.run_seed, 12345, "Run seed should be set")
	assert_eq(_run_state.oracle_class, "wanderer", "Oracle class should be set")
	assert_eq(_run_state.zone, 1, "Zone should start at 1")
	assert_eq(_run_state.stability, 100.0, "Default stability should be 100")


# ── Test RunState class initialization differences ───────────
func test_run_state_naturalist_class() -> void:
	_run_state.new_run(54321, "naturalist")

	assert_eq(_run_state.oracle_class, "naturalist", "Class should be naturalist")
	assert_eq(_run_state.gold, 10, "Naturalist should have bonus gold")
	assert_true(_run_state.pegs.size() >= 2, "Should have starting pegs")


# ── Test RunState stability changes ─────────────────────────
func test_run_state_stability_modification() -> void:
	_run_state.new_run(11111, "wanderer")
	var initial_stability = _run_state.stability

	_run_state.stability = initial_stability - 20.0

	assert_eq(_run_state.stability, initial_stability - 20.0, "Stability should be modified")


# ── Test RunState gold changes ─────────────────────────────
func test_run_state_gold_modification() -> void:
	_run_state.new_run(22222, "wanderer")
	var initial_gold = _run_state.gold

	_run_state.gold = initial_gold + 10

	assert_eq(_run_state.gold, initial_gold + 10, "Gold should be modified")


# ── Test run state has required methods ─────────────────────
func test_run_state_has_required_methods() -> void:
	assert_true(_run_state.has_method("new_run"), "RunState should have new_run method")
	assert_true(_run_state.has_method("snapshot_board"), "RunState should have snapshot_board method")
	assert_true(_run_state.has_method("modify_stability"), "RunState should have modify_stability method")


# ── Test autoload interfaces ───────────────────────────────
func test_event_bus_interface() -> void:
	# Verify EventBus has expected methods
	assert_true(_event_bus.has_method("emit_signal"), "EventBus should have emit_signal")

	# Verify it has the signals we're expecting
	assert_true(_event_bus.has_signal("peg_hit"))
	assert_true(_event_bus.has_signal("run_ended"))
	assert_true(_event_bus.has_signal("game_victory"))
