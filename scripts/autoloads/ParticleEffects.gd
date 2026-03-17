extends Node
## ParticleEffects AutoLoad
##
## Handles particle effects for peg hits and boss effects.
## Subscribes to EventBus.peg_hit and spawns appropriate particles based on peg state.
##
## Particle effects follow ART_BIBLE specifications:
## - Blessed sparkle: Small 4-pointed gold stars, 6-8px, float upward slowly
## - Rot spore: Tiny irregular circles, muted green-brown, drift sideways
## - Cursed crack: Thin crimson fracture lines radiating outward, fade over 0.5s
## - Void wisp: Dark blue tendril shapes, reach and retract

# Preload particle scenes
var _blessed_sparkle: PackedScene
var _rot_spore: PackedScene
var _cursed_crack: PackedScene
var _void_wisp: PackedScene
var _generic_hit: PackedScene

# Particle colors from ART_BIBLE palette
const COLOR_BLESSED := Color("#C9A84C")    # Blessed Gold
const COLOR_CURSED := Color("#8C1E1E")     # Cursed Crimson
const COLOR_MUTANT := Color("#1E5E2A")     # Mutant Green
const COLOR_VOID := Color("#0A0A2A")       # Deep Void (void_touched)
const COLOR_DEFAULT := Color("#8880A8")    # Dim Gray (dormant)

# Maximum active particle systems to prevent performance issues
const MAX_ACTIVE_PARTICLES := 50
var _active_particles: int = 0


func _ready() -> void:
	# Connect to peg_hit signal like AudioManager does
	EventBus.peg_hit.connect(_on_peg_hit)

	# Connect to boss phase changes for screen distortion
	EventBus.boss_phase_changed.connect(_on_boss_phase_changed)

	# Preload particle scenes
	_preload_particle_scenes()


func _preload_particle_scenes() -> void:
	# Try to preload particle scenes if they exist
	# Fallback to creating them programmatically if not found
	_blessed_sparkle = preload("res://scenes/effects/BlessedSparkle.tscn")
	_rot_spore = preload("res://scenes/effects/RotSpore.tscn")
	_cursed_crack = preload("res://scenes/effects/CursedCrack.tscn")
	_void_wisp = preload("res://scenes/effects/VoidWisp.tscn")
	_generic_hit = preload("res://scenes/effects/GenericHit.tscn")


func _on_peg_hit(peg: Node, ball: Node) -> void:
	# Spawn particles at the hit location
	if _active_particles >= MAX_ACTIVE_PARTICLES:
		return  # Skip if too many particles active

	var spawn_pos := Vector2.ZERO
	if peg and peg.has_node("."):
		spawn_pos = peg.global_position

	# Get peg state to determine particle type
	var peg_state := "dormant"
	if peg and peg.has_method("get_peg_state_string"):
		peg_state = peg.get_peg_state_string()

	# Spawn appropriate particle effect
	_spawn_hit_particles(spawn_pos, peg_state)


func _spawn_hit_particles(pos: Vector2, peg_state: String) -> void:
	var particle: Node2D = null

	match peg_state:
		"blessed":
			particle = _spawn_particle(_blessed_sparkle, pos)
		"cursed":
			particle = _spawn_particle(_cursed_crack, pos)
		"mutant":
			particle = _spawn_particle(_rot_spore, pos)
		"void", "void_touched":
			particle = _spawn_particle(_void_wisp, pos)
		_:
			particle = _spawn_particle(_generic_hit, pos)

	if particle:
		_active_particles += 1


func _spawn_particle(scene: PackedScene, pos: Vector2) -> Node2D:
	if scene == null:
		return null

	var instance = scene.instantiate()
	if instance:
		instance.global_position = pos
		# Add to the current scene's EffectsLayer if available
		var board = get_tree().get_first_node_in_group("effects_layer")
		if board:
			board.add_child(instance)
		else:
			# Fallback: add to root
			get_tree().root.add_child(instance)

		# Connect to finished signal to track cleanup
		if instance.has_signal("finished"):
			instance.finished.connect(_on_particle_finished.bind(instance))

		# Emit one-shot burst
		if "emitting" in instance:
			instance.emitting = true

	return instance


func _on_particle_finished(particle: Node) -> void:
	_active_particles = max(0, _active_particles - 1)
	if is_instance_valid(particle):
		particle.queue_free()


func _on_boss_phase_changed(phase: int) -> void:
	# Trigger distortion on boss phase change
	trigger_boss_distortion(1.0, 2.0)


## Trigger boss screen distortion effect
func trigger_boss_distortion(intensity: float = 1.0, duration: float = 2.0) -> void:
	var distortion_rect = get_tree().get_first_node_in_group("boss_distortion")
	if distortion_rect and "distortion_amount" in distortion_rect.material:
		# Animate distortion
		var tween = create_tween()
		tween.tween_property(distortion_rect.material, "distortion_amount", intensity, duration * 0.3)
		tween.tween_property(distortion_rect.material, "distortion_amount", 0.0, duration * 0.7)
