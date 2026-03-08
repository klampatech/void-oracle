# EmberPeg.gd — Ember peg type
extends BasePeg

## Distance threshold for adjacent pegs (in pixels, ~3 peg distances)
const ADJACENT_DISTANCE := 150.0

## How much to shift corruption toward cursed
const CORRUPTION_SHIFT := 0.1


func _ready() -> void:
	peg_type = PegType.EMBER
	super._ready()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return

	# Get all pegs in the 'peg' group
	var all_pegs := get_tree().get_nodes_in_group("peg")

	# Affect adjacent pegs
	for peg in all_pegs:
		# Skip self
		if peg == self:
			continue

		# Check if peg is adjacent
		var distance := global_position.distance_to(peg.global_position)
		if distance <= ADJACENT_DISTANCE:
			# Shift corruption toward cursed
			_corrupt_peg(peg)

	# Emit peg hit signal
	hit_count += 1
	EventBus.peg_hit.emit(self, body)


func _corrupt_peg(peg: Node) -> void:
	if not peg.has_method("set_corruption_level"):
		return

	# Get current corruption level
	var current: float = 0.5
	if "corruption_level" in peg:
		current = peg.corruption_level as float

	# Shift toward cursed (increase corruption)
	var new_level := clampf(current + CORRUPTION_SHIFT, 0.0, 1.0)

	# Only emit state changed if crossing threshold
	var old_state := _state_from_corruption(current)
	var new_state := _state_from_corruption(new_level)

	peg.set_corruption_level(new_level)

	if old_state != new_state:
		EventBus.peg_state_changed.emit(peg, old_state, new_state)


func _state_from_corruption(level: float) -> String:
	if level < 0.33:
		return "blessed"
	elif level > 0.66:
		return "cursed"
	else:
		return "dormant"
