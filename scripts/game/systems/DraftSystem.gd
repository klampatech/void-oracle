# DraftSystem.gd — Handles random peg offerings and placement after combat
extends Node
class_name DraftSystem

## Tier weights for random selection
const TIER_WEIGHTS := {
	"common": 50,
	"uncommon": 30,
	"rare": 15,
	"legendary": 5,
}

## Peg types by tier (from peg_definitions.json analysis)
const PEGS_BY_TIER := {
	"common": ["stone", "bone"],
	"uncommon": ["fungal", "ember"],
	"rare": ["eye", "heart"],
	"legendary": ["oracle", "void_rift"],
}

## Preload peg definitions
var _peg_data: Dictionary = preload("res://data/pegs/peg_definitions.json")

## Current offerings
var _current_offerings: Array[String] = []

## Selected peg type
var _selected_peg: String = ""

## Placement mode active
var _placement_mode: bool = false

## Board reference
var _board: Node2D = null


func _ready() -> void:
	# Get board reference
	_board = get_tree().get_first_node_in_group("board")
	if not _board:
		_board = get_node_or_null("../Board")


## Generate 3 random peg offerings based on tier weights
func generate_offerings() -> Array[String]:
	_current_offerings.clear()

	var total_weight := 0
	for tier in TIER_WEIGHTS:
		total_weight += TIER_WEIGHTS[tier]

	# Generate 3 offerings
	for i in range(3):
		var roll := randi() % total_weight
		var cumulative := 0
		var selected_tier: String = "common"

		for tier in TIER_WEIGHTS:
			cumulative += TIER_WEIGHTS[tier]
			if roll < cumulative:
				selected_tier = tier
				break

		# Pick random peg from tier
		var pegs: Array = PEGS_BY_TIER[selected_tier]
		var peg: String = pegs[randi() % pegs.size()]

		# Ensure no duplicates
		while peg in _current_offerings:
			pegs = PEGS_BY_TIER[selected_tier]
			peg = pegs[randi() % pegs.size()]

		_current_offerings.append(peg)

	return _current_offerings


## Get current offerings
func get_offerings() -> Array[String]:
	return _current_offerings


## Get peg data for display
func get_peg_info(peg_type: String) -> Dictionary:
	if _peg_data.has(peg_type):
		return _peg_data[peg_type]
	return {}


## Select a peg type for placement
func select_peg(peg_type: String) -> void:
	if peg_type in _current_offerings:
		_selected_peg = peg_type
		_placement_mode = true
		# Emit signal that placement mode started
		EventBus.draft_choice_made.emit(peg_type)


## Get selected peg type
func get_selected_peg() -> String:
	return _selected_peg


## Check if in placement mode
func is_in_placement_mode() -> bool:
	return _placement_mode


## Place peg at position
func place_peg_at(position: Vector2) -> bool:
	if not _placement_mode or _selected_peg.is_empty():
		return false

	if _board and _board.has_method("add_peg_at_position"):
		var peg = _board.add_peg_at_position(_selected_peg, position)
		if peg:
			_reset_draft()
			return true

	return false


## Cancel draft selection
func cancel_selection() -> void:
	_reset_draft()


func _reset_draft() -> void:
	_selected_peg = ""
	_placement_mode = false
	_current_offerings.clear()
