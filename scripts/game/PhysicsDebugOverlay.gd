# PhysicsDebugOverlay.gd — Debug visualization for physics tuning
extends Node2D

## Debug overlay for physics visualization
## Toggle with F1 key

## Debug toggle state
var _debug_enabled := false

## Reference to board for accessing nodes
var _board: Node2D

## Colors for debug drawing
const COLOR_COLLISION := Color(1, 0, 0, 0.5)
const COLOR_PEG := Color(0, 1, 0, 0.5)
const COLOR_BALL := Color(0, 0.5, 1, 0.8)
const COLOR_VELOCITY := Color(1, 1, 0, 1)
const COLOR_WALL := Color(1, 0.5, 0, 0.5)


func _ready() -> void:
	# Get board reference (grandparent - CanvasLayer is child of Board)
	_board = get_parent().get_parent() as Node2D

	# Connect to EventBus.peg_hit for console logging
	EventBus.peg_hit.connect(_on_peg_hit)


func _input(event: InputEvent) -> void:
	# Toggle debug with F1
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_debug_enabled = not _debug_enabled
		visible = _debug_enabled
		if _debug_enabled:
			print("[DEBUG] Physics debug overlay enabled")
		else:
			print("[DEBUG] Physics debug overlay disabled")


func _process(_delta: float) -> void:
	# Redraw every frame when enabled
	if _debug_enabled:
		queue_redraw()


func _draw() -> void:
	if not _debug_enabled or not _board:
		return

	# Draw collision shapes
	_draw_collision_shapes()
	# Draw ball velocity vectors
	_draw_ball_velocities()
	# Draw peg hit counts
	_draw_peg_hit_counts()


func _draw_collision_shapes() -> void:
	if not _board:
		return

	# Get physics world
	var physics_world := _board.get_node_or_null("PhysicsWorld") as Node2D
	if not physics_world:
		return

	# Draw peg collision shapes
	var peg_container := physics_world.get_node_or_null("PegContainer") as Node2D
	if peg_container:
		for peg in peg_container.get_children():
			if peg is StaticBody2D:
				_draw_collision_shape(peg, COLOR_PEG)

	# Draw walls
	for wall_name in ["WallLeft", "WallRight", "WallTop", "WallBottom"]:
		var wall := physics_world.get_node_or_null(wall_name) as StaticBody2D
		if wall:
			_draw_collision_shape(wall, COLOR_WALL)

	# Draw pockets
	var pocket_row := physics_world.get_node_or_null("PocketRow") as Node2D
	if pocket_row:
		for pocket in pocket_row.get_children():
			if pocket is Area2D:
				_draw_area_shape(pocket, COLOR_COLLISION)


func _draw_collision_shape(body: StaticBody2D, color: Color) -> void:
	# Get collision shapes from the body
	for child in body.get_children():
		if child is CollisionShape2D:
			var shape: Shape2D = child.shape
			var transform: Transform2D = child.global_transform

			if shape is CircleShape2D:
				var circle_shape: CircleShape2D = shape as CircleShape2D
				var center: Vector2 = transform * Vector2.ZERO
				var radius: float = circle_shape.radius
				_draw_circle_outline(center, radius, color)
			elif shape is RectangleShape2D:
				var rect_shape: RectangleShape2D = shape as RectangleShape2D
				var center: Vector2 = transform * Vector2.ZERO
				var half_size: Vector2 = rect_shape.size / 2
				var rect: Rect2 = Rect2(center - half_size, rect_shape.size)
				_draw_rect_outline(rect, color)


func _draw_area_shape(area: Area2D, color: Color) -> void:
	for child in area.get_children():
		if child is CollisionShape2D:
			var shape: Shape2D = child.shape
			var transform: Transform2D = child.global_transform

			if shape is RectangleShape2D:
				var rect_shape: RectangleShape2D = shape as RectangleShape2D
				var center: Vector2 = transform * Vector2.ZERO
				var half_size: Vector2 = rect_shape.size / 2
				var rect: Rect2 = Rect2(center - half_size, rect_shape.size)
				_draw_rect_outline(rect, color)


func _draw_circle_outline(center: Vector2, radius: float, color: Color) -> void:
	# Draw circle using arc points
	const SEGMENTS := 32
	var points := PackedVector2Array()
	for i in range(SEGMENTS):
		var angle := TAU * i / SEGMENTS
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	# Close the circle
	points.append(points[0])

	draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.1))
	draw_polyline(points, color, 2.0)


func _draw_rect_outline(rect: Rect2, color: Color) -> void:
	draw_rect(rect, Color(color.r, color.g, color.b, 0.1), true)
	# Draw outline
	var points := PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
		rect.position,
	])
	draw_polyline(points, color, 2.0)


func _draw_ball_velocities() -> void:
	# Get all balls in the scene
	var balls := get_tree().get_nodes_in_group("ball")

	for ball in balls:
		if ball is RigidBody2D:
			var ball_node := ball as RigidBody2D
			var velocity := ball_node.linear_velocity
			var pos := ball_node.global_position

			# Draw ball outline
			_draw_circle_outline(pos, 12.0, COLOR_BALL)

			# Draw velocity vector
			if velocity.length() > 10:
				var velocity_scaled := velocity * 2.0  # Scale for visibility
				var end_pos := pos + velocity_scaled
				draw_line(pos, end_pos, COLOR_VELOCITY, 2.0)

				# Draw arrowhead
				var arrow_size := 10.0
				var arrow_angle := velocity.angle()
				var arrow_point1 := end_pos - Vector2(cos(arrow_angle - PI/6), sin(arrow_angle - PI/6)) * arrow_size
				var arrow_point2 := end_pos - Vector2(cos(arrow_angle + PI/6), sin(arrow_angle + PI/6)) * arrow_size

				var arrow_points := PackedVector2Array([end_pos, arrow_point1, arrow_point2])
				draw_colored_polygon(arrow_points, COLOR_VELOCITY)

				# Draw velocity magnitude text
				var speed := velocity.length()
				_draw_label(str(int(speed)), pos + Vector2(20, -20), COLOR_VELOCITY)


func _draw_peg_hit_counts() -> void:
	if not _board:
		return

	# Get physics world
	var physics_world := _board.get_node_or_null("PhysicsWorld") as Node2D
	if not physics_world:
		return

	var peg_container := physics_world.get_node_or_null("PegContainer") as Node2D
	if not peg_container:
		return

	for peg in peg_container.get_children():
		if peg is StaticBody2D:
			var peg_pos: Vector2 = peg.global_position
			var hit_count: int = 0

			# Try to get hit_count from BasePeg
			if peg.has_method("get_hit_count"):
				hit_count = peg.get("hit_count") if peg.get("hit_count") != null else 0
			elif "hit_count" in peg:
				hit_count = peg.hit_count

			# Draw hit count label above peg
			if hit_count > 0:
				var label_pos: Vector2 = peg_pos + Vector2(0, -30)
				_draw_label("hits: " + str(hit_count), label_pos, COLOR_PEG)


func _draw_label(text: String, position: Vector2, color: Color) -> void:
	# Draw a simple label using draw_string
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)


func _on_peg_hit(peg: Node, ball: Node) -> void:
	# Log peg hits to console
	var peg_type := "unknown"
	if peg.has_method("get_peg_type_string"):
		peg_type = peg.get_peg_type_string()

	var hit_count: int = 0
	if "hit_count" in peg:
		hit_count = peg.hit_count

	var ball_vel := Vector2.ZERO
	if ball is RigidBody2D:
		ball_vel = ball.linear_velocity

	print("[DEBUG] PEG HIT: %s (hits: %d) | Ball velocity: %.1f" % [peg_type, hit_count, ball_vel.length()])
