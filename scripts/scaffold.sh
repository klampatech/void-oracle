#!/bin/bash
# Void Oracle — Godot 4 Project Scaffold Generator
# Run this from inside your Godot project root directory
# Usage: bash scaffold.sh

echo "Creating Void Oracle project structure..."

# ── Scenes ──────────────────────────────────────────────
mkdir -p scenes/game/pegs
mkdir -p scenes/map
mkdir -p scenes/menus
mkdir -p scenes/ui
mkdir -p scenes/effects

# ── Scripts ─────────────────────────────────────────────
mkdir -p scripts/autoloads
mkdir -p scripts/pegs
mkdir -p scripts/systems
mkdir -p scripts/ui
mkdir -p scripts/utils

# ── Shaders ─────────────────────────────────────────────
mkdir -p shaders

# ── Assets ──────────────────────────────────────────────
mkdir -p assets/audio/sfx
mkdir -p assets/audio/music
mkdir -p assets/audio/ambient
mkdir -p assets/textures/pegs
mkdir -p assets/textures/ui
mkdir -p assets/textures/effects
mkdir -p assets/textures/backgrounds
mkdir -p assets/fonts
mkdir -p assets/placeholders

# ── Data (JSON configs) ──────────────────────────────────
mkdir -p data/pegs
mkdir -p data/enemies
mkdir -p data/events
mkdir -p data/synergies
mkdir -p data/relics

echo "Creating AutoLoad singletons..."

cat > scripts/autoloads/EventBus.gd << 'EOF'
# EventBus.gd — Global signal hub. All cross-system communication flows through here.
# Add to AutoLoad in Project Settings as "EventBus"
extends Node

# ── Physics / Board ──────────────────────────────────────
signal peg_hit(peg: Node, ball: Node)
signal ball_entered_pocket(pocket: Node, ball: Node)
signal ball_lost(ball: Node)                          # fell off board

# ── Peg State ────────────────────────────────────────────
signal peg_state_changed(peg: Node, old_state: String, new_state: String)
signal peg_destroyed(peg: Node)
signal peg_spawned(peg: Node, position: Vector2)

# ── Synergies ────────────────────────────────────────────
signal synergy_activated(synergy_id: String, peg_count: int)
signal synergy_broken(synergy_id: String)
signal synergy_scaled(synergy_id: String, new_count: int)

# ── Drop Phase ───────────────────────────────────────────
signal drop_started(ball_count: int)
signal drop_ended(results: Dictionary)               # {damage, healing, gold, void_essence}
signal chaos_drop_triggered(chaos_type: String)

# ── Combat ───────────────────────────────────────────────
signal enemy_turn_start(enemy: Node)
signal enemy_action(enemy: Node, action: Dictionary)  # {type, target, value}
signal enemy_defeated(enemy: Node)
signal player_stability_changed(new_value: float, delta: float)

# ── Run / Map ────────────────────────────────────────────
signal node_selected(map_node: Dictionary)
signal encounter_started(encounter_type: String, data: Dictionary)
signal encounter_ended(result: String)               # "victory", "death", "fled"
signal run_ended(cause: String, board_state: Dictionary)

# ── UI ───────────────────────────────────────────────────
signal draft_choice_made(peg_type: String)
signal shop_purchase(item_id: String, cost: int)
signal relic_acquired(relic_id: String)
EOF

cat > scripts/autoloads/RunState.gd << 'EOF'
# RunState.gd — All mutable state for the current run.
# Add to AutoLoad in Project Settings as "RunState"
extends Node

# ── Run Meta ─────────────────────────────────────────────
var run_seed: int = 0
var run_id: String = ""
var zone: int = 1
var encounter_index: int = 0
var oracle_class: String = "none"

# ── Resources ────────────────────────────────────────────
var stability: float = 100.0
var max_stability: float = 100.0
var gold: int = 0
var void_essence: int = 0
var ball_count: int = 1           # balls available for next drop
var max_balls: int = 5

# ── Board State ──────────────────────────────────────────
var pegs: Array[Dictionary] = []  # [{id, type, position, state, hit_count, mutation_level}]
var active_synergies: Array[String] = []
var relics: Array[String] = []

# ── Run Stats ────────────────────────────────────────────
var total_drops: int = 0
var total_damage_dealt: int = 0
var enemies_defeated: int = 0
var ghost_board_encountered: bool = false

func new_run(seed: int, class_id: String = "none") -> void:
	run_seed = seed
	run_id = str(seed) + "_" + str(Time.get_unix_time_from_system())
	oracle_class = class_id
	zone = 1
	encounter_index = 0
	stability = 100.0
	gold = 0
	void_essence = 0
	ball_count = 1
	pegs = []
	active_synergies = []
	relics = []
	total_drops = 0

func modify_stability(delta: float) -> void:
	stability = clamp(stability + delta, 0.0, max_stability)
	EventBus.player_stability_changed.emit(stability, delta)
	if stability <= 0.0:
		EventBus.run_ended.emit("stability_depleted", snapshot_board())

func snapshot_board() -> Dictionary:
	return {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"run_seed": run_seed,
		"oracle_class": oracle_class,
		"zone_reached": zone,
		"pegs": pegs.duplicate(true),
		"active_synergies": active_synergies.duplicate(),
		"relics": relics.duplicate(),
		"stability_at_death": stability,
		"total_drops": total_drops,
	}
EOF

cat > scripts/autoloads/GhostBoardManager.gd << 'EOF'
# GhostBoardManager.gd — Persist and load Ghost Boards across runs.
# Add to AutoLoad in Project Settings as "GhostBoardManager"
extends Node

const SAVE_DIR = "user://void_oracle/ghost_boards/"
const MAX_GHOSTS = 10
var active_ghost: Dictionary = {}   # Ghost scheduled for this run's encounter

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_ghost(board_state: Dictionary) -> void:
	_rotate_ghosts()
	var path = SAVE_DIR + "ghost_001.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(board_state, "\t"))
		file.close()

func load_ghost(index: int) -> Dictionary:
	var path = SAVE_DIR + "ghost_%03d.json" % index
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var result = JSON.parse_string(file.get_as_text())
	file.close()
	return result if result else {}

func get_active_ghost() -> Dictionary:
	return active_ghost

func assign_ghost_for_run(run_seed: int) -> void:
	# Deterministically pick which ghost appears this run
	var rng = RandomNumberGenerator.new()
	rng.seed = run_seed + 9999
	var index = rng.randi_range(1, min(MAX_GHOSTS, _count_saved_ghosts()))
	active_ghost = load_ghost(index)

func _rotate_ghosts() -> void:
	for i in range(MAX_GHOSTS - 1, 0, -1):
		var src = SAVE_DIR + "ghost_%03d.json" % i
		var dst = SAVE_DIR + "ghost_%03d.json" % (i + 1)
		if FileAccess.file_exists(src):
			DirAccess.rename_absolute(src, dst)

func _count_saved_ghosts() -> int:
	var count = 0
	for i in range(1, MAX_GHOSTS + 1):
		if FileAccess.file_exists(SAVE_DIR + "ghost_%03d.json" % i):
			count += 1
	return count
EOF

cat > scripts/autoloads/SynergyChecker.gd << 'EOF'
# SynergyChecker.gd — Watches board state, activates/deactivates synergies.
# Add to AutoLoad in Project Settings as "SynergyChecker"
extends Node

# Synergy definitions: id -> {required_tags, min_count, curse_risk}
const SYNERGIES = {
	"necrotic_bloom": { "tags": ["death", "growth"], "min": 3 },
	"cursed_flame":   { "tags": ["fire", "cursed"],  "min": 3 },
	"void_choir":     { "tags": ["void"],             "min": 3 },
	"bleeding_arch":  { "tags": ["blood", "foundation"], "min": 3 },
	"profane_eye":    { "tags": ["void", "death"],    "min": 3 },
}

var _tag_counts: Dictionary = {}
var _active: Dictionary = {}   # synergy_id -> peg_count

func _ready() -> void:
	EventBus.peg_state_changed.connect(_on_peg_state_changed)
	EventBus.peg_spawned.connect(_on_peg_spawned)
	EventBus.peg_destroyed.connect(_on_peg_destroyed)

func recount_from_board(pegs: Array) -> void:
	_tag_counts.clear()
	for peg in pegs:
		for tag in peg.get("tags", []):
			_tag_counts[tag] = _tag_counts.get(tag, 0) + 1
	_evaluate_all()

func _on_peg_state_changed(_peg, _old, _new) -> void:
	recount_from_board(RunState.pegs)

func _on_peg_spawned(_peg, _pos) -> void:
	recount_from_board(RunState.pegs)

func _on_peg_destroyed(_peg) -> void:
	recount_from_board(RunState.pegs)

func _evaluate_all() -> void:
	for id in SYNERGIES:
		var def = SYNERGIES[id]
		var count = _min_tag_count(def["tags"])
		var was_active = _active.has(id)
		if count >= def["min"]:
			if not was_active:
				EventBus.synergy_activated.emit(id, count)
			elif _active[id] != count:
				EventBus.synergy_scaled.emit(id, count)
			_active[id] = count
		else:
			if was_active:
				_active.erase(id)
				EventBus.synergy_broken.emit(id)

func _min_tag_count(tags: Array) -> int:
	var min_count = INF
	for tag in tags:
		min_count = min(min_count, _tag_counts.get(tag, 0))
	return int(min_count) if min_count != INF else 0
EOF

cat > scripts/autoloads/AudioManager.gd << 'EOF'
# AudioManager.gd — Per-peg tone system + ambient layering.
# Add to AutoLoad in Project Settings as "AudioManager"
extends Node

# Map peg type -> tone frequency (Hz) — tuned to a pentatonic scale for harmonics
const PEG_TONES = {
	"stone":   261.6,   # C4
	"bone":    293.7,   # D4
	"fungal":  329.6,   # E4
	"ember":   392.0,   # G4
	"eye":     440.0,   # A4
	"heart":   523.3,   # C5
	"void_rift": 130.8, # C3 (deep)
	"oracle":  659.3,   # E5 (high)
}

const STATE_PITCH_MOD = {
	"dormant":  1.0,
	"blessed":  1.2,
	"cursed":   0.85,
	"mutant":   1.05,
	"void":     0.5,
	"shattered": 0.6,
}

func _ready() -> void:
	EventBus.peg_hit.connect(_on_peg_hit)

func _on_peg_hit(peg: Node, _ball: Node) -> void:
	var peg_type = peg.get("peg_type") if peg.get("peg_type") else "stone"
	var peg_state = peg.get("peg_state") if peg.get("peg_state") else "dormant"
	play_peg_tone(peg_type, peg_state)

func play_peg_tone(peg_type: String, state: String) -> void:
	var freq = PEG_TONES.get(peg_type, 261.6)
	var pitch_mod = STATE_PITCH_MOD.get(state, 1.0)
	# TODO: Replace with actual AudioStreamPlayer + AudioStreamGenerator
	# or load pre-generated tone samples from assets/audio/sfx/pegs/
	print("TONE: %s Hz (peg: %s, state: %s)" % [freq * pitch_mod, peg_type, state])
EOF

cat > scripts/autoloads/MutationEngine.gd << 'EOF'
# MutationEngine.gd — Tracks peg hit counts, manages blessed/cursed axis transitions.
# Add to AutoLoad in Project Settings as "MutationEngine"
extends Node

# How many hits before a peg can mutate
const MUTATION_THRESHOLD = 5
# Chance per hit (once threshold met) to shift state
const MUTATION_CHANCE = 0.15

func _ready() -> void:
	EventBus.peg_hit.connect(_on_peg_hit)

func _on_peg_hit(peg: Node, _ball: Node) -> void:
	if not peg.has_method("get_hit_count"):
		return
	var hits = peg.get_hit_count()
	if hits < MUTATION_THRESHOLD:
		return
	if randf() < MUTATION_CHANCE:
		_try_mutate(peg)

func _try_mutate(peg: Node) -> void:
	var current = peg.get("peg_state") if peg.get("peg_state") else "dormant"
	var new_state = _next_state(current, peg)
	if new_state != current:
		var old = current
		peg.set("peg_state", new_state)
		EventBus.peg_state_changed.emit(peg, old, new_state)

func _next_state(current: String, peg: Node) -> String:
	match current:
		"dormant":
			# Environmental pressure determines direction
			var corruption_pressure = _get_local_corruption(peg)
			return "cursed" if corruption_pressure > 0.5 else "blessed"
		"blessed":
			return "mutant" if randf() < 0.3 else "blessed"
		"cursed":
			return "mutant" if randf() < 0.4 else "cursed"
		"mutant":
			return "void" if randf() < 0.1 else "mutant"
	return current

func _get_local_corruption(peg: Node) -> float:
	# TODO: Sample nearby pegs' states and return corruption ratio 0.0-1.0
	return 0.3  # placeholder
EOF

echo ""
echo "Creating placeholder data files..."

cat > data/pegs/peg_definitions.json << 'EOF'
{
  "stone": {
    "display_name": "Stone Peg",
    "tier": "common",
    "tags": ["foundation"],
    "restitution": 0.6,
    "friction": 0.1,
    "base_bonus": {"gold": 1},
    "description": "The bedrock of any board. Reliable, humble, foundational."
  },
  "bone": {
    "display_name": "Bone Peg",
    "tier": "common",
    "tags": ["death"],
    "restitution": 0.5,
    "friction": 0.05,
    "base_bonus": {"damage": 2},
    "description": "Slick and sharp. Every contact draws something vital from the enemy."
  },
  "fungal": {
    "display_name": "Fungal Peg",
    "tier": "uncommon",
    "tags": ["growth", "death"],
    "restitution": 0.4,
    "friction": 0.45,
    "base_bonus": {"stability": 1},
    "growth_interval_drops": 3,
    "description": "It grows. Given time, it will fill every empty slot it can reach."
  },
  "ember": {
    "display_name": "Ember Peg",
    "tier": "uncommon",
    "tags": ["fire"],
    "restitution": 0.9,
    "friction": 0.05,
    "base_bonus": {"damage": 1},
    "chain_effect": "ignite_adjacent",
    "description": "Touch it and everything nearby catches fire."
  },
  "eye": {
    "display_name": "Eye Peg",
    "tier": "rare",
    "tags": ["void"],
    "restitution": 0.6,
    "friction": 0.1,
    "base_bonus": {"reveal_pocket": true},
    "description": "It watches. It remembers. It shows you what's coming."
  },
  "heart": {
    "display_name": "Heart Peg",
    "tier": "rare",
    "tags": ["blood"],
    "restitution": 0.7,
    "friction": 0.15,
    "base_bonus": {"stability": 5},
    "description": "Pumps ichor through the board. Each contact is a heartbeat."
  },
  "oracle": {
    "display_name": "Oracle Peg",
    "tier": "legendary",
    "tags": ["void", "death", "growth", "fire", "blood", "foundation"],
    "restitution": 0.6,
    "friction": 0.1,
    "special": "split_ball_3",
    "description": "One becomes three. The board awakens."
  },
  "void_rift": {
    "display_name": "Void Rift Peg",
    "tier": "legendary",
    "tags": ["void"],
    "restitution": 0.0,
    "friction": 0.0,
    "special": "teleport_to_best_pocket",
    "description": "The ball does not bounce. It ceases. It arrives."
  }
}
EOF

cat > data/synergies/synergy_definitions.json << 'EOF'
{
  "necrotic_bloom": {
    "display_name": "Necrotic Bloom",
    "required_tags": ["death", "growth"],
    "min_count": 3,
    "tiers": [
      {"count": 3, "effect": "rot_pegs_deal_3_damage_on_contact"},
      {"count": 6, "effect": "all_pegs_regen_1_stability_per_drop"}
    ],
    "curse_risk": "rot_spreads_2x_faster",
    "description": "Death feeds growth. Growth feeds death. The cycle accelerates."
  },
  "cursed_flame": {
    "display_name": "Cursed Flame",
    "required_tags": ["fire", "cursed"],
    "min_count": 3,
    "tiers": [
      {"count": 3, "effect": "burning_pegs_corrupt_adjacent_on_ignite"},
      {"count": 6, "effect": "ball_speed_plus_20pct_double_damage"}
    ],
    "curse_risk": "board_takes_5_damage_per_drop",
    "description": "The fire is wrong. It burns inward."
  },
  "void_choir": {
    "display_name": "Void Choir",
    "required_tags": ["void"],
    "min_count": 3,
    "tiers": [
      {"count": 3, "effect": "every_5th_ball_becomes_void_ball"},
      {"count": 6, "effect": "void_balls_open_extra_pocket_slot"}
    ],
    "curse_risk": "void_consumes_1_blessed_peg_per_run",
    "description": "The void does not stay silent forever."
  },
  "bleeding_architecture": {
    "display_name": "Bleeding Architecture",
    "required_tags": ["blood", "foundation"],
    "min_count": 3,
    "tiers": [
      {"count": 3, "effect": "stone_pegs_heal_1_stability_on_contact"},
      {"count": 6, "effect": "board_gains_regen_2_passive"}
    ],
    "curse_risk": "heart_pegs_slowly_rot",
    "description": "The stones remember being alive."
  },
  "profane_eye": {
    "display_name": "The Profane Eye",
    "required_tags": ["void", "death"],
    "min_count": 3,
    "tiers": [
      {"count": 3, "effect": "eye_pegs_reveal_enemy_next_move"},
      {"count": 6, "effect": "bone_pegs_double_damage_vs_revealed"}
    ],
    "curse_risk": "eye_pegs_blind_randomly",
    "description": "To see clearly is to invite what you see."
  }
}
EOF

echo ""
echo "Creating project.godot stub..."

cat > project.godot << 'EOF'
; Engine configuration file.
; Generated for Void Oracle

[application]
config/name="Void Oracle"
config/description="A roguelike pachinko game. The board is the character."
run/main_scene="res://scenes/menus/MainMenu.tscn"
config/features=PackedStringArray("4.3", "GL Compatibility")

[autoload]
EventBus="*res://scripts/autoloads/EventBus.gd"
RunState="*res://scripts/autoloads/RunState.gd"
GhostBoardManager="*res://scripts/autoloads/GhostBoardManager.gd"
SynergyChecker="*res://scripts/autoloads/SynergyChecker.gd"
AudioManager="*res://scripts/autoloads/AudioManager.gd"
MutationEngine="*res://scripts/autoloads/MutationEngine.gd"

[display]
window/size/viewport_width=1080
window/size/viewport_height=1920
window/size/resizable=false
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[physics]
common/physics_ticks_per_second=120
2d/default_gravity=980.0

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
EOF

echo ""
echo "✓ Void Oracle scaffold created successfully."
echo ""
echo "Next steps:"
echo "  1. Open Godot 4.3+"
echo "  2. Import this folder as a project"
echo "  3. Verify AutoLoads in Project > Project Settings > AutoLoad"
echo "  4. Start with scenes/game/Board.tscn"
