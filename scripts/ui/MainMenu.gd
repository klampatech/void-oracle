extends Control

func _ready() -> void:
	# Load the Board scene when ready
	# For now, this is a placeholder that will be replaced with actual menu
	pass

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/Board.tscn")
