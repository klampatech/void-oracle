class_name CorruptionMapManager
# CorruptionMapManager.gd — Manages the 64x64 corruption map for board background
# Subscribes to peg_state_changed and paints corruption on the map
extends Node

const MAP_SIZE := 64
const CORRUPTION_RADIUS := 8  # Radius in map pixels

# Board dimensions for coordinate conversion
const BOARD_WIDTH := 600.0
const BOARD_HEIGHT := 900.0

var _corruption_image: Image
var _corruption_texture: ImageTexture
var _shader_material: ShaderMaterial


func _ready() -> void:
	# Initialize the 64x64 corruption map
	_corruption_image = Image.create(MAP_SIZE, MAP_SIZE, false, Image.FORMAT_RF)
	_corruption_image.fill(Color(0, 0, 0, 0))  # Start with no corruption

	# Create texture from image
	_corruption_texture = ImageTexture.create_from_image(_corruption_image)

	# Connect to EventBus signals
	EventBus.peg_state_changed.connect(_on_peg_state_changed)


func setup_shader(material: ShaderMaterial) -> void:
	_shader_material = material
	if _shader_material:
		_shader_material.set_shader_parameter("corruption_map", _corruption_texture)


func _on_peg_state_changed(peg: Node, old_state: String, new_state: String) -> void:
	# Only paint corruption when peg becomes cursed
	if new_state == "cursed":
		_paint_corruption_at_peg(peg)


func _paint_corruption_at_peg(peg: Node) -> void:
	if not peg or not is_instance_valid(peg):
		return

	var peg_pos = peg.global_position

	# Convert board position to map coordinates (0-63)
	var map_x = int((peg_pos.x / BOARD_WIDTH) * MAP_SIZE)
	var map_y = int((peg_pos.y / BOARD_HEIGHT) * MAP_SIZE)

	# Clamp to valid range
	map_x = clampi(map_x, 0, MAP_SIZE - 1)
	map_y = clampi(map_y, 0, MAP_SIZE - 1)

	# Paint a circle of corruption
	_paint_circle(map_x, map_y, CORRUPTION_RADIUS, 1.0)

	# Also paint slight corruption around the main spot for bleed effect
	_paint_circle(map_x, map_y, CORRUPTION_RADIUS * 2, 0.3)

	# Update the texture
	_update_texture()


func _paint_circle(center_x: int, center_y: int, radius: int, intensity: float) -> void:
	for y in range(center_y - radius, center_y + radius + 1):
		for x in range(center_x - radius, center_x + radius + 1):
			if x < 0 or x >= MAP_SIZE or y < 0 or y >= MAP_SIZE:
				continue

			var dist = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
			if dist <= radius:
				# Calculate falloff from center
				var falloff = 1.0 - (dist / radius)
				falloff = ease(falloff, 0.5)  # Smooth falloff

				var current = _corruption_image.get_pixel(x, y).r
				var new_value = clampf(current + (intensity * falloff), 0.0, 1.0)
				_corruption_image.set_pixel(x, y, Color(new_value, 0, 0, 0))


func _update_texture() -> void:
	if _corruption_texture:
		_corruption_texture.update(_corruption_image)

		# Update shader parameter if material exists
		if _shader_material:
			_shader_material.set_shader_parameter("corruption_map", _corruption_texture)


func clear_corruption() -> void:
	_corruption_image.fill(Color(0, 0, 0, 0))
	_update_texture()


func get_corruption_level_at_position(board_pos: Vector2) -> float:
	var map_x = int((board_pos.x / BOARD_WIDTH) * MAP_SIZE)
	var map_y = int((board_pos.y / BOARD_HEIGHT) * MAP_SIZE)

	map_x = clampi(map_x, 0, MAP_SIZE - 1)
	map_y = clampi(map_y, 0, MAP_SIZE - 1)

	return _corruption_image.get_pixel(map_x, map_y).r
