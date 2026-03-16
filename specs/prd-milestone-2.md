# PRD: Milestone 2 — Core Systems

## Introduction

Milestone 2 adds the living, breathing aspect to the board: pegs change state through the mutation engine, synergies activate based on tag counts, and special peg behaviors trigger. The board becomes "alive" — it remembers, grows, and degrades.

**Goal:** Pegs change state. Synergies activate. The board is alive.

---

## Goals

- [ ] Create Peg State Shader with corruption_level, mutation_pulse, void_factor uniforms
- [ ] Wire MutationEngine to EventBus.peg_hit, implement state transitions
- [ ] Wire SynergyChecker to EventBus.peg_state_changed and peg_spawned
- [ ] Implement special behaviors for Oracle, Void Rift, Ember, and Fungal pegs
- [ ] Create Corruption Spread Shader for board background
- [ ] Create Ball Trail Effect using Line2D + shader

---

## User Stories

### VO-007: Peg State Shader
**Description:** As a player, I want pegs to visually transform when their state changes so I can see the blessing/corruption axis.

**Acceptance Criteria:**
- [ ] Create `shaders/peg_state.gdshader`
- [ ] Uniform: `corruption_level: float` (0.0 = blessed gold, 0.5 = neutral, 1.0 = cursed crimson)
- [ ] Uniform: `mutation_pulse: float` (animated sine, drives green pustule effect)
- [ ] Uniform: `void_factor: float` (0.0–1.0, drives star-field overlay)
- [ ] Apply to all peg types via ShaderMaterial
- [ ] Manually tweaking uniforms visibly shifts peg appearance

---

### VO-008: Mutation Engine Integration
**Description:** As a player, I want pegs to mutate over time so my board evolves across encounters.

**Acceptance Criteria:**
- [ ] Wire `MutationEngine` to listen to `EventBus.peg_hit`
- [ ] After MUTATION_THRESHOLD (5) hits, 15% chance per hit to shift peg state
- [ ] State transitions: dormant → blessed/cursed → mutant → void
- [ ] On state change: update peg's shader uniforms + emit `EventBus.peg_state_changed`
- [ ] Hit a peg 5+ times and watch it visibly mutate

---

### VO-009: Synergy Checker Integration
**Description:** As a player, I want synergies to activate when I have matching pegs so I can build powerful combos.

**Acceptance Criteria:**
- [ ] Wire `SynergyChecker` to `EventBus.peg_state_changed` and `EventBus.peg_spawned`
- [ ] On any board change: recount tags, check all 5 synergy thresholds
- [ ] Emit `synergy_activated` / `synergy_broken` / `synergy_scaled` as appropriate
- [ ] Debug: print active synergies to console on any change
- [ ] Place 3 Fungal + 3 Bone pegs manually → "necrotic_bloom" activates in console

---

### VO-010: Special Peg Behaviors
**Description:** As a player, I want special pegs to have unique effects so strategic choices matter.

**Acceptance Criteria:**
- [ ] **Oracle Peg**: on hit, spawn 2 additional balls at slight angle offset
- [ ] **Void Rift Peg**: on hit, remove ball from physics, add +10 gold via RunState
- [ ] **Ember Peg**: on hit, iterate adjacent pegs, shift their state toward "cursed" by 0.1
- [ ] **Fungal Peg**: after every 3 drops (`RunState.total_drops % 3 == 0`), check adjacent empty slots, 25% chance spawn Sprout peg
- [ ] Each special behavior demonstrable in physics sandbox

---

### VO-011: Corruption Spread Shader (Board Background)
**Description:** As a player, I want corruption to visually spread across the board so the world reflects my choices.

**Acceptance Criteria:**
- [ ] Create `shaders/corruption_spread.gdshader`
- [ ] Accepts a `sampler2D corruption_map` uniform (64×64 Image, updated by GDScript)
- [ ] Shader bleeds/blurs the corruption map across the background
- [ ] GDScript: on `peg_state_changed` to "cursed", paint a spot on the Image at peg position
- [ ] Cursing a peg visibly spreads ink across the board background

---

### VO-012: Ball Trail Effect
**Description:** As a player, I want balls to leave a trail so I can see their path through the board.

**Acceptance Criteria:**
- [ ] Create `shaders/ball_trail.gdshader`
- [ ] Line2D tracking last 20 ball positions, updated in `_process`
- [ ] Shader: fade opacity tail → head, shift color from white to ghost-blue
- [ ] Ball leaves visible fading trail as it falls

---

## Functional Requirements

### FR-1: Peg State Shader
- FR-1.1: Shader accepts `corruption_level` uniform (0.0 to 1.0)
- FR-1.2: Shader accepts `mutation_pulse` uniform (animated in process)
- FR-1.3: Shader accepts `void_factor` uniform (0.0 to 1.0)
- FR-1.4: Interpolates visual: gold veins (0.0) → neutral (0.5) → crimson cracks (1.0)
- FR-1.5: Mutation pulse creates green pustule effect when corruption_level ≈ 0.5
- FR-1.6: Void factor adds star-field/void overlay

### FR-2: Mutation Engine
- FR-2.1: MutationEngine subscribes to `EventBus.peg_hit`
- FR-2.2: Tracks hit_count per peg instance
- FR-2.3: After 5 hits, 15% chance to mutate on each subsequent hit
- FR-2.4: State transitions follow rules:
  - Dormant → Blessed (low corruption pressure) or Cursed (high pressure)
  - Blessed → Mutant (30% chance)
  - Cursed → Mutant (40% chance)
  - Mutant → Void (10% chance)
- FR-2.5: Emits `EventBus.peg_state_changed` on transition
- FR-2.6: Updates shader uniforms on peg instance

### FR-3: Synergy Checker
- FR-3.1: SynergyChecker subscribes to `EventBus.peg_state_changed` and `peg_spawned`
- FR-3.2: Maintains tag count dictionary: `{ "death": 3, "growth": 2, ... }`
- FR-3.3: Checks 5 synergies against tag counts:
  | Synergy | Required Tags | Min Pegs |
  |---------|--------------|----------|
  | necrotic_bloom | death + growth | 3 |
  | cursed_flame | fire + cursed | 3 |
  | void_choir | void | 3 |
  | bleeding_arch | blood + foundation | 3 |
  | profane_eye | void + death | 3 |
- FR-3.4: Emits `synergy_activated` / `synergy_broken` / `synergy_scaled`
- FR-3.5: Debug prints to console on any synergy change

### FR-4: Special Peg Behaviors
- FR-4.1: Oracle Peg `_on_body_entered`: spawn 2 new balls at ±15° offset
- FR-4.2: Void Rift Peg `_on_body_entered`: queue_free ball, RunState.gold += 10
- FR-4.3: Ember Peg `_on_body_entered`: get_tree().call_group("pegs"), iterate neighbors, shift toward cursed
- FR-4.4: Fungal Peg: check `RunState.total_drops % 3 == 0`, spawn Sprout in empty adjacent slot

### FR-5: Corruption Spread
- FR-5.1: Board background has ShaderMaterial with corruption_spread shader
- FR-5.2: GDScript maintains 64×64 Image for corruption map
- FR-5.3: On peg_state_changed to "cursed", paint circle on Image at peg position
- FR-5.4: Shader blurs and bleeds corruption map as it spreads

### FR-6: Ball Trail
- FR-6.1: Ball script maintains Array of last 20 positions
- FR-6.2: Line2D points updated each frame from position array
- FR-6.3: Shader fades opacity: tail (0.0) → head (1.0)
- FR-6.4: Shader shifts color: white → ghost-blue

---

## Non-Goals

- No enemy AI or combat logic
- No draft system or shop
- No map generation
- No save/load
- No stability system or game-over conditions

---

## Technical Considerations

### EventBus Integration
New signals for this milestone:
- `EventBus.peg_state_changed.emit(peg, old_state, new_state)` — MutationEngine emits this
- `EventBus.peg_spawned.emit(peg)` — Board emits when adding new peg
- `EventBus.synergy_activated.emit(synergy_id)` — SynergyChecker emits
- `EventBus.synergy_broken.emit(synergy_id)` — SynergyChecker emits
- `EventBus.synergy_scaled.emit(synergy_id, new_tier)` — SynergyChecker emits

### Data Dependencies
- `data/synergies/synergy_definitions.json` — synergy definitions with tags, thresholds, effects

### Shader Architecture
- Peg state shader: CanvasItem shader on each peg Sprite2D
- Corruption spread: CanvasItem shader on board background ColorRect
- Ball trail: Line2D with custom shader (not a full scene)

---

## Open Questions

- Mutation threshold (5 hits) and chance (15%) are from spec. Should these be tunable via JSON?
- Fungal spawn logic — what is a "Sprout peg"? A new Fungal peg type, or a lighter variant?
- The corruption map needs to persist across drops. Does it clear between encounters?

---

## Related Tickets

- **Blocks:** Milestone 3 (Core Systems required for combat)
- **Depends on:** Milestone 1 (Physics Sandbox foundation)
