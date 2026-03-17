# Test sanity check - verifies GUT is working
extends GutTest

func test_sanity() -> void:
	assert_true(true, "Sanity check should pass")

func test_run_state_initializes() -> void:
	# Verify RunState autoload exists and initializes
	assert_not_null(RunState, "RunState should be autoloaded")
	assert_true(RunState.has_method("new_run"), "RunState should have new_run method")
