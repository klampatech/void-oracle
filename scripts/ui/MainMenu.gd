extends Control

## Currently selected class (default: "none")
var _selected_class: String = "none"

## Class definitions
const CLASSES := {
	"none": {
		"name": "Wanderer",
		"description": "No special bonuses. A fresh start.",
		"bonus": "Starting: 2 random pegs"
	},
	"naturalist": {
		"name": "The Naturalist",
		"description": "Commands the power of growth and decay.",
		"bonus": "Starting: 4 Fungal pegs"
	},
	"doomsayer": {
		"name": "The Doomsayer",
		"description": "Embraces death and void energy.",
		"bonus": "Starting: 2 Bone + 1 Cursed peg"
	},
	"architect": {
		"name": "The Architect",
		"description": "Builds unshakeable foundations.",
		"bonus": "+10 Max Stability"
	},
	"void_walker": {
		"name": "The Void-Walker",
		"description": "Walk the boundary between worlds.",
		"bonus": "Starting: Void Rift + Eye peg"
	}
}

func _ready() -> void:
	# Update void shard display
	_update_void_shards_display()
	# Default to wanderer
	_select_class("none")


func _update_void_shards_display() -> void:
	var void_label = get_node_or_null("VoidShardLabel")
	if void_label:
		void_label.text = "Void Shards: %d" % MetaState.get_void_shards()


func _select_class(class_id: String) -> void:
	_selected_class = class_id
	print("MainMenu: Selected class: ", class_id)

	# Update button highlights
	for key in CLASSES.keys():
		var btn = get_node_or_null("ClassContainer/Class" + key.capitalize())
		if btn:
			if key == class_id:
				btn.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298))
				btn.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.5))
			else:
				btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				btn.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.9))

	# Update description
	var desc_label = get_node_or_null("ClassDescription")
	if desc_label:
		var class_data = CLASSES.get(class_id, {})
		desc_label.text = class_data.get("description", "")
		desc_label.text += "\n" + class_data.get("bonus", "")


func _on_class_selected(class_id: String) -> void:
	_select_class(class_id)


func _on_start_pressed() -> void:
	# Generate random seed for the run
	var seed := randi()
	print("MainMenu: Starting new run with seed: ", seed, ", class: ", _selected_class)

	# Hide the menu and set mouse_filter to IGNORE so it doesn't block input to the map
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Start the run via RunManager with selected class
	RunManager.start_new_run(seed, _selected_class)
