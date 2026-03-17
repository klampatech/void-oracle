# Board.gd — Main game board with physics boundaries and pockets
extends Node2D
class_name Board

## Board dimensions: 600x900px centered in viewport
const BOARD_WIDTH := 600
const BOARD_HEIGHT := 900
const WALL_THICKNESS := 20

## Pocket types (ordered left to right across bottom)
enum PocketType { DAMAGE, HEAL, GOLD, VOID, CHAOS }

@onready var _physics_world: Node2D = $PhysicsWorld
@onready var _pockets_container: Node2D = $PhysicsWorld/PocketRow
@onready var _peg_container: Node2D = $PhysicsWorld/PegContainer
@onready var _background: ColorRect = $Background

## Preload pocket scene for instantiation
var _pocket_scene: PackedScene

## Preload all peg scenes
var _peg_scenes: Dictionary = {
	"stone": preload("res://scenes/game/pegs/StonePeg.tscn"),
	"bone": preload("res://scenes/game/pegs/BonePeg.tscn"),
	"fungal": preload("res://scenes/game/pegs/FungalPeg.tscn"),
	"ember": preload("res://scenes/game/pegs/EmberPeg.tscn"),
	"eye": preload("res://scenes/game/pegs/EyePeg.tscn"),
	"heart": preload("res://scenes/game/pegs/HeartPeg.tscn"),
	"oracle": preload("res://scenes/game/pegs/OraclePeg.tscn"),
	"void_rift": preload("res://scenes/game/pegs/VoidRiftPeg.tscn"),
	"thorn": preload("res://scenes/game/pegs/ThornPeg.tscn"),
}

## Corruption map manager
var _corruption_manager: CorruptionMapManager

## Crack system for Architect boss
var _cracks: Array[Dictionary] = []
var _crack_effect: String = "none"  # "none", "void_channel", "hazard"
var _cracks_container: Node2D = null


func _ready() -> void:
	# Center board in viewport
	_center_board()
	# Create cracks container
	_cracks_container = Node2D.new()
	_cracks_container.name = "CracksContainer"
	_physics_world.add_child(_cracks_container)
	# Create pockets
	_create_pockets()
	# Create pegs
	_create_pegs()
	# Setup ball lost detector (area below the board)
	_setup_ball_lost_detector()
	# Setup corruption map shader
	_setup_corruption_map()

	# Connect to encounter end to clear cracks
	EventBus.encounter_ended.connect(_on_encounter_ended)


func _center_board() -> void:
	var viewport_size := get_viewport_rect().size
	var board_x := (viewport_size.x - BOARD_WIDTH) / 2
	var board_y := (viewport_size.y - BOARD_HEIGHT) / 2
	position = Vector2(board_x, board_y)


func _create_pockets() -> void:
	# Each pocket is 600/8 = 75px wide
	var pocket_width := BOARD_WIDTH / 8
	var pocket_height := 40.0
	var pocket_y := BOARD_HEIGHT - pocket_height

	# Load pocket scene (will be created in scene file)
	# For now, create Area2D pockets programmatically

	for i in range(8):
		var pocket_type: PocketType = PocketType.values()[i % PocketType.size()]
		var pocket_x := i * pocket_width

		var area := Area2D.new()
		area.name = "Pocket_%d" % i
		area.position = Vector2(pocket_x + pocket_width / 2, pocket_y + pocket_height / 2)

		# Create collision shape
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(pocket_width - 4, pocket_height - 4)  # Small gap between pockets
		collision.shape = shape
		area.add_child(collision)

		# Connect signal
		area.body_entered.connect(_on_pocket_body_entered.bind(area, pocket_type))

		# Add visual (colored rectangle)
		var visual := ColorRect.new()
		visual.size = Vector2(pocket_width - 4, pocket_height - 4)
		visual.position = Vector2(-(pocket_width - 4) / 2, -(pocket_height - 4) / 2)
		visual.color = _get_pocket_color(pocket_type)
		area.add_child(visual)

		_pockets_container.add_child(area)


func _create_pegs() -> void:
	# Check if RunState has starting pegs (from class selection)
	if RunState.pegs.size() > 0:
		# Use class-specific starting pegs
		_create_class_pegs()
		return

	# Default: create staggered grid of pegs
	_create_default_pegs()


func _create_class_pegs() -> void:
	# Spawn pegs from RunState at their defined positions
	for peg_data in RunState.pegs:
		var peg_type: String = peg_data.get("type", "stone")
		var position: Vector2 = peg_data.get("position", Vector2(300, 200))
		var state: String = peg_data.get("state", "blessed")

		if _peg_scenes.has(peg_type):
			var peg: Node2D = _peg_scenes[peg_type].instantiate()
			peg.position = position
			peg.add_to_group("peg")

			# Set initial state if different from blessed
			if state != "blessed" and peg.has_method("set_peg_state"):
				peg.set_peg_state(state)

			_peg_container.add_child(peg)
			print("Board: Spawned class starting peg: ", peg_type, " at ", position)

	# Fill remaining slots with default pegs to have a playable board
	_create_default_pegs_partial()


func _create_default_pegs_partial() -> void:
	# Add some additional pegs to make the board playable
	# Grid parameters
	var start_y := 350.0  # Start lower to leave room for class pegs
	var end_y := 700.0
	var column_spacing := 70.0
	var row_spacing := 60.0
	var left_margin := 60.0
	var right_margin := 60.0

	var num_columns := int((BOARD_WIDTH - left_margin - right_margin) / column_spacing) + 1
	var num_rows := int((end_y - start_y) / row_spacing) + 1

	var peg_types := _peg_scenes.keys()

	for row in range(num_rows):
		var y := start_y + row * row_spacing
		var x_offset := column_spacing / 2.0 if row % 2 == 1 else 0.0

		for col in range(num_columns):
			var x := left_margin + x_offset + col * column_spacing

			if x < left_margin or x > BOARD_WIDTH - right_margin:
				continue

			var peg_type: String = peg_types[(row * num_columns + col) % peg_types.size()]

			var peg: Node2D = _peg_scenes[peg_type].instantiate()
			peg.position = Vector2(x, y)
			peg.add_to_group("peg")

			_peg_container.add_child(peg)


func _create_default_pegs() -> void:
	# Grid parameters
	var start_y := 150.0
	var end_y := 700.0
	var column_spacing := 70.0
	var row_spacing := 60.0
	var left_margin := 60.0
	var right_margin := 60.0

	# Calculate columns and rows
	var num_columns := int((BOARD_WIDTH - left_margin - right_margin) / column_spacing) + 1
	var num_rows := int((end_y - start_y) / row_spacing) + 1

	# Peg type assignment in order (cycling through available types)
	var peg_types := _peg_scenes.keys()

	# Create staggered grid of pegs
	for row in range(num_rows):
		var y := start_y + row * row_spacing
		# Offset odd rows for staggered pattern
		var x_offset := column_spacing / 2.0 if row % 2 == 1 else 0.0

		for col in range(num_columns):
			var x := left_margin + x_offset + col * column_spacing

			# Skip if outside board bounds
			if x < left_margin or x > BOARD_WIDTH - right_margin:
				continue

			# Cycle through peg types
			var peg_type: String = peg_types[(row * num_columns + col) % peg_types.size()]

			# Instantiate peg scene
			var peg: Node2D = _peg_scenes[peg_type].instantiate()
			peg.position = Vector2(x, y)
			peg.add_to_group("peg")

			_peg_container.add_child(peg)


func _get_pocket_color(pocket_type: PocketType) -> Color:
	match pocket_type:
		PocketType.DAMAGE:
			return Color("#FF4444")  # Red for damage
		PocketType.HEAL:
			return Color("#44FF44")  # Green for heal
		PocketType.GOLD:
			return Color("#FFD700")  # Gold
		PocketType.VOID:
			return Color("#1A003A")  # Dark purple for void
		PocketType.CHAOS:
			return Color("#FF00FF")  # Magenta for chaos
		_:
			return Color.WHITE


func _on_pocket_body_entered(body: Node2D, pocket: Area2D, pocket_type: PocketType) -> void:
	if body.is_in_group("ball"):
		EventBus.ball_entered_pocket.emit(pocket, body)


func _setup_ball_lost_detector() -> void:
	# Area below the board to detect balls that fell off
	var detector := Area2D.new()
	detector.name = "BallLostDetector"

	# Position below the board
	detector.position = Vector2(BOARD_WIDTH / 2, BOARD_HEIGHT + 100)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(BOARD_WIDTH, 50)
	collision.shape = shape
	detector.add_child(collision)

	detector.body_entered.connect(_on_ball_lost.bind(detector))

	_physics_world.add_child(detector)


func _on_ball_lost(body: Node2D, _detector: Area2D) -> void:
	if body.is_in_group("ball"):
		EventBus.ball_lost.emit(body)
		# Queue free the ball after signal
		body.queue_free()


func _setup_corruption_map() -> void:
	# Create corruption map manager
	_corruption_manager = CorruptionMapManager.new()
	_corruption_manager.name = "CorruptionMapManager"
	add_child(_corruption_manager)

	# Load and apply corruption spread shader
	var shader = load("res://shaders/corruption_spread.gdshader") as Shader
	if shader:
		var material = ShaderMaterial.new()
		material.shader = shader
		_background.material = material
		_corruption_manager.setup_shader(material)


## Add a new peg at the specified position
## Returns the instantiated peg, or null if failed
func add_peg_at_position(peg_type: String, position: Vector2) -> bool:
	if not _peg_scenes.has(peg_type):
		push_warning("Unknown peg type: " + peg_type)
		return false

	var peg: Node2D = _peg_scenes[peg_type].instantiate()
	peg.position = position
	peg.add_to_group("peg")

	_peg_container.add_child(peg)

	# Emit peg spawned signal
	EventBus.peg_spawned.emit(peg, position)

	return true


## Get list of empty positions where new pegs can be placed
## Returns array of Vector2 positions in grid coordinates
func get_empty_slots() -> Array[Vector2]:
	var empty_slots: Array[Vector2] = []

	# Grid parameters (same as _create_pegs)
	var start_y := 150.0
	var end_y := 700.0
	var column_spacing := 70.0
	var row_spacing := 60.0
	var left_margin := 60.0
	var right_margin := 60.0

	# Calculate grid positions
	var num_columns := int((BOARD_WIDTH - left_margin - right_margin) / column_spacing) + 1
	var num_rows := int((end_y - start_y) / row_spacing) + 1

	# Get all existing peg positions
	var existing_positions: Array[Vector2] = []
	for peg in _peg_container.get_children():
		if peg is Node2D:
			existing_positions.append(peg.position)

	# Generate all possible grid positions and filter out occupied ones
	for row in range(num_rows):
		var y := start_y + row * row_spacing
		var x_offset := column_spacing / 2.0 if row % 2 == 1 else 0.0

		for col in range(num_columns):
			var x := left_margin + x_offset + col * column_spacing

			# Skip if outside board bounds
			if x < left_margin or x > BOARD_WIDTH - right_margin:
				continue

			var pos := Vector2(x, y)

			# Check if this position is already occupied
			var is_occupied := false
			for existing_pos in existing_positions:
				if pos.distance_to(existing_pos) < 30.0:  # Within 30 pixels = occupied
					is_occupied = true
					break

			if not is_occupied:
				empty_slots.append(pos)

	return empty_slots


func _input(event: InputEvent) -> void:
	# Handle mouse click for peg placement
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			# Check if draft system is in placement mode
			var draft_system = get_tree().get_first_node_in_group("draft_system")
			if draft_system and draft_system.has_method("is_in_placement_mode"):
				if draft_system.is_in_placement_mode():
					# Convert mouse position to local board position
					var local_pos := get_local_mouse_position()
					# Validate position is within board bounds
					if local_pos.x >= 0 and local_pos.x <= BOARD_WIDTH and local_pos.y >= 0 and local_pos.y <= BOARD_HEIGHT:
						# Try to place the peg
						draft_system.place_peg_at(local_pos)


## Get board width
func get_board_width() -> int:
	return BOARD_WIDTH


## Get board height
func get_board_height() -> int:
	return BOARD_HEIGHT


## Add a crack to the board (for Architect boss)
func add_crack(crack_data: Dictionary) -> void:
	var crack_pos: Vector2 = crack_data.get("position", Vector2.ZERO)
	var phase: int = crack_data.get("phase", 1)

	# Create visual representation of crack
	var crack_visual := ColorRect.new()
	crack_visual.size = Vector2(15, 40)
	crack_visual.position = crack_pos - Vector2(7.5, 20)

	# Color based on phase
	match phase:
		1:
			crack_visual.color = Color("#4A4A4A")  # Dark gray for Phase 1
		2:
			crack_visual.color = Color("#6A0DAD")  # Purple for Phase 2 (void channel)
		3:
			crack_visual.color = Color("#FF0000")  # Red for Phase 3 (hazard)

	crack_visual.name = "Crack_" + str(_cracks.size())
	_cracks_container.add_child(crack_visual)

	# Create collision area for the crack
	var crack_area := Area2D.new()
	crack_area.name = "CrackArea_" + str(_cracks.size())
	crack_area.position = crack_pos

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(15, 40)
	collision.shape = shape
	crack_area.add_child(collision)

	# Connect to ball detection
	crack_area.body_entered.connect(_on_crack_body_entered.bind(crack_area))

	_cracks_container.add_child(crack_area)

	# Store crack data
	_cracks.append({
		"visual": crack_visual,
		"area": crack_area,
		"position": crack_pos,
		"phase": phase,
	})

	print("Board: Added crack at ", crack_pos, " phase ", phase)


## Handle ball entering a crack
func _on_crack_body_entered(body: Node2D, crack_area: Area2D) -> void:
	if not body.is_in_group("ball"):
		return

	match _crack_effect:
		"void_channel":
			# Double void essence - handled by ball entering pocket
			EventBus.ball_entered_crack.emit(body, "void_channel")
		"hazard":
			# Ball gains Cursed state
			if body.has_method("add_state"):
				body.add_state("cursed")
			EventBus.ball_entered_crack.emit(body, "hazard")


## Set the effect type for all cracks
func set_crack_effect(effect_type: String) -> void:
	_crack_effect = effect_type

	# Update visual colors based on new effect
	for crack in _cracks:
		var visual: ColorRect = crack.get("visual")
		if visual:
			match effect_type:
				"void_channel":
					visual.color = Color("#6A0DAD")  # Purple
				"hazard":
					visual.color = Color("#FF0000")  # Red
				_:
					visual.color = Color("#4A4A4A")  # Default gray

	print("Board: Crack effect set to: ", effect_type)


## Get crack count
func get_crack_count() -> int:
	return _cracks.size()


## Clear all cracks (used when encounter ends)
func clear_cracks() -> void:
	for crack in _cracks:
		var visual: Node = crack.get("visual")
		var area: Node = crack.get("area")
		if visual:
			visual.queue_free()
		if area:
			area.queue_free()

	_cracks.clear()
	_crack_effect = "none"


## Called when encounter ends to clean up cracks
func _on_encounter_ended(_result: String) -> void:
	clear_cracks()
