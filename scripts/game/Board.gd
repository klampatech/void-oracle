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
}

## Corruption map manager
var _corruption_manager: CorruptionMapManager


func _ready() -> void:
	# Center board in viewport
	_center_board()
	# Create pockets
	_create_pockets()
	# Create pegs
	_create_pegs()
	# Setup ball lost detector (area below the board)
	_setup_ball_lost_detector()
	# Setup corruption map shader
	_setup_corruption_map()


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
