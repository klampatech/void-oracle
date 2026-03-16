# ShopSystem.gd — Handles shop services, peg purchases, and relic acquisitions
extends Node
class_name ShopSystem

## Shop service types
enum ServiceType { BLESS, PURIFY, REMOVE, TRANSMUTE }

## Service costs
const SERVICE_COSTS := {
	ServiceType.BLESS: 15,
	ServiceType.PURIFY: 10,
	ServiceType.REMOVE: 5,
	ServiceType.TRANSMUTE: 25,
}

## Peg definitions path
const PEG_DATA_PATH := "res://data/pegs/peg_definitions.json"

## Peg definitions
var _peg_data: Dictionary = {}

## Current shop offerings
var _current_peg_offers: Array[String] = []
var _current_relic_offers: Array[String] = []

## Shop reference
var _board: Node2D = null

## Shop active state
var _shop_active: bool = false

## Selected service type
var _selected_service: ServiceType = ServiceType.BLESS

## Peg tier progression
const TIER_PROGRESSION := ["dormant", "blessed", "sacred", "divine"]


func _ready() -> void:
	# Load peg definitions
	_load_peg_data()

	# Get board reference
	_board = get_tree().get_first_node_in_group("board")
	if not _board:
		_board = get_node_or_null("../Board")


func _load_peg_data() -> void:
	var file := FileAccess.open(PEG_DATA_PATH, FileAccess.READ)
	if file:
		var json_text := file.get_as_text()
		var json := JSON.new()
		var error := json.parse(json_text)
		if error == OK:
			_peg_data = json.data
		file.close()


## Generate shop offerings (pegs and relics)
func generate_offerings() -> void:
	_current_peg_offers.clear()
	_current_relic_offers.clear()

	# Generate 2-3 peg offers
	var peg_count := randi_range(2, 3)
	for i in range(peg_count):
		var peg_type := _random_peg_type()
		while peg_type in _current_peg_offers:
			peg_type = _random_peg_type()
		_current_peg_offers.append(peg_type)

	# Generate 1-2 relic offers (placeholder - relics system not fully implemented)
	var relic_count := randi_range(1, 2)
	for i in range(relic_count):
		_current_relic_offers.append("relic_placeholder_" + str(i + 1))


## Get random peg type
func _random_peg_type() -> String:
	var pegs := ["stone", "bone", "fungal", "ember", "eye", "heart", "oracle", "void_rift"]
	return pegs[randi() % pegs.size()]


## Get current peg offers
func get_peg_offers() -> Array[String]:
	return _current_peg_offers


## Get current relic offers
func get_relic_offers() -> Array[String]:
	return _current_relic_offers


## Get peg info for display
func get_peg_info(peg_type: String) -> Dictionary:
	if _peg_data.has(peg_type):
		return _peg_data[peg_type]
	return {}


## Get peg purchase price
func get_peg_price(peg_type: String) -> int:
	var info := get_peg_info(peg_type)
	if info.is_empty():
		return 10
	# Price based on rarity
	match info.get("rarity", "common"):
		"common":
			return 10
		"uncommon":
			return 20
		"rare":
			return 35
		"legendary":
			return 50
	return 10


## Get service cost
func get_service_cost(service: ServiceType) -> int:
	return SERVICE_COSTS.get(service, 10)


## Open shop
func open_shop() -> void:
	_shop_active = true
	generate_offerings()


## Close shop
func close_shop() -> void:
	_shop_active = false


## Is shop active
func is_shop_active() -> bool:
	return _shop_active


## Select service type
func select_service(service: ServiceType) -> void:
	_selected_service = service


## Get selected service
func get_selected_service() -> ServiceType:
	return _selected_service


## Execute selected service on a peg
func execute_service_on_peg(peg: Node) -> bool:
	if not _can_afford_service(_selected_service):
		return false

	var success := false
	match _selected_service:
		ServiceType.BLESS:
			success = _bless_peg(peg)
		ServiceType.PURIFY:
			success = _purify_peg(peg)
		ServiceType.REMOVE:
			success = _remove_peg(peg)
		ServiceType.TRANSMUTE:
			success = _transmute_peg(peg)

	if success:
		_deduct_gold(get_service_cost(_selected_service))
		EventBus.shop_purchase.emit("service_" + ServiceType.keys()[_selected_service], get_service_cost(_selected_service))

	return success


## Bless a peg (+1 tier toward Blessed)
func _bless_peg(peg: Node) -> bool:
	if not _has_method(peg, "get_peg_state_string"):
		return false

	var current_state: String = peg.get_peg_state_string()
	var current_tier := TIER_PROGRESSION.find(current_state)

	# If already at max tier, can't bless
	if current_tier >= TIER_PROGRESSION.size() - 1:
		return false

	# Advance one tier
	var new_state := TIER_PROGRESSION[current_tier + 1]
	if _has_method(peg, "set_peg_state"):
		peg.set_peg_state(new_state)
		return true

	return false


## Purify a peg (reset to Dormant)
func _purify_peg(peg: Node) -> bool:
	if not _has_method(peg, "set_peg_state"):
		return false

	peg.set_peg_state("dormant")
	return true


## Remove a peg (free a slot)
func _remove_peg(peg: Node) -> bool:
	if is_instance_valid(peg):
		peg.queue_free()
		return true
	return false


## Transmute pegs (sacrifice 2 pegs to create 1 of the next tier)
func _transmute_peg(peg: Node) -> bool:
	# Get the peg type
	var peg_type: String = ""
	if _has_method(peg, "get_peg_type_string"):
		peg_type = peg.get_peg_type_string()

	if peg_type.is_empty():
		return false

	# Remove the target peg
	peg.queue_free()

	# Get next tier peg of same type (simplified - just upgrade to next in list)
	var pegs := ["stone", "bone", "fungal", "ember", "eye", "heart", "oracle", "void_rift"]
	var current_idx := pegs.find(peg_type)
	if current_idx < 0 or current_idx >= pegs.size() - 1:
		return false

	var upgraded_type := pegs[current_idx + 1]

	# Find an empty position near the removed peg (simplified - use same position)
	var position := Vector2.ZERO
	if _has_method(peg, "get_position"):
		position = peg.get_position()

	# Spawn upgraded peg
	if _board and _board.has_method("add_peg_at_position"):
		var new_peg = _board.add_peg_at_position(upgraded_type, position)
		return new_peg != null

	return false


## Check if player can afford service
func _can_afford_service(service: ServiceType) -> bool:
	return RunState.gold >= get_service_cost(service)


## Check if player can afford peg
func can_afford_peg(peg_type: String) -> bool:
	return RunState.gold >= get_peg_price(peg_type)


## Purchase a peg
func purchase_peg(peg_type: String) -> bool:
	if not can_afford_peg(peg_type):
		return false

	# Deduct gold
	_deduct_gold(get_peg_price(peg_type))

	# Emit purchase event
	EventBus.shop_purchase.emit("peg_" + peg_type, get_peg_price(peg_type))

	# Return success - UI will handle placement mode
	return true


## Purchase a relic
func purchase_relic(relic_id: String) -> bool:
	# Placeholder - relics system not fully implemented
	return false


## Deduct gold
func _deduct_gold(amount: int) -> void:
	RunState.gold -= amount


## Helper to check if node has method
func _has_method(node: Node, method_name: String) -> bool:
	return node and is_instance_valid(node) and node.has_method(method_name)
