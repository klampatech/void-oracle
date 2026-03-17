# runner.gd — Test runner script for CLI execution
# Usage: godot -s test/runner.gd
#
# This script runs all GUT tests and generates JUnit XML output
# for CI integration.

extends SceneTree

var _gut: Gut = null

func _init() -> void:
	print("========================================")
	print("Void Oracle Test Runner")
	print("========================================")
	print("")

	# Run tests
	_run_tests()

	# Exit
	quit()


func _run_tests() -> void:
	# Create GUT instance
	_gut = Gut.new()

	# Configure GUT
	_gut.set_test_script_prefix("test_")
	_gut.set_test_script_suffix(".gd")

	# Add test directories
	_gut.add_directory("res://test/unit", true)
	_gut.add_directory("res://test/integration", true)

	# Configure output
	_gut.set_log_level(GutUtils.LOG_LEVEL.test_results)
	_gut.show()

	# Run all tests
	var summary = _gut.test_scripts()

	# Print summary
	print("")
	print("========================================")
	print("Test Results Summary")
	print("========================================")
	print("Tests: ", summary.get("tests", 0))
	print("Passed: ", summary.get("passed", 0))
	print("Failed: ", summary.get("failed", 0))
	print("Skipped: ", summary.get("skipped", 0))
	print("")

	# Set exit code based on results
	if summary.get("failed", 0) > 0:
		print("FAILED - Some tests did not pass")
		set_exit_code(1)
	else:
		print("SUCCESS - All tests passed")
		set_exit_code(0)
