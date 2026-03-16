# Implementation Plan — Void Oracle

**Last Updated:** 2026-03-16 (analysis refreshed)
**Analysis:** Gap between `specs/*.md` and current `scripts/` + `scenes/` + `shaders/`

---

## Gap Analysis Summary

### Completed (M1-M2 Core Systems):
- ✅ Physics sandbox: Board, Ball, BallSpawner, all 8 peg types with physics materials
- ✅ EventBus with all required signals (peg_hit, ball_entered_pocket, peg_state_changed, etc.)
- ✅ RunState with all required state (stability, gold, ball_count, snapshot_board, etc.)
- ✅ SynergyChecker, MutationEngine, AudioManager, GhostBoardManager wired up
- ✅ CorruptionMapManager, Board scene with pockets
- ✅ All 3 shaders: peg_state, corruption_spread, ball_trail
- ✅ Peg State Shader with corruption_level, mutation_pulse, void_factor uniforms
- ✅ Ball Trail Effect - fully wired in Ball.gd (Line2D with gradient)
- ✅ All 8 peg types implemented (Stone, Bone, Fungal, Ember, Eye, Heart, Oracle, VoidRift)
- ✅ Special peg behaviors: Oracle ball split, VoidRift ball consume, Ember chain corrupt, Fungal growth
- ✅ PhysicsDebugOverlay.tscn exists
- ✅ Data files: peg_definitions.json, synergy_definitions.json

### BUGS FOUND (Must Fix):
- ✅ BasePeg.gd missing `get_hit_count()` and `get_peg_state()` methods - FIXED in this commit

### M3 - Single Encounter (COMPLETED):
- ✅ EncounterManager - script exists to orchestrate DROP/RESULT/BOARD phases
- ✅ Enemy system - Corruptor enemy with JSON data
- ✅ Phase system - EncounterManager coordinates turn flow
- ✅ Stability UI - StabilityBar component created and added to Board
- ✅ Ghost save on death wiring - GhostBoardManager subscribes to EventBus.run_ended
- ✅ Death screen UI stub - shows ghost summary with run stats
- ✅ Board Phase UI - displays gold, void, stability, balls, pegs, "Drop Balls" button
- ✅ Pocket result calculation (damage=10, healing=5, gold=5, void=1, chaos effects)
- ✅ Enemy Corruptor implementation - corrupts pegs and deals 10 stability damage per turn
- ✅ FungalPeg growth - FIXED in previous commit (now actually spawns new pegs)

### NOT Yet Implemented (M4+):
- ❌ Map generation
- ❌ Shop system
- ❌ Ghost Board Encounter
- ❌ Boss encounters
- ❌ Synergy effects implementation
- ❌ Meta-progression
- ❌ Audio polish

---

## Priority 0: Bug Fixes (DO FIRST)

### P0.1 BasePeg Method Fixes
- [x] Add `get_hit_count()` method to `BasePeg.gd` that returns `hit_count`
- [x] Add `get_peg_state_string()` method to `BasePeg.gd` that returns state as string
- [x] Update MutationEngine to use the new methods

### P0.2 Fungal Growth Completion
- [x] Implement actual peg instantiation in FungalPeg._spawn_sprout()
- [x] Wire to Board.gd to handle placement

---

## Priority 1: Single Encounter Loop (M3) — COMPLETED

### P1.0 Encounter Manager System
- [x] Create `scripts/game/EncounterManager.gd` (AutoLoad or scene)
- [x] Create `scenes/game/EncounterManager.tscn`
- [x] Implement turn-based phases: DROP → RESULT → BOARD
- [x] Track ball inventory and drop completion
- [x] Wire to existing BallSpawner

### P1.1 Ball Drop Phase Logic
- [x] Wire BallSpawner to drop phase state
- [x] Implement multi-ball drop (1-5 balls, from RunState.ball_count)
- [x] Add drop ending detection (all balls in pockets or lost)
- [x] Calculate drop results: damage, healing, gold, void essence
- [x] Implement pocket result logic:
  | Pocket | Effect |
  |--------|--------|
  | Damage | enemy.hp -= damage_value |
  | Heal | stability += heal_value |
  | Gold | gold += gold_value |
  | Void | void_essence += void_value |
  | Chaos | trigger_chaos_effect() |

### P1.2 Enemy JSON Data
- [x] Create `data/enemies/corruptor.json`
- [x] Define HP (80), actions, intent display text
- [x] Create enemy data schema

### P1.3 First Enemy Type — Corruptor
- [x] Create `scripts/game/enemies/Enemy.gd` base class
- [x] Create `scripts/game/enemies/Corruptor.gd` script
- [x] Create `scenes/game/enemies/Corruptor.tscn`
- [x] Implement: turns random blessed peg to cursed each turn

### P1.4 Enemy Attack Phase
- [x] Connect enemy actions to EventBus
- [x] Implement enemy → board interaction (corruption)
- [x] Track and apply damage to Stability

### P1.5 Victory/Defeat Conditions
- [x] Enemy defeated when damage threshold met
- [x] Run defeat when Stability <= 0
- [x] Display encounter result UI (stub)

---

## Priority 2: Stability UI & Ghost Save (M3)

### P2.1 Stability UI
- [x] Create `scripts/ui/StabilityBar.gd`
- [x] Create `scenes/ui/StabilityBar.tscn`
- [x] HUD stability bar (gold → red as depletes)
- [x] Connect to EventBus.player_stability_changed
- [x] Run ends at 0 → show death screen

### P2.2 Ghost Save on Death
- [x] Wire EventBus.run_ended → GhostBoardManager.save_ghost()
- [x] Death screen UI stub showing ghost summary
- [x] Verify save to user://void_oracle/ghost_boards/

### P2.3 Board Phase UI
- [x] Create `scenes/ui/BoardPhaseUI.tscn`
- [x] Display peg inventory, gold, stability
- [x] "End Turn" button to next drop

---

## Priority 3: Draft System (M4)

### P3.1 Draft System
- [ ] Create `scripts/game/systems/DraftSystem.gd` script
- [ ] Create `scenes/ui/DraftUI.tscn`
- [ ] Draw 3 random pegs from available pool
- [ ] Player selects 1, placed in chosen empty slot
- [ ] Connect to RunState.pegs array

### P3.2 Peg Placement
- [ ] Click empty slot to place selected peg
- [ ] Validate placement (bounds, collision)
- [ ] Trigger peg_spawned signal

---

## Priority 4: Map & Run Loop (M5)

### P4.1 Map Generator
- [ ] Create `scripts/game/map/MapGenerator.gd` script
- [ ] Generate 3 zones, 8-10 nodes per zone
- [ ] Implement branching paths (DAG)
- [ ] Weight node types by board state

### P4.2 Run Map Scene
- [ ] Create `scenes/game/map/RunMap.tscn`
- [ ] Create `scenes/game/map/MapNode.tscn`
- [ ] Implement node selection and path visualization
- [ ] Connect to encounter loading

### P4.3 Navigation Phase
- [ ] After Board Phase, show map
- [ ] Highlight available paths
- [ ] Player selects next node

### P4.4 Shop System
- [ ] Create `scripts/game/systems/ShopSystem.gd` script
- [ ] Create `scenes/ui/ShopUI.tscn`
- [ ] Services: Bless, Purify, Remove, Transmute pegs
- [ ] Purchase pegs and relics

### P4.5 More Enemy Types
- [ ] Wrecker: Shatters 1 peg per turn
- [ ] Spawner: Drops enemy balls mid-turn
- [ ] Leech: Steals gold each turn

---

## Priority 5: Boss Encounters (M5-M6)

### P5.1 Zone 1 Boss — The Gardener
- [ ] Create boss encounter scene
- [ ] Phase 1: Converts blessed to dormant
- [ ] Phase 2: Places unremovable Thorn pegs

### P5.2 Zone 2 Boss — Architect of Ruin
- [ ] Creates cracks in board frame
- [ ] Phase 2: Cracks become Void Channels

### P5.3 Zone 3 Boss — Final Oracle
- [ ] Mirrors player's board layout
- [ ] Has same synergies as player
- [ ] Phase 3: Reveals as ghost of best run

---

## Priority 6: Ghost Board System (M4)

### P6.1 Ghost Board Loading
- [ ] Load ghost board data via GhostBoardManager
- [ ] Instantiate as enemy encounter board
- [ ] Ghost pegs interact with player balls

### P6.2 Ghost Behavior by Type
- [ ] Implement GhostBoardManager.assign_ghost_for_run(seed)
- [ ] Mostly Blessed: Heals enemy
- [ ] Mostly Cursed: Damages player board
- [ ] High Mutation: Randomizes peg states
- [ ] Void-heavy: Steals ball drops

### P6.3 Ghost Trigger
- [ ] Random moment in run (weighted to late Zone 2)
- [ ] Display "A Shadow Stirs" event

---

## Priority 7: Synergy Effects (M6)

### P7.1 Necrotic Bloom
- [ ] Rot pegs deal 3 damage on contact
- [ ] At 6: All pegs regen 1 stability/drop

### P7.2 Cursed Flame
- [ ] Burning pegs corrupt adjacent on ignite
- [ ] At 6: Ball speed +20%, double damage

### P7.3 Void Choir
- [ ] Every 5th ball becomes Void Ball
- [ ] At 6: Void balls open extra pocket slot

### P7.4 Bleeding Architecture
- [ ] Stone pegs heal 1 stability on contact
- [ ] At 6: Board gains regen 2 passive

### P7.5 The Profane Eye
- [ ] Eye pegs reveal enemy next move
- [ ] At 6: Bone pegs double damage vs revealed

---

## Priority 8: Meta-Progression (M6)

### P8.1 Void Shards
- [ ] Track shards from boss kills
- [ ] Unlock new pegs, events, boss variants

### P8.2 Oracle Classes
- [ ] The Naturalist: 4 Fungal, Growth bias
- [ ] The Doomsayer: 2 Bone, 1 Cursed, Death/Void bias
- [ ] The Architect: +10 Stability, Foundation/Fire bias
- [ ] The Void-Walker: 1 Void Rift, Void/Eye bias

---

## Priority 9: Polish & Export (M7)

### P9.1 Audio System
- [ ] Per-peg tone playback (AudioManager)
- [ ] Boss music layering
- [ ] Ambient sound design

### P9.2 Particle Effects
- [ ] Blessed sparkle CPUParticles2D
- [ ] Rot spore GPUParticles2D
- [ ] Screen distortion for bosses

### P9.3 Web Export
- [ ] Test HTML5 export
- [ ] Fix compatibility renderer issues
- [ ] Verify web input handling

---

## Data Files Status

| File | Status |
|------|--------|
| `data/pegs/peg_definitions.json` | ✅ Complete |
| `data/synergies/synergy_definitions.json` | ✅ Complete |
| `data/enemies/corruptor.json` | ✅ Complete |
| `data/enemies/wrecker.json` | ❌ MISSING |
| `data/enemies/spawner.json` | ❌ MISSING |
| `data/enemies/leech.json` | ❌ MISSING |
| `data/enemies/gardener.json` | ❌ MISSING |
| `data/enemies/architect.json` | ❌ MISSING |
| `data/enemies/final_oracle.json` | ❌ MISSING |

---

## Dependency Graph

```
P1.0 EncounterManager → P1.1 Drop Phase → P1.2 Enemy Data → P1.3 Corruptor
         ↓                              ↓
P1.4 Enemy Attack ← P1.5 Victory/Defeat
         ↓
P2.1 Stability UI ← P2.2 Ghost Save ← P2.3 Board Phase
         ↓
P3.1 Draft System ← P3.2 Peg Placement
         ↓
P4.1 Map Generator → P4.2 Run Map → P4.3 Navigation → P4.4 Shop
            ↓
P4.5 More Enemies → P5.1 Gardener → P5.2 Architect → P5.3 Final Oracle
            ↓
P6.1 Ghost Loading → P6.2 Ghost Behavior → P6.3 Ghost Trigger
            ↓
P7.1 Necrotic Bloom → P7.2 Cursed Flame → P7.3 Void Choir → P7.4 Bleeding Arch → P7.5 Profane Eye
            ↓
P8.1 Void Shards ← P8.2 Oracle Classes
            ↓
P9.1 Audio → P9.2 Particles → P9.3 Web Export
```
