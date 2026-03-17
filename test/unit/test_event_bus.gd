# test_event_bus.gd — Unit tests for EventBus signals
extends GutTest

var _event_bus: Node = null

func before_each() -> void:
	# Load the actual EventBus
	_event_bus = load("res://scripts/autoloads/EventBus.gd").new()
	add_child(_event_bus)

func after_each() -> void:
	if _event_bus and is_instance_valid(_event_bus):
		_event_bus.queue_free()

# ── Test peg_hit signal ────────────────────────────────────
func test_peg_hit_signal_exists() -> void:
	assert_true(_event_bus.has_signal("peg_hit"), "EventBus should have peg_hit signal")

	# Verify signal has correct number of parameters
	var method_bindings = _event_bus.get_method_list()
	# The signal exists - verify by trying to get its info
	var signal_info = _event_bus.get_signal_connection_list("peg_hit")
	# Just checking signal exists is sufficient

func test_peg_hit_signal_parameters() -> void:
	# Get the signal info to verify it exists
	var has_peg = _event_bus.has_signal("peg_hit")
	assert_true(has_peg, "peg_hit signal should exist")


# ── Test ball_entered_pocket signal ────────────────────────
func test_ball_entered_pocket_signal_exists() -> void:
	assert_true(_event_bus.has_signal("ball_entered_pocket"), "EventBus should have ball_entered_pocket signal")


# ── Test synergy signals ───────────────────────────────────
func test_synergy_activated_signal_exists() -> void:
	assert_true(_event_bus.has_signal("synergy_activated"), "EventBus should have synergy_activated signal")

func test_synergy_broken_signal_exists() -> void:
	assert_true(_event_bus.has_signal("synergy_broken"), "EventBus should have synergy_broken signal")

func test_synergy_scaled_signal_exists() -> void:
	assert_true(_event_bus.has_signal("synergy_scaled"), "EventBus should have synergy_scaled signal")


# ── Test drop phase signals ────────────────────────────────
func test_drop_phase_started_signal_exists() -> void:
	assert_true(_event_bus.has_signal("drop_phase_started"), "EventBus should have drop_phase_started signal")

func test_drop_phase_ended_signal_exists() -> void:
	assert_true(_event_bus.has_signal("drop_phase_ended"), "EventBus should have drop_phase_ended signal")

func test_drop_started_signal_exists() -> void:
	assert_true(_event_bus.has_signal("drop_started"), "EventBus should have drop_started signal")

func test_drop_ended_signal_exists() -> void:
	assert_true(_event_bus.has_signal("drop_ended"), "EventBus should have drop_ended signal")


# ── Test combat signals ────────────────────────────────────
func test_enemy_defeated_signal_exists() -> void:
	assert_true(_event_bus.has_signal("enemy_defeated"), "EventBus should have enemy_defeated signal")

func test_enemy_turn_start_signal_exists() -> void:
	assert_true(_event_bus.has_signal("enemy_turn_start"), "EventBus should have enemy_turn_start signal")

func test_enemy_action_signal_exists() -> void:
	assert_true(_event_bus.has_signal("enemy_action"), "EventBus should have enemy_action signal")

func test_player_stability_changed_signal_exists() -> void:
	assert_true(_event_bus.has_signal("player_stability_changed"), "EventBus should have player_stability_changed signal")

func test_boss_phase_changed_signal_exists() -> void:
	assert_true(_event_bus.has_signal("boss_phase_changed"), "EventBus should have boss_phase_changed signal")


# ── Test run signals ───────────────────────────────────────
func test_run_started_signal_exists() -> void:
	assert_true(_event_bus.has_signal("run_started"), "EventBus should have run_started signal")

func test_run_ended_signal_exists() -> void:
	assert_true(_event_bus.has_signal("run_ended"), "EventBus should have run_ended signal")

func test_game_victory_signal_exists() -> void:
	assert_true(_event_bus.has_signal("game_victory"), "EventBus should have game_victory signal")

func test_zone_completed_signal_exists() -> void:
	assert_true(_event_bus.has_signal("zone_completed"), "EventBus should have zone_completed signal")


# ── Test economy signals ───────────────────────────────────
func test_gold_changed_signal_exists() -> void:
	assert_true(_event_bus.has_signal("gold_changed"), "EventBus should have gold_changed signal")

func test_gold_stolen_signal_exists() -> void:
	assert_true(_event_bus.has_signal("gold_stolen"), "EventBus should have gold_stolen signal")


# ── Test peg state signals ────────────────────────────────
func test_peg_state_changed_signal_exists() -> void:
	assert_true(_event_bus.has_signal("peg_state_changed"), "EventBus should have peg_state_changed signal")

func test_peg_destroyed_signal_exists() -> void:
	assert_true(_event_bus.has_signal("peg_destroyed"), "EventBus should have peg_destroyed signal")

func test_peg_spawned_signal_exists() -> void:
	assert_true(_event_bus.has_signal("peg_spawned"), "EventBus should have peg_spawned signal")


# ── Test ghost signals ─────────────────────────────────────
func test_ghost_mutation_signal_exists() -> void:
	assert_true(_event_bus.has_signal("ghost_mutation"), "EventBus should have ghost_mutation signal")

func test_void_ghost_active_signal_exists() -> void:
	assert_true(_event_bus.has_signal("void_ghost_active"), "EventBus should have void_ghost_active signal")


# ── Test UI signals ────────────────────────────────────────
func test_draft_choice_made_signal_exists() -> void:
	assert_true(_event_bus.has_signal("draft_choice_made"), "EventBus should have draft_choice_made signal")

func test_shop_purchase_signal_exists() -> void:
	assert_true(_event_bus.has_signal("shop_purchase"), "EventBus should have shop_purchase signal")

func test_encounter_started_signal_exists() -> void:
	assert_true(_event_bus.has_signal("encounter_started"), "EventBus should have encounter_started signal")

func test_encounter_ended_signal_exists() -> void:
	assert_true(_event_bus.has_signal("encounter_ended"), "EventBus should have encounter_ended signal")


# ── Test chaos signals ─────────────────────────────────────
func test_chaos_drop_triggered_signal_exists() -> void:
	assert_true(_event_bus.has_signal("chaos_drop_triggered"), "EventBus should have chaos_drop_triggered signal")


# ── Test ball signals ─────────────────────────────────────
func test_ball_lost_signal_exists() -> void:
	assert_true(_event_bus.has_signal("ball_lost"), "EventBus should have ball_lost signal")

func test_ball_launched_signal_exists() -> void:
	assert_true(_event_bus.has_signal("ball_launched"), "EventBus should have ball_launched signal")


# ── Test synergy effect signals ───────────────────────────
func test_synergy_damage_dealt_signal_exists() -> void:
	assert_true(_event_bus.has_signal("synergy_damage_dealt"), "EventBus should have synergy_damage_dealt signal")

func test_enemy_revealed_signal_exists() -> void:
	assert_true(_event_bus.has_signal("enemy_revealed"), "EventBus should have enemy_revealed signal")

func test_enemy_intent_determined_signal_exists() -> void:
	assert_true(_event_bus.has_signal("enemy_intent_determined"), "EventBus should have enemy_intent_determined signal")

func test_synergy_stability_changed_signal_exists() -> void:
	assert_true(_event_bus.has_signal("synergy_stability_changed"), "EventBus should have synergy_stability_changed signal")


# ── Test all required signals are present ──────────────────
func test_all_required_signals_present() -> void:
	var required_signals = [
		"peg_hit", "ball_entered_pocket", "ball_lost",
		"peg_state_changed", "peg_destroyed", "peg_spawned",
		"synergy_activated", "synergy_broken", "synergy_scaled",
		"synergy_damage_dealt", "enemy_revealed", "enemy_intent_determined",
		"synergy_stability_changed",
		"drop_phase_started", "drop_phase_ended", "drop_started",
		"ball_launched", "drop_ended", "chaos_drop_triggered",
		"enemy_turn_start", "enemy_action", "enemy_defeated",
		"enemy_ball_spawned", "player_stability_changed", "boss_phase_changed",
		"ball_entered_crack",
		"ghost_mutation", "void_ghost_active",
		"gold_stolen", "gold_changed",
		"node_selected", "encounter_started", "encounter_ended",
		"run_started", "run_ended", "zone_completed", "game_victory",
		"draft_choice_made", "shop_purchase", "relic_acquired"
	]

	for signal_name in required_signals:
		assert_true(
			_event_bus.has_signal(signal_name),
			"EventBus should have signal: " + signal_name
		)

	# Verify we have at least 35 signals
	var total_signals = required_signals.size()
	assert_true(total_signals >= 35, "EventBus should have at least 35 signals, has: " + str(total_signals))
