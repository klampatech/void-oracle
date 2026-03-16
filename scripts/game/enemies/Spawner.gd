# Spawner.gd — Enemy type: spawns enemy balls each turn
extends Node2D
class_name Spawner

## Enemy data loaded from JSON
var enemy_data: Dictionary = {}

## Current HP
var hp: int = 0
var max_hp: int = 0

## Enemy ID
var enemy_id: String = "spawner"

## Stability damage per turn
const STABILITY_DAMAGE := 5

## Number of balls to spawn per turn
const BALLS_PER_TURN := 2

## Ball scene to spawn
const BALL_SCENE := preload("res://scenes/game/Ball.tscn")

## Whether the enemy has been defeated
var _defeated: bool = false

## Control node for UI
@onready var _ui: Control = $EnemyUI


func _ready() -> void:
	# Load spawner data
	_load_data()


## Load enemy data from JSON
func _load_data() -> void:
	var file_path := "res://data/enemies/spawner.json"

	if not ResourceLoader.exists(file_path):
		push_warning("Enemy data file not found: " + file_path)
		# Set defaults
		max_hp = 70
		hp = 70
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("Failed to open enemy data file: " + file_path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_warning("Failed to parse enemy JSON: " + file_path)
		return

	enemy_data = json.get_data()
	enemy_id = enemy_data.get("id", "spawner")
	max_hp = enemy_data.get("max_hp", 70)
	hp = enemy_data.get("hp", max_hp)

	# Update UI if present
	_update_ui()


func _update_ui() -> void:
	if _ui:
		var hp_bar: ProgressBar = _ui.get_node_or_null("Panel/VBox/HPBar")
		if hp_bar:
			hp_bar.max_value = max_hp
			hp_bar.value = hp


## Take damage
func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)

	# Update UI
	_update_ui()

	if hp <= 0:
		_defeated = true
		die()


## Check if defeated
func is_defeated() -> bool:
	return _defeated


## Called when HP reaches 0
func die() -> void:
	EventBus.enemy_defeated.emit(self)

	# Queue free after a delay for death animation
	await get_tree().create_timer(0.5).timeout
	queue_free()


## Execute turn: spawn enemy balls, then damage stability
func execute_turn() -> void:
	if _defeated:
		return

	# Step 1: Spawn enemy balls
	_spawn_enemy_balls()

	# Step 2: Deal stability damage
	_run_attack()

	# Emit action signal
	var action := {
		"type": "spawn_and_attack",
		"balls_spawned": BALLS_PER_TURN,
		"damage": STABILITY_DAMAGE,
	}
	EventBus.enemy_action.emit(self, action)


## Spawn enemy balls at the top of the board
func _spawn_enemy_balls() -> void:
	# Find board boundaries
	var viewport_size := get_viewport_rect().size
	var board_width := viewport_size.x
	var spawn_y := 50.0  # Near top of board

	# Spawn multiple balls with slight position variation
	for i in range(BALLS_PER_TURN):
		# Calculate random x position within board bounds
		var random_x := randf_range(50, board_width - 50)
		var spawn_pos := Vector2(random_x, spawn_y)

		# Spawn the ball
		_spawn_single_ball(spawn_pos)


## Spawn a single enemy ball
func _spawn_single_ball(spawn_pos: Vector2) -> void:
	if not BALL_SCENE:
		push_warning("Ball scene not found")
		return

	# Instantiate ball
	var ball: RigidBody2D = BALL_SCENE.instantiate()
	ball.global_position = spawn_pos

	# Add to scene tree - find PhysicsWorld or Board node
	var board := get_tree().get_first_node_in_group("board")
	if board:
		var physics_world := board.get_node_or_null("PhysicsWorld")
		if physics_world:
			physics_world.add_child(ball)
		else:
			board.add_child(ball)
	else:
		get_tree().root.add_child(ball)

	# Mark as enemy ball (won't give rewards)
	ball.add_to_group("enemy_ball")

	# Give downward velocity
	ball.linear_velocity = Vector2(randf_range(-50, 50), randf_range(100, 200))

	# Emit signal for tracking
	EventBus.enemy_ball_spawned.emit(ball)


## Deal stability damage to player
func _run_attack() -> void:
	RunState.modify_stability(-STABILITY_DAMAGE)


## Get intent display text
func get_intent_text() -> String:
	return enemy_data.get("intent_display", "Will spawn enemy balls")


## Get current HP
func get_hp() -> int:
	return hp


## Get max HP
func get_max_hp() -> int:
	return max_hp


## Get HP as percentage (0.0 - 1.0)
func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)
