# DraftUI.gd — Displays 3 peg cards for selection
extends CanvasLayer
class_name DraftUI

## Reference to DraftSystem (will be added as autoload later)
var _draft_system: Node = null

## Card container
@onready var _card_container: HBoxContainer = $VBoxContainer/CardContainer

## Label for instructions
@onready var _instructions: Label = $VBoxContainer/Instructions

## Preload peg scenes
var _peg_scenes: Dictionary = {
	"stone": preload("res://scenes/game/pegs/StonePeg.tscn"),
	"bone": preload("res://scenes/game/pegs/BonePeg.tscn"),
	"fungal": preload("res://scenes/game/pegs/FungalPeg.tscn"),
	"ember": preload("res://scenes/game/pegs/EmberPeg.tscn"),
	"eye": preload("res://scenes/game/pegs/EyePeg.tscn"),
	"heart": preload("res://scenes/game/pegs/HeartPeg.tscn"),
	"oracle": preload("res://scenes/game/pegs/OraclePeg.tscn"),
	"void_rift": preload("res://scenes/game/pegs/VoidRiftPeg.tscn"),
}

## Peg definitions
var _peg_data: Dictionary = preload("res://data/pegs/peg_definitions.json")


func _ready() -> void:
	# Get DraftSystem reference
	_draft_system = get_tree().get_first_node_in_group("draft_system")
	if not _draft_system:
		_draft_system = get_node_or_null("/root/DraftSystem")

	# Hide initially
	hide()


## Show draft UI with offerings
func show_draft(offerings: Array[String]) -> void:
	# Clear existing cards
	for child in _card_container.get_children():
		child.queue_free()

	# Create card for each offering
	for peg_type in offerings:
		var card := _create_card(peg_type)
		_card_container.add_child(card)

	show()


## Create a single peg card
func _create_card(peg_type: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 200)

	# Create vbox for card content
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Peg name
	var name_label := Label.new()
	name_label.text = _peg_data.get(peg_type, {}).get("display_name", peg_type)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Tier label
	var tier_label := Label.new()
	var tier: String = _get_tier_for_peg(peg_type)
	tier_label.text = tier
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(tier_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = _peg_data.get(peg_type, {}).get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(130, 60)
	vbox.add_child(desc_label)

	# Click handler
	card.gui_input.connect(_on_card_clicked.bind(peg_type))

	# Style by tier
	_add_card_style(card, tier)

	return card


func _get_tier_for_peg(peg_type: String) -> String:
	var peg_info: Dictionary = _peg_data.get(peg_type, {})
	return peg_info.get("tier", "common")


func _add_card_style(card: PanelContainer, tier: String) -> void:
	var color: Color
	match tier:
		"common":
			color = Color("#888888")
		"uncommon":
			color = Color("#4A7A3A")
		"rare":
			color = Color("#9060E8")
		"legendary":
			color = Color("#C9A84C")
		_:
			color = Color("#888888")

	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.3)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)


func _on_card_clicked(event: InputEvent, peg_type: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _draft_system and _draft_system.has_method("select_peg"):
			_draft_system.select_peg(peg_type)
			hide()
