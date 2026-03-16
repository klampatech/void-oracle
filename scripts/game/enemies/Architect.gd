# Architect.gd — Zone 2 Boss: creates cracks in the board frame
extends Node2D
class_name Architect

## Enemy data loaded from JSON
var enemy_data: Dictionary = {}

## Current HP
var hp: int = 0
var max_hp: int = 0

## Enemy ID
var enemy_id: String = "architect"

## Current phase (1, 2, or 3)
var _current_phase: int = 1

## Whether the enemy has been defeated
var _defeated: bool = false

## Turn counter for phase 1 crack timing
var _turn_count: int = 0

## Number of cracks created
var _crack_count: int = 0

## Board reference for frame manipulation
var _board: Node = null

## Control node for UI
@onready var _ui: Control = $EnemyUI


func _ready() -> void:
	# Load architect data
	_load_data()


## Load enemy data from JSON
func _load_data() -> void:
	var file_path := "res://data/enemies/architect.json"

	if not ResourceLoader.exists(file_path):
		push_warning("Enemy data file not found: " + file_path)
		# Set defaults
		max_hp = 200
		hp = 200
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
	enemy_id = enemy_data.get("id", "architect")
	max_hp = enemy_data.get("max_hp", 200)
	hp = enemy_data.get("hp", max_hp)

	# Initialize phase
	_current_phase = 1
	_turn_count = 0
	_crack_count = 0

	# Update UI if present
	_update_ui()


func _update_ui() -> void:
	if _ui:
		var hp_bar: ProgressBar = _ui.get_node_or_null("Panel/VBox/HPBar")
		if hp_bar:
			hp_bar.max_value = max_hp
			hp_bar.value = hp

		# Update phase indicator if exists
		var phase_label = _ui.get_node_or_null("Panel/VBox/PhaseLabel")
		if phase_label:
			phase_label.text = "Phase " + str(_current_phase)

		# Update crack count
		var crack_label = _ui.get_node_or_null("Panel/VBox/CrackLabel")
		if crack_label:
			crack_label.text = "Cracks: " + str(_crack_count)


## Take damage
func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)

	# Check for phase change
	_check_phase_change()

	# Update UI
	_update_ui()

	if hp <= 0:
		_defeated = true
		die()


## Check if phase should change
func _check_phase_change() -> void:
	var hp_percent := get_hp_percent()

	# Phase 2 starts when HP drops below 60%
	if _current_phase == 1 and hp_percent < 0.6:
		_current_phase = 2
		EventBus.boss_phase_changed.emit(_current_phase)
		print("Architect entered Phase 2! Cracks become Void Channels.")
		_apply_phase_2_effects()

	# Phase 3 starts when HP drops below 30%
	elif _current_phase == 2 and hp_percent < 0.3:
		_current_phase = 3
		EventBus.boss_phase_changed.emit(_current_phase)
		print("Architect entered Phase 3! Cracks become hazards.")
		_apply_phase_3_effects()


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


## Phase 1: Crack board frame every 2 turns
func _phase_1_actions() -> void:
	# Only crack every 2 turns
	if _turn_count % 2 == 1:
		_create_board_crack()

	# Emit action signal
	var action := {
		"type": "crack_frame",
		"phase": 1,
		"turn": _turn_count,
		"cracks": _crack_count,
	}
	EventBus.enemy_action.emit(self, action)


## Phase 2: Cracks become Void Channels (double void essence)
func _phase_2_actions() -> void:
	# Phase 2 still creates cracks but they have void channel effect
	if _turn_count % 2 == 1:
		_create_board_crack()

	# Emit action signal
	var action := {
		"type": "void_channels",
		"phase": 2,
		"turn": _turn_count,
		"cracks": _crack_count,
	}
	EventBus.enemy_action.emit(self, action)


## Phase 3: Cracks become hazards (balls gain Cursed)
func _phase_3_actions() -> void:
	# Phase 3 still creates cracks but they have hazard effect
	if _turn_count % 2 == 1:
		_create_board_crack()

	# Emit action signal
	var action := {
		"type": "hazard_cracks",
		"phase": 3,
		"turn": _turn_count,
		"cracks": _crack_count,
	}
	EventBus.enemy_action.emit(self, action)


## Create a crack in the board frame
func _create_board_crack() -> void:
	# Find the board
	if not _board:
		_board = get_tree().get_first_node_in_group("board")

	if _board and _board.has_method("add_crack"):
		var crack_data := {
			"phase": _current_phase,
			"position": _calculate_crack_position(),
		}
		_board.add_crack(crack_data)
		_crack_count += 1
		_update_ui()


## Calculate a position for a new crack (along the sides of the board)
func _calculate_crack_position() -> Vector2:
	# Cracks appear along the left and right edges of the board
	# Randomly choose left or right side
	var is_left := randi() % 2 == 0

	if not _board:
		# Default positions if board not found
		return Vector2(0, 300 + _crack_count * 100) if is_left else Vector2(600, 300 + _crack_count * 100)

	# Get board dimensions
	var board_width := 600  # Default
	var board_height := 900  # Default

	if _board.has_method("get_board_width"):
		board_width = _board.get_board_width()
	if _board.has_method("get_board_height"):
		board_height = _board.get_board_height()

	# Position crack along the side, randomly along the height
	var crack_y := randf_range(200, board_height - 200)
	var crack_x := 20 if is_left else board_width - 20

	return Vector2(crack_x, crack_y)


## Apply phase 2 effects (Void Channels)
func _apply_phase_2_effects() -> void:
	if _board and _board.has_method("set_crack_effect"):
		_board.set_crack_effect("void_channel")

	print("Architect: Cracks now grant 2x Void Essence!")


## Apply phase 3 effects (Hazards - balls gain Cursed)
func _apply_phase_3_effects() -> void:
	if _board and _board.has_method("set_crack_effect"):
		_board.set_crack_effect("hazard")

	print("Architect: Cracks now curse balls that touch them!")


## Get intent display text
func get_intent_text() -> String:
	match _current_phase:
		1:
			if _turn_count % 2 == 1:
				return "Will crack the frame"
			else:
				return "Gathering strength..."
		2:
			if _turn_count % 2 == 1:
				return "Will strengthen cracks"
			else:
				return "Void energy builds..."
		3:
			if _turn_count % 2 == 1:
				return "Will hazard cracks"
			else:
				return "Chaos intensifies..."
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


## Get crack count
func get_crack_count() -> int:
	return _crack_count


## Check if this is a boss
func is_boss() -> bool:
	return enemy_data.get("is_boss", false)
