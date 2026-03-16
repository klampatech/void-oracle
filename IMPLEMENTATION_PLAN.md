# Implementation Plan — Void Oracle

**Last Updated:** 2026-03-16
**Analysis:** Gap between `specs/*.md` and current `scripts/` + `scenes/` + `shaders/`

---

## Gap Analysis Summary

### Completed (M1-M2 Core Systems):
- ✅ Physics sandbox: Board, Ball, BallSpawner, all 8 peg types with physics materials
- ✅ EventBus, RunState, SynergyChecker, MutationEngine wired up
- ✅ CorruptionMapManager, GhostBoardManager (basic)
- ✅ All 3 shaders: peg_state, corruption_spread, ball_trail
- ✅ Peg State Shader with corruption_level, mutation_pulse, void_factor
- ✅ MutationEngine connected to EventBus.peg_hit
- ✅ SynergyChecker connected to peg_state_changed and peg_spawned
- ✅ Data files: peg_definitions.json, synergy_definitions.json

### Partially Complete (M1-M2):
- ⚠️ Special peg behaviors (Oracle, Void Rift, Ember, Fungal) — partial implementation
- ⚠️ Ball Trail Effect — shader exists, needs wiring in Ball.gd
- ⚠️ Console logging for peg_hit — signal fires, limited data

### NOT Yet Implemented (M3+):
- ❌ Phase system (DROP/RESULT/BOARD)
- ❌ Enemy system (Corruptor, etc.)
- ❌ Stability UI
- ❌ Ghost save on death (wiring)
- ❌ Map generation
- ❌ Draft system
- ❌ Shop system

---

## Priority 0: M1 Verification Fixes (IMMEDIATE)

### P0.1 Physics Debug Overlay
- [ ] Create `scenes/game/PhysicsDebugOverlay.tscn`
- [ ] Create `scripts/game/PhysicsDebugOverlay.gd`
- [ ] F1 key toggles visibility
- [ ] Shows collision shapes via debug draw
- [ ] Shows ball velocity vector (Line2D)
- [ ] Shows peg hit_count as labels
- [ ] Console logging: peg_type, position, ball velocity

### P0.2 Ball Trail Wiring
- [ ] Update `scripts/game/Ball.gd` to maintain position array (last 20)
- [ ] Add Line2D child node, update each frame
- [ ] Apply `shaders/ball_trail.gdshader`

---

## Priority 1: Single Encounter Loop (M3)

### P1.1 Encounter Manager System
- [ ] Create `scripts/game/GameManager.gd` or `EncounterManager.gd`
- [ ] Create scene `scenes/game/EncounterManager.tscn`
- [ ] Implement turn-based phases: Drop Phase → Result Phase → Board Phase
- [ ] Track ball inventory and drop completion

### P1.2 Ball Drop Phase Logic
- [ ] Wire BallSpawner to drop phase state
- [ ] Implement multi-ball drop (1-5 balls)
- [ ] Add drop ending detection (all balls in pockets or lost)
- [ ] Calculate drop results: damage, healing, gold, void essence
- [ ] Implement pocket result logic:
  | Pocket | Effect |
  |--------|--------|
  | Damage | enemy.hp -= damage_value |
  | Heal | stability += heal_value |
  | Gold | gold += gold_value |
  | Void | void_essence += void_value |
  | Chaos | trigger_chaos_effect() |

### P1.3 First Enemy Type — Corruptor
- [ ] Create enemy data in `data/enemies/corruptor.json`
- [ ] Create `scripts/game/enemies/Enemy.gd` base class
- [ ] Create `scripts/game/enemies/Corruptor.gd` script
- [ ] Create `scenes/game/enemies/Corruptor.tscn`
- [ ] Implement: turns random blessed peg to cursed each turn

### P1.4 Enemy Attack Phase
- [ ] Connect enemy actions to EventBus
- [ ] Implement enemy → board interaction (corruption)
- [ ] Track and apply damage to Stability

### P1.5 Victory/Defeat Conditions
- [ ] Enemy defeated when damage threshold met
- [ ] Run defeat when Stability <= 0 (wire to existing RunState)
- [ ] Display encounter result UI

---

## Priority 2: Peg Special Abilities (M3)

### P2.1 Void Rift Ball Teleportation
- [x] Basic implementation exists in VoidRiftPeg.gd
- [ ] Ball teleports to "best" pocket (highest value)
- [ ] Apply pocket effect immediately

### P2.2 Oracle Ball Split
- [ ] Implement in `scripts/game/pegs/OraclePeg.gd`
- [ ] On contact, spawn 2 additional balls with slight velocity offset (±15°)
- [ ] Track original ball for scoring

### P2.3 Eye Peg Pocket Vision
- [ ] Implement reveal_pocket bonus in `scripts/game/pegs/EyePeg.gd`
- [ ] UI overlay showing pocket types during drop

### P2.4 Fungal Peg Growth
- [x] Basic implementation exists
- [ ] Implement growth_interval_drops from peg_definitions (every 3 drops)
- [ ] After N drops, spawn adjacent Fungal peg in empty slot (25% chance)
- [ ] Track growth state per peg

### P2.5 Ember Peg Chain Ignite
- [x] Basic implementation exists
- [ ] On contact, find adjacent pegs and apply ignite effect (shift toward cursed by 0.1)

### P2.6 Heart Peg Stability Bonus
- [x] Basic implementation exists
- [ ] Wire stability bonus from `HeartPeg.gd` to RunState

---

## Priority 3: Board Phase & Draft (M3-M4)

### P3.1 Stability UI
- [ ] Create `scripts/ui/StabilityBar.gd`
- [ ] HUD stability bar (gold → red as depletes)
- [ ] Tick down 10 stability per enemy action
- [ ] Run ends at 0 → emit run_ended

### P3.2 Ghost Save on Death
- [ ] Wire EventBus.run_ended → GhostBoardManager.save_ghost()
- [ ] Death screen UI stub
- [ ] Verify save to user://void_oracle/ghost_boards/

### P3.3 Board Phase UI
- [ ] Create `scenes/ui/BoardPhaseUI.tscn`
- [ ] Display peg inventory, gold, stability
- [ ] "Continue" button to next node

### P3.4 Draft System
- [ ] Create `scripts/game/systems/DraftSystem.gd` script
- [ ] Create `scenes/ui/DraftUI.tscn`
- [ ] Draw 3 random pegs from available pool
- [ ] Player selects 1, placed in chosen empty slot
- [ ] Connect to RunState.pegs array

### P3.5 Peg Placement
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
| `data/enemies/corruptor.json` | ❌ MISSING |
| `data/enemies/wrecker.json` | ❌ MISSING |
| `data/enemies/spawner.json` | ❌ MISSING |
| `data/enemies/leech.json` | ❌ MISSING |
| `data/enemies/gardener.json` | ❌ MISSING |
| `data/enemies/architect.json` | ❌ MISSING |
| `data/enemies/final_oracle.json` | ❌ MISSING |

---

## Dependency Graph

```
P0.1 → P0.2
   ↓
P1.1 → P1.2 → P1.3 → P1.4 → P1.5
            ↓
P2.1 → P2.2 → P2.3 → P2.4 → P2.5 → P2.6
                                    ↓
P3.1 ← P3.2 ← P3.3 ← P3.4 ← P3.5 ← P1.5 (complete encounter)
            ↓
P4.1 → P4.2 → P4.3 → P4.4
            ↓
          P4.5 → P5.1 → P5.2 → P5.3
            ↓
          P6.1 → P6.2 → P6.3
            ↓
P7.1 → P7.2 → P7.3 → P7.4 → P7.5
            ↓
P8.1 ← P8.2
            ↓
P9.1 → P9.2 → P9.3
```
