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

## Current zone (1, 2, or 3)
var _current_zone: int = 1


func _ready() -> void:
	# Connect to EventBus
	EventBus.encounter_ended.connect(_on_encounter_ended)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)


## Start a new run with given seed
func start_new_run(seed: int) -> void:
	_map_seed = seed
	_current_zone = 1
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
			# Load elite enemy (Wrecker, Spawner, etc.)
			_load_elite_enemy()
		"ghost":
			# Load ghost board encounter
			_load_ghost_encounter()
		"boss":
			# Load boss based on current zone
			_load_boss_for_zone()


## Load the appropriate boss for the current zone
func _load_boss_for_zone() -> void:
	if not _encounter_manager:
		return

	var boss_scene: PackedScene

	match _current_zone:
		1:
			# Zone 1: The Gardener
			boss_scene = load("res://scenes/game/enemies/Gardener.tscn") as PackedScene
			if boss_scene:
				_encounter_manager.start_encounter(boss_scene)
				print("RunManager: Boss encounter - The Gardener (Zone 1)")
			else:
				push_error("Failed to load Gardener scene")
		2:
			# Zone 2: Architect of Ruin
			boss_scene = load("res://scenes/game/enemies/Architect.tscn") as PackedScene
			if boss_scene:
				_encounter_manager.start_encounter(boss_scene)
				print("RunManager: Boss encounter - Architect of Ruin (Zone 2)")
			else:
				push_error("Failed to load Architect scene")
		3:
			# Zone 3: Final Oracle
			boss_scene = load("res://scenes/game/enemies/FinalOracle.tscn") as PackedScene
			if boss_scene:
				_encounter_manager.start_encounter(boss_scene)
				print("RunManager: Boss encounter - The Final Oracle (Zone 3)")
			else:
				push_error("Failed to load Final Oracle scene")
		_:
			print("RunManager: Unknown zone ", _current_zone, ", loading Gardener")
			boss_scene = load("res://scenes/game/enemies/Gardener.tscn") as PackedScene
			if boss_scene:
				_encounter_manager.start_encounter(boss_scene)


## Load a random elite enemy
func _load_elite_enemy() -> void:
	if not _encounter_manager:
		return

	# Randomly select an elite enemy
	var rng := RandomNumberGenerator.new()
	rng.seed = _map_seed + Time.get_ticks_msec()

	var elite_types := ["wrecker", "spawner", "leech"]
	var selected: String = elite_types[rng.randi() % elite_types.size()]

	var elite_scene: PackedScene

	match selected:
		"wrecker":
			elite_scene = load("res://scenes/game/enemies/Wrecker.tscn") as PackedScene
		"spawner":
			elite_scene = load("res://scenes/game/enemies/Spawner.tscn") as PackedScene
		"leech":
			elite_scene = load("res://scenes/game/enemies/Leech.tscn") as PackedScene
		_:
			elite_scene = load("res://scenes/game/enemies/Corruptor.tscn") as PackedScene

	if elite_scene:
		_encounter_manager.start_encounter(elite_scene)
		print("RunManager: Elite encounter - ", selected)
	else:
		push_error("Failed to load elite scene: ", selected)


## Load ghost board encounter
func _load_ghost_encounter() -> void:
	if not _encounter_manager:
		return

	# Check if there are any saved ghosts
	var ghost_count := GhostBoardManager.count_saved_ghosts()

	if ghost_count == 0:
		# No ghosts saved - fall back to Corruptor
		print("RunManager: No ghost boards found, loading Corruptor instead")
		var corruptor_scene := load("res://scenes/game/enemies/Corruptor.tscn") as PackedScene
		if corruptor_scene:
			_encounter_manager.start_encounter(corruptor_scene)
		return

	# Load ghost enemy scene
	var ghost_scene := load("res://scenes/game/enemies/GhostEnemy.tscn") as PackedScene
	if not ghost_scene:
		push_error("Failed to load GhostEnemy scene")
		return

	# Get a ghost board for this run
	GhostBoardManager.assign_ghost_for_run(_map_seed)
	var ghost_data := GhostBoardManager.get_active_ghost()

	if ghost_data.is_empty():
		print("RunManager: No ghost data available, loading Corruptor instead")
		var corruptor_scene := load("res://scenes/game/enemies/Corruptor.tscn") as PackedScene
		if corruptor_scene:
			_encounter_manager.start_encounter(corruptor_scene)
		return

	# Start encounter with ghost
	_encounter_manager.start_encounter(ghost_scene)

	# Get the ghost enemy instance and load ghost data
	await get_tree().process_frame  # Wait for enemy to be ready
	var ghost_enemy = _find_ghost_enemy()
	if ghost_enemy and ghost_enemy.has_method("load_ghost"):
		ghost_enemy.load_ghost(ghost_data)
		print("RunManager: Ghost encounter loaded")


## Find the ghost enemy in the scene tree
func _find_ghost_enemy() -> Node:
	if not _encounter_manager:
		return null

	# Look for ghost enemy in encounter manager's children
	for child in _encounter_manager.get_children():
		if child is GhostEnemy:
			return child

	return null


## Called when an enemy is defeated
func _on_enemy_defeated(enemy: Node) -> void:
	if enemy.has_method("is_boss") and enemy.is_boss():
		print("RunManager: Boss defeated in zone ", _current_zone)

		# Check if this was zone 1 boss - unlock zone 2
		if _current_zone == 1:
			_current_zone = 2
			EventBus.zone_completed.emit(1)
			print("RunManager: Zone 1 completed, unlocked Zone 2")

		# Check if this was zone 2 boss - unlock zone 3
		elif _current_zone == 2:
			_current_zone = 3
			EventBus.zone_completed.emit(2)
			print("RunManager: Zone 2 completed, unlocked Zone 3")

		# Check if this was zone 3 boss - game victory
		elif _current_zone == 3:
			EventBus.game_victory.emit()
			print("RunManager: GAME VICTORY! Final Oracle defeated!")


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
