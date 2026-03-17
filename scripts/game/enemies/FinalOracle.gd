# FinalOracle.gd — Zone 3 Boss: mirrors player synergies, reveals as ghost board
extends Node2D
class_name FinalOracle

## Enemy data loaded from JSON
var enemy_data: Dictionary = {}

## Current HP
var hp: int = 0
var max_hp: int = 0

## Enemy ID
var enemy_id: String = "final_oracle"

## Current phase (1, 2, or 3)
var _current_phase: int = 1

## Whether the enemy has been defeated
var _defeated: bool = false

## Turn counter
var _turn_count: int = 0

## Player's active synergies (synergy_id -> count)
var _player_synergies: Dictionary = {}

## Mirrored synergies (resistances applied to player)
var _mirrored_synergies: Array[String] = []

## Best ghost board data for phase 3
var _best_ghost_board: Dictionary = {}

## Whether ghost board has been revealed
var _ghost_revealed: bool = false

## Board reference for ghost board visualization
var _board: Node = null

## Control node for UI
@onready var _ui: Control = $EnemyUI


func _ready() -> void:
	# Load final oracle data
	_load_data()
	# Analyze player's synergies
	_analyze_player_synergies()


## Load enemy data from JSON
func _load_data() -> void:
	var file_path := "res://data/enemies/final_oracle.json"

	if not ResourceLoader.exists(file_path):
		push_warning("Enemy data file not found: " + file_path)
		# Set defaults
		max_hp = 300
		hp = 300
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("Failed to open enemy data file: " + file_path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_warning("Failed to parse enemy JSON: " + file_path)
		return

	enemy_data = json.get_data()
	enemy_id = enemy_data.get("id", "final_oracle")
	max_hp = enemy_data.get("max_hp", 300)
	hp = enemy_data.get("hp", max_hp)

	# Initialize phase
	_current_phase = 1
	_turn_count = 0
	_mirrored_synergies.clear()
	_ghost_revealed = false

	# Load best ghost board for phase 3
	_load_best_ghost_board()

	# Update UI if present
	_update_ui()


## Analyze player's current synergies
func _analyze_player_synergies() -> void:
	_player_synergies.clear()

	# Check SynergyChecker for active synergies
	if SynergyChecker and SynergyChecker.has_method("get_active_synergies"):
		_player_synergies = SynergyChecker.get_active_synergies()
	else:
		# Fallback: scan board for tags
		_scan_board_for_synergies()

	print("FinalOracle: Player synergies detected: ", _player_synergies)


## Scan board for synergy tags
func _scan_board_for_synergies() -> void:
	var pegs := get_tree().get_nodes_in_group("peg")
	if pegs.is_empty():
		return

	# Count tags
	var tag_counts: Dictionary = {}
	for peg in pegs:
		if not peg.has_method("get_peg_tags"):
			continue
		var tags: Array = peg.get_peg_tags()
		for tag in tags:
			tag_counts[tag] = tag_counts.get(tag, 0) + 1

	# Determine synergies from tags
	var synergy_defs := {
		"necrotic_bloom": ["death", "growth"],
		"cursed_flame": ["fire", "cursed"],
		"void_choir": ["void"],
		"bleeding_architecture": ["blood", "foundation"],
		"profane_eye": ["void", "death"],
	}

	for synergy_id in synergy_defs:
		var required_tags: Array = synergy_defs[synergy_id]
		var min_count := 999999
		for tag in required_tags:
			min_count = min(min_count, tag_counts.get(tag, 0))
		if min_count > 0 and min_count != 999999:
			_player_synergies[synergy_id] = min_count


## Load the best ghost board for phase 3 reveal
func _load_best_ghost_board() -> void:
	_best_ghost_board = {}

	# Try to load the best (most recent) ghost board
	var ghost_count := GhostBoardManager.count_saved_ghosts()
	if ghost_count > 0:
		# Load ghost 001 (most recent)
		_best_ghost_board = GhostBoardManager.load_ghost(1)
		print("FinalOracle: Loaded best ghost board with ", _best_ghost_board.get("pegs", []).size(), " pegs")


func _update_ui() -> void:
	if _ui:
		var hp_bar: ProgressBar = _ui.get_node_or_null("Panel/VBox/HPBar")
		if hp_bar:
			hp_bar.max_value = max_hp
			hp_bar.value = hp

		# Update phase indicator
		var phase_label = _ui.get_node_or_null("Panel/VBox/PhaseLabel")
		if phase_label:
			phase_label.text = "Phase " + str(_current_phase)

		# Update synergy display
		var synergy_label = _ui.get_node_or_null("Panel/VBox/SynergyLabel")
		if synergy_label:
			if _mirrored_synergies.is_empty():
				synergy_label.text = "Analyzing your board..."
			else:
				synergy_label.text = "Mirrored: " + ", ".join(_mirrored_synergies)


## Take damage
func take_damage(amount: int) -> void:
	# Apply resistance reduction if player has the synergy
	var actual_damage := amount
	if _has_resistance():
		actual_damage = int(amount * 0.5)  # 50% damage reduction
		print("FinalOracle: Resistance reduces damage from ", amount, " to ", actual_damage)

	hp = max(0, hp - actual_damage)

	# Check for phase change
	_check_phase_change()

	# Update UI
	_update_ui()

	if hp <= 0:
		_defeated = true
		die()


## Check if player has any active synergies (which would be resisted)
func _has_resistance() -> bool:
	return not _player_synergies.is_empty()


## Check if phase should change
func _check_phase_change() -> void:
	var hp_percent := get_hp_percent()

	# Phase 2 starts when HP drops below 67%
	if _current_phase == 1 and hp_percent < 0.67:
		_current_phase = 2
		EventBus.boss_phase_changed.emit(_current_phase)
		print("FinalOracle entered Phase 2! Second synergy mirrored.")
		_apply_phase_2_effects()

	# Phase 3 starts when HP drops below 34%
	elif _current_phase == 2 and hp_percent < 0.34:
		_current_phase = 3
		EventBus.boss_phase_changed.emit(_current_phase)
		print("FinalOracle entered Phase 3! Ghost revealed!")
		_apply_phase_3_effects()


## Apply phase 2 effects (add second synergy resistance)
func _apply_phase_2_effects() -> void:
	# Mirror second strongest synergy
	if _player_synergies.size() >= 2:
		# Get sorted synergies by count
		var sorted := _player_synergies.keys()
		sorted.sort_custom(func(a, b): return _player_synergies[a] > _player_synergies[b])

		if sorted.size() >= 2:
			var second_synergy: String = sorted[1]
			_mirrored_synergies.append(second_synergy)
			print("FinalOracle: Mirrored second synergy: ", second_synergy)

	# If only one synergy, just note it
	elif _player_synergies.size() == 1:
		print("FinalOracle: Only one synergy to mirror")

	_update_ui()


## Apply phase 3 effects (reveal ghost board)
func _apply_phase_3_effects() -> void:
	_ghost_revealed = true

	# All player synergies now provide resistance
	_mirrored_synergies.clear()
	for synergy_id in _player_synergies.keys():
		_mirrored_synergies.append(synergy_id)

	print("FinalOracle: All synergies now resisted: ", _mirrored_synergies)

	# Emit signal to reveal ghost board visualization
	EventBus.enemy_action.emit(self, {
		"type": "reveal_ghost",
		"ghost_data": _best_ghost_board,
		"phase": 3,
	})

	_update_ui()


## Check if defeated
func is_defeated() -> bool:
	return _defeated


## Called when HP reaches 0
func die() -> void:
	EventBus.enemy_defeated.emit(self)

	# Grant rewards
	var on_death: Dictionary = enemy_data.get("on_death", {})
	var rewards: Dictionary = on_death.get("rewards", {})

	if rewards.has("gold"):
		RunState.gold += rewards.get("gold", 0)
	if rewards.has("void_essence"):
		RunState.void_essence += rewards.get("void_essence", 0)

	# Emit game victory
	EventBus.game_victory.emit()

	# Queue free after a delay for death animation
	await get_tree().create_timer(0.5).timeout
	queue_free()


## Execute turn: based on current phase
func execute_turn() -> void:
	if _defeated:
		return

	_turn_count += 1

	match _current_phase:
		1:
			_phase_1_actions()
		2:
			_phase_2_actions()
		3:
			_phase_3_actions()


## Phase 1: Mirror primary synergy
func _phase_1_actions() -> void:
	# Mirror the strongest synergy
	if _player_synergies.size() >= 1:
		var sorted := _player_synergies.keys()
		sorted.sort_custom(func(a, b): return _player_synergies[a] > _player_synergies[b])
		var primary_synergy: String = sorted[0]
		_mirrored_synergies.append(primary_synergy)
		print("FinalOracle: Mirrored primary synergy: ", primary_synergy)

	# Emit action signal
	var action := {
		"type": "mirror_synergy",
		"phase": 1,
		"synergy": _mirrored_synergies[0] if _mirrored_synergies.size() > 0 else "none",
	}
	EventBus.enemy_action.emit(self, action)
	_update_ui()


## Phase 2: Mirror second synergy
func _phase_2_actions() -> void:
	# Already applied in phase change, just emit signal
	var action := {
		"type": "mirror_synergy_2",
		"phase": 2,
		"synergies": _mirrored_synergies,
	}
	EventBus.enemy_action.emit(self, action)


## Phase 3: All synergies + ghost reveal
func _phase_3_actions() -> void:
	# Just emit the ongoing effect
	var action := {
		"type": "ghost_revelation",
		"phase": 3,
		"all_resisted": _mirrored_synergies,
	}
	EventBus.enemy_action.emit(self, action)


## Get intent display text
func get_intent_text() -> String:
	match _current_phase:
		1:
			if _mirrored_synergies.size() > 0:
				return "Will mirror your power"
			else:
				return "Will analyze your board"
		2:
			return "Will double your weakness"
		3:
			return "Will face your past"
	return "Unknown intent"


## Get current HP
func get_hp() -> int:
	return hp


## Get max HP
func get_max_hp() -> int:
	return max_hp


## Get HP as percentage (0.0 - 1.0)
func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)


## Get current phase
func get_phase() -> int:
	return _current_phase


## Get mirrored synergies
func get_mirrored_synergies() -> Array[String]:
	return _mirrored_synergies


## Get best ghost board data
func get_ghost_board() -> Dictionary:
	return _best_ghost_board


## Check if this is a boss
func is_boss() -> bool:
	return enemy_data.get("is_boss", false)
