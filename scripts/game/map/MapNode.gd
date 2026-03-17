# MapNode.gd — Individual node on the run map
extends Control
class_name MapNode

## Node type textures
const NODE_TEXTURES := {
	"combat": preload("res://assets/textures/ui/map/map_node_combat.png"),
	"elite": preload("res://assets/textures/ui/map/map_node_elite.png"),
	"event": preload("res://assets/textures/ui/map/map_node_event.png"),
	"shop": preload("res://assets/textures/ui/map/map_node_shop.png"),
	"rest": preload("res://assets/textures/ui/map/map_node_rest.png"),
	"boss": preload("res://assets/textures/ui/map/map_node_boss.png"),
	"ghost": preload("res://assets/textures/ui/map/map_node_ghost.png"),
}

## Node type display names
const NODE_NAMES := {
	"start": "Start",
	"combat": "Combat",
	"elite": "Elite",
	"event": "Event",
	"shop": "Shop",
	"rest": "Rest",
	"boss": "Boss",
	"ghost": "Ghost",
}

## Node data
var node_data: Dictionary = {}

## Whether this node is currently selectable
var is_selectable: bool = false

## Whether this node is the current player position
var is_current: bool = false

## Whether this node has been visited
var is_visited: bool = false

## Signal emitted when node is clicked
signal node_clicked(node_id: String)

## Visual components
var _background: TextureRect
var _label: Label
var _selection_indicator: ColorRect

## Fallback color for start node (no texture)
const START_COLOR := Color("#4CAF50")


func _ready() -> void:
	_setup_visuals()


func _setup_visuals() -> void:
	# Use existing scene nodes instead of creating duplicates
	_background = $Background
	_label = $Label
	_selection_indicator = $SelectionIndicator

	# Ensure children pass mouse events through to this Control
	_background.mouse_filter = Control.MOUSE_FILTER_PASS
	_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_selection_indicator.mouse_filter = Control.MOUSE_FILTER_PASS

	# Set size
	custom_minimum_size = Vector2(60, 60)


func _process(_delta: float) -> void:
	# Update visuals based on state
	_update_visuals()


func _update_visuals() -> void:
	if not _background or not _label:
		return

	# Update background texture based on node type
	var node_type: String = node_data.get("type", "combat")
	if NODE_TEXTURES.has(node_type):
		_background.texture = NODE_TEXTURES[node_type]
	else:
		# Start node has no dedicated texture — use modulate tint
		_background.texture = NODE_TEXTURES.get("combat")
		_background.modulate = START_COLOR

	# Update label
	_label.text = NODE_NAMES.get(node_type, node_type)

	# Update size
	if _background:
		_background.size = size

	if _label:
		_label.size = size

	# Show selection indicator for selectable nodes
	if _selection_indicator:
		_selection_indicator.size = size + Vector2(8, 8)
		_selection_indicator.position = Vector2(-4, -4)
		_selection_indicator.visible = is_selectable and not is_current

	# Dim visited nodes
	if is_visited and not is_current:
		modulate = Color(1, 1, 1, 0.5)
	elif is_current:
		modulate = Color(1.2, 1.2, 1.2, 1)  # Slightly brighter
	else:
		modulate = Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_selectable:
				node_clicked.emit(node_data.get("id", ""))


## Set node data
func set_node_data(data: Dictionary) -> void:
	node_data = data
	_update_visuals()


## Set selectable state
func set_selectable(selectable: bool) -> void:
	is_selectable = selectable
	_update_visuals()


## Set current position
func set_current(current: bool) -> void:
	is_current = current
	_update_visuals()


## Set visited state
func set_visited(visited: bool) -> void:
	is_visited = visited
	_update_visuals()


## Get node ID
func get_node_id() -> String:
	return node_data.get("id", "")
