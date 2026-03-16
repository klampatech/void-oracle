# BasePeg.gd — Base class for all peg types
extends StaticBody2D
class_name BasePeg

## Peg types
enum PegType { STONE, BONE, FUNGAL, EMBER, EYE, HEART, ORACLE, VOID_RIFT }

## Peg states
enum PegState { DORMANT, BLESSED, CURSED, MUTANT, VOID }

## Data file path
const PEG_DATA_PATH := "res://data/pegs/peg_definitions.json"

## Shader path
const SHADER_PATH := "res://shaders/peg_state.gdshader"

## Peg properties
var peg_type: PegType = PegType.STONE
var peg_state: PegState = PegState.DORMANT
var hit_count: int = 0
var corruption_level: float = 0.5  ## 0.0 = blessed, 0.5 = neutral, 1.0 = cursed

## Placeholder colors from CLAUDE.md spec
const PEG_COLORS = {
	PegType.STONE: Color(0.533, 0.533, 0.533, 1.0),    # #888888
	PegType.BONE: Color(0.91, 0.878, 0.816, 1.0),       # #E8E0D0
	PegType.FUNGAL: Color(0.29, 0.478, 0.227, 1.0),     # #4A7A3A
	PegType.EMBER: Color(0.91, 0.353, 0.125, 1.0),      # #E85A20
	PegType.EYE: Color(0.565, 0.376, 0.91, 1.0),         # #9060E8
	PegType.HEART: Color(0.91, 0.188, 0.376, 1.0),      # #E83060
	PegType.ORACLE: Color(0.788, 0.659, 0.298, 1.0),    # #C9A84C
	PegType.VOID_RIFT: Color(0.039, 0.039, 0.165, 1.0),  # #0A0A2A
}

## Loaded data
var _peg_data: Dictionary

## Shader material reference
var _shader_material: ShaderMaterial


func _ready() -> void:
	# Add to peg group
	add_to_group("peg")
	# Load peg data
	_load_peg_data()
	# Apply physics material based on type
	_apply_physics_material()
	# Setup visual shader
	_setup_shader()


func _load_peg_data() -> void:
	var file := FileAccess.open(PEG_DATA_PATH, FileAccess.READ)
	if file:
		var json_text := file.get_as_text()
		var json := JSON.new()
		var error := json.parse(json_text)
		if error == OK:
			_peg_data = json.data
		file.close()


func _apply_physics_material() -> void:
	var peg_key := _get_peg_key()
	if peg_key.is_empty() or not _peg_data.has(peg_key):
		return

	var data: Dictionary = _peg_data[peg_key]
	var physics_mat := PhysicsMaterial.new()
	physics_mat.friction = data.get("friction", 0.1)
	physics_mat.bounce = data.get("restitution", 0.5)
	physics_material_override = physics_mat


func _get_peg_key() -> String:
	match peg_type:
		PegType.STONE: return "stone"
		PegType.BONE: return "bone"
		PegType.FUNGAL: return "fungal"
		PegType.EMBER: return "ember"
		PegType.EYE: return "eye"
		PegType.HEART: return "heart"
		PegType.ORACLE: return "oracle"
		PegType.VOID_RIFT: return "void_rift"
	return ""


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return

	hit_count += 1
	EventBus.peg_hit.emit(self, body)


func get_peg_type_string() -> String:
	return _get_peg_key()


func get_hit_count() -> int:
	return hit_count


func get_peg_state_string() -> String:
	match peg_state:
		PegState.DORMANT: return "dormant"
		PegState.BLESSED: return "blessed"
		PegState.CURSED: return "cursed"
		PegState.MUTANT: return "mutant"
		PegState.VOID: return "void"
	return "dormant"


func get_peg_state() -> String:
	return get_peg_state_string()


## Set peg state directly (for shop services)
func set_peg_state(new_state: String) -> void:
	mutate_to(new_state)


func mutate_to(new_state: String) -> void:
	var old_state: String = get_peg_state_string()
	match new_state:
		"dormant":
			peg_state = PegState.DORMANT
			set_corruption_level(0.0)
		"blessed":
			peg_state = PegState.BLESSED
			set_corruption_level(0.0)
		"cursed":
			peg_state = PegState.CURSED
			set_corruption_level(1.0)
		"mutant":
			peg_state = PegState.MUTANT
			set_mutation_pulse(1.0)
		"void":
			peg_state = PegState.VOID
			set_void_factor(1.0)

	EventBus.peg_state_changed.emit(self, old_state, new_state)


func _setup_shader() -> void:
	# Load the shader
	var shader := load(SHADER_PATH) as Shader
	if not shader:
		push_warning("Failed to load shader: " + SHADER_PATH)
		return

	# Create a unique material instance for this peg
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader

	# Set default values
	_shader_material.set_shader_parameter("corruption_level", corruption_level)
	_shader_material.set_shader_parameter("mutation_pulse", 0.0)
	_shader_material.set_shader_parameter("void_factor", 0.0)

	# Set base color based on peg type
	var base_col: Color = PEG_COLORS.get(peg_type, Color.GRAY)
	_shader_material.set_shader_parameter("base_color", base_col)

	# Apply to visual node
	var visual := get_node_or_null("Visual")
	if visual and visual is ColorRect:
		visual.material = _shader_material


func set_corruption_level(level: float) -> void:
	corruption_level = clampf(level, 0.0, 1.0)
	if _shader_material:
		_shader_material.set_shader_parameter("corruption_level", corruption_level)


func set_mutation_pulse(pulse: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("mutation_pulse", clampf(pulse, 0.0, 1.0))


func set_void_factor(factor: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("void_factor", clampf(factor, 0.0, 1.0))


func get_shader_material() -> ShaderMaterial:
	return _shader_material
