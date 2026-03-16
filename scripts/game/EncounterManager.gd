# EncounterManager.gd — Orchestrates the encounter loop: DROP → RESULT → BOARD phases
extends Node
class_name EncounterManager

## Encounter phases
enum Phase { DROP, RESULT, BOARD, ENEMY_TURN, VICTORY, DEFEAT }

## Signals
signal phase_changed(new_phase: Phase)

## Current phase
var _current_phase: Phase = Phase.BOARD

## Ball tracking
var _balls_in_play: Array[Node] = []
var _balls_dropped: int = 0
var _total_balls_to_drop: int = 0

## Drop results accumulator
var _drop_results: Dictionary = {
	"damage": 0,
	"healing": 0,
	"gold": 0,
	"void_essence": 0,
	"chaos_count": 0,
}

## Pocket values (loaded from data)
var _pocket_values: Dictionary = {
	"damage": 10,
	"healing": 5,
	"gold": 5,
	"void_essence": 1,
}

## Current enemy reference
var _current_enemy: Node = null

## Board reference
var _board: Node2D = null

## Ball spawner reference
var _ball_spawner: Node2D = null


func _ready() -> void:
	# Get references to board and ball spawner
	_board = get_node_or_null("../Board")
	_ball_spawner = get_node_or_null("../Board/BallSpawner")

	# Connect to EventBus signals
	EventBus.ball_entered_pocket.connect(_on_ball_entered_pocket)
	EventBus.ball_lost.connect(_on_ball_lost)
	EventBus.ball_launched.connect(_on_ball_launched)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)

	# Defer enemy start to ensure all scripts are loaded
	call_deferred("_start_initial_encounter")


func _start_initial_encounter() -> void:
	# Load Corruptor scene
	var corruptor_scene := load("res://scenes/game/enemies/Corruptor.tscn") as PackedScene
	if corruptor_scene:
		start_encounter(corruptor_scene)
	else:
		print("Failed to load Corruptor scene")


func _process(_delta: float) -> void:
	# Check if all balls have settled or left the board
	if _current_phase == Phase.DROP and _balls_dropped >= _total_balls_to_drop:
		_check_drop_complete()


## Start a new encounter
func start_encounter(enemy_scene: PackedScene) -> void:
	# Spawn enemy
	if enemy_scene:
		_current_enemy = enemy_scene.instantiate()
		add_child(_current_enemy)

		# Position enemy UI (would be in a CanvasLayer)
		if _current_enemy.has_method("setup"):
			_current_enemy.setup()

	# Emit encounter started
	EventBus.encounter_started.emit("corruptor", {})

	# Start in BOARD phase
	_set_phase(Phase.BOARD)


## Begin DROP phase - player can now launch balls
func begin_drop_phase() -> void:
	if _current_phase != Phase.BOARD:
		return

	# Reset drop tracking
	_balls_in_play.clear()
	_balls_dropped = 0
	_total_balls_to_drop = RunState.ball_count

	# Reset results
	_drop_results = {
		"damage": 0,
		"healing": 0,
		"gold": 0,
		"void_essence": 0,
		"chaos_count": 0,
	}

	# Emit drop started
	EventBus.drop_started.emit(_total_balls_to_drop)

	# Enable ball spawning
	_set_phase(Phase.DROP)


## Register a ball that's been launched (called from BallSpawner)
func register_ball(ball: Node) -> void:
	if _current_phase != Phase.DROP:
		return

	_balls_dropped += 1
	_balls_in_play.append(ball)


## Called when ball enters a pocket
func _on_ball_entered_pocket(pocket: Node, ball: Node) -> void:
	if _current_phase != Phase.DROP:
		return

	# Remove ball from tracking
	if ball in _balls_in_play:
		_balls_in_play.erase(ball)

	# Determine pocket type and apply effect
	var pocket_type: String = _get_pocket_type(pocket)
	_apply_pocket_effect(pocket_type, ball)

	# Queue free the ball
	ball.queue_free()


## Called when ball is lost (fell off board)
func _on_ball_lost(ball: Node) -> void:
	if _current_phase != Phase.DROP:
		return

	# Remove from tracking
	if ball in _balls_in_play:
		_balls_in_play.erase(ball)


## Called when a ball is launched (from BallSpawner via EventBus.ball_launched)
func _on_ball_launched(ball: Node) -> void:
	# Track ball in play - balls are registered via register_ball() from BallSpawner
	pass


## Check if drop phase is complete
func _check_drop_complete() -> void:
	# Wait for all balls to be removed from play
	if _balls_in_play.is_empty():
		# All balls have finished
		_run_result_phase()


## Execute RESULT phase - calculate and apply results
func _run_result_phase() -> void:
	_set_phase(Phase.RESULT)

	# Apply damage to enemy
	if _current_enemy and _current_enemy.has_method("take_damage"):
		_current_enemy.take_damage(_drop_results["damage"])

	# Apply healing to stability
	if _drop_results["healing"] > 0:
		RunState.modify_stability(_drop_results["healing"])

	# Apply gold
	if _drop_results["gold"] > 0:
		RunState.gold += _drop_results["gold"]

	# Apply void essence
	if _drop_results["void_essence"] > 0:
		RunState.void_essence += _drop_results["void_essence"]

	# Handle chaos effects
	if _drop_results["chaos_count"] > 0:
		_trigger_chaos_effect(_drop_results["chaos_count"])

	# Emit drop ended
	EventBus.drop_ended.emit(_drop_results)

	# Increment total drops
	RunState.total_drops += 1

	# Check if enemy is defeated
	if _current_enemy and _current_enemy.has_method("is_defeated") and _current_enemy.is_defeated():
		_on_enemy_defeated(_current_enemy)
		return

	# Move to enemy turn
	_run_enemy_turn()


## Execute enemy turn
func _run_enemy_turn() -> void:
	_set_phase(Phase.ENEMY_TURN)

	EventBus.enemy_turn_start.emit(_current_enemy)

	# Wait a moment for enemy animation, then execute action
	await get_tree().create_timer(0.5).timeout

	if _current_enemy and _current_enemy.has_method("execute_turn"):
		_current_enemy.execute_turn()

	# Return to BOARD phase
	_set_phase(Phase.BOARD)


## Called when enemy is defeated
func _on_enemy_defeated(enemy: Node) -> void:
	_set_phase(Phase.VICTORY)

	# Update stats
	RunState.enemies_defeated += 1

	# Emit encounter ended
	EventBus.encounter_ended.emit("victory")

	# TODO: Trigger rewards/draft phase


## Handle player death (stability depleted)
func trigger_defeat() -> void:
	_set_phase(Phase.DEFEAT)

	# Emit run ended
	EventBus.run_ended.emit("stability_depleted", RunState.snapshot_board())

	# Show death screen
	# TODO: Show death screen UI


## Get pocket type from pocket node
func _get_pocket_type(pocket: Node) -> String:
	# Board.gd creates pockets with names like "Pocket_0", "Pocket_1", etc.
	# Pocket types cycle: 0=DAMAGE, 1=HEAL, 2=GOLD, 3=VOID, 4=CHAOS, 5=DAMAGE, etc.
	var pocket_name: String = pocket.name
	if "Pocket_" in pocket_name:
		var index: int = pocket_name.replace("Pocket_", "").to_int()
		match index % 5:
			0:
				return "damage"
			1:
				return "healing"
			2:
				return "gold"
			3:
				return "void"
			4:
				return "chaos"

	return "damage"


## Apply pocket effect to results
func _apply_pocket_effect(pocket_type: String, _ball: Node) -> void:
	match pocket_type:
		"damage":
			_drop_results["damage"] += _pocket_values["damage"]
		"healing":
			_drop_results["healing"] += _pocket_values["healing"]
		"gold":
			_drop_results["gold"] += _pocket_values["gold"]
		"void":
			_drop_results["void_essence"] += _pocket_values["void_essence"]
		"chaos":
			_drop_results["chaos_count"] += 1


## Trigger chaos effect
func _trigger_chaos_effect(count: int) -> void:
	# TODO: Implement chaos effects
	# For now, just emit the signal
	EventBus.chaos_drop_triggered.emit("chaos_" + str(count))
	print("Chaos effect triggered: ", count)


## Set current phase
func _set_phase(new_phase: Phase) -> void:
	_current_phase = new_phase
	phase_changed.emit(_current_phase)

	match _current_phase:
		Phase.DROP:
			print("EncounterManager: DROP phase")
		Phase.RESULT:
			print("EncounterManager: RESULT phase")
		Phase.BOARD:
			print("EncounterManager: BOARD phase")
		Phase.ENEMY_TURN:
			print("EncounterManager: ENEMY_TURN phase")
		Phase.VICTORY:
			print("EncounterManager: VICTORY")
		Phase.DEFEAT:
			print("EncounterManager: DEFEAT")


## Get current phase (for UI queries)
func get_current_phase() -> Phase:
	return _current_phase
