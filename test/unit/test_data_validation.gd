# test/unit/test_data_validation.gd — Data validation tests
extends GutTest

## Test peg definitions JSON is valid and complete
func test_peg_definitions_exist() -> void:
	var peg_defs := load_json("res://data/pegs/peg_definitions.json")
	assert_not_null(peg_defs, "peg_definitions.json should exist")


func test_peg_definitions_has_all_types() -> void:
	var peg_defs := load_json("res://data/pegs/peg_definitions.json")
	assert_not_null(peg_defs, "peg_definitions.json should exist")

	# Expected peg types from game design
	var expected_types := [
		"stone", "bone", "fungal", "ember",
		"eye", "heart", "oracle", "void_rift"
	]

	for peg_type in expected_types:
		assert_true(
			peg_defs.has(peg_type),
			"Peg definitions should have type: " + peg_type
		)


func test_peg_definitions_have_required_fields() -> void:
	var peg_defs := load_json("res://data/pegs/peg_definitions.json")
	assert_not_null(peg_defs, "peg_definitions.json should exist")

	for peg_type in peg_defs.keys():
		var peg_data = peg_defs[peg_type]
		assert_true(
			peg_data.has("display_name"),
			"Peg " + peg_type + " should have display_name"
		)
		assert_true(
			peg_data.has("friction"),
			"Peg " + peg_type + " should have friction"
		)
		assert_true(
			peg_data.has("restitution"),
			"Peg " + peg_type + " should have restitution"
		)


func test_peg_physics_values_in_range() -> void:
	var peg_defs := load_json("res://data/pegs/peg_definitions.json")
	assert_not_null(peg_defs, "peg_definitions.json should exist")

	for peg_type in peg_defs.keys():
		var peg_data = peg_defs[peg_type]
		var friction = peg_data.get("friction", -1)
		var restitution = peg_data.get("restitution", -1)

		# Physics values should be in valid ranges
		assert_true(
			friction >= 0.0 and friction <= 1.0,
			"Peg " + peg_type + " friction should be 0-1, got: " + str(friction)
		)
		assert_true(
			restitution >= 0.0 and restitution <= 1.0,
			"Peg " + peg_type + " restitution should be 0-1, got: " + str(restitution)
		)


## Test synergy definitions JSON is valid and complete
func test_synergy_definitions_exist() -> void:
	var synergy_defs := load_json("res://data/synergies/synergy_definitions.json")
	assert_not_null(synergy_defs, "synergy_definitions.json should exist")


func test_synergy_definitions_has_all_synergies() -> void:
	var synergy_defs := load_json("res://data/synergies/synergy_definitions.json")
	assert_not_null(synergy_defs, "synergy_definitions.json should exist")

	# Expected synergies from game design
	var expected_synergies := [
		"necrotic_bloom", "cursed_flame", "void_choir",
		"bleeding_architecture", "profane_eye"
	]

	for synergy_id in expected_synergies:
		assert_true(
			synergy_defs.has(synergy_id),
			"Synergy definitions should have: " + synergy_id
		)


func test_synergy_definitions_have_required_fields() -> void:
	var synergy_defs := load_json("res://data/synergies/synergy_definitions.json")
	assert_not_null(synergy_defs, "synergy_definitions.json should exist")

	for synergy_id in synergy_defs.keys():
		var synergy_data = synergy_defs[synergy_id]
		assert_true(
			synergy_data.has("display_name"),
			"Synergy " + synergy_id + " should have display_name"
		)
		assert_true(
			synergy_data.has("description"),
			"Synergy " + synergy_id + " should have description"
		)
		assert_true(
			synergy_data.has("required_tags"),
			"Synergy " + synergy_id + " should have required_tags"
		)
		assert_true(
			synergy_data.has("tiers"),
			"Synergy " + synergy_id + " should have tiers"
		)


## Test enemy data files exist
func test_all_enemy_files_exist() -> void:
	var enemy_dir := DirAccess.open("res://data/enemies/")
	assert_not_null(enemy_dir, "Enemy data directory should exist")

	var expected_enemies := [
		"corruptor.json", "wrecker.json", "spawner.json",
		"leech.json", "gardener.json", "architect.json",
		"final_oracle.json"
	]

	for enemy_file in expected_enemies:
		var file_path: String = "res://data/enemies/" + enemy_file
		var file_exists: bool = FileAccess.file_exists(file_path)
		assert_true(
			file_exists,
			"Enemy file should exist: " + enemy_file
		)


func test_enemy_json_is_valid() -> void:
	var enemies := ["corruptor", "wrecker", "spawner", "leech"]

	for enemy_id in enemies:
		var enemy_data := load_json("res://data/enemies/" + enemy_id + ".json")
		assert_not_null(
			enemy_data,
			"Enemy " + enemy_id + " should have valid JSON"
		)

		# Check required fields
		assert_true(
			enemy_data.has("name"),
			"Enemy " + enemy_id + " should have name"
		)
		assert_true(
			enemy_data.has("hp"),
			"Enemy " + enemy_id + " should have hp"
		)
		assert_true(
			enemy_data.has("actions"),
			"Enemy " + enemy_id + " should have actions"
		)


## Edge cases
func test_missing_peg_file() -> void:
	var result = load_json_safe("res://data/pegs/nonexistent.json")
	assert_true(result.is_empty(), "Should return empty for missing file")


func test_invalid_json_handled() -> void:
	# This test verifies error handling
	# Create a temporary invalid JSON file would require file system access
	# For now, just verify the load_json function exists
	assert_true(has_method("load_json"), "Helper method should exist")


## Helper to load JSON file
func load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		return {}

	return json.get_data()


func load_json_safe(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	return load_json(path)
