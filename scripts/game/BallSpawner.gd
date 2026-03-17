# BallSpawner.gd — Spawns balls at top of board with aim line
extends Node2D
class_name BallSpawner

## Ball scene to spawn
const BALL_SCENE := preload("res://scenes/game/Ball.tscn")

## Launch velocity (px/s)
@export var launch_velocity: float = 500.0

## Default ball count
const DEFAULT_BALL_COUNT := 1

## Spawn position (relative to board)
var _spawn_position := Vector2(300, 50)

## Reference to EncounterManager for ball tracking
var _encounter_manager: Node = null


func _ready() -> void:
	# RunState.ball_count is initialized in autoload
	# Get encounter manager reference
	_encounter_manager = get_node_or_null("../EncounterManager")


func _add_ball_to_tracking(ball: RigidBody2D) -> void:
	if _encounter_manager and _encounter_manager.has_method("register_ball"):
		_encounter_manager.register_ball(ball)


func _process(_delta: float) -> void:
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_launch_ball(event.position)


func _launch_ball(mouse_pos: Vector2) -> void:
	# Calculate direction from spawn to mouse
	var direction := (mouse_pos - global_position).normalized()

	# Apply Cursed Flame speed boost if active (Tier 2: +20%)
	var speed_multiplier := 1.0
	if SynergyEffects:
		speed_multiplier = SynergyEffects.get_ball_speed_multiplier()

	var velocity := direction * launch_velocity * speed_multiplier

	# Instantiate ball
	var ball: RigidBody2D = BALL_SCENE.instantiate()
	ball.global_position = _spawn_position

	# Apply velocity
	ball.linear_velocity = velocity

	# Check if this should be a Void Ball (Void Choir Tier 1+)
	if SynergyEffects and SynergyEffects.check_and_convert_to_void_ball():
		ball.set("is_void_ball", true)
		print("[BallSpawner] Spawned Void Ball")

	# Add to scene tree
	get_tree().root.add_child(ball)

	# Track ball for drop phase
	_add_ball_to_tracking(ball)

	# Emit ball launched signal
	EventBus.ball_launched.emit(ball)


func _draw() -> void:
	# Draw aim line to mouse position
	var mouse_pos := get_global_mouse_position()
	var direction := (mouse_pos - global_position).normalized()
	var end_point := global_position + direction * 200

	# Draw aim line
	draw_line(Vector2.ZERO, end_point - global_position, Color.WHITE, 2.0)

	# Draw spawn point indicator
	draw_circle(_spawn_position - global_position, 8, Color.CYAN)
