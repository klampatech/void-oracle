# ShopUI.gd — Displays shop services and peg purchases
extends CanvasLayer
class_name ShopUI

## Reference to ShopSystem
var _shop_system: Node = null

## Main container
@onready var _main_container: VBoxContainer = $VBoxContainer

## Peg offers container
@onready var _peg_container: HBoxContainer = $VBoxContainer/PegSection/PegContainer

## Services container
@onready var _services_container: VBoxContainer = $VBoxContainer/ServicesSection/ServicesGrid

## Gold display
@onready var _gold_label: Label = $VBoxContainer/GoldDisplay/GoldLabel

## Close button
@onready var _close_button: Button = $VBoxContainer/CloseButton

## Peg definitions
var _peg_data: Dictionary = {}

## Peg definitions path
const PEG_DATA_PATH := "res://data/pegs/peg_definitions.json"


func _ready() -> void:
	# Load peg definitions
	_load_peg_data()

	# Get ShopSystem reference
	_shop_system = get_tree().get_first_node_in_group("shop_system")
	if not _shop_system:
		_shop_system = get_node_or_null("/root/ShopSystem")

	# Connect close button
	if _close_button:
		_close_button.pressed.connect(_on_close_pressed)

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


## Show shop UI
func show_shop() -> void:
	if not _shop_system:
		return

	# Refresh offerings
	_shop_system.open_shop()

	# Update gold display
	_update_gold_display()

	# Show peg offers
	_show_peg_offers()

	# Show services
	_show_services()

	show()


## Update gold display
func _update_gold_display() -> void:
	if _gold_label:
		_gold_label.text = "Gold: %d" % RunState.gold


## Show peg offerings
func _show_peg_offers() -> void:
	# Clear existing
	for child in _peg_container.get_children():
		child.queue_free()

	if not _shop_system:
		return

	var offers := _shop_system.get_peg_offers()
	for peg_type in offers:
		var card := _create_peg_card(peg_type)
		_peg_container.add_child(card)


## Create peg purchase card
func _create_peg_card(peg_type: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 180)

	# Create vbox for card content
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Peg name
	var name_label := Label.new()
	name_label.text = _peg_data.get(peg_type, {}).get("display_name", peg_type)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Price
	var price := 10
	if _shop_system:
		price = _shop_system.get_peg_price(peg_type)

	var price_label := Label.new()
	price_label.text = "Cost: %d Gold" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(price_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = _peg_data.get(peg_type, {}).get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(130, 60)
	vbox.add_child(desc_label)

	# Buy button
	var buy_button := Button.new()
	buy_button.text = "Buy"
	buy_button.pressed.connect(_on_buy_peg.bind(peg_type))
	vbox.add_child(buy_button)

	# Style
	_add_card_style(card, _peg_data.get(peg_type, {}).get("tier", "common"))

	return card


## Show services
func _show_services() -> void:
	# Clear existing
	for child in _services_container.get_children():
		child.queue_free()

	if not _shop_system:
		return

	# Create service buttons
	var services := [
		{"type": 0, "name": "Bless", "desc": "+1 tier toward Blessed"},
		{"type": 1, "name": "Purify", "desc": "Reset to Dormant"},
		{"type": 2, "name": "Remove", "desc": "Remove a peg"},
		{"type": 3, "name": "Transmute", "desc": "Upgrade to next tier"},
	]

	for service in services:
		var service_card := _create_service_card(service)
		_services_container.add_child(service_card)


## Create service card
func _create_service_card(service: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 120)

	# Create vbox
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Service name
	var name_label := Label.new()
	name_label.text = service["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = service["desc"]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	# Cost
	var cost := 10
	if _shop_system:
		cost = _shop_system.get_service_cost(service["type"])

	var cost_label := Label.new()
	cost_label.text = "Cost: %d Gold" % cost
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(cost_label)

	# Select button
	var select_button := Button.new()
	select_button.text = "Select"
	select_button.pressed.connect(_on_select_service.bind(service["type"]))
	vbox.add_child(select_button)

	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2A2A4A")
	style.border_color = Color("#6A6AAA")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)

	return card


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


func _on_buy_peg(peg_type: String) -> void:
	if not _shop_system:
		return

	if _shop_system.purchase_peg(peg_type):
		# Update gold display
		_update_gold_display()

		# Remove from offers
		_show_peg_offers()


func _on_select_service(service_type: int) -> void:
	if not _shop_system:
		return

	_shop_system.select_service(service_type)

	# For now, close shop and let player click on pegs
	# In a more complete implementation, we'd enter a "service mode" where clicking a peg applies the service
	hide()


func _on_close_pressed() -> void:
	if _shop_system:
		_shop_system.close_shop()
	hide()
