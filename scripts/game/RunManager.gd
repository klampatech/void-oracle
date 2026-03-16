# RunManager.gd — Orchestrates the complete run flow: Map → Encounter → Map → Victory/Defeat
# Note: This is added as an AutoLoad "RunManager" in project.godot
extends Node

## Run states
enum Phase { MAP, ENCOUNTER, VICTORY, DEFEAT }

## Current run state
var _current_state: Phase = Phase.MAP

## Scene references
var _run_map: Control = null
var _board: Node2D = null
var _encounter_manager: Node = null

## Scene paths
const MAP_SCENE_PATH := "res://scenes/game/map/RunMap.tscn"
const BOARD_SCENE_PATH := "res://scenes/game/Board.tscn"

## Current map seed
var _map_seed: int = 0


func _ready() -> void:
	# Connect to EventBus
	EventBus.encounter_ended.connect(_on_encounter_ended)
	EventBus.run_ended.connect(_on_run_ended)


## Start a new run with given seed
func start_new_run(seed: int) -> void:
	_map_seed = seed
	_run_map = null
	_board = null
	_encounter_manager = null

	# Initialize RunState
	RunState.new_run(seed)

	# Show the map
	_show_map()


## Show the map scene
func _show_map() -> void:
	_current_state = Phase.MAP

	# Clear existing children
	_clear_current_scene()

	# Load and show map
	var map_scene := load(MAP_SCENE_PATH) as PackedScene
	if map_scene:
		_run_map = map_scene.instantiate()
		add_child(_run_map)
		_run_map.initialize_map(_map_seed)

		# Connect node selection
		_run_map.node_selected.connect(_on_map_node_selected)

		print("RunManager: Showing map")
	else:
		push_error("Failed to load map scene")


## Handle map node selection
func _on_map_node_selected(node_id: String, node_data: Dictionary) -> void:
	if _current_state != Phase.MAP:
		return

	print("RunManager: Node selected: ", node_id, " type: ", node_data.get("type", "unknown"))

	# Start encounter based on node type
	_start_encounter(node_data)


## Start an encounter based on node data
func _start_encounter(node_data: Dictionary) -> void:
	_current_state = Phase.ENCOUNTER

	# Clear map
	if _run_map:
		_run_map.queue_free()
		_run_map = null

	# Load board scene
	var board_scene := load(BOARD_SCENE_PATH) as PackedScene
	if board_scene:
		_board = board_scene.instantiate()
		add_child(_board)

		# Get EncounterManager
		_encounter_manager = _board.get_node_or_null("EncounterManager")

		# Start encounter based on node type
		var encounter_type: String = node_data.get("type", "combat")
		_start_encounter_by_type(encounter_type)

		print("RunManager: Starting encounter: ", encounter_type)
	else:
		push_error("Failed to load board scene")


## Start specific encounter type
func _start_encounter_by_type(encounter_type: String) -> void:
	if not _encounter_manager:
		return

	match encounter_type:
		"combat":
			# Load Corruptor enemy
			var corruptor_scene := load("res://scenes/game/enemies/Corruptor.tscn") as PackedScene
			if corruptor_scene:
				_encounter_manager.start_encounter(corruptor_scene)
		"elite":
			# TODO: Load elite enemy (Wrecker, Spawner, etc.)
			var corruptor_scene := load("res://scenes/game/enemies/Corruptor.tscn") as PackedScene
			if corruptor_scene:
				_encounter_manager.start_encounter(corruptor_scene)
				print("RunManager: Elite encounter (using Corruptor for now)")
		"boss":
			# Load Gardener boss
			var gardener_scene := load("res://scenes/game/enemies/Gardener.tscn") as PackedScene
			if gardener_scene:
				_encounter_manager.start_encounter(gardener_scene)
				print("RunManager: Boss encounter - The Gardener")
			else:
				push_error("Failed to load Gardener scene")
				# Fallback to Corruptor
				var corruptor_scene := load("res://scenes/game/enemies/Corruptor.tscn") as PackedScene
				if corruptor_scene:
					_encounter_manager.start_encounter(corruptor_scene)
		"event":
			# TODO: Handle event encounters
			print("RunManager: Event encounter - not implemented, returning to map")
			_return_to_map()
		"shop":
			# TODO: Handle shop
			print("RunManager: Shop - not implemented, returning to map")
			_return_to_map()
		"rest":
			# TODO: Handle rest sites
			print("RunManager: Rest site - not implemented, returning to map")
			_return_to_map()
		_:
			print("RunManager: Unknown encounter type: ", encounter_type)
			_return_to_map()


## Called when encounter ends
func _on_encounter_ended(result: String) -> void:
	print("RunManager: Encounter ended: ", result)

	match result:
		"victory":
			_current_state = Phase.VICTORY
			# Return to map after a short delay
			await get_tree().create_timer(1.0).timeout
			_return_to_map()
		"death", "fled":
			_current_state = Phase.DEFEAT
			# Handle defeat - death screen is shown via EventBus.run_ended
			pass


## Return to map after encounter
func _return_to_map() -> void:
	# Clear board
	if _board:
		_board.queue_free()
		_board = null
	_encounter_manager = null

	# Show map
	_show_map()


## Called when run ends (death)
func _on_run_ended(cause: String, board_state: Dictionary) -> void:
	_current_state = Phase.DEFEAT
	print("RunManager: Run ended - cause: ", cause)

	# Clear scenes
	_clear_current_scene()

	# TODO: Show death screen
	# For now, return to map to restart
	await get_tree().create_timer(2.0).timeout
	start_new_run(_map_seed)


## Clear current scene
func _clear_current_scene() -> void:
	for child in get_children():
		child.queue_free()
		wait_for_free(child)


## Wait for node to be freed
func wait_for_free(node: Node) -> void:
	await node.tree_exited


## Get current state
func get_current_state() -> Phase:
	return _current_state
