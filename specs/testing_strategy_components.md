# Void Oracle Testing Strategy — Component Analysis

This document catalogs all testable components in the Void Oracle game and outlines testing strategies for each. The goal is to ensure robust, maintainable code through systematic testing coverage.

---

## 1. Physics Components

### 1.1 Ball (Ball.gd)

**Location:** `scripts/game/Ball.gd`

**What to Test:**
- Ball correctly joins the "ball" group for collision detection
- Trail rendering updates correctly each physics frame
- Ball velocity is correctly tracked and retrievable via `get_velocity()`
- Ball cleanup (trail Line2D) on `queue_free()`
- Void ball flag can be set and retrieved

**Behaviors:**
- `_physics_process`: Updates trail positions, maintains 20-frame history
- `_on_body_entered`: Emits `EventBus.peg_hit` when colliding with pegs
- `apply_deflect(angle_degrees)`: Applies directional deflection to ball velocity

**Edge Cases:**
- Ball falls off board (handled by BallLostDetector in Board.gd)
- Multiple rapid collisions in same frame
- Void ball conversion via SynergyEffects

**Recommended Tests:**
- Unit: Trail array management, velocity calculations, deflection math
- Integration: Ball-peg collision detection, EventBus signal emission

---

### 1.2 BallSpawner (BallSpawner.gd)

**Location:** `scripts/game/BallSpawner.gd`

**What to Test:**
- Ball instantiation with correct scene
- Direction calculation from mouse position to spawn point
- Ball speed multiplier application from SynergyEffects
- Void ball conversion on spawn
- Ball tracking registration with EncounterManager

**Behaviors:**
- `_launch_ball(mouse_pos)`: Calculates direction, applies velocity, spawns ball
- `_draw`: Renders aim line to mouse position

**Edge Cases:**
- Click outside valid spawn area
- Ball spawn with zero available balls (should be handled by EncounterManager)
- Multiple rapid clicks

**Recommended Tests:**
- Unit: Direction calculation, speed multiplier logic
- Integration: Ball spawn → ball in play tracking

---

### 1.3 BasePeg (BasePeg.gd)

**Location:** `scripts/game/pegs/BasePeg.gd`

**What to Test:**
- Peg data loading from `peg_definitions.json`
- Physics material application (friction, restitution)
- Shader setup and parameter management
- State machine transitions (dormant → blessed → cursed → mutant → void)
- Hit count tracking
- Tag system for synergy detection

**Behaviors:**
- `_load_peg_data()`: Parses JSON, extracts tags
- `_apply_physics_material()`: Creates PhysicsMaterial from JSON values
- `_on_body_entered(body)`: Increments hit_count, emits `peg_hit` signal
- `mutate_to(new_state)`: Updates state, emits `peg_state_changed`
- Shader parameter setters: `set_corruption_level`, `set_mutation_pulse`, `set_void_factor`

**Edge Cases:**
- Missing or malformed peg_definitions.json
- Invalid peg type enum value
- Shader material creation failure

**Recommended Tests:**
- Unit: Physics material values match JSON, state transitions emit correct signals
- Integration: Peg hit → EventBus.peg_hit → MutationEngine mutation roll

---

### 1.4 Concrete Peg Implementations

| Peg Type | File | Unique Behavior |
|----------|------|-----------------|
| StonePeg | `StonePeg.gd` | Base behavior only (inherits from BasePeg) |
| BonePeg | `BonePeg.gd` | Base behavior (tags: ["death"]) |
| FungalPeg | `FungalPeg.gd` | Growth interval tracking, peg spawning |
| EmberPeg | `EmberPeg.gd` | Chain effect (ignite adjacent), high bounce |
| EyePeg | `EyePeg.gd` | Pocket reveal tracking |
| HeartPeg | `HeartPeg.gd` | Stability bonus on hit |
| OraclePeg | `OraclePeg.gd` | Ball splitting (special: "split_ball_3") |
| VoidRiftPeg | `VoidRiftPeg.gd` | **Destroys ball, grants gold reward (10)** |
| ThornPeg | `ThornPeg.gd` | **Deflects ball sideways, cannot be removed** |

**What to Test (VoidRiftPeg):**
- Ball destruction on contact (`body.queue_free()`)
- Gold reward added to RunState
- Hit count incremented, peg_hit signal emitted

**What to Test (ThornPeg):**
- Deflection angle applied to ball
- Random left/right direction selection
- `can_be_removed()` returns false

**Recommended Tests:**
- Unit: VoidRiftPeg ball destruction, ThornPeg deflection math
- Integration: ThornPeg → Ball.apply_deflect → modified velocity

---

## 2. Game Logic Systems

### 2.1 Board (Board.gd)

**Location:** `scripts/game/Board.gd`

**What to Test:**
- Board dimensions: 600x900 pixels
- Pocket creation and positioning (8 pockets, evenly spaced)
- Pocket color assignment based on type
- Default peg grid generation (staggered pattern)
- Class-specific peg spawning from RunState
- Empty slot calculation for placement
- Crack system for Architect boss (add, effect, clear)
- Ball lost detector positioning

**Behaviors:**
- `_create_pockets()`: Instantiates 8 Area2D pockets with collision
- `_create_default_pegs()`: Generates staggered grid
- `_create_class_pegs()`: Spawns RunState.pegs at defined positions
- `get_empty_slots()`: Returns unoccupied grid positions
- `add_peg_at_position(type, pos)`: Instantiates peg, emits `peg_spawned`
- `add_crack(crack_data)`: Creates crack visual + collision area
- `_on_crack_body_entered(body, area)`: Handles void_channel/hazard effects

**Edge Cases:**
- Spawning peg at occupied position
- Board resize on different viewport sizes
- Crack cleanup on encounter end
- Empty board (no pegs)

**Recommended Tests:**
- Unit: Pocket count, grid calculation, empty slot detection
- Integration: Board → EncounterManager → drop phase

---

### 2.2 EncounterManager (EncounterManager.gd)

**Location:** `scripts/game/EncounterManager.gd`

**What to Test:**
- Phase machine: BOARD → DROP → RESULT → ENEMY_TURN → BOARD (loop)
- Ball tracking: `register_ball`, ball removal on pocket/lost
- Pocket effect application: damage, healing, gold, void, chaos
- Void ball pocket doubling (Void Choir Tier 2)
- Damage multiplier from SynergyEffects
- Enemy turn execution flow
- Victory/defeat detection
- Draft phase trigger (every 4 encounters → shop)
- Shop appearance frequency

**Behaviors:**
- `start_encounter(enemy_scene)`: Spawns enemy, sets BOARD phase
- `begin_drop_phase()`: Resets tracking, enables ball spawning
- `_on_ball_entered_pocket(pocket, ball)`: Determines pocket type, applies effect
- `_run_result_phase()`: Calculates final damage, applies all results
- `_run_enemy_turn()`: Executes enemy action, returns to BOARD
- `_on_enemy_defeated(enemy)`: Increments counter, triggers draft/shop

**Phase Transition Tests:**
```
BOARD → DROP (player clicks to drop)
DROP → RESULT (all balls settled/lost)
RESULT → ENEMY_TURN (damage applied)
ENEMY_TURN → BOARD (enemy action complete)
BOARD → VICTORY (enemy HP ≤ 0)
BOARD → DEFEAT (stability ≤ 0)
```

**Edge Cases:**
- Ball enters pocket during RESULT phase (should be ignored)
- All balls lost without hitting any pockets
- Enemy defeated mid-drop (should complete drop first)
- Zero damage/healing/gold applied

**Recommended Tests:**
- Unit: Phase transitions, pocket effect calculations, damage multipliers
- Integration: Full DROP → RESULT → ENEMY_TURN cycle

---

### 2.3 DraftSystem (DraftSystem.gd)

**Location:** `scripts/game/systems/DraftSystem.gd`

**What to Test:**
- Tier-weighted random peg selection (common: 50, uncommon: 30, rare: 15, legendary: 5)
- No duplicate offerings in single draft
- Peg selection enters placement mode
- Peg placement at valid positions
- Board reference resolution

**Behaviors:**
- `generate_offerings()`: Returns 3 unique peg types
- `select_peg(type)`: Activates placement mode, emits signal
- `place_peg_at(position)`: Validates mode, calls Board.add_peg_at_position
- `_reset_draft()`: Clears state

**Edge Cases:**
- Offering generation with exhausted peg pool
- Placement on invalid position (outside board)
- Multiple rapid selection changes

**Recommended Tests:**
- Unit: Tier weighting distribution, duplicate prevention
- Integration: Draft → Board peg addition

---

## 3. Autoloads / Singletons

### 3.1 EventBus (EventBus.gd)

**Location:** `scripts/autoloads/EventBus.gd`

**What to Test:**
- All defined signals match documented usage
- Signal parameters are correct types
- No duplicate signal definitions

**Signals to Verify:**
| Category | Signals |
|----------|---------|
| Physics | `peg_hit`, `ball_entered_pocket`, `ball_lost` |
| Peg State | `peg_state_changed`, `peg_destroyed`, `peg_spawned` |
| Synergies | `synergy_activated`, `synergy_broken`, `synergy_scaled`, `synergy_damage_dealt`, `synergy_stability_changed`, `enemy_revealed`, `enemy_intent_determined` |
| Drop | `drop_phase_started`, `drop_phase_ended`, `drop_started`, `ball_launched`, `drop_ended`, `chaos_drop_triggered` |
| Combat | `enemy_turn_start`, `enemy_action`, `enemy_defeated`, `enemy_ball_spawned`, `player_stability_changed`, `boss_phase_changed` |
| Board Effects | `ball_entered_crack` |
| Ghost | `ghost_mutation`, `void_ghost_active` |
| Economy | `gold_stolen`, `gold_changed` |
| Run/Map | `node_selected`, `encounter_started`, `encounter_ended`, `run_started`, `run_ended`, `zone_completed`, `game_victory` |
| UI | `draft_choice_made`, `shop_purchase`, `relic_acquired` |

**Recommended Tests:**
- Integration: Verify all signals are connected and emitted correctly throughout codebase

---

### 3.2 RunState (RunState.gd)

**Location:** `scripts/autoloads/RunState.gd`

**What to Test:**
- `new_run(seed, class_id)`: Resets all state, applies class bonuses
- `modify_stability(delta)`: Clamping, event emission, death check
- `modify_gold(delta)`: Non-negative clamping, event emission
- `snapshot_board()`: Returns complete state dictionary
- Class-specific starting bonuses:
  - Naturalist: 4 fungal pegs, 10 gold
  - Doomsayer: 3 bone pegs, 3 void essence, 3 gold
  - Architect: 110 max stability, stone+stone+ember, 8 gold
  - Void Walker: void_rift + 2 eye, 5 void essence, 2 balls, 3 gold
  - Wanderer (default): 2 stone pegs

**Edge Cases:**
- Stability modification causes death (0 → emit run_ended)
- Gold goes negative (should clamp to 0)
- Invalid class_id (falls back to wanderer)

**Recommended Tests:**
- Unit: All state modifications, clamping, event emission
- Integration: Run start → state initialization → snapshot

---

### 3.3 SynergyChecker (SynergyChecker.gd)

**Location:** `scripts/autoloads/SynergyChecker.gd`

**What to Test:**
- Tag counting from peg array
- Synergy activation threshold (min 3 matching tags)
- Synergy scaling (count changes)
- Synergy break detection (below threshold)
- Synergy definitions:
  - necrotic_bloom: ["death", "growth"], min 3
  - cursed_flame: ["fire", "cursed"], min 3
  - void_choir: ["void"], min 3
  - bleeding_arch: ["blood", "foundation"], min 3
  - profane_eye: ["void", "death"], min 3

**Behaviors:**
- `recount_from_board(pegs)`: Rebuilds tag counts, evaluates synergies
- `_evaluate_all()`: Checks each synergy, emits activated/scaled/broken
- `_min_tag_count(tags)`: Returns minimum count across required tags
- `get_active_synergies()`: Returns copy of active dict

**Edge Cases:**
- Pegs with no tags
- Multiple tags on single peg (counts for all)
- Empty peg array
- Synergy at exactly threshold (3)

**Recommended Tests:**
- Unit: Tag counting logic, threshold detection, _min_tag_count math
- Integration: Peg state change → recount → synergy evaluation

---

### 3.4 SynergyEffects (SynergyEffects.gd)

**Location:** `scripts/autoloads/SynergyEffects.gd`

**What to Test:**
- Tier calculation: tier 1 = 3-5 pegs, tier 2 = 6+ pegs
- Necrotic Bloom: damage on cursed/mutant peg hits, stability regen at tier 2
- Cursed Flame: ball speed +20% tier 2, damage multiplier 2.0x tier 2
- Void Choir: void ball conversion every 5th ball, extra pocket at tier 2
- Bleeding Architecture: stone pegs heal 1 stability, tier 2 regen 2
- Profane Eye: eye peg reveals enemy, tier 2 bone bonus damage vs revealed

**Public API:**
- `should_convert_to_void_ball() → bool`
- `check_and_convert_to_void_ball() → bool`
- `get_ball_speed_multiplier() → float`
- `get_damage_multiplier() → float`
- `get_void_ball_drop_number() → int` (returns 5)
- `should_void_ball_extra_pocket() → bool`
- `get_board_regen() → int`
- `is_synergy_active(id) → bool`
- `get_synergy_tier(id) → int`

**Edge Cases:**
- Synergy broken mid-drop (should effects persist for drop?)
- Enemy reveal reset timing
- Multiple synergy interactions

**Recommended Tests:**
- Unit: All multiplier calculations, tier thresholds
- Integration: Peg hit → synergy effect → RunState modification

---

### 3.5 MutationEngine (MutationEngine.gd)

**Location:** `scripts/autoloads/MutationEngine.gd`

**What to Test:**
- Mutation threshold: 5 hits before eligible
- Mutation chance: 15% per hit after threshold
- State transitions:
  - dormant → blessed OR cursed (based on corruption pressure)
  - blessed → mutant (30%) OR stay blessed
  - cursed → mutant (40%) OR stay cursed
  - mutant → void (10%) OR stay mutant
- Shader parameter updates per state
- Signal emission on state change

**Constants:**
- `MUTATION_THRESHOLD = 5`
- `MUTATION_CHANCE = 0.15`

**Edge Cases:**
- 5 hits exactly (eligible, not guaranteed)
- Rapid hits (each triggers independent roll)
- Peg destroyed mid-mutation calculation

**Recommended Tests:**
- Unit: State transition probabilities, threshold logic
- Integration: Peg hit count → mutation roll → state change

---

### 3.6 Other Autoloads

| Autoload | File | What to Test |
|----------|------|--------------|
| AudioManager | `AudioManager.gd` | Sound playback calls, volume/mute state |
| GhostBoardManager | `GhostBoardManager.gd` | File I/O for ghost saves |
| MetaState | `MetaState.gd` | Global meta-progression state |
| ParticleEffects | `ParticleEffects.gd` | Particle system spawning |

---

## 4. Enemy Components

### 4.1 Base Enemy (Enemy.gd)

**Location:** `scripts/game/enemies/Enemy.gd`

**What to Test:**
- JSON data loading from `data/enemies/{id}.json`
- HP tracking: current, max, percentage
- Damage application with death check
- Death sequence: signal emission, timer, queue_free

**Base Interface:**
- `setup(data_path)`: Load and apply data
- `take_damage(amount)`: Reduce HP, check death
- `is_defeated() → bool`
- `die()`: Emit defeat, cleanup
- `execute_turn()`: Override per enemy
- `get_intent_text() → String`
- `get_hp() / get_max_hp() / get_hp_percent()`

---

### 4.2 Concrete Enemy Implementations

| Enemy | File | Behavior Summary |
|-------|------|------------------|
| Corruptor | `Corruptor.gd` | Phase 1: Corrupt blessed peg + 10 stability damage |
| Wrecker | `Wrecker.gd` | AOE damage based on peg count |
| Leech | `Leech.gd` | Drains stability, heals self |
| Spawner | `Spawner.gd` | Spawns additional balls |
| Architect | `Architect.gd` | Places cracks on board (void_channel/hazard effects) |
| Gardener | `Gardener.gd` | Phase 1: Prune blessed; Phase 2: Prune + 2x Thorn pegs |
| GhostEnemy | `GhostEnemy.gd` | Ghost board encounter |
| FinalOracle | `FinalOracle.gd` | Final boss, multi-phase |

**What to Test (Corruptor):**
- `_corrupt_blessed_peg()`: Finds blessed pegs, mutates to "cursed"
- Fallback: Corrupt any non-void, non-cursed peg
- `_run_attack()`: Deals 10 stability damage

**What to Test (Gardener):**
- Phase change at 50% HP
- Phase 1: `_prune_blessed_peg()` → dormancy
- Phase 2: Prune + `_place_thorn_pegs()` (2 thorns)
- Thorn placement via Board.get_empty_slots() + add_peg_at_position()

**Recommended Tests:**
- Unit: Enemy action logic, peg selection algorithms
- Integration: Enemy turn → peg modification / stability damage

---

## 5. Data-Driven Components

### 5.1 Peg Definitions (data/pegs/peg_definitions.json)

**What to Test:**
- All 9 peg entries exist with required fields
- Physics values are valid (friction: 0.0-1.0, restitution: 0.0-1.0)
- Tags array is present and non-empty
- Tier values are valid (common/uncommon/rare/legendary/enemy)

**Validation:**
```json
{
  "stone": { "tier": "common", "tags": ["foundation"], "restitution": 0.6, "friction": 0.1 },
  "bone": { "tier": "common", "tags": ["death"], ... },
  "fungal": { "tier": "uncommon", "tags": ["growth", "death"], ... },
  "ember": { "tier": "uncommon", "tags": ["fire"], ... },
  "eye": { "tier": "rare", "tags": ["void"], ... },
  "heart": { "tier": "rare", "tags": ["blood"], ... },
  "oracle": { "tier": "legendary", "tags": [...all tags...], "special": "split_ball_3" },
  "void_rift": { "tier": "legendary", "tags": ["void"], "special": "teleport_to_best_pocket" },
  "thorn": { "tier": "enemy", "tags": ["enemy_only"], "deflect_angle": 30 }
}
```

---

### 5.2 Enemy Data (data/enemies/*.json)

**What to Test:**
- All 8 enemy files exist
- Required fields: id, max_hp, hp, intent_display
- Optional: is_boss, on_death rewards

**Files:**
- `corruptor.json`, `wrecker.json`, `leech.json`, `spawner.json`
- `architect.json`, `gardener.json`, `ghost_enemy.json`, `final_oracle.json`

---

### 5.3 Synergy Definitions (data/synergies/synergy_definitions.json)

**What to Test:**
- Synergy IDs match SynergyChecker constants
- Required tags arrays
- min_count thresholds

---

## 6. UI Components

### 6.1 StabilityBar (StabilityBar.gd)

**Location:** `scripts/ui/StabilityBar.gd`

**What to Test:**
- Subscribes to `player_stability_changed` signal
- Visual update on stability change
- Death state display

---

### 6.2 BoardPhaseUI (BoardPhaseUI.gd)

**Location:** `scripts/ui/BoardPhaseUI.gd`

**What to Test:**
- Drop button triggers EncounterManager.begin_drop_phase()
- Phase indicator display

---

### 6.3 DraftUI (DraftUI.gd)

**Location:** `scripts/ui/DraftUI.gd`

**What to Test:**
- Displays 3 offerings from DraftSystem
- Selection calls DraftSystem.select_peg()
- Placement mode visual state

---

### 6.4 ShopUI (ShopUI.gd)

**Location:** `scripts/ui/ShopUI.gd`

**What to Test:**
- Shop items display
- Purchase logic with gold deduction
- Relic/special item acquisition

---

### 6.5 DeathScreen (DeathScreen.gd)

**Location:** `scripts/ui/DeathScreen.gd`

**What to Test:**
- Displays final run stats
- Restart/return to menu actions

---

## 7. Map System

### 7.1 RunMap (RunMap.gd)

**Location:** `scripts/game/map/RunMap.gd`

**What to Test:**
- Map initialization with seed
- Node positioning calculation (zones 1-3)
- Connection line drawing
- Node selection and reachability
- Current position tracking
- Visited node state

---

### 7.2 MapNode (MapNode.gd)

**Location:** `scripts/game/map/MapNode.gd`

**What to Test:**
- Node data display (type, zone)
- Click handling and signal emission
- Visual states: selectable, current, visited, locked

---

### 7.3 MapGenerator (MapGenerator.gd)

**Location:** `scripts/game/map/MapGenerator.gd`

**What to Test:**
- Map generation with deterministic seed
- Node count and zone distribution
- Connection graph validity
- Boss node placement per zone

---

## 8. Testing Patterns & Considerations

### 8.1 Physics Testing Challenges

**Determinism Issues:**
- Godot physics is non-deterministic across platforms
- Use seeded RNG where possible
- Test physics *behavior* not exact values

**CCD (Continuous Collision Detection):**
- Must stay enabled on balls
- Test: ball passing through thin pegs at high velocity

**Recommended Approach:**
- Integration tests for physics interactions
- Verify *outcomes* (ball reached pocket, collision detected) not frame-exact positions

---

### 8.2 Signal Testing

**Pattern:**
```gdscript
# Test helper
func wait_for_signal(signal: Signal, timeout: float = 1.0) -> bool:
    var completed = false
    signal.connect(func(): completed = true)
    await get_tree().create_timer(timeout).timeout
    return completed
```

**Verify:**
- All EventBus connections are valid
- No signal spam (duplicate emissions)
- Proper cleanup on node death

---

### 8.3 Data Validation

**JSON Loading Tests:**
- Valid JSON parses without error
- Missing file handled gracefully
- Malformed JSON produces warning, doesn't crash

**Schema Validation:**
- All required fields present
- Type checking (int, float, string, array)
- Enum values are valid

---

### 8.4 Test Categories Summary

| Category | What to Test | Tools/Approach |
|----------|--------------|----------------|
| Unit | Pure logic functions, math, state machines | GUT assertions |
| Integration | Component interactions, signal flow | GUT + scene tests |
| Physics | Ball-peg collisions, trajectory | Integration tests |
| Data | JSON loading, validation | Unit tests for parsers |
| System | Full encounter cycles | Integration tests |

---

## 9. GUT Framework Integration

**Setup:**
- Install godot-gut via AssetLib
- Place tests in `tests/` directory
- Naming: `{module}_test.gd`

**Example Test Structure:**
```
tests/
├── unit/
│   ├── synergy_checker_test.gd
│   ├── run_state_test.gd
│   └── peg_data_test.gd
├── integration/
│   ├── ball_peg_collision_test.gd
│   ├── drop_phase_test.gd
│   └── enemy_turn_test.gd
└── mocks/
    ├── mock_event_bus.gd
    └── mock_board.gd
```

**Key GUT Features to Use:**
- `assert_eq()`, `assert_ne()`, `assert_true()`
- `assert_signal_emitted()`
- `replace_node()` for mocking
- `add_child()` for scene setup

---

## 10. Priority Recommendations

### High Priority (Core Gameplay)
1. **EncounterManager phase machine** — Controls entire game loop
2. **SynergyChecker tag counting** — Central to build strategy
3. **SynergyEffects multipliers** — Significant damage/economy impact
4. **RunState stability/gold** — Player resources
5. **Ball physics collision** — Core mechanic

### Medium Priority (Feature Complete)
6. DraftSystem offerings
7. Enemy turn execution
8. MutationEngine state transitions
9. Board peg spawning

### Lower Priority (Polish)
10. Map generation
11. UI signal wiring
12. Audio/particle systems
13. Ghost board save/load

---

*Document Version: 1.0*
*Created: 2026-03-16*
*For: Void Oracle M2+ Testing Infrastructure*
