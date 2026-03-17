# test_synergy_effects.gd — Unit tests for SynergyEffects
extends GutTest

var _synergy_effects: Node = null

func before_each() -> void:
	_synergy_effects = load("res://scripts/autoloads/SynergyEffects.gd").new()
	add_child(_synergy_effects)
	_synergy_effects._ready()

func after_each() -> void:
	if _synergy_effects and is_instance_valid(_synergy_effects):
		_synergy_effects.queue_free()

func test_get_tier_level_tier_0() -> void:
	# 0-2 pegs = tier 0
	assert_eq(_synergy_effects._get_tier_level(0), 0, "0 pegs should be tier 0")
	assert_eq(_synergy_effects._get_tier_level(1), 0, "1 peg should be tier 0")
	assert_eq(_synergy_effects._get_tier_level(2), 0, "2 pegs should be tier 0")

func test_get_tier_level_tier_1() -> void:
	# 3-5 pegs = tier 1
	assert_eq(_synergy_effects._get_tier_level(3), 1, "3 pegs should be tier 1")
	assert_eq(_synergy_effects._get_tier_level(4), 1, "4 pegs should be tier 1")
	assert_eq(_synergy_effects._get_tier_level(5), 1, "5 pegs should be tier 1")

func test_get_tier_level_tier_2() -> void:
	# 6+ pegs = tier 2
	assert_eq(_synergy_effects._get_tier_level(6), 2, "6 pegs should be tier 2")
	assert_eq(_synergy_effects._get_tier_level(10), 2, "10 pegs should be tier 2")
	assert_eq(_synergy_effects._get_tier_level(100), 2, "100 pegs should be tier 2")

func test_should_convert_to_void_ball_no_synergy() -> void:
	var result = _synergy_effects.should_convert_to_void_ball()
	assert_false(result, "Should not convert without void_choir synergy")

func test_get_ball_speed_multiplier_default() -> void:
	var result = _synergy_effects.get_ball_speed_multiplier()
	assert_eq(result, 1.0, "Default speed multiplier should be 1.0")

func test_get_damage_multiplier_default() -> void:
	var result = _synergy_effects.get_damage_multiplier()
	assert_eq(result, 1.0, "Default damage multiplier should be 1.0")

func test_get_void_ball_drop_number() -> void:
	var result = _synergy_effects.get_void_ball_drop_number()
	assert_eq(result, 5, "Void ball should drop every 5th ball")

func test_should_void_ball_extra_pocket_default() -> void:
	var result = _synergy_effects.should_void_ball_extra_pocket()
	assert_false(result, "Should not have extra pocket by default")

func test_get_board_regen_default() -> void:
	var result = _synergy_effects.get_board_regen()
	assert_eq(result, 0, "Default board regen should be 0")

func test_is_synergy_active_no_synergies() -> void:
	assert_false(_synergy_effects.is_synergy_active("necrotic_bloom"), "Should return false when no synergy")

func test_get_synergy_tier_no_synergy() -> void:
	var result = _synergy_effects.get_synergy_tier("void_choir")
	assert_eq(result, 0, "Should return 0 when synergy not active")

func test_check_and_convert_to_void_ball_no_synergy() -> void:
	# Should return false and not increment counter
	var result = _synergy_effects.check_and_convert_to_void_ball()
	assert_false(result, "Should not convert without void_choir synergy")
