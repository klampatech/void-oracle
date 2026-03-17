# MetaState.gd — Persistent meta-progression data between runs.
# Add to AutoLoad in Project Settings as "MetaState"
extends Node

## Persistent meta-progression data
var total_void_shards: int = 0
var unlocked_pegs: Array[String] = []
var unlocked_relics: Array[String] = []
var runs_completed: int = 0
var highest_zone_reached: int = 0

## Run history - array of completed run records
var run_history: Array[Dictionary] = []
var best_run: Dictionary = {}

## Save file paths
const SAVE_PATH := "user://void_oracle/meta_save.json"
const RUN_HISTORY_PATH := "user://void_oracle/run_history.json"

## Version for save compatibility
const SAVE_VERSION := "1.0"


func _ready() -> void:
	load_data()
	load_run_history()

	# Connect to signals to record runs
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.game_victory.connect(_on_game_victory)


## Called when player dies (run_ended signal)
func _on_run_ended(cause: String, board_state: Dictionary) -> void:
	if cause == "stability_depleted":
		var zone_reached: int = board_state.get("zone_reached", 1)
		var total_drops: int = board_state.get("total_drops", 0)
		var oracle_class: String = board_state.get("oracle_class", "none")
		var void_essence: int = board_state.get("void_essence", 0)

		# Record defeat (is_victory = false)
		record_run(zone_reached, total_drops, false, oracle_class, void_essence)


## Called when player defeats Final Oracle (game_victory signal)
func _on_game_victory() -> void:
	# Victory - zone 3 completed with all 3 zones
	# RunState should still have valid data at this point
	var zone_reached: int = RunState.zone
	var total_drops: int = RunState.total_drops
	var oracle_class: String = RunState.oracle_class
	var void_essence: int = RunState.void_essence

	# Record victory (is_victory = true)
	record_run(zone_reached, total_drops, true, oracle_class, void_essence)


## Load meta state from disk
func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("MetaState: No save file found, starting fresh")
		_reset()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("MetaState: Failed to open save file for reading")
		_reset()
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_error("MetaState: Failed to parse save JSON")
		_reset()
		return

	var data: Dictionary = json.get_data()
	if not data.has("version"):
		push_error("MetaState: Save file missing version")
		_reset()
		return

	# Load values with defaults
	total_void_shards = data.get("total_void_shards", 0)
	unlocked_pegs = Array(data.get("unlocked_pegs", []), TYPE_STRING, "", null)
	unlocked_relics = Array(data.get("unlocked_relics", []), TYPE_STRING, "", null)
	runs_completed = data.get("runs_completed", 0)
	highest_zone_reached = data.get("highest_zone_reached", 0)

	print("MetaState: Loaded - void_shards: ", total_void_shards, ", runs: ", runs_completed)


## Save meta state to disk
func save_data() -> void:
	var dir := DirAccess.open("user://void_oracle")
	if not dir:
		# Create directory if it doesn't exist
		dir = DirAccess.open("user://")
		if dir:
			dir.make_dir("void_oracle")
			dir = DirAccess.open("user://void_oracle")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("MetaState: Failed to open save file for writing")
		return

	var data := {
		"version": SAVE_VERSION,
		"total_void_shards": total_void_shards,
		"unlocked_pegs": unlocked_pegs,
		"unlocked_relics": unlocked_relics,
		"runs_completed": runs_completed,
		"highest_zone_reached": highest_zone_reached,
	}

	var json_text := JSON.stringify(data, "\t")
	file.store_string(json_text)
	file.close()

	print("MetaState: Saved - void_shards: ", total_void_shards)


## Reset to default values
func _reset() -> void:
	total_void_shards = 0
	unlocked_pegs = []
	unlocked_relics = []
	runs_completed = 0
	highest_zone_reached = 0
	run_history = []
	best_run = {}


## Add void shards (e.g., from boss defeat)
func add_void_shards(amount: int) -> void:
	total_void_shards += amount
	save_data()
	print("MetaState: Added ", amount, " void shards, total: ", total_void_shards)


## Increment run completion count
func complete_run(zone_reached: int) -> void:
	runs_completed += 1
	if zone_reached > highest_zone_reached:
		highest_zone_reached = zone_reached
	save_data()


## Unlock a peg type for future drafts
func unlock_peg(peg_type: String) -> void:
	if not peg_type in unlocked_pegs:
		unlocked_pegs.append(peg_type)
		save_data()
		print("MetaState: Unlocked peg: ", peg_type)


## Check if a peg type is unlocked
func is_peg_unlocked(peg_type: String) -> bool:
	return peg_type in unlocked_pegs


## Get available void shard balance
func get_void_shards() -> int:
	return total_void_shards


## Load run history from disk
func load_run_history() -> void:
	if not FileAccess.file_exists(RUN_HISTORY_PATH):
		print("MetaState: No run history file found")
		run_history = []
		best_run = {}
		return

	var file := FileAccess.open(RUN_HISTORY_PATH, FileAccess.READ)
	if not file:
		push_error("MetaState: Failed to open run history file for reading")
		run_history = []
		best_run = {}
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_error("MetaState: Failed to parse run history JSON")
		run_history = []
		best_run = {}
		return

	var data: Dictionary = json.get_data()
	run_history = Array(data.get("runs", []), TYPE_DICTIONARY, "", null)
	best_run = data.get("best_run", {})

	print("MetaState: Loaded ", run_history.size(), " runs from history")


## Save run history to disk
func save_run_history() -> void:
	var dir := DirAccess.open("user://void_oracle")
	if not dir:
		dir = DirAccess.open("user://")
		if dir:
			dir.make_dir("void_oracle")
			dir = DirAccess.open("user://void_oracle")

	var file := FileAccess.open(RUN_HISTORY_PATH, FileAccess.WRITE)
	if not file:
		push_error("MetaState: Failed to open run history file for writing")
		return

	var data := {
		"runs": run_history,
		"best_run": best_run,
	}

	var json_text := JSON.stringify(data, "\t")
	file.store_string(json_text)
	file.close()

	print("MetaState: Saved run history with ", run_history.size(), " runs")


## Record a completed run
## zone_reached: 1-3 (or 0 if died in zone 1)
## total_drops: number of ball drops in this run
## is_victory: true if player defeated Final Oracle
## oracle_class: the class played in this run
## void_essence_earned: void essence collected in this run
func record_run(zone_reached: int, total_drops: int, is_victory: bool, oracle_class: String, void_essence_earned: int) -> void:
	var run_record := {
		"timestamp": Time.get_unix_time_from_system(),
		"zone_reached": zone_reached,
		"total_drops": total_drops,
		"is_victory": is_victory,
		"oracle_class": oracle_class,
		"void_essence": void_essence_earned,
	}

	run_history.append(run_record)

	# Update best run if this run is better
	if best_run.is_empty() or zone_reached > best_run.get("zone_reached", 0) or (zone_reached == best_run.get("zone_reached", 0) and total_drops < best_run.get("total_drops", 999999)):
		best_run = run_record.duplicate(true)

	# Update highest zone reached
	if zone_reached > highest_zone_reached:
		highest_zone_reached = zone_reached

	# Increment runs completed
	runs_completed += 1

	save_run_history()
	save_data()

	print("MetaState: Recorded run - zone ", zone_reached, ", drops ", total_drops, ", victory: ", is_victory)


## Get all run history
func get_run_history() -> Array[Dictionary]:
	return run_history


## Get best run record
func get_best_run() -> Dictionary:
	return best_run


## Get total runs completed
func get_total_runs() -> int:
	return runs_completed
