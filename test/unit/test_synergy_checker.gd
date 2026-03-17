# test_synergy_checker.gd — Unit tests for SynergyChecker
extends GutTest

var _synergy_checker: Node = null

# Mock peg data for testing
var _mock_pegs_with_tags: Array = [
	{"type": "bone", "tags": ["death"]},
	{"type": "fungal", "tags": ["growth", "death"]},
	{"type": "ember", "tags": ["fire"]},
	{"type": "eye", "tags": ["void"]},
	{"type": "heart", "tags": ["blood"]},
	{"type": "stone", "tags": ["foundation"]},
]

func before_each() -> void:
	_synergy_checker = load("res://scripts/autoloads/SynergyChecker.gd").new()
	add_child(_synergy_checker)
	# Note: _ready() is called automatically when added as child

func after_each() -> void:
	if _synergy_checker and is_instance_valid(_synergy_checker):
		_synergy_checker.queue_free()

func test_synergy_definitions_exist() -> void:
	# Verify all required synergy definitions exist
	var synergies = _synergy_checker.SYNERGIES

	assert_true(synergies.has("necrotic_bloom"), "necrotic_bloom should exist")
	assert_true(synergies.has("cursed_flame"), "cursed_flame should exist")
	assert_true(synergies.has("void_choir"), "void_choir should exist")
	assert_true(synergies.has("bleeding_arch"), "bleeding_arch should exist")
	assert_true(synergies.has("profane_eye"), "profane_eye should exist")

func test_synergy_definitions_have_required_fields() -> void:
	var synergies = _synergy_checker.SYNERGIES

	for id in synergies:
		var synergy = synergies[id]
		assert_true(synergy.has("tags"), "%s should have tags" % id)
		assert_true(synergy.has("min"), "%s should have min" % id)
		assert_true(synergy["tags"] is Array, "%s tags should be array" % id)
		assert_true(synergy["min"] is int, "%s min should be int" % id)

func test_necrotic_bloom_definition() -> void:
	var synergy = _synergy_checker.SYNERGIES["necrotic_bloom"]
	assert_eq(synergy["tags"], ["death", "growth"], "necrotic_bloom requires death and growth tags")
	assert_eq(synergy["min"], 3, "necrotic_bloom requires min 3")

func test_cursed_flame_definition() -> void:
	var synergy = _synergy_checker.SYNERGIES["cursed_flame"]
	assert_eq(synergy["tags"], ["fire", "cursed"], "cursed_flame requires fire and cursed tags")
	assert_eq(synergy["min"], 3, "cursed_flame requires min 3")

func test_void_choir_definition() -> void:
	var synergy = _synergy_checker.SYNERGIES["void_choir"]
	assert_eq(synergy["tags"], ["void"], "void_choir requires void tag")
	assert_eq(synergy["min"], 3, "void_choir requires min 3")

func test_bleeding_arch_definition() -> void:
	var synergy = _synergy_checker.SYNERGIES["bleeding_arch"]
	assert_eq(synergy["tags"], ["blood", "foundation"], "bleeding_arch requires blood and foundation tags")
	assert_eq(synergy["min"], 3, "bleeding_arch requires min 3")

func test_profane_eye_definition() -> void:
	var synergy = _synergy_checker.SYNERGIES["profane_eye"]
	assert_eq(synergy["tags"], ["void", "death"], "profane_eye requires void and death tags")
	assert_eq(synergy["min"], 3, "profane_eye requires min 3")

func test_min_tag_count_empty() -> void:
	# Test with empty tag counts
	var result = _synergy_checker._min_tag_count(["death", "growth"])
	assert_eq(result, 0, "Should return 0 when no tags present")

func test_min_tag_count_single_tag() -> void:
	# Manually set tag counts
	_synergy_checker._tag_counts = {"death": 5, "growth": 3}

	var result = _synergy_checker._min_tag_count(["death", "growth"])
	assert_eq(result, 3, "Should return minimum count (3)")

func test_min_tag_count_multiple_tags() -> void:
	_synergy_checker._tag_counts = {"death": 10, "growth": 2, "fire": 5}

	var result = _synergy_checker._min_tag_count(["death", "growth"])
	assert_eq(result, 2, "Should return minimum count (2)")

func test_min_tag_count_missing_tag() -> void:
	_synergy_checker._tag_counts = {"death": 5}

	var result = _synergy_checker._min_tag_count(["death", "void"])
	assert_eq(result, 0, "Should return 0 when tag is missing")

func test_get_active_synergies_empty() -> void:
	var result = _synergy_checker.get_active_synergies()
	assert_eq(result.size(), 0, "Should return empty dict initially")

func test_recount_from_board_clears_counts() -> void:
	_synergy_checker._tag_counts = {"old_tag": 100}
	_synergy_checker._tag_counts = {}
	# Verify internal state
	var result = _synergy_checker.get_active_synergies()
	assert_eq(result.size(), 0, "Should have no active synergies")

func test_synergy_activation_threshold() -> void:
	# Set up tag counts that meet threshold
	_synergy_checker._tag_counts = {"death": 3, "growth": 5}
	_synergy_checker._active = {}

	# Call _evaluate_all
	_synergy_checker._evaluate_all()

	var active = _synergy_checker.get_active_synergies()
	assert_true(active.has("necrotic_bloom"), "necrotic_bloom should activate at min 3")
	assert_eq(active["necrotic_bloom"], 3, "necrotic_bloom should have count 3")

func test_synergy_breaks_below_threshold() -> void:
	# Start with active synergy
	_synergy_checker._active = {"necrotic_bloom": 5}
	_synergy_checker._tag_counts = {"death": 2, "growth": 1}

	_synergy_checker._evaluate_all()

	var active = _synergy_checker.get_active_synergies()
	assert_false(active.has("necrotic_bloom"), "necrotic_bloom should break below threshold")

func test_synergy_scales_with_count() -> void:
	_synergy_checker._tag_counts = {"death": 5, "growth": 5}
	_synergy_checker._active = {}

	_synergy_checker._evaluate_all()

	var active = _synergy_checker.get_active_synergies()
	assert_eq(active["necrotic_bloom"], 5, "Should track scaled count")
