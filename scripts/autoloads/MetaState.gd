# MetaState.gd — Persistent meta-progression data between runs.
# Add to AutoLoad in Project Settings as "MetaState"
extends Node

## Persistent meta-progression data
var total_void_shards: int = 0
var unlocked_pegs: Array[String] = []
var unlocked_relics: Array[String] = []
var runs_completed: int = 0
var highest_zone_reached: int = 0

## Save file path
const SAVE_PATH := "user://void_oracle/meta_save.json"

## Version for save compatibility
const SAVE_VERSION := "1.0"


func _ready() -> void:
	load_data()


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
