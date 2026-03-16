# Corruptor.gd — First enemy type: corrupts blessed pegs each turn
extends Node2D
class_name Corruptor

## Enemy data loaded from JSON
var enemy_data: Dictionary = {}

## Current HP
var hp: int = 0
var max_hp: int = 0

## Enemy ID
var enemy_id: String = "corruptor"

## Stability damage per turn
const STABILITY_DAMAGE := 10

## Whether the enemy has been defeated
var _defeated: bool = false

## Control node for UI
@onready var _ui: Control = $EnemyUI


func _ready() -> void:
	# Load corruptor data
	_load_data()


## Load enemy data from JSON
func _load_data() -> void:
	var file_path := "res://data/enemies/corruptor.json"

	if not ResourceLoader.exists(file_path):
		push_warning("Enemy data file not found: " + file_path)
		# Set defaults
		max_hp = 80
		hp = 80
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
	enemy_id = enemy_data.get("id", "corruptor")
	max_hp = enemy_data.get("max_hp", 80)
	hp = enemy_data.get("hp", max_hp)

	# Update UI if present
	_update_ui()


func _update_ui() -> void:
	if _ui:
		var hp_bar: ProgressBar = _ui.get_node_or_null("Panel/VBox/HPBar")
		if hp_bar:
			hp_bar.max_value = max_hp
			hp_bar.value = hp


## Take damage
func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)

	# Update UI
	_update_ui()

	if hp <= 0:
		_defeated = true
		die()


## Check if defeated
func is_defeated() -> bool:
	return _defeated


## Called when HP reaches 0
func die() -> void:
	EventBus.enemy_defeated.emit(self)

	# Queue free after a delay for death animation
	await get_tree().create_timer(0.5).timeout
	queue_free()


## Execute turn: corrupt a random blessed peg, then damage stability
func execute_turn() -> void:
	if _defeated:
		return

	# Step 1: Try to corrupt a blessed peg
	var corrupted := _corrupt_blessed_peg()

	# Step 2: Deal stability damage
	_run_attack()

	# Emit action signal
	var action := {
		"type": "corrupt_and_attack",
		"corrupted": corrupted,
		"damage": STABILITY_DAMAGE,
	}
	EventBus.enemy_action.emit(self, action)


## Try to corrupt a blessed peg
## Returns true if successful, false if no blessed pegs found
func _corrupt_blessed_peg() -> bool:
	# Get all pegs
	var pegs := get_tree().get_nodes_in_group("peg")
	if pegs.is_empty():
		return false

	# Find blessed pegs
	var blessed_pegs: Array[Node] = []
	for peg in pegs:
		if peg.has_method("get_peg_state") and peg.get_peg_state() == "blessed":
			blessed_pegs.append(peg)

	if not blessed_pegs.is_empty():
		# Corrupt a random blessed peg
		var target: Node = blessed_pegs.pick_random()
		if target.has_method("mutate_to"):
			target.mutate_to("cursed")
			return true
	else:
		# No blessed pegs - try to corrupt any non-void peg
		var corruptable_pegs: Array[Node] = []
		for peg in pegs:
			if peg.has_method("get_peg_state"):
				var state: String = peg.get_peg_state()
				if state != "void" and state != "cursed":
					corruptable_pegs.append(peg)

		if not corruptable_pegs.is_empty():
			var target: Node = corruptable_pegs.pick_random()
			if target.has_method("mutate_to"):
				target.mutate_to("cursed")
				return true

	return false


## Deal stability damage to player
func _run_attack() -> void:
	RunState.modify_stability(-STABILITY_DAMAGE)


## Get intent display text
func get_intent_text() -> String:
	return enemy_data.get("intent_display", "Will corrupt a peg")


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
