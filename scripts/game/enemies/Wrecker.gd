# Wrecker.gd — Enemy type: shatters pegs each turn
extends Node2D
class_name Wrecker

## Enemy data loaded from JSON
var enemy_data: Dictionary = {}

## Current HP
var hp: int = 0
var max_hp: int = 0

## Enemy ID
var enemy_id: String = "wrecker"

## Stability damage per turn
const STABILITY_DAMAGE := 8

## Whether the enemy has been defeated
var _defeated: bool = false

## Control node for UI
@onready var _ui: Control = $EnemyUI


func _ready() -> void:
	# Load wrecker data
	_load_data()


## Load enemy data from JSON
func _load_data() -> void:
	var file_path := "res://data/enemies/wrecker.json"

	if not ResourceLoader.exists(file_path):
		push_warning("Enemy data file not found: " + file_path)
		# Set defaults
		max_hp = 100
		hp = 100
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
	enemy_id = enemy_data.get("id", "wrecker")
	max_hp = enemy_data.get("max_hp", 100)
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


## Execute turn: shatter a random peg, then damage stability
func execute_turn() -> void:
	if _defeated:
		return

	# Step 1: Try to shatter a peg
	var shattered := _shatter_peg()

	# Step 2: Deal stability damage
	_run_attack()

	# Emit action signal
	var action := {
		"type": "shatter_and_attack",
		"shattered": shattered,
		"damage": STABILITY_DAMAGE,
	}
	EventBus.enemy_action.emit(self, action)


## Try to shatter a random peg
## Returns true if successful, false if no pegs found
func _shatter_peg() -> bool:
	# Get all pegs
	var pegs := get_tree().get_nodes_in_group("peg")
	if pegs.is_empty():
		return false

	# Pick a random peg to shatter (prefer non-void, non-Oracle pegs)
	var shatterable_pegs: Array[Node] = []
	var fallback_pegs: Array[Node] = []

	for peg in pegs:
		# Skip void rift and oracle pegs as they're special
		if peg.has_method("get_peg_type_string"):
			var peg_type: String = peg.get_peg_type_string()
			if peg_type == "void_rift" or peg_type == "oracle":
				fallback_pegs.append(peg)
				continue
		shatterable_pegs.append(peg)

	# Use shatterable pegs if available, otherwise use fallback
	var target_list := shatterable_pegs if not shatterable_pegs.is_empty() else fallback_pegs

	if target_list.is_empty():
		return false

	# Shatter a random peg
	var target: Node = target_list.pick_random()
	if is_instance_valid(target):
		# Emit destroyed signal before removing
		EventBus.peg_destroyed.emit(target)
		# Remove the peg
		target.queue_free()
		return true

	return false


## Deal stability damage to player
func _run_attack() -> void:
	RunState.modify_stability(-STABILITY_DAMAGE)


## Get intent display text
func get_intent_text() -> String:
	return enemy_data.get("intent_display", "Will shatter a peg")


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
