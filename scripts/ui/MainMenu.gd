extends Control

func _ready() -> void:
	# Start button will call start_run
	pass


func _on_start_pressed() -> void:
	# Generate random seed for the run
	var seed := randi()
	print("MainMenu: Starting new run with seed: ", seed)

	# Hide the menu so the map (added by RunManager) becomes visible
	visible = false

	# Start the run via RunManager
	RunManager.start_new_run(seed)
