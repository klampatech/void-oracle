# GhostEnemy.gd — Ghost board encounter enemy
# The ghost is a mirror of a previous run's board
extends Enemy
class_name GhostEnemy

## Ghost type classification
enum GhostType {
	MOSTLY_BLESSED,   # Heals enemy each turn
	MOSTLY_CURSED,    # Damages player stability each turn
	HIGH_MUTATION,    # Randomizes peg states each turn
	VOID_HEAVY,       # Steals ball drops
	NEUTRAL,          # Basic ghost, no special effect
}

## Current ghost type
var _ghost_type: GhostType = GhostType.NEUTRAL

## Ghost board data
var _ghost_board: Dictionary = {}

## Reference to board (set by EncounterManager)
var _board_ref: Node2D = null

## Turn counter
var _turn_count: int = 0


func _ready() -> void:
	super._ready()
	# Ghost doesn't use JSON data - it loads from ghost board
	enemy_id = "ghost"
	max_hp = 80
	hp = max_hp


## Load ghost board for this encounter
func load_ghost(ghost_data: Dictionary) -> void:
	_ghost_board = ghost_data
	if _ghost_board.is_empty():
		push_warning("GhostEnemy: No ghost data loaded, using default")
		_ghost_type = GhostType.NEUTRAL
		return

	# Determine ghost type based on board characteristics
	_determine_ghost_type()

	# Apply ghost HP based on type
	_apply_ghost_hp()


## Determine ghost type based on ghost board characteristics
func _determine_ghost_type() -> void:
	if _ghost_board.is_empty():
		_ghost_type = GhostType.NEUTRAL
		return

	var pegs: Array = _ghost_board.get("pegs", [])
	if pegs.is_empty():
		_ghost_type = GhostType.NEUTRAL
		return

	var blessed_count: int = 0
	var cursed_count: int = 0
	var mutated_count: int = 0
	var void_count: int = 0
	var total: int = pegs.size()

	for peg in pegs:
		var state: String = peg.get("state", "dormant")
		var tags: Array = peg.get("tags", [])

		if state == "blessed" or "blessed" in tags:
			blessed_count += 1
		if state == "cursed" or "cursed" in tags:
			cursed_count += 1
		if "mutation" in tags or "mutating" in tags:
			mutated_count += 1
		if "void" in tags or state == "void_touched":
			void_count += 1

	# Determine type based on majority
	var ratio_threshold: float = 0.5

	if float(blessed_count) / total >= ratio_threshold:
		_ghost_type = GhostType.MOSTLY_BLESSED
	elif float(cursed_count) / total >= ratio_threshold:
		_ghost_type = GhostType.MOSTLY_CURSED
	elif float(mutated_count) / total >= ratio_threshold:
		_ghost_type = GhostType.HIGH_MUTATION
	elif float(void_count) / total >= ratio_threshold:
		_ghost_type = GhostType.VOID_HEAVY
	else:
		_ghost_type = GhostType.NEUTRAL

	print("GhostEnemy: Ghost type determined: ", _get_ghost_type_name())


## Apply HP based on ghost type
func _apply_ghost_hp() -> void:
	match _ghost_type:
		GhostType.MOSTLY_BLESSED:
			max_hp = 100  # Tougher - heals itself
			hp = max_hp
		GhostType.MOSTLY_CURSED:
			max_hp = 70   # Weaker - relies on stability damage
			hp = max_hp
		GhostType.HIGH_MUTATION:
			max_hp = 90   # Medium - unpredictable
			hp = max_hp
		GhostType.VOID_HEAVY:
			max_hp = 80   # Medium - steals balls
			hp = max_hp
		_:
			max_hp = 80
			hp = max_hp


## Get ghost type name for display
func _get_ghost_type_name() -> String:
	match _ghost_type:
		GhostType.MOSTLY_BLESSED:
			return "Blessed Spirit"
		GhostType.MOSTLY_CURSED:
			return "Cursed Shade"
		GhostType.HIGH_MUTATION:
			return "Twisted Phantom"
		GhostType.VOID_HEAVY:
			return "Void Wraith"
		_:
			return "Lost Soul"


## Get intent text for display
func get_intent_text() -> String:
	match _ghost_type:
		GhostType.MOSTLY_BLESSED:
			return "Will channel the light..."
		GhostType.MOSTLY_CURSED:
			return "Will drain your vitality..."
		GhostType.HIGH_MUTATION:
			return "Will warp reality..."
		GhostType.VOID_HEAVY:
			return "Will consume your offerings..."
		_:
			return "Will manifest..."


## Execute ghost's turn based on type
func execute_turn() -> void:
	_turn_count += 1
	print("GhostEnemy: Executing turn ", _turn_count, " as ", _get_ghost_type_name())

	match _ghost_type:
		GhostType.MOSTLY_BLESSED:
			_execute_blessed_turn()
		GhostType.MOSTLY_CURSED:
			_execute_cursed_turn()
		GhostType.HIGH_MUTATION:
			_execute_mutation_turn()
		GhostType.VOID_HEAVY:
			_execute_void_turn()
		_:
			_execute_neutral_turn()


## Blessed ghost heals itself each turn
func _execute_blessed_turn() -> void:
	var heal_amount: int = 5
	hp = min(max_hp, hp + heal_amount)
	print("GhostEnemy: Blessed Spirit heals ", heal_amount, " HP (now ", hp, "/", max_hp, ")")


## Cursed ghost damages player stability each turn
func _execute_cursed_turn() -> void:
	var damage: int = 8
	RunState.modify_stability(-damage)
	print("GhostEnemy: Cursed Shade deals ", damage, " stability damage")


## Mutation ghost randomizes peg states each turn
func _execute_mutation_turn() -> void:
	# Randomly mutate 1-2 pegs
	var rng := RandomNumberGenerator.new()
	var num_mutations: int = rng.randi_range(1, 2)

	print("GhostEnemy: Twisted Phantom will mutate ", num_mutations, " pegs")

	# Emit signal for board to handle mutations
	EventBus.ghost_mutation.emit(num_mutations)


## Void ghost steals ball drops
func _execute_void_turn() -> void:
	# Mark that void ghost is active - will steal gold from pockets
	# This is handled when balls enter pockets
	EventBus.void_ghost_active.emit(true)
	print("GhostEnemy: Void Wraith is consuming your offerings...")


## Neutral ghost - minor effect
func _execute_neutral_turn() -> void:
	# Small stability damage
	var damage: int = 3
	RunState.modify_stability(-damage)
	print("GhostEnemy: Lost Soul deals ", damage, " stability damage")


## Check if this is a boss (ghosts are not bosses)
func is_boss() -> bool:
	return false


## Get ghost board data for display
func get_ghost_data() -> Dictionary:
	return _ghost_board


## Get ghost type
func get_ghost_type() -> GhostType:
	return _ghost_type
