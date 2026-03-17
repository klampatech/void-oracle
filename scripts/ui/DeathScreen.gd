# DeathScreen.gd — Death screen UI showing ghost board summary
extends CanvasLayer

## Death screen that displays when the player dies.
## Shows ghost board summary and provides restart option.

## Signals
signal restart_requested
signal main_menu_requested

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var stats_container: VBoxContainer = $MarginContainer/VBoxContainer/StatsContainer
@onready var ghost_summary_label: Label = $MarginContainer/VBoxContainer/GhostSummaryLabel
@onready var restart_button: Button = $MarginContainer/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $MarginContainer/VBoxContainer/MainMenuButton
@onready var background: ColorRect = $Background

var _ghost_data: Dictionary = {}


func _ready() -> void:
	# Connect buttons
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# Hide by default
	visible = false

	# Subscribe to run ended to show death screen
	EventBus.run_ended.connect(_on_run_ended)


func _on_run_ended(cause: String, board_state: Dictionary) -> void:
	if cause == "stability_depleted":
		_ghost_data = board_state
		_show_death_screen()


func _show_death_screen() -> void:
	visible = true

	# Update title based on cause
	title_label.text = "STABILITY DEPLETED"

	# Build stats display
	_update_stats_display()

	# Build ghost summary
	_update_ghost_summary()


func _update_stats_display() -> void:
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()

	# Add stat rows
	_add_stat_row("Zone Reached", str(_ghost_data.get("zone_reached", 1)))
	_add_stat_row("Total Drops", str(_ghost_data.get("total_drops", 0)))
	_add_stat_row("Stability at Death", str(_ghost_data.get("stability_at_death", 0)))
	_add_stat_row("Oracle Class", _ghost_data.get("oracle_class", "none").capitalize())

	# Show peg count
	var pegs: Array = _ghost_data.get("pegs", [])
	_add_stat_row("Pegs on Board", str(pegs.size()))

	# Show active synergies
	var synergies: Array = _ghost_data.get("active_synergies", [])
	if not synergies.is_empty():
		_add_stat_row("Active Synergies", ", ".join(synergies))


func _add_stat_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = label_text + ": "
	label.custom_minimum_size.x = 150
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", Color(1, 0.84, 0))  # Gold color
	row.add_child(value)

	stats_container.add_child(row)


func _update_ghost_summary() -> void:
	# Build a summary of the ghost board
	var pegs: Array = _ghost_data.get("pegs", [])

	# Count peg types
	var peg_counts: Dictionary = {}
	for peg in pegs:
		var peg_type: String = peg.get("type", "unknown")
		peg_counts[peg_type] = peg_counts.get(peg_type, 0) + 1

	# Format summary
	var summary_lines: PackedStringArray = []
	summary_lines.append("=== GHOST BOARD SUMMARY ===")

	if peg_counts.is_empty():
		summary_lines.append("No pegs recorded.")
	else:
		summary_lines.append("Peg Composition:")
		var sorted_keys = peg_counts.keys()
		sorted_keys.sort()
		for peg_type in sorted_keys:
			summary_lines.append("  - %s: %d" % [peg_type, peg_counts[peg_type]])

	var relics: Array = _ghost_data.get("relics", [])
	if not relics.is_empty():
		summary_lines.append("Relics: %s" % ", ".join(relics))

	ghost_summary_label.text = "\n".join(summary_lines)


func _on_restart_pressed() -> void:
	# Hide death screen
	visible = false

	# Emit signal for restart
	restart_requested.emit()

	# Start a new run with a new seed
	var new_seed := Time.get_unix_time_from_system()
	RunManager.start_new_run(new_seed)


func _on_main_menu_pressed() -> void:
	# Hide death screen
	visible = false

	# Emit signal for main menu
	main_menu_requested.emit()

	# Load main menu scene
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
