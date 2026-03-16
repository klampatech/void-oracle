# Void Oracle — Development Backlog

Ordered by milestone. Complete each milestone fully before starting the next.
Each ticket has an ID, estimated complexity (S/M/L/XL), and acceptance criteria.

---

## MILESTONE 1 — Physics Sandbox
*Goal: A board you can drop a ball into. No game logic. Just physics that feel great.*

### VO-001 · S · Godot Project Setup
- Run `scaffold.sh` to generate folder structure
- Verify all 6 AutoLoad singletons appear in Project Settings > AutoLoad
- Set physics ticks to 120 in Project Settings
- Confirm GL Compatibility renderer is selected
- **Done when**: Project opens without errors, all AutoLoads listed

### VO-002 · M · Board Scene (Physics World)
- Create `scenes/game/Board.tscn`
- Board frame: 4 StaticBody2D walls (left, right, bottom-barrier, ceiling)
- Board dimensions: 600×900px logical space
- 8 pocket slots at bottom row as StaticBody2D + Area2D detectors
- Pocket types: Damage, Heal, Gold, Void, Chaos (assign 2 of each type, vary layout)
- **Done when**: Board renders, ball added manually stays in bounds

### VO-003 · M · Ball Physics
- Create `scenes/game/Ball.tscn` as RigidBody2D + CircleShape2D
- Radius: 12px, mass: 1.0, gravity_scale: 1.4
- linear_damp: 0.05, CCD: Cast Ray
- Ball joins group "ball" on ready
- Ball emits `EventBus.ball_lost` when it exits board bounds
- Ball emits `EventBus.ball_entered_pocket` when entering pocket Area2D
- **Done when**: Ball dropped from top reaches bottom, hits pockets, signal fires

### VO-004 · L · Base Peg + All 8 Peg Types
- Create `scenes/game/pegs/BasePeg.tscn` as StaticBody2D + CircleShape2D
- Radius: 16px
- `BasePeg.gd`: exposes `peg_type`, `peg_state`, `hit_count`
- On `_on_body_entered`: emit `EventBus.peg_hit`, increment hit_count
- Load PhysicsMaterial values from `data/pegs/peg_definitions.json`
- Create one `.tscn` per peg type extending BasePeg, placeholder ColorRect color per type
- **Done when**: All 8 pegs instantiable, each has correct restitution/friction, peg_hit fires

### VO-005 · S · Ball Spawner
- `BallSpawner` node at top of board
- Aim line: simple Line2D showing projected launch angle
- Click/tap to launch ball at aimed angle
- Ball count limited by `RunState.ball_count` (default 1)
- **Done when**: Click launches ball, aim line updates with mouse/touch

### VO-006 · S · Physics Debug Overlay
- Toggle with F1 key in debug builds
- Shows: all collider shapes, ball velocity vector, peg hit_count labels
- Console prints peg_hit signal data (peg_type, position, ball velocity)
- **Done when**: F1 toggles overlay, hitting pegs prints to console

---

## MILESTONE 2 — Core Systems
*Goal: Pegs change state. Synergies activate. The board is alive.*

### VO-007 · M · Peg State Shader
- Create `shaders/peg_state.gdshader`
- Uniform: `corruption_level: float` (0.0 = blessed gold, 0.5 = neutral, 1.0 = cursed crimson)
- Uniform: `mutation_pulse: float` (animated sine, drives green pustule effect)
- Uniform: `void_factor: float` (0.0–1.0, drives star-field overlay)
- Apply to all peg types via ShaderMaterial
- **Done when**: Manually tweaking uniforms visibly shifts peg appearance

### VO-008 · M · Mutation Engine Integration
- Wire `MutationEngine` to listen to `EventBus.peg_hit`
- After MUTATION_THRESHOLD hits, 15% chance per hit to shift peg state
- State transitions: dormant → blessed/cursed → mutant → void
- On state change: update peg's shader uniforms + emit `EventBus.peg_state_changed`
- **Done when**: Hit a peg 5+ times and watch it visibly mutate

### VO-009 · M · Synergy Checker Integration
- Wire `SynergyChecker` to `EventBus.peg_state_changed` and `EventBus.peg_spawned`
- On any board change: recount tags, check all 5 synergy thresholds
- Emit `synergy_activated` / `synergy_broken` / `synergy_scaled` as appropriate
- Debug: print active synergies to console on any change
- **Done when**: Place 3 Fungal + 3 Bone pegs manually → "necrotic_bloom" activates in console

### VO-010 · M · Special Peg Behaviors
- **Oracle Peg**: on hit, spawn 2 additional balls at slight angle offset
- **Void Rift Peg**: on hit, remove ball from physics, add +10 gold via RunState
- **Ember Peg**: on hit, iterate adjacent pegs, shift their state toward "cursed" by 0.1
- **Fungal Peg**: after every 3 drops (`RunState.total_drops % 3 == 0`), check adjacent empty slots, 25% chance spawn Sprout peg
- **Done when**: Each special behavior demonstrable in physics sandbox

### VO-011 · S · Corruption Spread Shader (Board Background)
- Create `shaders/corruption_spread.gdshader`
- Accepts a `sampler2D corruption_map` uniform (64×64 Image, updated by GDScript)
- Shader bleeds/blurs the corruption map across the background
- GDScript: on `peg_state_changed` to "cursed", paint a spot on the Image at peg position
- **Done when**: Cursing a peg visibly spreads ink across the board background

### VO-012 · S · Ball Trail Effect
- Create `shaders/ball_trail.gdshader`
- Line2D tracking last 20 ball positions, updated in `_process`
- Shader: fade opacity tail → head, shift color from white to ghost-blue
- **Done when**: Ball leaves visible fading trail as it falls

---

## MILESTONE 3 — Single Encounter
*Goal: Fight one enemy. Win or die. Loop feels complete.*

### VO-013 · M · Drop Phase / Result Phase Loop
- Drop Phase: launch N balls, wait for all balls to settle or leave board
- Result Phase: tally pocket results (damage, healing, gold, void essence)
- Apply results to `RunState` and enemy HP
- Board Phase: show draft UI (stub for now — just "End Turn" button)
- **Done when**: Full drop → result → next drop loop runs without errors

### VO-014 · M · Corruptor Enemy (First Enemy)
- Enemy panel UI: HP bar, name, intent display
- On each player turn end: pick 1 random Blessed peg → shift to Cursed
- If no Blessed pegs: pick random Dormant peg
- HP: 80. Takes damage from Damage pockets
- On death: emit `EventBus.enemy_defeated`, trigger draft phase
- **Done when**: Full combat loop: drop → deal damage → enemy corrupts a peg → repeat until enemy dies

### VO-015 · S · Stability System UI
- HUD stability bar (ColorRect, fills left to right, gold → red as depletes)
- Tick down 10 stability on each enemy action
- Run ends at 0 stability → show death screen stub
- **Done when**: Taking damage from enemy visibly depletes bar; 0 triggers game over

### VO-016 · M · Ghost Board: Save on Death
- On `EventBus.run_ended`: call `RunState.snapshot_board()` → `GhostBoardManager.save_ghost()`
- Death screen shows board state summary (zone reached, pegs, synergies)
- Save persists: restart game, load ghost_001.json successfully
- **Done when**: Die, restart, confirm ghost JSON exists in user:// directory

---

## MILESTONE 4 — Ghost Board Encounter
*Goal: Your past haunts you. Mechanically.*

### VO-017 · L · Ghost Board Encounter Scene
- Load `GhostBoardManager.active_ghost` board layout
- Render ghost board as semi-transparent enemy "display" panel
- Ghost behavior based on board composition (see GDD Section 7)
- Mostly Blessed → heals enemy each drop
- Mostly Cursed → damages your board (acts as Corruptor)
- High Mutation → fires chaos balls that randomize your peg states
- **Done when**: A ghost encounter spawns, exhibits correct behavior based on saved state

### VO-018 · S · Ghost Board Assignment
- At run start: `GhostBoardManager.assign_ghost_for_run(run_seed)`
- Seeded random pick from saved ghosts
- Place ghost encounter at deterministic position in Zone 2 map
- **Done when**: Ghost encounter appears in same map position if run is restarted with same seed

---

## MILESTONE 5 — Map & Full Run Loop

### VO-019 · L · Run Map (DAG Generator)
- `MapGenerator.gd`: generates 3-zone DAG, 8–10 nodes per zone
- Node types: Combat(40%), Elite(15%), Event(20%), Shop(10%), Rest(10%), Boss(1 per zone)
- Node weighting reads `RunState` board tags (Rot-heavy board → more Mycologist events)
- Render as clickable node graph (simple lines + icons, no art yet)
- **Done when**: Map generates, player can navigate zone 1 start to zone 1 boss

### VO-020 · M · Draft System
- After combat victory: show 3 randomly drawn pegs from tier-weighted pool
- Player clicks to select; chosen peg added to PegContainer at player-chosen slot
- Draft pool seeded from `run_seed + encounter_index`
- **Done when**: Win a fight, see 3 peg choices, place selection on board

### VO-021 · M · Shop
- Appears every ~4 nodes
- Offers: 3 pegs for sale, 1 relic, 3 services (Bless, Purify, Remove)
- Costs in Gold: pegs 10–30g, relics 40–60g, services 15–25g
- **Done when**: Enter shop, buy a peg, see it in draft pool

### VO-022 · M · Remaining 2 Enemy Types
- **Wrecker**: shatters 1 peg per turn (removes it from board permanently)
- **Spawner**: drops enemy balls mid-turn; enemy balls have inverse effect (deal stability damage on pocket entry)
- Each with unique intent display
- **Done when**: Both enemies behave distinctly and correctly in combat

### VO-023 · L · Zone 1 Boss — The Gardener
- Multi-phase: Phase 1 converts Blessed → Dormant each turn
- Phase 2 (below 50% HP): places 2 Thorn pegs (enemy-owned, cannot be removed, deflect balls sideways)
- 150 HP
- Victory: zone 2 unlocks, peg unlock added to draft pool
- **Done when**: Full Gardener fight, both phases, victory/defeat both handled

---

## MILESTONE 6 — Full Game
*(Zone 2, Zone 3, all peg types, all synergies, meta-progression — ticket details TBD after M5)*

### VO-024 · M · Zone 2 + Architect of Ruin Boss
### VO-025 · M · Zone 3 + Final Oracle Boss
### VO-026 · L · All 5 Synergy Effects Implemented
### VO-027 · M · Meta-Progression (Void Shards + Unlocks)
### VO-028 · M · Oracle Classes (4 starting conditions)
### VO-029 · S · Run History / Stats Screen

---

## MILESTONE 7 — Polish & Web Export

### VO-030 · M · Full Shader Pass (all pegs, corruption, trails)
### VO-031 · M · Audio: Per-Peg Tone System
### VO-032 · S · Audio: Ambient Layering (3 loop tracks, zone-based)
### VO-033 · M · Main Menu + UI Polish
### VO-034 · S · Web Export Test (itch.io test page)
### VO-035 · S · Mobile Touch Input Layer

---

## MILESTONE 8 — Steam

### VO-036 · M · Windows + macOS Builds
### VO-037 · M · GodotSteam Integration (achievements)
### VO-038 · S · Steam Page Assets

---

## Backlog / Future
- Additional boss variants (The Overgarden, Architect of Eternity)
- Daily seed runs
- Leaderboards
- Additional Oracle Classes
- Accessibility options (colorblind mode for peg states)
