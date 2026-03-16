# Gardener.gd — Zone 1 Boss: multi-phase gardener enemy
extends Node2D
class_name Gardener

## Enemy data loaded from JSON
var enemy_data: Dictionary = {}

## Current HP
var hp: int = 0
var max_hp: int = 0

## Enemy ID
var enemy_id: String = "gardener"

## Current phase (1 or 2)
var _current_phase: int = 1

## Whether the enemy has been defeated
var _defeated: bool = false

## Thorn peg scene for phase 2
var _thorn_pegs_placed: int = 0

## Control node for UI
@onready var _ui: Control = $EnemyUI


func _ready() -> void:
	# Load gardener data
	_load_data()


## Load enemy data from JSON
func _load_data() -> void:
	var file_path := "res://data/enemies/gardener.json"

	if not ResourceLoader.exists(file_path):
		push_warning("Enemy data file not found: " + file_path)
		# Set defaults
		max_hp = 150
		hp = 150
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
	enemy_id = enemy_data.get("id", "gardener")
	max_hp = enemy_data.get("max_hp", 150)
	hp = enemy_data.get("hp", max_hp)

	# Initialize phase
	_current_phase = 1

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

	# Phase 2 starts when HP drops below 50%
	if _current_phase == 1 and hp_percent < 0.5:
		_current_phase = 2
		EventBus.boss_phase_changed.emit(_current_phase)
		print("Gardener entered Phase 2!")


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

	match _current_phase:
		1:
			_phase_1_actions()
		2:
			_phase_2_actions()


## Phase 1: Convert 1 Blessed → Dormant per turn
func _phase_1_actions() -> void:
	# Prune a blessed peg
	var pruned := _prune_blessed_peg()

	# Emit action signal
	var action := {
		"type": "prune",
		"phase": 1,
		"pruned": pruned,
	}
	EventBus.enemy_action.emit(self, action)


## Phase 2: Convert 1 Blessed → Dormant + place 2 Thorn pegs
func _phase_2_actions() -> void:
	# Prune a blessed peg
	var pruned := _prune_blessed_peg()

	# Place thorn pegs
	_place_thorn_pegs()

	# Emit action signal
	var action := {
		"type": "prune_and_thorns",
		"phase": 2,
		"pruned": pruned,
		"thorns_placed": 2,
	}
	EventBus.enemy_action.emit(self, action)


## Try to prune a blessed peg (convert to dormant)
## Returns true if successful
func _prune_blessed_peg() -> bool:
	var pegs := get_tree().get_nodes_in_group("peg")
	if pegs.is_empty():
		return false

	# Find blessed pegs that are NOT void_touched (the weakness)
	var targetable_pegs: Array[Node] = []
	var void_touched_pegs: Array[Node] = []

	for peg in pegs:
		if not peg.has_method("get_peg_state"):
			continue

		var state: String = peg.get_peg_state()
		var peg_type: String = ""

		if peg.has_method("get_peg_type_string"):
			peg_type = peg.get_peg_type_string()

		# Skip void_touched pegs (weakness)
		if state == "void_touched":
			void_touched_pegs.append(peg)
			continue

		# Target blessed pegs first
		if state == "blessed":
			targetable_pegs.append(peg)

	# If no blessed pegs, target any non-void, non-void_touched, non-cursed peg
	if targetable_pegs.is_empty():
		for peg in pegs:
			if not peg.has_method("get_peg_state"):
				continue
			if not peg.has_method("get_peg_type_string"):
				continue

			var state: String = peg.get_peg_state()
			var peg_type: String = peg.get_peg_type_string()

			# Skip void rift, oracle, void_touched, and already cursed
			if state == "void_touched" or state == "cursed":
				continue
			if peg_type == "void_rift" or peg_type == "oracle":
				continue

			targetable_pegs.append(peg)

	if not targetable_pegs.is_empty():
		var target: Node = targetable_pegs.pick_random()
		if target.has_method("mutate_to"):
			target.mutate_to("dormant")
			return true

	return false


## Place thorn pegs in phase 2
func _place_thorn_pegs() -> void:
	var board := get_tree().get_first_node_in_group("board")
	if not board:
		return

	# Try to place 2 thorn pegs
	for i in range(2):
		var placed := _try_place_thorn(board)
		if placed:
			_thorn_pegs_placed += 1


## Try to place a single thorn peg
func _try_place_thorn(board: Node) -> bool:
	# Find empty slot
	if not board.has_method("get_empty_slots"):
		return false

	var empty_slots = board.get_empty_slots()
	if empty_slots.is_empty():
		return false

	# Pick a random empty slot
	var slot_position = empty_slots.pick_random()

	# Create thorn peg using the board's add_peg_at_position
	if board.has_method("add_peg_at_position"):
		var success = board.add_peg_at_position("thorn", slot_position)
		return success

	return false


## Get intent display text
func get_intent_text() -> String:
	match _current_phase:
		1:
			return enemy_data.get("intent_display", "Will prune a peg")
		2:
			return "Will prune + place thorns"
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


## Check if this is a boss
func is_boss() -> bool:
	return enemy_data.get("is_boss", false)
