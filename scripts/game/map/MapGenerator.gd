# MapGenerator.gd — Generates procedural run maps with DAG structure
extends Node
class_name MapGenerator

## Node types and their weights (excluding guaranteed nodes)
const NODE_TYPE_WEIGHTS := {
	"combat": 40,
	"elite": 15,
	"event": 20,
	"shop": 10,
	"rest": 10,
}

## Number of zones
const ZONE_COUNT := 3

## Nodes per zone range
const NODES_PER_ZONE_MIN := 8
const NODES_PER_ZONE_MAX := 10

## Current map data
var _map_data: Dictionary = {}

## Seed for RNG
var _seed: int = 0

## RNG instance
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Board tag weights for node generation
const BOARD_TAG_WEIGHTS := {
	"growth": {"event": 10},      # More mycologist events
	"death": {"elite": 10},       # More elite (hard) encounters
	"void": {"event": 10},        # More void events
	"fire": {"elite": 5},         # More elite (dangerous) encounters
	"nature": {"rest": 10},        # More rest sites
}


## Generate a new map
func generate_map(seed: int) -> Dictionary:
	_seed = seed
	_rng.seed = seed
	_map_data = {
		"version": "1.0",
		"seed": seed,
		"zones": [],
		"nodes": [],
		"connections": [],
	}

	# Generate each zone
	for zone_num in range(1, ZONE_COUNT + 1):
		_generate_zone(zone_num)

	# Generate connections between zones (DAG)
	_generate_connections()

	# Add start node
	_add_start_node()

	return _map_data


## Generate a single zone
func _generate_zone(zone_num: int) -> void:
	var node_count: int = _rng.randi_range(NODES_PER_ZONE_MIN, NODES_PER_ZONE_MAX)
	var zone_nodes: Array[Dictionary] = []

	# Determine if this zone has a boss
	var is_boss_zone: bool = zone_num == ZONE_COUNT

	# Reserve spots for guaranteed nodes
	var guaranteed_nodes: Array[Dictionary] = []

	# Add boss at end of final zone
	if is_boss_zone:
		guaranteed_nodes.append({
			"type": "boss",
			"id": "zone%d_boss" % zone_num,
			"zone": zone_num,
			"position": node_count - 1,
		})

	# Add shop (guaranteed every zone)
	guaranteed_nodes.append({
		"type": "shop",
		"id": "zone%d_shop" % zone_num,
		"zone": zone_num,
		"position": _rng.randi() % (node_count - 1),  # Not at end (reserved for boss)
	})

	# Add rest (guaranteed every zone)
	guaranteed_nodes.append({
		"type": "rest",
		"id": "zone%d_rest" % zone_num,
		"zone": zone_num,
		"position": _rng.randi() % (node_count - 1),
	})

	# Generate remaining nodes
	for i in range(node_count):
		# Check if this position has a guaranteed node
		var node_type: String = ""
		var is_guaranteed: bool = false

		for gnode in guaranteed_nodes:
			if gnode["position"] == i:
				node_type = gnode["type"]
				is_guaranteed = true
				gnode["generated"] = true
				break

		# Skip boss position (already set)
		if is_boss_zone and i == node_count - 1:
			continue

		# Skip guaranteed positions
		if is_guaranteed:
			zone_nodes.append({
				"type": node_type,
				"id": "zone%d_node_%d" % [zone_num, i],
				"zone": zone_num,
				"index": i,
			})
			continue

		# Generate weighted random node type
		node_type = _get_weighted_node_type(zone_num)
		zone_nodes.append({
			"type": node_type,
			"id": "zone%d_node_%d" % [zone_num, i],
			"zone": zone_num,
			"index": i,
		})

	# Add zone to map
	_map_data["zones"].append({
		"number": zone_num,
		"nodes": zone_nodes,
	})

	# Add all nodes to flat list
	for node in zone_nodes:
		_map_data["nodes"].append(node)


## Get weighted random node type based on board state
func _get_weighted_node_type(zone_num: int) -> String:
	var total_weight: int = 0
	for type in NODE_TYPE_WEIGHTS:
		total_weight += NODE_TYPE_WEIGHTS[type]

	# Apply board tag modifiers if available
	var modifiers: Dictionary = _get_board_tag_modifiers()

	var roll: int = _rng.randi() % total_weight
	var cumulative: int = 0

	for type in NODE_TYPE_WEIGHTS:
		var weight: int = NODE_TYPE_WEIGHTS[type]
		# Apply modifier if exists
		if modifiers.has(type):
			weight += modifiers[type]
		cumulative += weight
		if roll < cumulative:
			return type

	return "combat"


## Get board tag modifiers from RunState
func _get_board_tag_modifiers() -> Dictionary:
	var modifiers: Dictionary = {}

	if not RunState or RunState.pegs.is_empty():
		return modifiers

	# Count tags from current board
	var tag_counts: Dictionary = {}
	for peg_data in RunState.pegs:
		if peg_data.has("tags"):
			for tag in peg_data["tags"]:
				tag_counts[tag] = tag_counts.get(tag, 0) + 1

	# Apply weights based on tags
	for tag in tag_counts:
		if BOARD_TAG_WEIGHTS.has(tag):
			for node_type in BOARD_TAG_WEIGHTS[tag]:
				var bonus: int = BOARD_TAG_WEIGHTS[tag][node_type]
				modifiers[node_type] = modifiers.get(node_type, 0) + bonus

	return modifiers


## Generate connections between zones (DAG structure)
func _generate_connections() -> void:
	var connections: Array[Array] = []

	# For each zone (except last), connect to next zone
	for zone_idx in range(_map_data["zones"].size() - 1):
		var current_zone: Dictionary = _map_data["zones"][zone_idx]
		var next_zone: Dictionary = _map_data["zones"][zone_idx + 1]

		var current_nodes: Array = current_zone["nodes"]
		var next_nodes: Array = next_zone["nodes"]

		# Connect each node in current zone to 1-3 nodes in next zone
		for node in current_nodes:
			var num_connections: int = _rng.randi_range(1, 3)
			var available_next: Array = next_nodes.duplicate()

			for i in range(num_connections):
				if available_next.is_empty():
					break

				# Prefer forward progression (nodes with higher index)
				var next_idx: int = _rng.randi() % available_next.size()
				var target: Dictionary = available_next[next_idx]
				available_next.remove_at(next_idx)

				# Add connection (from -> to)
				connections.append([node["id"], target["id"]])

	# Add connections to map
	_map_data["connections"] = connections


## Add start node for zone 1
func _add_start_node() -> void:
	# Add entry node at start of zone 1
	var start_node: Dictionary = {
		"type": "start",
		"id": "zone1_start",
		"zone": 1,
		"index": -1,
	}
	_map_data["nodes"].insert(0, start_node)

	# Connect start to first zone 1 nodes
	var zone1_nodes: Array = []
	for node in _map_data["nodes"]:
		if node["zone"] == 1:
			zone1_nodes.append(node)

	if not zone1_nodes.is_empty():
		# Connect to 1-2 random nodes in zone 1
		var num_start_connections: int = _rng.randi_range(1, min(2, zone1_nodes.size()))
		for i in range(num_start_connections):
			var target_idx: int = _rng.randi() % zone1_nodes.size()
			_map_data["connections"].append([start_node["id"], zone1_nodes[target_idx]["id"]])


## Get all nodes in a specific zone
func get_zone_nodes(zone_num: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in _map_data["nodes"]:
		if node["zone"] == zone_num:
			result.append(node)
	return result


## Get available next nodes from current node
func get_available_next_nodes(current_node_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for connection in _map_data["connections"]:
		if connection[0] == current_node_id:
			for node in _map_data["nodes"]:
				if node["id"] == connection[1]:
					result.append(node)
					break
	return result


## Get node by ID
func get_node_data(node_id: String) -> Dictionary:
	for node in _map_data["nodes"]:
		if node["id"] == node_id:
			return node
	return {}


## Check if a path exists from current to target zone
func can_reach_node(from_node_id: String, to_node_id: String) -> bool:
	var visited: Array[String] = []
	var queue: Array[String] = [from_node_id]

	while not queue.is_empty():
		var current: String = queue.pop_front()
		if current == to_node_id:
			return true
		if current in visited:
			continue
		visited.append(current)

		var next_nodes: Array = get_available_next_nodes(current)
		for node in next_nodes:
			if not node["id"] in visited:
				queue.append(node["id"])

	return false


## Get the boss node for a zone
func get_zone_boss(zone_num: int) -> Dictionary:
	for node in _map_data["nodes"]:
		if node["zone"] == zone_num and node["type"] == "boss":
			return node
	return {}


## Serialize map to JSON-suitable dictionary
func serialize() -> Dictionary:
	return _map_data


## Get map statistics
func get_map_stats() -> Dictionary:
	var stats: Dictionary = {
		"total_nodes": _map_data["nodes"].size(),
		"zones": _map_data["zones"].size(),
		"connections": _map_data["connections"].size(),
		"node_types": {},
	}

	for node in _map_data["nodes"]:
		var node_type: String = node["type"]
		stats["node_types"][node_type] = stats["node_types"].get(node_type, 0) + 1

	return stats
