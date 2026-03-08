# Ball.gd — Physics ball that falls and collides with pegs
extends RigidBody2D
class_name Ball

## Ball velocity for debug display
var _last_velocity := Vector2.ZERO

## Trail positions (last 20 positions)
var _trail_positions: Array[Vector2] = []
const TRAIL_LENGTH := 20

## Line2D for trail rendering
var _trail_line: Line2D


func _ready() -> void:
	# Join ball group for collision detection
	add_to_group("ball")

	# Create Line2D for trail
	_trail_line = Line2D.new()
	_trail_line.name = "Trail"
	_trail_line.width = 6.0
	_trail_line.default_color = Color(0.4, 0.6, 0.9, 0.8)
	_trail_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail_line.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Create gradient for fade effect
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 1.0, 0.0))   # Transparent at tail (white)
	gradient.add_point(0.5, Color(0.7, 0.8, 0.95, 0.4)) # Mid trail
	gradient.add_point(1.0, Color(0.4, 0.6, 0.9, 1.0))  # Opaque at head (ghost-blue)
	_trail_line.gradient = gradient

	# Add to scene at ball position
	get_parent().add_child(_trail_line)
	_trail_line.global_position = global_position

	# Initialize trail with current position
	for i in range(TRAIL_LENGTH):
		_trail_positions.append(global_position)


func _physics_process(_delta: float) -> void:
	_last_velocity = linear_velocity

	# Update trail positions
	_trail_positions.push_front(global_position)
	if _trail_positions.size() > TRAIL_LENGTH:
		_trail_positions.pop_back()

	# Keep Line2D at current ball position
	_trail_line.global_position = global_position

	# Update Line2D points (local coordinates from Line2D position)
	_trail_line.clear_points()
	for i in range(_trail_positions.size()):
		var offset = _trail_positions[i] - global_position
		_trail_line.add_point(offset)


func _exit_tree() -> void:
	# Clean up trail when ball is removed
	if _trail_line and is_instance_valid(_trail_line):
		_trail_line.queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Check if we hit a peg (any StaticBody2D in the peg group)
	if body.is_in_group("peg"):
		EventBus.peg_hit.emit(body, self)


func get_velocity() -> Vector2:
	return _last_velocity
