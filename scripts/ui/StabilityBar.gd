# StabilityBar.gd — HUD stability bar showing player health
extends Control
class_name StabilityBar

## Progress bar for stability
@onready var _progress_bar: ProgressBar = $Panel/ProgressBar
@onready var _label: Label = $Panel/Label

## Colors for the bar (gold → red as it depletes)
const COLOR_FULL := Color("#FFD700")     # Gold
const COLOR_MEDIUM := Color("#FF8C00")   # Orange
const COLOR_LOW := Color("#FF4444")      # Red

## Threshold percentages for color changes
const THRESHOLD_MEDIUM := 0.5
const THRESHOLD_LOW := 0.25


func _ready() -> void:
	# Subscribe to stability changes
	EventBus.player_stability_changed.connect(_on_stability_changed)

	# Initialize with current stability
	_update_bar(RunState.stability, RunState.max_stability)


## Called when player stability changes
func _on_stability_changed(new_value: float, _delta: float) -> void:
	_update_bar(new_value, RunState.max_stability)


## Update the bar display
func _update_bar(current: float, maximum: float) -> void:
	if _progress_bar:
		_progress_bar.max_value = maximum
		_progress_bar.value = current

		# Update color based on percentage
		var percentage := current / maximum if maximum > 0 else 0.0
		var color := _get_color_for_percentage(percentage)
		_progress_bar.modulate = color

	# Update label
	if _label:
		_label.text = "%d / %d" % [int(current), int(maximum)]


## Get color based on percentage
func _get_color_for_percentage(percentage: float) -> Color:
	if percentage > THRESHOLD_MEDIUM:
		return COLOR_FULL
	elif percentage > THRESHOLD_LOW:
		return COLOR_MEDIUM
	else:
		return COLOR_LOW
