# OraclePeg.gd — Oracle peg type
extends BasePeg

## Ball scene to spawn
const BALL_SCENE_PATH := "res://scenes/game/Ball.tscn"
var _ball_scene: PackedScene


func _ready() -> void:
	peg_type = PegType.ORACLE
	# Preload ball scene
	_ball_scene = load(BALL_SCENE_PATH) as PackedScene
	super._ready()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return

	# M1: Ball splitting disabled for physics sandbox milestone
	# This causes exponential ball multiplication and performance issues
	# TODO: Re-enable for M2+ with proper ball count limits
	#
	# var ball := body as RigidBody2D
	# if ball and ball.linear_velocity.length() > 0:
	# 	call_deferred("_spawn_split_ball_deferred", body, _calculate_split_velocity(ball.linear_velocity, 15.0))
	# 	call_deferred("_spawn_split_ball_deferred", body, _calculate_split_velocity(ball.linear_velocity, -15.0))

	# Always emit the peg hit signal
	hit_count += 1
	EventBus.peg_hit.emit(self, body)


func _calculate_split_velocity(velocity: Vector2, angle_offset: float) -> Vector2:
	var angle_rad := deg_to_rad(angle_offset)
	var direction := velocity.normalized()
	var new_direction := direction.rotated(angle_rad)
	return new_direction * velocity.length()


func _spawn_split_ball(original_ball: Node, velocity: Vector2, angle_offset: float) -> void:
	if not _ball_scene:
		return

	# Calculate new velocity with angle offset
	var new_velocity := _calculate_split_velocity(velocity, angle_offset)

	# Defer physics operations to avoid "Can't change this state while flushing queries"
	# This happens because we're in a collision callback
	_spawn_split_ball_deferred(original_ball, new_velocity)


func _spawn_split_ball_deferred(original_ball: Node, new_velocity: Vector2) -> void:
	# Create new ball
	var new_ball := _ball_scene.instantiate() as RigidBody2D
	if not new_ball:
		return

	# Position at the original ball's position
	new_ball.global_position = original_ball.global_position

	# Add to parent (same parent as original ball)
	original_ball.get_parent().add_child(new_ball)

	# Apply the new velocity
	new_ball.linear_velocity = new_velocity

	# Make sure the new ball is in the "ball" group
	new_ball.add_to_group("ball")
