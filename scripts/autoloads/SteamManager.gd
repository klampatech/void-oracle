# SteamManager.gd — Steam achievements integration
# Add to AutoLoad in Project Settings as "SteamManager"
extends Node

## Steam achievement IDs - must match Steamworks dashboard exactly
## These will need to be configured in Steamworks partner portal

# Combat achievements
const ACHIEVEMENT_FIRST_BLOOD := "FIRST_BLOOD"  # Win first combat
const ACHIEVEMENT_GHOST_HUNTER := "GHOST_HUNTER"  # Defeat ghost board

# Boss achievements
const ACHIEVEMENT_GARDENER := "THE_GARDENER"  # Defeat Zone 1 boss
const ACHIEVEMENT_ARCHITECT := "ARCHITECT"  # Defeat Zone 2 boss
const ACHIEVEMENT_ORACLE := "ORACLE"  # Complete the game

# Progression achievements
const ACHIEVEMENT_MUTANT := "MUTANT"  # Get a peg to mutate
const ACHIEVEMENT_SYNERGY := "SYNERGY"  # Activate first synergy

# Collection achievements
const ACHIEVEMENT_COLLECTOR := "COLLECTOR"  # Own all peg types

# Difficulty achievement (requires difficulty system)
const ACHIEVEMENT_MASTER := "MASTER"  # Win on hardest difficulty

## Local achievement state - tracks which achievements have been unlocked
## This prevents repeated Steam API calls and works offline
var _achievements_unlocked: Dictionary = {
	ACHIEVEMENT_FIRST_BLOOD: false,
	ACHIEVEMENT_GHOST_HUNTER: false,
	ACHIEVEMENT_GARDENER: false,
	ACHIEVEMENT_ARCHITECT: false,
	ACHIEVEMENT_ORACLE: false,
	ACHIEVEMENT_MUTANT: false,
	ACHIEVEMENT_SYNERGY: false,
	ACHIEVEMENT_COLLECTOR: false,
	ACHIEVEMENT_MASTER: false,
}

## Track unique peg types owned for Collector achievement
var _owned_peg_types: Array[String] = []

## Track if Steam is initialized
var _steam_initialized: bool = false

## Track if we're in Steam mode (vs. running from editor/standalone)
var _is_steam_build: bool = false

## Track first combat win
var _has_won_combat: bool = false

## Track total runs completed
var _runs_completed: int = 0


func _ready() -> void:
	# Try to initialize Steam
	_initialize_steam()

	# Connect to game events for achievement tracking
	_connect_signals()


## Initialize Steam connection
func _initialize_steam() -> void:
	# Check if GodotSteam is available
	if not has_node("/root/Steam") and not _steam_available():
		print("SteamManager: Steam not available (not a Steam build or GodotSteam not installed)")
		_is_steam_build = false
		_steam_initialized = false
		return

	# Try to initialize Steam
	var steam_node = _get_steam_node()
	if steam_node == null:
		print("SteamManager: Steam node not found")
		_steam_initialized = false
		return

	# Initialize Steam
	var init_result = steam_node.steamInitEx()
	if init_result == null or init_result.get("status", -1) > 0:
		print("SteamManager: Failed to initialize Steam: ", init_result)
		_steam_initialized = false
		return

	_steam_initialized = true
	_is_steam_build = true
	print("SteamManager: Steam initialized successfully")

	# Load achievements from Steam
	_load_achievements()


## Check if Steam API is available
func _steam_available() -> bool:
	# Try to get the Steam singleton
	var steam = _get_steam_node()
	return steam != null


## Get Steam node reference
func _get_steam_node() -> Node:
	# GodotSteam adds a "Steam" node to the scene tree
	if has_node("/root/Steam"):
		return get_node("/root/Steam")

	# Try alternative: GodotSteam might be accessible via Engine class
	if Engine.has_singleton("Steam"):
		return Engine.get_singleton("Steam")

	return null


## Connect to game event signals
func _connect_signals() -> void:
	# Enemy defeated - for First Blood and Ghost Hunter
	if EventBus.enemy_defeated:
		EventBus.enemy_defeated.connect(_on_enemy_defeated)

	# Zone completed - for Gardener and Architect
	if EventBus.zone_completed:
		EventBus.zone_completed.connect(_on_zone_completed)

	# Game victory - for Oracle
	if EventBus.game_victory:
		EventBus.game_victory.connect(_on_game_victory)

	# Peg state changed - for Mutant
	if EventBus.peg_state_changed:
		EventBus.peg_state_changed.connect(_on_peg_state_changed)

	# Synergy activated - for Synergy!
	if EventBus.synergy_activated:
		EventBus.synergy_activated.connect(_on_synergy_activated)

	# Run started - for tracking runs
	if EventBus.run_started:
		EventBus.run_started.connect(_on_run_started)


## Load achievements from Steam
func _load_achievements() -> void:
	if not _steam_initialized:
		return

	var steam = _get_steam_node()
	if steam == null:
		return

	# Request stats from Steam
	steam.requestCurrentStats()

	# Note: In a full implementation, we'd wait for stats_received callback
	# and then read achievement states. For now, we track locally.


## Unlock an achievement
func unlock_achievement(achievement_id: String) -> void:
	# Check if already unlocked
	if _achievements_unlocked.get(achievement_id, false):
		print("SteamManager: Achievement already unlocked: ", achievement_id)
		return

	# Check if achievement exists
	if not _achievements_unlocked.has(achievement_id):
		push_warning("SteamManager: Unknown achievement: " + achievement_id)
		return

	# Mark as unlocked locally
	_achievements_unlocked[achievement_id] = true

	# Try to unlock on Steam
	if _steam_initialized:
		var steam = _get_steam_node()
		if steam != null:
			var result = steam.setAchievement(achievement_id)
			if result:
				print("SteamManager: Unlocked achievement: ", achievement_id)
				# Store stats to persist achievement
				steam.storeStats()
			else:
				print("SteamManager: Failed to unlock achievement: ", achievement_id)
	else:
		print("SteamManager: Achievement unlocked (offline): ", achievement_id)


## Check if an achievement is unlocked
func is_achievement_unlocked(achievement_id: String) -> bool:
	return _achievements_unlocked.get(achievement_id, false)


## Save achievement state to disk (for non-Steam runs)
func save_achievement_state() -> void:
	# Save to user://void_oracle/achievements.json
	var save_path := "user://void_oracle/achievements.json"

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("SteamManager: Failed to open save file: " + save_path)
		return

	var save_data := {
		"achievements": _achievements_unlocked,
		"owned_peg_types": _owned_peg_types,
		"runs_completed": _runs_completed,
	}

	var json_string := JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	print("SteamManager: Achievement state saved")


## Load achievement state from disk
func load_achievement_state() -> void:
	var save_path := "user://void_oracle/achievements.json"

	if not FileAccess.file_exists(save_path):
		print("SteamManager: No saved achievement state found")
		return

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("SteamManager: Failed to open save file: " + save_path)
		return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("SteamManager: Failed to parse achievement save file")
		return

	var save_data: Dictionary = json.get_data()
	if save_data.is_empty():
		return

	# Load achievements
	if save_data.has("achievements"):
		var saved_achievements: Dictionary = save_data["achievements"]
		for achievement_id in saved_achievements:
			if _achievements_unlocked.has(achievement_id):
				_achievements_unlocked[achievement_id] = saved_achievements[achievement_id]

	# Load owned peg types
	if save_data.has("owned_peg_types"):
		_owned_peg_types = save_data["owned_peg_types"]

	# Load run count
	if save_data.has("runs_completed"):
		_runs_completed = save_data["runs_completed"]

	print("SteamManager: Achievement state loaded")


## Event handlers

func _on_enemy_defeated(enemy: Node) -> void:
	var enemy_id = enemy.enemy_id if enemy.has("enemy_id") else ""

	# First Blood - win first combat
	if not _has_won_combat:
		_has_won_combat = true
		unlock_achievement(ACHIEVEMENT_FIRST_BLOOD)

	# Ghost Hunter - defeat ghost board
	if enemy_id == "ghost":
		unlock_achievement(ACHIEVEMENT_GHOST_HUNTER)


func _on_zone_completed(zone_number: int) -> void:
	match zone_number:
		1:
			unlock_achievement(ACHIEVEMENT_GARDENER)
		2:
			unlock_achievement(ACHIEVEMENT_ARCHITECT)


func _on_game_victory() -> void:
	unlock_achievement(ACHIEVEMENT_ORACLE)
	_runs_completed += 1

	# Check for Master achievement (hardest difficulty)
	# This requires difficulty system to be implemented
	# For now, check if player has won multiple times
	if _runs_completed >= 5:
		unlock_achievement(ACHIEVEMENT_MASTER)

	# Save state after victory
	save_achievement_state()


func _on_peg_state_changed(peg: Node, old_state: String, new_state: String) -> void:
	# Mutant - get a peg to mutate
	if new_state == "mutant":
		unlock_achievement(ACHIEVEMENT_MUTANT)

	# Track peg types for Collector achievement
	if peg.has("peg_type"):
		var peg_type: String = peg.get("peg_type")
		if peg_type not in _owned_peg_types:
			_owned_peg_types.append(peg_type)
			_check_collector_achievement()


func _on_synergy_activated(synergy_id: String, peg_count: int) -> void:
	# Synergy! - activate first synergy
	unlock_achievement(ACHIEVEMENT_SYNERGY)


func _on_run_started(oracle_class: String) -> void:
	# Load achievement state when new run starts
	load_achievement_state()

	# Reset per-run tracking
	_has_won_combat = false


## Check Collector achievement
func _check_collector_achievement() -> void:
	# All 8 peg types needed for Collector
	var required_pegs: Array[String] = [
		"stone", "bone", "fungal", "ember",
		"eye", "heart", "oracle", "void_rift"
	]

	var has_all: bool = true
	for peg_type in required_pegs:
		if peg_type not in _owned_peg_types:
			has_all = false
			break

	if has_all:
		unlock_achievement(ACHIEVEMENT_COLLECTOR)


## Get debug info (for testing)
func get_debug_info() -> Dictionary:
	return {
		"steam_initialized": _steam_initialized,
		"is_steam_build": _is_steam_build,
		"achievements_unlocked": _achievements_unlocked,
		"owned_peg_types": _owned_peg_types,
		"runs_completed": _runs_completed,
	}
