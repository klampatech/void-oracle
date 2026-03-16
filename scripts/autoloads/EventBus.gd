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
signal ball_launched(ball: Node)                     # emitted when a ball is launched
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
