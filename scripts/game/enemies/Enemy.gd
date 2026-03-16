# Enemy.gd — Base class for all enemies
extends Node2D
class_name Enemy

## Enemy data loaded from JSON
var enemy_data: Dictionary = {}

## Current HP
var hp: int = 0
var max_hp: int = 0

## Enemy ID
var enemy_id: String = ""

## Whether the enemy has been defeated
var _defeated: bool = false


func _ready() -> void:
	pass


## Setup enemy from data file
func setup(data_path: String = "") -> void:
	if not data_path.is_empty():
		load_from_file(data_path)
	_apply_data()


## Load enemy data from JSON file
func load_from_file(data_path: String) -> bool:
	var file_path := "res://data/enemies/" + data_path + ".json"

	if not ResourceLoader.exists(file_path):
		push_warning("Enemy data file not found: " + file_path)
		return false

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("Failed to open enemy data file: " + file_path)
		return false

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_warning("Failed to parse enemy JSON: " + file_path)
		return false

	enemy_data = json.get_data()
	return true


## Apply loaded data to this enemy
func _apply_data() -> void:
	if enemy_data.is_empty():
		return

	enemy_id = enemy_data.get("id", "unknown")
	max_hp = enemy_data.get("max_hp", 100)
	hp = enemy_data.get("hp", max_hp)


## Take damage
func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)

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


## Execute turn - override in subclasses
func execute_turn() -> void:
	# Default implementation - subclasses should override
	pass


## Get intent display text
func get_intent_text() -> String:
	return enemy_data.get("intent_display", "Unknown intent")


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
