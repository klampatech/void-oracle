# BoardPhaseUI.gd — UI shown during BOARD phase before dropping balls
extends CanvasLayer

## UI overlay shown during the BOARD phase.
## Displays peg inventory, gold, void essence, stability, and ball count.
## "End Turn" button triggers the DROP phase.

@onready var gold_label: Label = $BottomLeftBox/GoldLabel
@onready var void_label: Label = $BottomRightBox/VoidLabel
@onready var stability_label: Label = $HiddenStats/StabilityRow/StabilityLabel
@onready var balls_label: Label = $TopLeftBox/BallsRow/BallsLabel
@onready var pegs_label: Label = $HiddenStats/PegsLabel
@onready var end_turn_button: TextureButton = $EndTurnContainer/EndTurnButton

var _encounter_manager: Node = null


func _ready() -> void:
	# Get reference to EncounterManager
	_encounter_manager = get_tree().get_first_node_in_group("encounter_manager")

	# Connect button
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Subscribe to EncounterManager phase changes
	if _encounter_manager and _encounter_manager.has_signal("phase_changed"):
		_encounter_manager.phase_changed.connect(_on_phase_changed)

	# Subscribe to EventBus signals
	EventBus.drop_started.connect(_on_drop_started)
	EventBus.drop_ended.connect(_on_drop_ended)
	EventBus.player_stability_changed.connect(_on_stability_changed)

	# Initial update
	_update_display()

	# Hide initially - shown during BOARD phase
	visible = false


func _process(_delta: float) -> void:
	# Update display every frame in case values change
	_update_display()


func _update_display() -> void:
	# Update gold
	gold_label.text = "Gold: %d" % RunState.gold

	# Update void essence
	void_label.text = "Void: %d" % RunState.void_essence

	# Update stability
	var stability_percent = (RunState.stability / RunState.max_stability) * 100
	stability_label.text = "Stability: %d/%d (%.0f%%)" % [RunState.stability, RunState.max_stability, stability_percent]

	# Update ball count
	balls_label.text = "Balls: %d" % RunState.ball_count

	# Update peg count
	pegs_label.text = "Pegs: %d" % RunState.pegs.size()


func _on_end_turn_pressed() -> void:
	if _encounter_manager and _encounter_manager.has_method("begin_drop_phase"):
		_encounter_manager.begin_drop_phase()


func _on_drop_started(_ball_count: int) -> void:
	# Hide when drop starts
	visible = false


func _on_drop_ended(_results: Dictionary) -> void:
	# Show when drop ends and we're back to BOARD phase
	visible = true


func _on_stability_changed(_new_value: float, _delta: float) -> void:
	# Update immediately on stability change
	_update_display()


func _on_phase_changed(new_phase: int) -> void:
	# Show UI during BOARD phase
	# Phase enum: 0=DROP, 1=RESULT, 2=BOARD, 3=ENEMY_TURN, 4=VICTORY, 5=DEFEAT
	visible = (new_phase == 2)  # BOARD phase
