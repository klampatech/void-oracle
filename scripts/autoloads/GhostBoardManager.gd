# GhostBoardManager.gd — Persist and load Ghost Boards across runs.
# Add to AutoLoad in Project Settings as "GhostBoardManager"
extends Node

const SAVE_DIR = "user://void_oracle/ghost_boards/"
const MAX_GHOSTS = 10
var active_ghost: Dictionary = {}   # Ghost scheduled for this run's encounter

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

	# Subscribe to run ended to save ghost board
	EventBus.run_ended.connect(_on_run_ended)


func _on_run_ended(cause: String, board_state: Dictionary) -> void:
	if cause == "stability_depleted" and not board_state.is_empty():
		save_ghost(board_state)
		print("Ghost board saved on death")

func save_ghost(board_state: Dictionary) -> void:
	_rotate_ghosts()
	var path = SAVE_DIR + "ghost_001.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(board_state, "\t"))
		file.close()

func load_ghost(index: int) -> Dictionary:
	var path = SAVE_DIR + "ghost_%03d.json" % index
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var result = JSON.parse_string(file.get_as_text())
	file.close()
	return result if result else {}

func get_active_ghost() -> Dictionary:
	return active_ghost

func assign_ghost_for_run(run_seed: int) -> void:
	# Deterministically pick which ghost appears this run
	var rng = RandomNumberGenerator.new()
	rng.seed = run_seed + 9999
	var index = rng.randi_range(1, min(MAX_GHOSTS, count_saved_ghosts()))
	active_ghost = load_ghost(index)

func _rotate_ghosts() -> void:
	for i in range(MAX_GHOSTS - 1, 0, -1):
		var src = SAVE_DIR + "ghost_%03d.json" % i
		var dst = SAVE_DIR + "ghost_%03d.json" % (i + 1)
		if FileAccess.file_exists(src):
			DirAccess.rename_absolute(src, dst)

func count_saved_ghosts() -> int:
	var count = 0
	for i in range(1, MAX_GHOSTS + 1):
		if FileAccess.file_exists(SAVE_DIR + "ghost_%03d.json" % i):
			count += 1
	return count
