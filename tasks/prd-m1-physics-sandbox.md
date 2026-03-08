# PRD: M1 — Physics Sandbox

## Introduction

Milestone 1 establishes the foundational physics system for Void Oracle. This includes the project setup, board scene with physics world, ball mechanics, all 8 peg types with correct physics materials, ball spawning, and debug tooling. This milestone delivers a playable physics sandbox where balls can be dropped onto pegs and fall through the board—no game logic, enemies, or UI yet.

The physics sandbox is critical because every mechanic in the game flows from ball-peg collisions. Getting the physics "feeling right" early prevents costly refactoring later.

## Goals

- Create a runnable Godot project with all AutoLoad singletons configured
- Build a functional board with walls, pockets, and pegs where balls fall naturally
- Implement all 8 peg types with correct restitution and friction values from the spec
- Enable ball spawning with aiming mechanic
- Provide debug tooling for physics visualization and tuning

## User Stories

### US-001: Godot Project Setup
**Description:** As a developer, I need a properly configured Godot 4.6 project so I can start building scenes and scripts.

**Acceptance Criteria:**
- [ ] Run scaffold.sh to generate folder structure
- [ ] Open project in Godot 4.6 without errors
- [ ] Verify all 6 AutoLoads appear in Project Settings > AutoLoad: EventBus, RunState, GhostBoardManager, SynergyChecker, AudioManager, MutationEngine
- [ ] Confirm physics ticks set to 120 in Project Settings
- [ ] Confirm GL Compatibility renderer is selected
- [ ] project.godot is properly configured with display, physics, and rendering settings

### US-002: Board Scene with Physics World
**Description:** As a developer, I need a Board scene that defines the playable area with walls and pockets so balls have bounds to interact with.

**Acceptance Criteria:**
- [ ] Create `scenes/game/Board.tscn` as the main game scene
- [ ] Board dimensions: 600×900px logical space centered in viewport
- [ ] 4 StaticBody2D walls: left, right, bottom-barrier, ceiling
- [ ] 8 pocket slots at bottom row as StaticBody2D + Area2D detectors
- [ ] Pocket types assigned: 2 Damage, 2 Heal, 2 Gold, 1 Void, 1 Chaos (vary layout)
- [ ] Each pocket emits `EventBus.ball_entered_pocket` when ball enters
- [ ] Balls that exit bottom of screen emit `EventBus.ball_lost`
- [ ] Board renders with dark background (#0A0A1A)

### US-003: Ball Physics
**Description:** As a developer, I need a Ball scene with correct physics properties so it behaves realistically when dropped.

**Acceptance Criteria:**
- [ ] Create `scenes/game/Ball.tscn` as RigidBody2D + CircleShape2D
- [ ] Ball radius: 12px, mass: 1.0, gravity_scale: 1.4
- [ ] linear_damp: 0.05 (minimal air resistance)
- [ ] CCD mode: Cast Ray (prevents tunneling through thin pegs)
- [ ] Ball joins group "ball" on `_ready()`
- [ ] Ball detects collision with pegs and emits appropriate signals
- [ ] Ball detects entry into pocket Area2D detectors
- [ ] Ball correctly falls from top to bottom, hitting pegs and pockets

### US-004: Base Peg + All 8 Peg Types
**Description:** As a developer, I need all 8 peg types with correct physics materials so each feels distinct when hit.

**Acceptance Criteria:**
- [ ] Create `scenes/game/pegs/BasePeg.tscn` as StaticBody2D + CircleShape2D
- [ ] Peg radius: 16px
- [ ] BasePeg.gd script exposes: `peg_type`, `peg_state`, `hit_count`
- [ ] On `_on_body_entered(body)`: emit `EventBus.peg_hit`, increment hit_count
- [ ] Load PhysicsMaterial values from `data/pegs/peg_definitions.json`
- [ ] Create 8 concrete peg scenes extending BasePeg:

| Peg Type | Restitution | Friction | Placeholder Color |
|----------|-------------|-----------|-------------------|
| Stone | 0.6 | 0.1 | #888888 |
| Bone | 0.5 | 0.05 | #E8E0D0 |
| Fungal | 0.4 | 0.45 | #4A7A3A |
| Ember | 0.9 | 0.05 | #E85A20 |
| Eye | 0.6 | 0.1 | #9060E8 |
| Heart | 0.7 | 0.15 | #E83060 |
| Oracle | 0.6 | 0.1 | #C9A84C |
| Void Rift | 0.0 | 0.0 | #0A0A2A |

- [ ] All pegs show correct physics behavior (balls bounce differently off each)
- [ ] `EventBus.peg_hit` fires on every ball-peg collision

### US-005: Ball Spawner
**Description:** As a developer, I need a ball spawner at the top of the board so I can launch balls into play.

**Acceptance Criteria:**
- [ ] BallSpawner node positioned at top of board
- [ ] Aim line: Line2D showing projected launch angle from spawn point to mouse/touch position
- [ ] Click/tap to launch ball at aimed angle
- [ ] Ball velocity based on angle: launch from top-center at configurable speed
- [ ] Ball count managed by `RunState.ball_count` (default 1 for sandbox)
- [ ] Visual feedback when aiming (line updates in real-time)

### US-006: Physics Debug Overlay
**Description:** As a developer, I need debug visualization so I can tune physics values and verify collision behavior.

**Acceptance Criteria:**
- [ ] Toggle with F1 key (only in debug builds, not release)
- [ ] Shows all collider shapes (debug draw or CollisionPolygon2D visibility)
- [ ] Shows ball velocity vector as arrow/line
- [ ] Shows peg hit_count labels above each peg
- [ ] Console prints `EventBus.peg_hit` signal data: peg_type, position, ball velocity
- [ ] Debug overlay does not affect physics performance

## Functional Requirements

### FR-1: Project Configuration
- FR-1.1: Godot 4.6+ with GL Compatibility renderer
- FR-1.2: Physics ticks: 120 per second (double default)
- FR-1.3: Default gravity: 980 px/s²
- FR-1.4: All 6 AutoLoad singletons registered and functional
- FR-1.5: Window size: 1080×1920, portrait orientation, canvas_items stretch

### FR-2: Board Scene Structure
- FR-2.1: Board is a Node2D containing PhysicsWorld, EffectsLayer, BoardUI
- FR-2.2: PhysicsWorld contains all RigidBody2D and StaticBody2D nodes
- FR-2.3: Pockets are StaticBody2D + Area2D with detection
- FR-2.4: Board frame walls prevent balls escaping bounds

### FR-3: Ball Physics Parameters
- FR-3.1: RigidBody2D with gravity_scale 1.4
- FR-3.2: Mass: 1.0, linear_damp: 0.05
- FR-3.3: Continuous CD: Cast Ray (always on)
- FR-3.4: Max velocity capped at 4000 px/s in ProjectSettings

### FR-4: Peg Physics Parameters
- FR-4.1: All values loaded from `data/pegs/peg_definitions.json`
- FR-4.2: Each peg has PhysicsMaterial with unique restitution/friction
- FR-4.3: Peg collision triggers `EventBus.peg_hit`

### FR-5: Spawner Mechanics
- FR-5.1: Mouse/touch position determines aim angle
- FR-5.2: Launch velocity: configurable, default 500 px/s
- FR-5.3: Aim line rendered as Line2D with 20+ points

### FR-6: Debug System
- FR-6.1: Input.is_action_just_pressed("ui_toggle_debug") triggers overlay
- FR-6.2: Collision shapes visible when debug enabled
- FR-6.3: Peg labels update in real-time as hit_count changes

## Non-Goals

- No game loop (turns, phases) — just physics sandbox
- No enemies, combat, or stability system
- No UI beyond basic debug labels
- No synergies, mutations, or special peg behaviors (Oracle split, Void Rift teleport, etc.) — plain physics only for M1
- No save/load or ghost board system
- No audio (placeholder print statements only)
- No shaders — placeholder colors only

## Design Considerations

### Node Structure

```
Board.tscn (Node2D)
├── PhysicsWorld (Node2D)
│   ├── BallSpawner (Node2D)
│   │   └── AimLine (Line2D)
│   ├── PegContainer (Node2D)
│   │   ├── StonePeg (StaticBody2D)
│   │   ├── BonePeg (StaticBody2D)
│   │   └── ... (all 8 peg types)
│   ├── PocketRow (Node2D)
│   │   ├── Pocket_Damage_1 (StaticBody2D + Area2D)
│   │   ├── Pocket_Damage_2 (StaticBody2D + Area2D)
│   │   └── ... (8 pockets total)
│   └── BoardFrame (Node2D)
│       ├── WallLeft (StaticBody2D)
│       ├── WallRight (StaticBody2D)
│       ├── WallTop (StaticBody2D)
│       └── WallBottom (StaticBody2D)
├── EffectsLayer (CanvasLayer)  # For future shaders/particles
└── DebugOverlay (CanvasLayer)   # For debug labels
```

### Peg Placement Grid

The board should use a staggered grid for peg placement:
- ~8 columns × 12 rows = 96 potential slots
- Staggered pattern (odd rows offset by half column width)
- Place initial pegs in typical pachinko arrangement for testing

### Performance Targets

- Maintain 120 FPS physics on mid-range hardware
- Ball-peg collision detection: <1ms per frame
- Maximum 50 active balls before performance degradation
- Memory: <100MB for sandbox scene

## Technical Considerations

### Godot 4.6 Specific

- Use `@export` for editor-exposed fields (aim speed, debug toggle)
- Use `Callable` for signal connections instead of string-based
- Use `is_instance_valid()` before accessing nodes from signals
- Use `Vector2` for all position/velocity math
- PhysicsBody2D methods: `get_collide_rect()`, `global_position`

### Signal Architecture (Enforced)

All peg-ball interactions MUST flow through EventBus:

```gdscript
# CORRECT: Emit signal
EventBus.peg_hit.emit(self, body)

# WRONG: Direct method call
some_system.process_peg_hit(self, body)
```

### Data Loading Pattern

```gdscript
# Load peg definitions (called once at startup)
var PEG_DATA = preload("res://data/pegs/peg_definitions.json")

# In BasePeg.gd _ready():
var type = self.peg_type
var data = PEG_DATA[type]
physics_material.friction = data["friction"]
physics_material.bounce = data["restitution"]
```

## Success Metrics

- [ ] Balls drop naturally with satisfying physics feel
- [ ] All 8 peg types produce distinct bounce behaviors
- [ ] No ball tunneling through pegs at any angle
- [ ] Balls consistently reach pockets at bottom
- [ ] Debug overlay shows all collision shapes and velocity vectors
- [ ] Console shows peg_hit signals with correct data
- [ ] Project runs at 120 FPS on development hardware

## Open Questions

1. **Should the scaffold.sh be re-run or manual setup?** — Recommend manual setup to understand project structure; scaffold.sh is reference
2. **Initial peg placement?** — Use standard pachinko layout: staggered rows, ~15-20 pegs placed
3. **Pocket detection method?** — Area2D with body_entered signal is simplest; consider contact_monitor + max_contacts for reliability

## Implementation Status (2026-03-08)

### Completed
- [x] US-001: Godot Project Setup
- [x] US-002: Board Scene with Physics World
- [x] US-003: Ball Physics
- [x] US-004: Base Peg + All 8 Peg Types (scenes created, physics data loaded from JSON)
- [x] US-005: Ball Spawner (aim line, click-to-launch)

### Not Implemented
- [ ] US-006: Physics Debug Overlay

### Gaps Found
1. **Pegs not spawned**: 8 peg scene files exist but Board.gd has no code to instantiate them on the board. Need to add `_create_pegs()` method. This is blocking the sandbox from being playable.
2. **PhysicsDebugOverlay**: Scene and script referenced in progress.txt but files don't exist in codebase.

### To Complete M1
1. Add peg spawning logic to `Board.gd` that instantiates pegs in a staggered grid pattern (~15-20 pegs)
2. Create `scenes/game/PhysicsDebugOverlay.tscn` + `scripts/game/PhysicsDebugOverlay.gd`

## Implementation Order

1. VO-001: Run scaffold.sh / setup project
2. VO-002: Board scene + walls + pockets
3. VO-003: Ball physics
4. VO-004: BasePeg + all 8 types (start with Stone, add one at a time)
5. VO-005: Ball spawner with aim line
6. VO-006: Debug overlay

## Dependencies

- **Blocks:** All future milestones (M2-M8)
- **Blocked by:** None — this is the starting point

---

*PRD Version: 1.0*
*Target: Godot 4.6*
*Milestone: M1 — Physics Sandbox*
