# RunMap.gd — Main map view and navigation controller
extends Control
class_name RunMap

## Map Generator reference
var _map_generator: MapGenerator = null

## Current map data
var _map_data: Dictionary = {}

## Node scene to instantiate
var _map_node_scene: PackedScene = null

## Current player position
var _current_node_id: String = ""

## All map node instances
var _map_nodes: Dictionary = {}

## Connections (lines) between nodes
var _connection_lines: Array[Line2D] = []

## Zone labels
var _zone_labels: Array[Label] = []

## Event signals
signal node_selected(node_id: String, node_data: Dictionary)
signal map_exited()


func _ready() -> void:
	# Load map node scene
	_map_node_scene = preload("res://scenes/game/map/MapNode.tscn")

	# Create MapGenerator
	_map_generator = MapGenerator.new()
	add_child(_map_generator)


## Initialize map with seed
func initialize_map(seed: int) -> void:
	# Generate map data
	_map_data = _map_generator.generate_map(seed)

	# Build visual representation
	_build_map_visuals()


## Build the visual representation of the map
func _build_map_visuals() -> void:
	# Clear existing
	_clear_map()

	# Calculate node positions
	var node_positions: Dictionary = _calculate_node_positions()

	# Draw connections first (so they're behind nodes)
	_draw_connections(node_positions)

	# Create node instances
	_create_nodes(node_positions)

	# Set initial position
	_set_current_node("zone1_start")


## Calculate positions for all nodes
func _calculate_node_positions() -> Dictionary:
	var positions: Dictionary = {}
	var view_size := get_viewport_rect().size

	# Margins
	var margin_x := 80.0
	var margin_y := 100.0

	# Zone widths
	var zone_width := (view_size.x - 2 * margin_x) / 3.0

	# Group nodes by zone
	var zones: Dictionary = {}
	for node in _map_data["nodes"]:
		var zone_num: int = node.get("zone", 1)
		if not zones.has(zone_num):
			zones[zone_num] = []
		zones[zone_num].append(node)

	# Calculate positions for each zone
	for zone_num in zones:
		var zone_nodes: Array = zones[zone_num]
		var zone_x: float = margin_x + (zone_num - 1) * zone_width + zone_width / 2

		# Sort by index
		zone_nodes.sort_custom(func(a, b): return a.get("index", 0) < b.get("index", 0))

		# Calculate Y spacing
		var node_height := (view_size.y - 2 * margin_y) / float(max(1, zone_nodes.size() - 1))

		for i in range(zone_nodes.size()):
			var node: Dictionary = zone_nodes[i]
			var node_id: String = node["id"]

			# Add some randomness to Y position
			var base_y := margin_y + i * node_height
			var y_offset := randf_range(-20, 20)
			var node_y: float = base_y + y_offset

			# Clamp to bounds
			node_y = clamp(node_y, margin_y, view_size.y - margin_y)

			positions[node_id] = Vector2(zone_x, node_y)

	# Add zone labels
	_create_zone_labels(margin_x, zone_width, view_size)

	return positions


## Draw connection lines between nodes
func _draw_connections(positions: Dictionary) -> void:
	for connection in _map_data["connections"]:
		var from_id: String = connection[0]
		var to_id: String = connection[1]

		if positions.has(from_id) and positions.has(to_id):
			var line := Line2D.new()
			line.add_point(positions[from_id])
			line.add_point(positions[to_id])
			line.width = 3.0
			line.default_color = Color(1, 1, 1, 0.3)

			# Add to scene tree
			add_child(line)
			_connection_lines.append(line)


## Create node visual instances
func _create_nodes(positions: Dictionary) -> void:
	for node in _map_data["nodes"]:
		var node_id: String = node["id"]

		if not positions.has(node_id):
			continue

		# Instantiate node
		var map_node: Control = _map_node_scene.instantiate()
		map_node.set_node_data(node)
		map_node.position = positions[node_id] - map_node.size / 2

		# Connect signal
		map_node.node_clicked.connect(_on_node_clicked)

		# Add to scene
		add_child(map_node)
		_map_nodes[node_id] = map_node


## Create zone labels
func _create_zone_labels(margin_x: float, zone_width: float, view_size: Vector2) -> void:
	for zone_num in range(1, 4):
		var label := Label.new()
		label.text = "Zone " + str(zone_num)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var label_x := margin_x + (zone_num - 1) * zone_width + zone_width / 2 - 30
		label.position = Vector2(label_x, 20)

		add_child(label)
		_zone_labels.append(label)


## Handle node click
func _on_node_clicked(node_id: String) -> void:
	# Check if selectable
	if not _is_node_selectable(node_id):
		return

	# Emit signal
	var node_data := _map_generator.get_node(node_id)
	node_selected.emit(node_id, node_data)


## Check if a node is selectable
func _is_node_selectable(node_id: String) -> bool:
	# Must be reachable from current position
	return _map_generator.can_reach_node(_current_node_id, node_id)


## Set current player position
func _set_current_node(node_id: String) -> void:
	# Update old current node
	if _map_nodes.has(_current_node_id):
		_map_nodes[_current_node_id].set_current(false)
		_map_nodes[_current_node_id].set_visited(true)

	# Set new current
	_current_node_id = node_id
	if _map_nodes.has(_current_node_id):
		_map_nodes[_current_node_id].set_current(true)

	# Update selectable states
	_update_selectable_nodes()


## Update which nodes are selectable
func _update_selectable_nodes() -> void:
	for node_id in _map_nodes:
		var is_selectable := _is_node_selectable(node_id)
		_map_nodes[node_id].set_selectable(is_selectable)


## Clear all map visuals
func _clear_map() -> void:
	# Remove node instances
	for node in _map_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	_map_nodes.clear()

	# Remove connection lines
	for line in _connection_lines:
		if is_instance_valid(line):
			line.queue_free()
	_connection_lines.clear()

	# Remove zone labels
	for label in _zone_labels:
		if is_instance_valid(label):
			label.queue_free()
	_zone_labels.clear()


## Travel to a node
func travel_to_node(node_id: String) -> void:
	if _is_node_selectable(node_id):
		_set_current_node(node_id)
		# Emit selection
		var node_data := _map_generator.get_node(node_id)
		node_selected.emit(node_id, node_data)


## Get current node ID
func get_current_node_id() -> String:
	return _current_node_id


## Get current zone
func get_current_zone() -> int:
	var node := _map_generator.get_node(_current_node_id)
	return node.get("zone", 1)


## Check if current zone is complete (boss defeated)
func is_zone_complete(zone_num: int) -> bool:
	# For now, zones are complete when player reaches the boss node
	var boss_node := _map_generator.get_zone_boss(zone_num)
	if boss_node.is_empty():
		return false

	# Check if boss node has been visited
	if _map_nodes.has(boss_node["id"]):
		return _map_nodes[boss_node["id"]].is_visited

	return false


## Get map data for saving
func get_map_data() -> Dictionary:
	return {
		"map": _map_data,
		"current_node": _current_node_id,
		"visited_nodes": _get_visited_nodes(),
	}


## Get list of visited node IDs
func _get_visited_nodes() -> Array[String]:
	var visited: Array[String] = []
	for node_id in _map_nodes:
		if _map_nodes[node_id].is_visited:
			visited.append(node_id)
	return visited


## Restore map state
func restore_map_state(state: Dictionary) -> void:
	if state.has("map"):
		_map_data = state["map"]
		_build_map_visuals()

		# Restore current position
		if state.has("current_node"):
			_set_current_node(state["current_node"])

		# Restore visited nodes
		if state.has("visited_nodes"):
			for node_id in state["visited_nodes"]:
				if _map_nodes.has(node_id):
					_map_nodes[node_id].set_visited(true)
