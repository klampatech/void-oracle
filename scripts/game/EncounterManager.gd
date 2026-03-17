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

## Draft system reference
var _draft_system: Node = null

## Draft UI reference
var _draft_ui: Node = null

## Pending chaos effects to apply on next drop
## Each effect is a Dictionary: {type: String, value: int, description: String}
var _pending_chaos_effects: Array[Dictionary] = []

## Chaos effect types
const CHAOS_EFFECTS: Array[String] = [
	"extra_gold",
	"extra_damage",
	"extra_balls",
	"stability_boost",
	"void_bonus",
	"instability",
]

## Shop system reference
var _shop_system: Node = null

## Shop UI reference
var _shop_ui: Node = null

## Encounter counter for shop spawning
var _encounter_count: int = 0

## Shop appears every N encounters
const ENCOUNTERS_PER_SHOP: int = 4


func _ready() -> void:
	# Get references to board and ball spawner
	_board = get_node_or_null("../Board")
	_ball_spawner = get_node_or_null("../Board/BallSpawner")

	# Connect to EventBus signals
	EventBus.ball_entered_pocket.connect(_on_ball_entered_pocket)
	EventBus.ball_lost.connect(_on_ball_lost)
	EventBus.ball_launched.connect(_on_ball_launched)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.synergy_damage_dealt.connect(_on_synergy_damage_dealt)
	EventBus.synergy_stability_changed.connect(_on_synergy_stability_changed)

	# Get draft system reference
	_draft_system = get_tree().get_first_node_in_group("draft_system")
	if not _draft_system:
		# Try to create draft system if not already in scene
		var DraftSystemScript = load("res://scripts/game/systems/DraftSystem.gd")
		if DraftSystemScript:
			_draft_system = DraftSystemScript.new()
			_draft_system.name = "DraftSystem"
			_draft_system.add_to_group("draft_system")
			add_child(_draft_system)

	# Get draft UI reference
	_draft_ui = get_tree().get_first_node_in_group("draft_ui")
	if not _draft_ui:
		_draft_ui = get_node_or_null("../DraftUI")

	# Get shop system reference
	_shop_system = get_tree().get_first_node_in_group("shop_system")
	if not _shop_system:
		_shop_system = get_node_or_null("../ShopSystem")

	# Get shop UI reference
	_shop_ui = get_node_or_null("../ShopUI")

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

	# Apply pending chaos effects
	_apply_pending_chaos_effects()

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


## Apply pending chaos effects from previous drops
func _apply_pending_chaos_effects() -> void:
	if _pending_chaos_effects.is_empty():
		return

	print("[EncounterManager] Applying %d pending chaos effects" % _pending_chaos_effects.size())

	for effect in _pending_chaos_effects:
		match effect["type"]:
			"extra_gold":
				RunState.gold += effect["value"]
				_drop_results["gold"] += effect["value"]
				print("[EncounterManager] Chaos: +%d gold" % effect["value"])
			"extra_damage":
				_drop_results["damage"] += effect["value"]
				print("[EncounterManager] Chaos: +%d damage" % effect["value"])
			"extra_balls":
				_total_balls_to_drop += effect["value"]
				print("[EncounterManager] Chaos: +%d balls" % effect["value"])
			"stability_boost":
				RunState.stability = min(RunState.stability + effect["value"], RunState.max_stability)
				_drop_results["healing"] += effect["value"]
				print("[EncounterManager] Chaos: +%d stability" % effect["value"])
			"void_bonus":
				RunState.void_essence += effect["value"]
				_drop_results["void_essence"] += effect["value"]
				print("[EncounterManager] Chaos: +%d void essence" % effect["value"])
			"instability":
				RunState.stability = max(RunState.stability - effect["value"], 0.0)
				print("[EncounterManager] Chaos: -%d stability" % effect["value"])
				# Emit stability changed event
				EventBus.player_stability_changed.emit(RunState.stability, RunState.max_stability)

	# Clear pending effects after applying
	_pending_chaos_effects.clear()


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

	# Apply damage to enemy (with Cursed Flame multiplier if active)
	var damage_multiplier := 1.0
	if SynergyEffects:
		damage_multiplier = SynergyEffects.get_damage_multiplier()
	var final_damage := int(_drop_results["damage"] * damage_multiplier)

	if _current_enemy and _current_enemy.has_method("take_damage"):
		_current_enemy.take_damage(final_damage)
		if damage_multiplier > 1.0:
			print("[EncounterManager] Cursed Flame doubled damage: ", _drop_results["damage"], " -> ", final_damage)

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


## Called when synergy deals damage (e.g., Necrotic Bloom, Profane Eye)
func _on_synergy_damage_dealt(damage: int, source: String) -> void:
	if _current_enemy and _current_enemy.has_method("take_damage"):
		_current_enemy.take_damage(damage)
		print("[EncounterManager] Synergy ", source, " dealt ", damage, " damage")


## Called when synergy provides stability (e.g., Bleeding Architecture, Necrotic Bloom regen)
func _on_synergy_stability_changed(amount: int, source: String) -> void:
	RunState.modify_stability(amount)
	print("[EncounterManager] Synergy ", source, " changed stability by ", amount)


## Called when enemy is defeated
func _on_enemy_defeated(enemy: Node) -> void:
	_set_phase(Phase.VICTORY)

	# Update stats
	RunState.enemies_defeated += 1
	_encounter_count += 1

	# Emit encounter ended
	EventBus.encounter_ended.emit("victory")

	# Check if it's time for a shop (every ~4 encounters)
	if _encounter_count > 0 and _encounter_count % ENCOUNTERS_PER_SHOP == 0:
		_show_shop()
	else:
		# Trigger draft phase
		_start_draft_phase()


## Start draft phase after victory
func _start_draft_phase() -> void:
	if _draft_system and _draft_system.has_method("generate_offerings"):
		var offerings = _draft_system.generate_offerings()

		# Find DraftUI and show it
		if _draft_ui and _draft_ui.has_method("show_draft"):
			_draft_ui.show_draft(offerings)

		# Enable placement mode
		_set_phase(Phase.BOARD)


## Show shop UI
func _show_shop() -> void:
	if _shop_ui and _shop_ui.has_method("show_shop"):
		_shop_ui.show_shop()

	# Set phase to BOARD (waiting for shop to close)
	_set_phase(Phase.BOARD)


## Handle player death (stability depleted)
func trigger_defeat() -> void:
	_set_phase(Phase.DEFEAT)

	# Emit run ended
	EventBus.run_ended.emit("stability_depleted", RunState.snapshot_board())

	# Show death screen (handled by DeathScreen listening to run_ended signal)


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
func _apply_pocket_effect(pocket_type: String, ball: Node) -> void:
	var is_void_ball: bool = false
	if ball.has_method("get_is_void_ball"):
		is_void_ball = ball.get_is_void_ball()
	elif ball.get("is_void_ball") != null:
		is_void_ball = ball.get("is_void_ball")
	var extra_pocket = false

	# Check for Void Choir extra pocket (Tier 2)
	if is_void_ball and SynergyEffects and SynergyEffects.should_void_ball_extra_pocket():
		extra_pocket = true

	match pocket_type:
		"damage":
			_drop_results["damage"] += _pocket_values["damage"]
		"healing":
			_drop_results["healing"] += _pocket_values["healing"]
		"gold":
			_drop_results["gold"] += _pocket_values["gold"]
		"void":
			var void_amount = _pocket_values["void_essence"]
			# Void Choir Tier 2: Double void essence from void balls
			if is_void_ball:
				void_amount *= 2
			_drop_results["void_essence"] += void_amount
		"chaos":
			_drop_results["chaos_count"] += 1

	# Apply extra pocket effect for Void Choir Tier 2
	if extra_pocket:
		print("[EncounterManager] Void Choir extra pocket triggered")
		# Extra pocket gives gold + void
		_drop_results["gold"] += 3
		_drop_results["void_essence"] += 1


## Trigger chaos effect - applies random buff/debuff to the next drop
func _trigger_chaos_effect(count: int) -> void:
	for i in range(count):
		# Pick a random chaos effect
		var effect_type: String = CHAOS_EFFECTS.pick_random()
		var effect: Dictionary = _create_chaos_effect(effect_type)
		_pending_chaos_effects.append(effect)
		print("[EncounterManager] Chaos effect applied: ", effect["description"])
		EventBus.chaos_drop_triggered.emit(effect_type)


## Create a specific chaos effect
func _create_chaos_effect(effect_type: String) -> Dictionary:
	match effect_type:
		"extra_gold":
			var value: int = randi_range(5, 15)
			return {
				"type": "extra_gold",
				"value": value,
				"description": "Extra Gold +%d" % value,
			}
		"extra_damage":
			var value: int = randi_range(5, 10)
			return {
				"type": "extra_damage",
				"value": value,
				"description": "Damage Boost +%d" % value,
			}
		"extra_balls":
			var value: int = randi_range(1, 2)
			return {
				"type": "extra_balls",
				"value": value,
				"description": "Extra Ball +%d" % value,
			}
		"stability_boost":
			var value: int = randi_range(5, 10)
			return {
				"type": "stability_boost",
				"value": value,
				"description": "Stability +%d" % value,
			}
		"void_bonus":
			var value: int = randi_range(1, 3)
			return {
				"type": "void_bonus",
				"value": value,
				"description": "Void Essence +%d" % value,
			}
		"instability":
			var value: int = randi_range(5, 10)
			return {
				"type": "instability",
				"value": value,
				"description": "Stability -%d" % value,
			}
		_:
			return {
				"type": "unknown",
				"value": 0,
				"description": "Unknown effect",
			}


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
