# RunHistoryUI.gd — Displays run history and stats from the main menu.
extends CanvasLayer

## Run history display UI shown from main menu.

@onready var history_container: VBoxContainer = $MarginContainer/VBoxContainer/HistoryContainer
@onready var stats_container: VBoxContainer = $MarginContainer/VBoxContainer/StatsContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var no_history_label: Label = $MarginContainer/VBoxContainer/NoHistoryLabel

var _is_visible_state: bool = false


func _ready() -> void:
	# Connect back button
	back_button.pressed.connect(_on_back_pressed)

	# Hide by default
	visible = false


## Show the run history
func show_history() -> void:
	visible = true
	_is_visible_state = true
	_update_display()


## Hide the run history
func hide_history() -> void:
	visible = false
	_is_visible_state = false


func _update_display() -> void:
	# Clear existing content
	_clear_history_entries()
	_clear_stats()

	# Get data from MetaState
	var run_history: Array[Dictionary] = MetaState.get_run_history()
	var best_run: Dictionary = MetaState.get_best_run()
	var total_runs: int = MetaState.get_total_runs()
	var total_shards: int = MetaState.get_void_shards()
	var highest_zone: int = MetaState.highest_zone_reached

	# Show/hide no history label
	no_history_label.visible = run_history.is_empty()

	# Update stats
	_add_stat_row("Total Runs", str(total_runs))
	_add_stat_row("Void Shards", str(total_shards))
	_add_stat_row("Highest Zone", str(highest_zone))

	if not best_run.is_empty():
		_add_stat_row("Best Run Zone", str(best_run.get("zone_reached", 0)))
		_add_stat_row("Best Run Drops", str(best_run.get("total_drops", 0)))

	# Update run history list
	if not run_history.is_empty():
		_add_history_header()

		# Show most recent runs first (reverse order)
		for i in range(run_history.size() - 1, -1, -1):
			var run: Dictionary = run_history[i]
			_add_history_entry(run)


func _clear_history_entries() -> void:
	for child in history_container.get_children():
		child.queue_free()


func _clear_stats() -> void:
	for child in stats_container.get_children():
		child.queue_free()


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


func _add_history_header() -> void:
	var header := Label.new()
	header.text = "=== Recent Runs ==="
	header.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298))
	header.add_theme_font_size_override("font_size", 18)
	history_container.add_child(header)


func _add_history_entry(run: Dictionary) -> void:
	var entry := HBoxContainer.new()

	# Result icon/color
	var result_label := Label.new()
	var is_victory: bool = run.get("is_victory", false)
	var zone: int = run.get("zone_reached", 1)
	var drops: int = run.get("total_drops", 0)
	var oracle_class: String = run.get("oracle_class", "none")

	if is_victory:
		result_label.text = "VICTORY"
		result_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))  # Green
	else:
		result_label.text = "DEFEAT"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))  # Red

	result_label.custom_minimum_size.x = 80
	entry.add_child(result_label)

	# Zone info
	var zone_label := Label.new()
	zone_label.text = "Zone %d" % zone
	zone_label.custom_minimum_size.x = 80
	entry.add_child(zone_label)

	# Drops
	var drops_label := Label.new()
	drops_label.text = "%d drops" % drops
	drops_label.custom_minimum_size.x = 80
	entry.add_child(drops_label)

	# Class
	var class_label := Label.new()
	class_label.text = oracle_class.capitalize()
	class_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	entry.add_child(class_label)

	history_container.add_child(entry)


func _on_back_pressed() -> void:
	hide_history()
