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

## Preloaded card textures
var _card_bg_texture: Texture2D = preload("res://assets/textures/ui/draft/draft_card_background.png")
var _tier_textures: Dictionary = {
	"common": preload("res://assets/textures/ui/draft/draft_tier_common.png"),
	"uncommon": preload("res://assets/textures/ui/draft/draft_tier_uncommon.png"),
	"rare": preload("res://assets/textures/ui/draft/draft_tier_rare.png"),
	"legendary": preload("res://assets/textures/ui/draft/draft_tier_legendary.png"),
}

## Peg definitions
var _peg_data: Dictionary = {}

## Peg definitions path
const PEG_DATA_PATH := "res://data/pegs/peg_definitions.json"


func _ready() -> void:
	# Load peg definitions
	_load_peg_data()

	# Get DraftSystem reference
	_draft_system = get_tree().get_first_node_in_group("draft_system")
	if not _draft_system:
		_draft_system = get_node_or_null("/root/DraftSystem")

	# Hide initially
	hide()


func _load_peg_data() -> void:
	var file := FileAccess.open(PEG_DATA_PATH, FileAccess.READ)
	if file:
		var json_text := file.get_as_text()
		var json := JSON.new()
		var error := json.parse(json_text)
		if error == OK:
			_peg_data = json.data
		file.close()


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
	var card := Control.new()
	card.custom_minimum_size = Vector2(150, 220)

	# Card background texture
	var card_bg := TextureRect.new()
	card_bg.texture = _card_bg_texture
	card_bg.expand_mode = 1  # Ignore size
	card_bg.stretch_mode = 5  # Keep aspect covered
	card_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_bg)

	# Tier frame overlay
	var tier: String = _get_tier_for_peg(peg_type)
	var tier_overlay := TextureRect.new()
	if _tier_textures.has(tier):
		tier_overlay.texture = _tier_textures[tier]
	tier_overlay.expand_mode = 1
	tier_overlay.stretch_mode = 5
	tier_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tier_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tier_overlay)

	# Content margin
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	# Create vbox for card content
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# Peg name
	var name_label := Label.new()
	name_label.text = _peg_data.get(peg_type, {}).get("display_name", peg_type)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	vbox.add_child(name_label)

	# Tier label
	var tier_label := Label.new()
	tier_label.text = tier.to_upper()
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 12)
	tier_label.add_theme_color_override("font_color", _get_tier_color(tier))
	vbox.add_child(tier_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Description
	var desc_label := Label.new()
	desc_label.text = _peg_data.get(peg_type, {}).get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(120, 60)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	# Click handler
	card.gui_input.connect(_on_card_clicked.bind(peg_type))
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	return card


func _get_tier_color(tier: String) -> Color:
	match tier:
		"common":
			return Color(0.7, 0.7, 0.7)
		"uncommon":
			return Color(0.4, 0.8, 0.4)
		"rare":
			return Color(0.6, 0.4, 0.9)
		"legendary":
			return Color(1, 0.84, 0.3)
		_:
			return Color(0.7, 0.7, 0.7)


func _get_tier_for_peg(peg_type: String) -> String:
	var peg_info: Dictionary = _peg_data.get(peg_type, {})
	return peg_info.get("tier", "common")


func _on_card_clicked(event: InputEvent, peg_type: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _draft_system and _draft_system.has_method("select_peg"):
			_draft_system.select_peg(peg_type)
			hide()
