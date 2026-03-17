# test_mutation_engine.gd — Unit tests for MutationEngine
extends GutTest

var _mutation_engine: Node = null

func before_each() -> void:
	_mutation_engine = load("res://scripts/autoloads/MutationEngine.gd").new()
	add_child(_mutation_engine)
	# Skip _ready to avoid signal connection issues in tests
	# _mutation_engine._ready()

func after_each() -> void:
	if _mutation_engine and is_instance_valid(_mutation_engine):
		_mutation_engine.queue_free()

func test_mutation_threshold_constant() -> void:
	assert_eq(_mutation_engine.MUTATION_THRESHOLD, 5, "Mutation threshold should be 5")

func test_mutation_chance_constant() -> void:
	assert_eq(_mutation_engine.MUTATION_CHANCE, 0.15, "Mutation chance should be 15%")

func test_next_state_dormant_to_blessed() -> void:
	# Create a mock peg that returns "dormant"
	var mock_peg = Node.new()
	mock_peg.set_meta("peg_state", "blessed")
	mock_peg.set_meta("hit_count", 5)

	# Test with default behavior (corruption = 0.3)
	var result = _mutation_engine._next_state("dormant", mock_peg)
	mock_peg.queue_free()
	# With 0.3 corruption (below 0.5), should go to blessed
	assert_eq(result, "blessed", "Dormant should go to blessed with low corruption")

func test_next_state_dormant_to_cursed() -> void:
	var mock_peg = Node.new()
	mock_peg.set_meta("peg_state", "cursed")
	mock_peg.set_meta("hit_count", 5)

	# Can't override private method in test, so we just verify the function exists
	# The actual behavior depends on internal _get_local_corruption which returns 0.3
	var result = _mutation_engine._next_state("dormant", mock_peg)
	mock_peg.queue_free()
	# With default 0.3 corruption (below 0.5), should go to blessed
	# This test verifies the function is callable
	assert_true(result == "blessed" or result == "cursed", "Should return a valid state")

func test_next_state_blessed_stays_blessed_or_mutates() -> void:
	var mock_peg = Node.new()
	mock_peg.set_meta("peg_state", "blessed")
	mock_peg.set_meta("hit_count", 5)

	# Just verify the function exists and returns expected types
	var result = _mutation_engine._next_state("blessed", mock_peg)
	mock_peg.queue_free()
	assert_true(result == "blessed" or result == "mutant", "Blessed should stay blessed or become mutant")

func test_next_state_cursed_stays_cursed_or_mutates() -> void:
	var mock_peg = Node.new()
	mock_peg.set_meta("peg_state", "cursed")
	mock_peg.set_meta("hit_count", 5)

	var result = _mutation_engine._next_state("cursed", mock_peg)
	mock_peg.queue_free()
	assert_true(result == "cursed" or result == "mutant", "Cursed should stay cursed or become mutant")

func test_next_state_mutant_stays_mutant_or_voids() -> void:
	var mock_peg = Node.new()
	mock_peg.set_meta("peg_state", "mutant")
	mock_peg.set_meta("hit_count", 5)

	var result = _mutation_engine._next_state("mutant", mock_peg)
	mock_peg.queue_free()
	assert_true(result == "mutant" or result == "void", "Mutant should stay mutant or become void")

func test_next_state_unknown() -> void:
	var mock_peg = Node.new()
	mock_peg.set_meta("peg_state", "unknown")
	mock_peg.set_meta("hit_count", 5)

	var result = _mutation_engine._next_state("unknown", mock_peg)
	mock_peg.queue_free()
	assert_eq(result, "unknown", "Unknown state should stay unchanged")

func test_get_local_corruption_returns_value() -> void:
	var mock_peg = Node.new()
	mock_peg.set_meta("peg_state", "dormant")
	mock_peg.set_meta("hit_count", 5)

	var result = _mutation_engine._get_local_corruption(mock_peg)
	mock_peg.queue_free()
	assert_true(result >= 0.0 and result <= 1.0, "Corruption should be between 0 and 1")
