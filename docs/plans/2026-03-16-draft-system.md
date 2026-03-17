# Draft System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the Draft System allowing players to select and place 1 of 3 random pegs after defeating an enemy.

**Architecture:** A DraftSystem singleton that generates tier-weighted random peg offerings, displays them in a DraftUI overlay, and handles placement on empty board slots using the existing Board.add_peg_at_position() method.

**Tech Stack:** Godot 4.3+, GDScript, existing EventBus signal architecture

---

## Files Reference

### Key Existing Files:
- `scripts/game/EncounterManager.gd:235` — Replace TODO to trigger draft after enemy defeat
- `scripts/autoloads/EventBus.gd:39` — Has `draft_choice_made(peg_type: String)` signal
- `scripts/game/Board.gd:198` — Has `add_peg_at_position(peg_type, position)` method
- `data/pegs/peg_definitions.json` — Peg tier data: common, uncommon, rare, legendary
- `scripts/autoloads/RunState.gd` — Track current zone, gold, ball_count

### Files to Create:
- `scripts/game/systems/DraftSystem.gd` — Main draft logic (create directory)
- `scenes/ui/DraftUI.tscn` — Draft card selection UI
- `scripts/ui/DraftUI.gd` — DraftUI logic

### Files to Modify:
- `scripts/game/EncounterManager.gd` — Hook up draft trigger

---

## Task 1: Create DraftSystem.gd Script

**Files:**
- Create: `scripts/game/systems/DraftSystem.gd`

**Step 1: Create the script**

```gdscript
# DraftSystem.gd — Handles random peg offerings and placement after combat
extends Node
class_name DraftSystem

## Tier weights for random selection
const TIER_WEIGHTS := {
	"common": 50,
	"uncommon": 30,
	"rare": 15,
	"legendary": 5,
}

## Peg types by tier (from peg_definitions.json analysis)
const PEGS_BY_TIER := {
	"common": ["stone", "bone"],
	"uncommon": ["fungal", "ember"],
	"rare": ["eye", "heart"],
	"legendary": ["oracle", "void_rift"],
}

## Preload peg definitions
var _peg_data: Dictionary = preload("res://data/pegs/peg_definitions.json")

## Current offerings
var _current_offerings: Array[String] = []

## Selected peg type
var _selected_peg: String = ""

## Placement mode active
var _placement_mode: bool = false

## Board reference
var _board: Node2D = null


func _ready() -> void:
	# Get board reference
	_board = get_tree().get_first_node_in_group("board") or get_node_or_null("../Board")


## Generate 3 random peg offerings based on tier weights
func generate_offerings() -> Array[String]:
	_current_offerings.clear()

	var total_weight := 0
	for tier in TIER_WEIGHTS:
		total_weight += TIER_WEIGHTS[tier]

	# Generate 3 offerings
	for i in range(3):
		var roll := randi() % total_weight
		var cumulative := 0
		var selected_tier: String = "common"

		for tier in TIER_WEIGHTS:
			cumulative += TIER_WEIGHTS[tier]
			if roll < cumulative:
				selected_tier = tier
				break

		# Pick random peg from tier
		var pegs: Array = PEGS_BY_TIER[selected_tier]
		var peg: String = pegs[randi() % pegs.size()]

		# Ensure no duplicates
		while peg in _current_offerings:
			pegs = PEGS_BY_TIER[selected_tier]
			peg = pegs[randi() % pegs.size()]

		_current_offerings.append(peg)

	return _current_offerings


## Get current offerings
func get_offerings() -> Array[String]:
	return _current_offerings


## Get peg data for display
func get_peg_info(peg_type: String) -> Dictionary:
	if _peg_data.has(peg_type):
		return _peg_data[peg_type]
	return {}


## Select a peg type for placement
func select_peg(peg_type: String) -> void:
	if peg_type in _current_offerings:
		_selected_peg = peg_type
		_placement_mode = true
		# Emit signal that placement mode started
		EventBus.draft_choice_made.emit(peg_type)


## Get selected peg type
func get_selected_peg() -> String:
	return _selected_peg


## Check if in placement mode
func is_in_placement_mode() -> bool:
	return _placement_mode


## Place peg at position
func place_peg_at(position: Vector2) -> bool:
	if not _placement_mode or _selected_peg.is_empty():
		return false

	if _board and _board.has_method("add_peg_at_position"):
		var peg = _board.add_peg_at_position(_selected_peg, position)
		if peg:
			_reset_draft()
			return true

	return false


## Cancel draft selection
func cancel_selection() -> void:
	_reset_draft()


func _reset_draft() -> void:
	_selected_peg = ""
	_placement_mode = false
	_current_offerings.clear()
```

**Step 2: Verify file created**

Run: `ls -la scripts/game/systems/DraftSystem.gd`
Expected: File exists

---

## Task 2: Create DraftUI Scene

**Files:**
- Create: `scenes/ui/DraftUI.tscn`
- Create: `scripts/ui/DraftUI.gd`

**Step 1: Create DraftUI.gd script**

```gdscript
# DraftUI.gd — Displays 3 peg cards for selection
extends CanvasLayer
class_name DraftUI

## Reference to DraftSystem (will be added as autoload later)
var _draft_system: Node = null

## Card container
@onready var _card_container: HBoxContainer = $VBoxContainer/CardContainer

## Label for instructions
@onready var _instructions: Label = $VBoxContainer/Instructions

## Preload peg card scene (we'll create inline)
var _peg_scenes: Dictionary = {
	"stone": preload("res://scenes/game/pegs/StonePeg.tscn"),
	"bone": preload("res://scenes/game/pegs/BonePeg.tscn"),
	"fungal": preload("res://scenes/game/pegs/FungalPeg.tscn"),
	"ember": preload("res://scenes/game/pegs/EmberPeg.tscn"),
	"eye": preload("res://scenes/game/pegs/EyePeg.tscn"),
	"heart": preload("res://scenes/game/pegs/HeartPeg.tscn"),
	"oracle": preload("res://scenes/game/pegs/OraclePeg.tscn"),
	"void_rift": preload("res://scenes/game/pegs/VoidRiftPeg.tscn"),
}

## Peg definitions
var _peg_data: Dictionary = preload("res://data/pegs/peg_definitions.json")


func _ready() -> void:
	# Get DraftSystem reference
	_draft_system = get_tree().get_first_node_in_group("draft_system")
	if not _draft_system:
		_draft_system = get_node_or_null("/root/DraftSystem")

	# Hide initially
	hide()


## Show draft UI with offerings
func show_draft(offerings: Array[String]) -> void:
	# Clear existing cards
	for child in _card_container.get_children():
		child.queue_free()

	# Create card for each offering
	for peg_type in offerings:
		var card := _create_card(peg_type)
		_card_container.add_child(card)

	show()


## Create a single peg card
func _create_card(peg_type: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 200)

	# Create vbox for card content
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Peg name
	var name_label := Label.new()
	name_label.text = _peg_data.get(peg_type, {}).get("display_name", peg_type)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Tier label
	var tier_label := Label.new()
	var tier: String = _get_tier_for_peg(peg_type)
	tier_label.text = tier
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(tier_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = _peg_data.get(peg_type, {}).get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(130, 60)
	vbox.add_child(desc_label)

	# Click handler
	card.gui_input.connect(_on_card_clicked.bind(peg_type))

	# Style by tier
	_add_card_style(card, tier)

	return card


func _get_tier_for_peg(peg_type: String) -> String:
	var peg_info: Dictionary = _peg_data.get(peg_type, {})
	return peg_info.get("tier", "common")


func _add_card_style(card: PanelContainer, tier: String) -> void:
	var color: Color
	match tier:
		"common":
			color = Color("#888888")
		"uncommon":
			color = Color("#4A7A3A")
		"rare":
			color = Color("#9060E8")
		"legendary":
			color = Color("#C9A84C")
		_:
			color = Color("#888888")

	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.3)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)


func _on_card_clicked(event: InputEvent, peg_type: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _draft_system and _draft_system.has_method("select_peg"):
			_draft_system.select_peg(peg_type)
			hide()
```

**Step 2: Create DraftUI.tscn scene**

Create a new scene with this structure:
```
DraftUI (CanvasLayer)
└── VBoxContainer (anchors: center)
    ├── Label: "Choose a Peg" (instructions)
    └── HBoxContainer (CardContainer)
        └── (Cards created programmatically)
```

Use Godot editor to create:
1. New Scene → CanvasLayer → Name: DraftUI
2. Add VBoxContainer → Set Layout: Center
3. Add Label → Text: "Choose a Peg to Add"
4. Add HBoxContainer → Name: CardContainer
5. Attach DraftUI.gd script to root
6. Save as `scenes/ui/DraftUI.tscn`

---

## Task 3: Integrate with EncounterManager

**Files:**
- Modify: `scripts/game/EncounterManager.gd:226-236`

**Step 1: Add DraftSystem reference**

Add at top of EncounterManager.gd (after other var declarations):
```gdscript
## Draft system reference
var _draft_system: Node = null
```

Add in `_ready()` function after getting board/ball_spawner:
```gdscript
# Get draft system reference
_draft_system = get_tree().get_first_node_in_group("draft_system")
if not _draft_system:
    _draft_system = get_node_or_null("/root/DraftSystem")
```

**Step 2: Modify _on_enemy_defeated**

Replace lines 226-236 (current):
```gdscript
## Called when enemy is defeated
func _on_enemy_defeated(enemy: Node) -> void:
    _set_phase(Phase.VICTORY)

    # Update stats
    RunState.enemies_defeated += 1

    # Emit encounter ended
    EventBus.encounter_ended.emit("victory")

    # TODO: Trigger rewards/draft phase
```

With:
```gdscript
## Called when enemy is defeated
func _on_enemy_defeated(enemy: Node) -> void:
    _set_phase(Phase.VICTORY)

    # Update stats
    RunState.enemies_defeated += 1

    # Emit encounter ended
    EventBus.encounter_ended.emit("victory")

    # Trigger draft phase
    _start_draft_phase()


## Start draft phase after victory
func _start_draft_phase() -> void:
    if _draft_system and _draft_system.has_method("generate_offerings"):
        var offerings = _draft_system.generate_offerings()

        # Find DraftUI and show it
        var draft_ui = get_tree().get_first_node_in_group("draft_ui")
        if draft_ui and draft_ui.has_method("show_draft"):
            draft_ui.show_draft(offerings)

        # Enable placement mode
        _set_phase(Phase.BOARD)
```

---

## Task 4: Register as Autoload (Optional - Alternative)

**Alternative Approach:** If you want DraftSystem as an autoload:

**Files:**
- Modify: Add to Project Settings > Autoload

Since this is complex in CLI, use alternative: Add DraftSystem as child of EncounterManager

In EncounterManager._ready():
```gdscript
# Create draft system if not autoloaded
if not _draft_system:
    var DraftSystemScript = load("res://scripts/game/systems/DraftSystem.gd")
    _draft_system = DraftSystemScript.new()
    _draft_system.name = "DraftSystem"
    add_child(_draft_system)
    _draft_system.add_to_group("draft_system")
```

---

## Task 5: Test the Draft System

**Step 1: Run the game**

Run: `./run_debug.sh`

**Step 2: Defeat the Corruptor enemy**

1. Play through to encounter
2. Drop balls to deal 80+ damage
3. Watch for VICTORY in console

**Step 3: Verify draft UI appears**

Expected: After enemy defeat, DraftUI overlay shows 3 peg cards

**Step 4: Click a card**

Expected: UI hides, empty slot indicators appear (if implemented)

**Step 5: Click board to place**

Expected: Peg appears at clicked position

---

## Task 6: Commit

```bash
git add scripts/game/systems/DraftSystem.gd scenes/ui/DraftUI.tscn scripts/ui/DraftUI.gd scripts/game/EncounterManager.gd
git commit -m "feat: Implement Draft System - peg selection and placement after combat

- Add DraftSystem.gd with tier-weighted random peg generation
- Add DraftUI.tscn with card selection display
- Integrate with EncounterManager to trigger draft on enemy defeat
- Uses existing Board.add_peg_at_position() for placement

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Summary

This implementation adds:
1. **DraftSystem.gd** — Generates 3 random peg offerings, handles selection and placement
2. **DraftUI** — Visual card-based selection interface
3. **EncounterManager integration** — Triggers draft after enemy defeat

The system uses existing infrastructure:
- `EventBus.draft_choice_made` signal (already exists)
- `Board.add_peg_at_position()` method (already exists)
- `RunState` for tracking run state
