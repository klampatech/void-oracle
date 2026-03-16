# Leech.gd — Enemy type: steals gold each turn
extends Node2D
class_name Leech

## Enemy data loaded from JSON
var enemy_data: Dictionary = {}

## Current HP
var hp: int = 0
var max_hp: int = 0

## Enemy ID
var enemy_id: String = "leech"

## Stability damage per turn
const STABILITY_DAMAGE := 6

## Gold stolen per turn
const GOLD_STEAL_AMOUNT := 5

## Whether the enemy has been defeated
var _defeated: bool = false

## Control node for UI
@onready var _ui: Control = $EnemyUI


func _ready() -> void:
	# Load leech data
	_load_data()


## Load enemy data from JSON
func _load_data() -> void:
	var file_path := "res://data/enemies/leech.json"

	if not ResourceLoader.exists(file_path):
		push_warning("Enemy data file not found: " + file_path)
		# Set defaults
		max_hp = 90
		hp = 90
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
	enemy_id = enemy_data.get("id", "leech")
	max_hp = enemy_data.get("max_hp", 90)
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


## Execute turn: steal gold, then damage stability
func execute_turn() -> void:
	if _defeated:
		return

	# Step 1: Steal gold from player
	var gold_stolen := _steal_gold()

	# Step 2: Deal stability damage
	_run_attack()

	# Emit action signal
	var action := {
		"type": "drain_and_attack",
		"gold_stolen": gold_stolen,
		"damage": STABILITY_DAMAGE,
	}
	EventBus.enemy_action.emit(self, action)


## Steal gold from the player
## Returns amount actually stolen (may be less if player has less gold)
func _steal_gold() -> int:
	# Check current gold
	var current_gold: int = RunState.gold

	if current_gold <= 0:
		return 0

	# Calculate steal amount (can't steal more than player has)
	var steal_amount := mini(GOLD_STEAL_AMOUNT, current_gold)

	# Deduct from player (negative delta = stolen)
	RunState.modify_gold(-steal_amount)

	# Emit gold stolen signal
	EventBus.gold_stolen.emit(steal_amount)

	return steal_amount


## Deal stability damage to player
func _run_attack() -> void:
	RunState.modify_stability(-STABILITY_DAMAGE)


## Get intent display text
func get_intent_text() -> String:
	return enemy_data.get("intent_display", "Will steal gold")


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
