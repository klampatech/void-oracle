# MockEventBus.gd — Mock EventBus for testing
# Provides stub signals for unit tests
extends Node

var _signal_history: Dictionary = {}

# Stub all required signals
signal peg_hit(peg, ball)
signal ball_entered_pocket(pocket, ball)
signal ball_lost(ball)
signal peg_state_changed(peg, old_state, new_state)
signal peg_destroyed(peg)
signal peg_spawned(peg, position)
signal synergy_activated(synergy_id, peg_count)
signal synergy_broken(synergy_id)
signal synergy_scaled(synergy_id, new_count)
signal synergy_damage_dealt(damage, source)
signal enemy_revealed()
signal enemy_intent_determined(intent_text)
signal synergy_stability_changed(amount, source)
signal drop_phase_started()
signal drop_phase_ended()
signal drop_started(ball_count)
signal ball_launched(ball)
signal drop_ended(results)
signal chaos_drop_triggered(chaos_type)
signal enemy_turn_start(enemy)
signal enemy_action(enemy, action)
signal enemy_defeated(enemy)
signal enemy_ball_spawned(ball)
signal player_stability_changed(new_value, delta)
signal boss_phase_changed(phase)
signal ball_entered_crack(ball, effect_type)
signal ghost_mutation(peg_count)
signal void_ghost_active(is_active)
signal gold_stolen(amount)
signal gold_changed(new_value, delta)
signal node_selected(map_node)
signal encounter_started(encounter_type, data)
signal encounter_ended(result)
signal run_started(oracle_class)
signal run_ended(cause, board_state)
signal zone_completed(zone_number)
signal game_victory()
signal draft_choice_made(peg_type)
signal shop_purchase(item_id, cost)
signal relic_acquired(relic_id)

func _ready() -> void:
	# Initialize signal history
	_signal_history = {}

func clear_history() -> void:
	_signal_history.clear()

func was_signal_emitted(signal_name: String) -> bool:
	return _signal_history.has(signal_name) and not _signal_history[signal_name].is_empty()

func get_signal_emit_count(signal_name: String) -> int:
	return _signal_history.get(signal_name, []).size()

func _emit_wrapper(signal_name: String) -> void:
	if not _signal_history.has(signal_name):
		_signal_history[signal_name] = []
	_signal_history[signal_name].append({
		"args": [],
		"time": Time.get_ticks_msec()
	})
	# Call the actual emit would require using call_deferred or direct call
	# For testing purposes, we just track the calls
