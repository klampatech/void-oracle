# SynergyEffects.gd — Applies mechanical effects when synergies activate
# Add to AutoLoad in Project Settings as "SynergyEffects"
extends Node

## Track active synergies and their tiers
## Format: { synergy_id: tier_level }
var _active_synergies: Dictionary = {}

## Track ball drops for void choir
var _ball_drop_counter: int = 0

## Track void balls for extra pocket
var _void_ball_extra_pocket: bool = false

## Track enemy reveal state for profane eye
var _enemy_revealed: bool = false

## Track regen passive for bleeding architecture
var _board_regen: int = 0

## Track rot spread multiplier for necrotic bloom curse
var _rot_spread_multiplier: float = 1.0

## Track curse risks
var _curse_risks_active: Dictionary = {}


func _ready() -> void:
	# Subscribe to synergy events
	EventBus.synergy_activated.connect(_on_synergy_activated)
	EventBus.synergy_broken.connect(_on_synergy_broken)
	EventBus.synergy_scaled.connect(_on_synergy_scaled)

	# Subscribe to peg hit for various effects
	EventBus.peg_hit.connect(_on_peg_hit)

	# Subscribe to ball drop start
	EventBus.drop_started.connect(_on_drop_started)

	# Subscribe to enemy intent for profane eye
	EventBus.enemy_intent_determined.connect(_on_enemy_intent_determined)

	# Subscribe to board clear for regen effects
	EventBus.drop_ended.connect(_on_drop_ended)

	print("[SynergyEffects] Initialized")


func _on_synergy_activated(synergy_id: String, peg_count: int) -> void:
	print("[SynergyEffects] Synergy activated: ", synergy_id, " (", peg_count, " pegs)")
	_active_synergies[synergy_id] = _get_tier_level(peg_count)
	_apply_synergy_activation(synergy_id, peg_count)


func _on_synergy_broken(synergy_id: String) -> void:
	print("[SynergyEffects] Synergy broken: ", synergy_id)
	_active_synergies.erase(synergy_id)
	_apply_synergy_break(synergy_id)


func _on_synergy_scaled(synergy_id: String, new_count: int) -> void:
	print("[SynergyEffects] Synergy scaled: ", synergy_id, " -> ", new_count)
	var old_tier = _active_synergies.get(synergy_id, 0)
	var new_tier = _get_tier_level(new_count)
	_active_synergies[synergy_id] = new_tier
	_apply_synergy_scale(synergy_id, old_tier, new_tier)


func _get_tier_level(peg_count: int) -> int:
	if peg_count >= 6:
		return 2
	elif peg_count >= 3:
		return 1
	return 0


## Apply effects when synergy activates
func _apply_synergy_activation(synergy_id: String, peg_count: int) -> void:
	match synergy_id:
		"necrotic_bloom":
			# Tier 1+: Rot pegs deal 3 damage on contact (handled in _on_peg_hit)
			# Tier 2: All pegs regen 1 stability per drop
			if peg_count >= 6:
				_board_regen += 1
		"cursed_flame":
			# Handled in _on_peg_hit for corruption spread
			# Tier 2: Ball speed +20%, double damage
			pass
		"void_choir":
			# Handled in _on_drop_started for void ball conversion
			# Tier 2: Extra pocket slot
			if peg_count >= 6:
				_void_ball_extra_pocket = true
		"bleeding_arch":
			# Tier 1: Stone pegs heal 1 stability on contact (handled in _on_peg_hit)
			# Tier 2: Board gains Regen 2 passive
			if peg_count >= 6:
				_board_regen += 2
		"profane_eye":
			# Tier 1: Eye pegs reveal enemy next move (handled in _on_peg_hit)
			# Tier 2: Bone pegs double damage vs revealed (handled in _on_peg_hit)
			pass


## Apply effects when synergy breaks
func _apply_synergy_break(synergy_id: String) -> void:
	match synergy_id:
		"necrotic_bloom":
			_board_regen = max(0, _board_regen - 1)
			_rot_spread_multiplier = 1.0
		"void_choir":
			_void_ball_extra_pocket = false
		"bleeding_arch":
			_board_regen = max(0, _board_regen - 2)


## Apply effects when synergy tier changes
func _apply_synergy_scale(synergy_id: String, old_tier: int, new_tier: int) -> void:
	match synergy_id:
		"necrotic_bloom":
			# Adjust regen based on tier change
			if new_tier >= 2 and old_tier < 2:
				_board_regen += 1
			elif new_tier < 2 and old_tier >= 2:
				_board_regen = max(0, _board_regen - 1)
		"void_choir":
			_void_ball_extra_pocket = (new_tier >= 2)
		"bleeding_arch":
			# Adjust regen based on tier
			_board_regen = 0
			if _active_synergies.has("bleeding_arch"):
				if _active_synergies["bleeding_arch"] >= 2:
					_board_regen += 2
				elif _active_synergies["bleeding_arch"] >= 1:
					_board_regen += 1


## Handle peg hit effects based on active synergies
func _on_peg_hit(peg, ball) -> void:
	if not (peg and is_instance_valid(peg)):
		return

	var peg_tags = peg.get("tags", [])
	var peg_state = peg.get_peg_state_string()

	# NECROTIC BLOOM: Rot pegs deal 3 damage on contact
	if _active_synergies.has("necrotic_bloom"):
		if _active_synergies["necrotic_bloom"] >= 1:
			# Check if this is a rot (cursed) peg
			if peg_state == "cursed" or peg_state == "mutant":
				var damage = 3
				# Apply damage to enemy (via EventBus)
				EventBus.synergy_damage_dealt.emit(damage, "necrotic_bloom")
				print("[SynergyEffects] Necrotic Bloom dealt ", damage, " damage")

	# BLEEDING ARCHITECTURE: Stone pegs heal 1 stability on contact
	if _active_synergies.has("bleeding_arch"):
		if _active_synergies["bleeding_arch"] >= 1:
			var peg_type_str = peg.get_peg_type_string()
			if peg_type_str == "stone":
				var heal = 1
				EventBus.synergy_stability_changed.emit(heal, "synergy_bleeding_arch")
				print("[SynergyEffects] Bleeding Architecture healed ", heal, " stability")

	# PROFANE EYE: Eye pegs reveal enemy next move
	if _active_synergies.has("profane_eye"):
		if _active_synergies["profane_eye"] >= 1:
			var peg_type_str = peg.get_peg_type_string()
			if peg_type_str == "eye":
				_enemy_revealed = true
				EventBus.enemy_revealed.emit()
				print("[SynergyEffects] Profane Eye revealed enemy intent")

	# PROFANE EYE TIER 2: Bone pegs double damage vs revealed
	if _active_synergies.has("profane_eye"):
		if _active_synergies["profane_eye"] >= 2:
			var peg_type_str = peg.get_peg_type_string()
			if peg_type_str == "bone" and _enemy_revealed:
				var bonus_damage = 2  # Double the base 2
				EventBus.synergy_damage_dealt.emit(bonus_damage, "profane_eye")
				print("[SynergyEffects] Profane Eye dealt ", bonus_damage, " bonus damage vs revealed")


## Handle drop phase start for void choir
func _on_drop_started(_ball_count: int) -> void:
	_ball_drop_counter = 0
	_enemy_revealed = false


## Handle drop phase end for stability regen
func _on_drop_ended(_results: Dictionary) -> void:
	if _board_regen > 0:
		EventBus.synergy_stability_changed.emit(_board_regen, "synergy_regen")
		print("[SynergyEffects] Applied ", _board_regen, " stability regen")


## Handle enemy intent determined
func _on_enemy_intent_determined(_intent_text: String) -> void:
	# Reset reveal state when new enemy intent is shown
	_enemy_revealed = false


## Check if void choir should convert ball to void ball
func should_convert_to_void_ball() -> bool:
	return _active_synergies.has("void_choir") and _active_synergies["void_choir"] >= 1


## Increment ball counter and return true if this ball should be void (Void Choir)
## Call this when a ball is spawned
func check_and_convert_to_void_ball() -> bool:
	if not should_convert_to_void_ball():
		return false
	_ball_drop_counter += 1
	var is_void_ball = (_ball_drop_counter % get_void_ball_drop_number() == 0)
	if is_void_ball:
		print("[SynergyEffects] Void Choir converting ball #", _ball_drop_counter, " to void ball")
	return is_void_ball


## Get ball speed multiplier for Cursed Flame (Tier 2: +20%)
func get_ball_speed_multiplier() -> float:
	if _active_synergies.has("cursed_flame") and _active_synergies["cursed_flame"] >= 2:
		return 1.2
	return 1.0


## Get damage multiplier for Cursed Flame (Tier 2: double damage)
func get_damage_multiplier() -> float:
	if _active_synergies.has("cursed_flame") and _active_synergies["cursed_flame"] >= 2:
		return 2.0
	return 1.0


## Get ball drop number for void choir conversion
func get_void_ball_drop_number() -> int:
	return 5  # Every 5th ball


## Should void ball get extra pocket slot
func should_void_ball_extra_pocket() -> bool:
	return _void_ball_extra_pocket


## Get current board regen amount
func get_board_regen() -> int:
	return _board_regen


## Get rot spread multiplier (for curse risk)
func get_rot_spread_multiplier() -> float:
	return _rot_spread_multiplier


## Check if a specific synergy is active
func is_synergy_active(synergy_id: String) -> bool:
	return _active_synergies.has(synergy_id)


## Get synergy tier (0, 1, or 2)
func get_synergy_tier(synergy_id: String) -> int:
	return _active_synergies.get(synergy_id, 0)
