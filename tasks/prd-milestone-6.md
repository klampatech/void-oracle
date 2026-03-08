# PRD: Milestone 6 — Full Game

## Introduction

Milestone 6 completes the full game experience: Zones 2 and 3 with their bosses, all synergies, meta-progression through Void Shards, and Oracle Classes. This is the v1.0 release content.

**Goal:** Complete the full game. All zones. All bosses. Victory or death, the run ends at the Final Oracle.

---

## Goals

- [ ] Implement Zone 2 + Architect of Ruin Boss
- [ ] Implement Zone 3 + Final Oracle Boss
- [ ] Implement all 5 synergy effects
- [ ] Implement meta-progression (Void Shards + Unlocks)
- [ ] Implement Oracle Classes (4 starting conditions)
- [ ] Implement Run History / Stats Screen

---

## User Stories

### VO-024: Zone 2 + Architect of Ruin Boss
**Description:** As a player, I want to progress to Zone 2 so my board faces new challenges.

**Acceptance Criteria:**
- [ ] Zone 2 map generates after Zone 1 boss defeat
- [ ] New enemies available in Zone 2 pool
- [ ] Architect of Ruin boss: HP 200
- [ ] Phase 1 (200-120 HP): Cracks board frame every 2 turns (-20px width)
- [ ] Phase 2 (119-60 HP): Cracks become Void Channels (×2 Void Essence)
- [ ] Phase 3 (59-0 HP): Cracks become hazards (balls touching gain Cursed)
- [ ] Victory unlocks Zone 3

---

### VO-025: Zone 3 + Final Oracle Boss
**Description:** As a player, I want to face the final challenge so there's a complete victory condition.

**Acceptance Criteria:**
- [ ] Zone 3 map generates after Zone 2 boss defeat
- [ ] Final Oracle boss: HP 300
- [ ] Phase 1 (300-200 HP): Copies player's most active synergy
- [ ] Phase 2 (199-100 HP): Adds second copied synergy
- [ ] Phase 3 (99-0 HP): Reveals it's a Ghost Board of player's best run
- [ ] All player synergies become resistances
- [ ] Defeat Final Oracle = game victory

---

### VO-026: All 5 Synergy Effects Implemented
**Description:** As a player, I want all synergies to have mechanical effects so building around tags is rewarding.

**Acceptance Criteria:**
- [ ] **Necrotic Bloom** (death + growth):
  - Tier 1 (3 pegs): Rot pegs deal 3 dmg on contact
  - Tier 2 (6 pegs): All pegs regen 1 Stability/drop
  - Curse Risk: Rot spreads 2× faster
- [ ] **Cursed Flame** (fire + cursed):
  - Tier 1: Burning pegs corrupt adjacent on ignite
  - Tier 2: Ball speed +20%, double damage
  - Curse Risk: Board takes 5 dmg/drop
- [ ] **Void Choir** (void ×3):
  - Tier 1: Every 5th ball becomes Void Ball
  - Tier 2: Void Balls open extra pocket slot
  - Curse Risk: Void consumes 1 Blessed peg/run
- [ ] **Bleeding Architecture** (blood + foundation):
  - Tier 1: Stone pegs heal 1 Stability on contact
  - Tier 2: Board gains Regen 2 passive
  - Curse Risk: Heart pegs slowly rot
- [ ] **Profane Eye** (void + death):
  - Tier 1: Eye pegs reveal enemy next move
  - Tier 2: Bone pegs double dmg vs revealed
  - Curse Risk: Eye pegs blind randomly

---

### VO-027: Meta-Progression (Void Shards + Unlocks)
**Description:** As a player, I want to earn permanent upgrades so future runs are more interesting.

**Acceptance Criteria:**
- [ ] Earn Void Shards from boss kills and high-score drops
- [ ] Shards spent on: new peg types, new events, boss variants, starter relics
- [ ] Track unlocked content in `user://void_oracle/meta.json`
- [ ] Unlocks persist across runs

---

### VO-028: Oracle Classes (4 starting conditions)
**Description:** As a player, I want different starting conditions so I can specialize my runs.

**Acceptance Criteria:**
- [ ] **The Naturalist**: 4 Fungal Pegs pre-placed, Growth/Blood pegs more common
- [ ] **The Doomsayer**: 2 Bone Pegs, 1 Cursed Peg pre-placed, Death/Void more common
- [ ] **The Architect**: Board frame pre-runed (+10 Stability), Fire pegs more common
- [ ] **The Void-Walker**: 1 Void Rift Peg pre-placed (center), Void/Eye more common
- [ ] Class selection at run start
- [ ] Unlocks after clearing game once

---

### VO-029: Run History / Stats Screen
**Description:** As a player, I want to see my past runs so I can track progress.

**Acceptance Criteria:**
- [ ] Show list of past runs: zone reached, total drops, victory/defeat
- [ ] Show best run (highest zone)
- [ ] Show Void Shards earned total
- [ ] Accessible from main menu

---

## Functional Requirements

### FR-1: Zone 2 - Architect of Ruin
- FR-1.1: Zone 2 has unique node types/enemy pools
- FR-1.2: Architect HP: 200
- FR-1.3: Phase 1: Every 2 turns, create board crack (reduce effective width by 20px)
- FR-1.4: Phase 2: Cracks become Void Channels (balls through = 2× Void Essence)
- FR-1.5: Phase 3: Cracks become hazards (touch = Cursed)
- FR-1.6: Defeat unlocks Zone 3, adds new peg to pool

### FR-2: Zone 3 - Final Oracle
- FR-2.1: Zone 3 is final zone, most difficult
- FR-2.2: Final Oracle HP: 300
- FR-2.3: Phase 1: Mirror player's #1 synergy as resistance
- FR-2.4: Phase 2: Add second synergy resistance
- FR-2.5: Phase 3: Reveal as Ghost Board of player's best run
- FR-2.6: All player synergies provide resistance (reduced effectiveness)
- FR-2.7: Victory = game complete

### FR-3: Synergy Implementation
- FR-3.1: Necrotic Bloom: damage on rot contact, stability regen, rot spread rate
- FR-3.2: Cursed Flame: corrupt on ignite, ball speed buff, board damage
- FR-3.3: Void Choir: void ball conversion, extra pocket, blessed consumption
- FR-3.4: Bleeding Architecture: stability heal on stone hit, regen passive, rot hearts
- FR-3.5: Profane Eye: reveal enemy intent, bone damage vs revealed, blind chance

### FR-4: Meta-Progression
- FR-4.1: Void Shards earned: boss kill = 10, elite = 5, high drop = 1-3
- FR-4.2: Spend shards in meta shop between runs
- FR-4.3: Unlock new peg types (beyond base 8)
- FR-4.4: Unlock new event cards
- FR-4.5: Unlock boss variants
- FR-4.6: Unlock starter relics
- FR-4.7: Persist in `user://void_oracle/meta.json`

### FR-5: Oracle Classes
- FR-5.1: Select class at run start
- FR-5.2: Class determines: starting pegs, draft bias, starting gold/stability
- FR-5.3: Classes unlock after first victory
- FR-5.4: Each class has unique starting board layout

### FR-6: Run History
- FR-6.1: Store last 20 runs
- FR-6.2: Display: date, zone reached, drops taken, victory/defeat
- FR-6.3. Track: total Void Shards earned, best zone

---

## Non-Goals

- No additional zones beyond 3
- No daily seed runs (future)
- No leaderboards (future)
- No additional accessibility options beyond colorblind (future)

---

## Technical Considerations

### EventBus Integration
New signals:
- `EventBus.zone_completed.emit(zone_number)` — Zone boss defeated
- `EventBus.game_victory.emit()` — Final Oracle defeated
- `EventBus.shards_earned.emit(amount)` — Boss/elite kill
- `EventBus.unlock_earned.emit(unlock_type, unlock_id)` — New content unlocked
- `EventBus.class_selected.emit(class_id)` — Oracle Class chosen

### Data Dependencies
- `data/enemies/architect.json` — boss stats, phases
- `data/enemies/oracle.json` — boss stats, phases
- `data/classes/` — class definitions
- `data/unlocks/` — unlock definitions and costs

### Save System Expansion
- `user://void_oracle/meta.json` — Void Shards, unlocks, class access
- `user://void_oracle/run_history.json` — past run data

---

## Open Questions

- Void Shard amounts — are the numbers (10/5/1-3) final or placeholders?
- How many new peg types unlock? Spec says "beyond base 8" — maybe 3-4 more?
- Boss variants — The Overgarden, Architect of Eternity — unlock after first clear?

---

## Related Tickets

- **Depends on:** Milestone 5 (Zone 1, basic map)
- **Blocks:** Milestone 7 (polish, export)
