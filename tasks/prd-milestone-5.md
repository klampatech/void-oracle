# PRD: Milestone 5 — Map & Full Run Loop

## Introduction

Milestone 5 completes the core game experience: procedural map generation, draft system, shop, remaining enemies, and the Zone 1 boss (The Gardener). Players can complete a full run from start to finish.

**Goal:** Complete the first zone. Fight the Gardener. Win or lose, loop restarts.

---

## Goals

- [ ] Implement Run Map (DAG generator) with 3 zones, 8-10 nodes per zone
- [ ] Implement Draft System (choose 1 of 3 pegs after combat)
- [ ] Implement Shop (pegs, relics, services)
- [ ] Implement remaining 2 enemy types (Wrecker, Spawner)
- [ ] Implement Zone 1 Boss (The Gardener) with multi-phase fight

---

## User Stories

### VO-019: Run Map (DAG Generator)
**Description:** As a player, I want to navigate a branching map so each run feels different.

**Acceptance Criteria:**
- [ ] `MapGenerator.gd`: generates 3-zone DAG, 8–10 nodes per zone
- [ ] Node types: Combat(40%), Elite(15%), Event(20%), Shop(10%), Rest(10%), Boss(1 per zone)
- [ ] Node weighting reads `RunState` board tags (Rot-heavy board → more Mycologist events)
- [ ] Render as clickable node graph (simple lines + icons, no art yet)
- [ ] Map generates, player can navigate zone 1 start to zone 1 boss

---

### VO-020: Draft System
**Description:** As a player, I want to choose new pegs after winning so my board evolves.

**Acceptance Criteria:**
- [ ] After combat victory: show 3 randomly drawn pegs from tier-weighted pool
- [ ] Player clicks to select; chosen peg added to PegContainer at player-chosen slot
- [ ] Draft pool seeded from `run_seed + encounter_index`
- [ ] Win a fight, see 3 peg choices, place selection on board

---

### VO-021: Shop
**Description:** As a player, I want to spend gold on pegs and services so I have economy choices.

**Acceptance Criteria:**
- [ ] Appears every ~4 nodes
- [ ] Offers: 3 pegs for sale, 1 relic, 3 services (Bless, Purify, Remove)
- [ ] Costs in Gold: pegs 10–30g, relics 40–60g, services 15–25g
- [ ] Enter shop, buy a peg, see it in draft pool

---

### VO-022: Remaining 2 Enemy Types
**Description:** As a player, I want varied enemies so combat requires different strategies.

**Acceptance Criteria:**
- [ ] **Wrecker**: shatters 1 peg per turn (removes it from board permanently)
- [ ] **Spawner**: drops enemy balls mid-turn; enemy balls have inverse effect (deal stability damage on pocket entry)
- [ ] Each with unique intent display
- [ ] Both enemies behave distinctly and correctly in combat

---

### VO-023: Zone 1 Boss — The Gardener
**Description:** As a player, I want a challenging boss so there's a meaningful victory condition.

**Acceptance Criteria:**
- [ ] Multi-phase: Phase 1 converts Blessed → Dormant each turn
- [ ] Phase 2 (below 50% HP): places 2 Thorn pegs (enemy-owned, cannot be removed, deflect balls sideways)
- [ ] 150 HP
- [ ] Victory: zone 2 unlocks, peg unlock added to draft pool
- [ ] Full Gardener fight, both phases, victory/defeat both handled

---

## Functional Requirements

### FR-1: Map Generator
- FR-1.1: MapGenerator generates directed acyclic graph (DAG)
- FR-1.2: 3 zones, each with 8-10 nodes
- FR-1.3: Node distribution per zone:
  | Type | Weight |
  |------|--------|
  | Combat | 40% |
  | Elite | 15% |
  | Event | 20% |
  | Shop | 10% |
  | Rest | 10% |
  | Boss | 1 per zone |
- FR-1.4: Guaranteed: 1 shop per zone, 1 rest per zone, boss at end
- FR-1.5: Node weighting influenced by RunState board tags
- FR-1.6: Player starts at zone 1 entry node
- FR-1.7: Click node to travel, validate path exists

### FR-2: Draft System
- FR-2.1: DraftPool generates 3 peg choices from weighted random
- FR-2.2: Weighting: Common 60%, Uncommon 30%, Rare 9%, Legendary 1%
- FR-2.3: Seeded RNG: `run_seed + encounter_index` determines draw
- FR-2.4: Player selects 1 peg, clicks empty slot to place
- FR-2.5: If no empty slots, draft is skipped (or forced remove prompt)

### FR-3: Shop System
- FR-3.1: Shop appears every ~4 nodes (randomized ±1)
- FR-3.2: Inventory:
  - 3 pegs for sale (random, priced 10-30g)
  - 1 relic for sale (random, priced 40-60g)
  - 3 services: Bless (+1 tier to Blessed), Purify (reset to Dormant), Remove (free slot)
- FR-3.3: Player has gold deducted on purchase
- FR-3.4: Shop inventory seeded from `run_seed + shop_visit_count`

### FR-4: Wrecker Enemy
- FR-4.1: HP: 100
- FR-4.2: Intent: "Will shatter 1 peg"
- FR-4.3: Action: Select random player peg, remove from board permanently
- FR-4.4: Death drops 1 random common peg

### FR-5: Spawner Enemy
- FR-5.1: HP: 90
- FR-5.2: Intent: "Will drop enemy ball"
- FR-5.3: Action: Spawn enemy ball from top, ball has inverse pocket effects
- FR-5.4: Enemy ball: Damage pocket → -5 Stability, Heal pocket → +5 Enemy HP
- FR-5.5: Void pocket neutralizes enemy ball

### FR-6: The Gardener Boss
- FR-6.1: HP: 150
- FR-6.2: Phase 1 (100-75 HP): Converts 1 Blessed → Dormant per turn
- FR-6.3: Phase 2 (74-0 HP): Places 2 Thorn pegs (StaticBody2D, deflect ±30°)
- FR-6.4: Thorn pegs are enemy-owned, cannot be removed by player
- FR-6.5: On victory: unlock Zone 2, add new peg to draft pool
- FR-6.6: Weakness: Void-Touched pegs are invisible to Gardener's pruning

---

## Non-Goals

- No Zone 2 or Zone 3 content (Zone 1 boss is final for M5)
- No Oracle Classes
- No meta-progression (Void Shards)
- No event complexity beyond basic branching

---

## Technical Considerations

### EventBus Integration
New signals:
- `EventBus.node_reached.emit(node_type, node_data)` — Map emits when player arrives
- `EventBus.draft_started.emit(poptions: Array)` — DraftSystem emits with options
- `EventBus.draft_ended.emit(selected_peg)` — Player made selection
- `EventBus.shop_entered.emit(shop_inventory)` — Shop opens
- `EventBus.purchase_made.emit(item_type, item_id)` — Player bought something
- `EventBus.boss_phase_changed.emit(new_phase)` — Gardener phase shift

### Data Dependencies
- `data/events/` — event scripts (for Event nodes)
- `data/shop/shop_inventory.json` — shop item pools

### RunState Expansion
- `current_zone: int` (1-3)
- `current_node_index: int`
- `gold: int`
- `void_shards: int` (for future use)
- `shop_visit_count: int`
- `encounter_index: int`

---

## Open Questions

- What happens if board is full at draft time? Skip draft or force remove?
- Rest node — what does it do? Spec says "board repair" — heal stability?
- Elite enemy — what is it? Not defined yet. Use random non-boss enemy for now.

---

## Related Tickets

- **Depends on:** Milestone 3 (basic combat), Milestone 4 (ghost integration)
- **Blocks:** Milestone 6 (full game with all zones)
