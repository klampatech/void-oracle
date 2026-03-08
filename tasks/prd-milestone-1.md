# PRD: Milestone 1 — Physics Sandbox

## Introduction

Milestone 1 establishes the foundational physics system for Void Oracle: a board with pegs, a working ball drop, and all peg friction/restitution values producing satisfying physics. This is the core mechanical foundation — everything else builds on it.

**Goal:** A board you can drop a ball into. No game logic. Just physics that feel great.

---

## Goals

- [ ] Create Godot project with 6 AutoLoad singletons configured
- [ ] Build Board scene with physics walls and 8 pocket slots
- [ ] Implement Ball with proper RigidBody2D physics (CCD, gravity, damping)
- [ ] Create BasePeg and all 8 peg types with correct PhysicsMaterial values
- [ ] Implement BallSpawner with aim line and click-to-launch
- [ ] Add Physics Debug Overlay (F1 toggle) showing colliders, velocity vectors, hit counts

---

## User Stories

### VO-001: Godot Project Setup
**Description:** As a developer, I need the Godot project scaffolded with all AutoLoad singletons so the architecture is in place.

**Acceptance Criteria:**
- [ ] Run `scaffold.sh` to generate folder structure
- [ ] Verify all 6 AutoLoad singletons appear in Project Settings > AutoLoad (EventBus, RunState, GhostBoardManager, SynergyChecker, AudioManager, MutationEngine)
- [ ] Set physics ticks to 120 in Project Settings
- [ ] Confirm GL Compatibility renderer is selected
- [ ] Project opens without errors, all AutoLoads listed

---

### VO-002: Board Scene (Physics World)
**Description:** As a player, I need a board with walls and pockets so balls stay in bounds and score correctly.

**Acceptance Criteria:**
- [ ] Create `scenes/game/Board.tscn`
- [ ] Board frame: 4 StaticBody2D walls (left, right, bottom-barrier, ceiling)
- [ ] Board dimensions: 600×900px logical space
- [ ] 8 pocket slots at bottom row as StaticBody2D + Area2D detectors
- [ ] Pocket types assigned: Damage, Heal, Gold, Void, Chaos (assign 2 of each type, vary layout)
- [ ] Ball added manually stays in bounds

---

### VO-003: Ball Physics
**Description:** As a player, I need a ball that falls realistically and interacts with pegs so the physics feel satisfying.

**Acceptance Criteria:**
- [ ] Create `scenes/game/Ball.tscn` as RigidBody2D + CircleShape2D
- [ ] Radius: 12px, mass: 1.0, gravity_scale: 1.4
- [ ] linear_damp: 0.05, CCD: Cast Ray
- [ ] Ball joins group "ball" on ready
- [ ] Ball emits `EventBus.ball_lost` when it exits board bounds
- [ ] Ball emits `EventBus.ball_entered_pocket` when entering pocket Area2D
- [ ] Ball dropped from top reaches bottom, hits pockets, signal fires

---

### VO-004: Base Peg + All 8 Peg Types
**Description:** As a player, I need all 8 peg types with distinct physics so each feels unique when hit.

**Acceptance Criteria:**
- [ ] Create `scenes/game/pegs/BasePeg.tscn` as StaticBody2D + CircleShape2D
- [ ] Radius: 16px
- [ ] `BasePeg.gd`: exposes `peg_type`, `peg_state`, `hit_count`
- [ ] On `_on_body_entered`: emit `EventBus.peg_hit`, increment hit_count
- [ ] Load PhysicsMaterial values from `data/pegs/peg_definitions.json`
- [ ] Create one `.tscn` per peg type extending BasePeg
- [ ] Placeholder ColorRect color per type:
  - Stone: #888888
  - Bone: #E8E0D0
  - Fungal: #4A7A3A
  - Ember: #E85A20
  - Eye: #9060E8
  - Heart: #E83060
  - Oracle: #C9A84C
  - Void Rift: #0A0A2A
- [ ] All 8 pegs instantiable, each has correct restitution/friction
- [ ] `peg_hit` signal fires on collision

---

### VO-005: Ball Spawner
**Description:** As a player, I need to aim and launch balls so I can control where they enter the board.

**Acceptance Criteria:**
- [ ] `BallSpawner` node at top of board
- [ ] Aim line: simple Line2D showing projected launch angle
- [ ] Click/tap to launch ball at aimed angle
- [ ] Ball count limited by `RunState.ball_count` (default 1)
- [ ] Click launches ball, aim line updates with mouse/touch

---

### VO-006: Physics Debug Overlay
**Description:** As a developer, I need to see physics state in real-time so I can debug and tune the feel.

**Acceptance Criteria:**
- [ ] Toggle with F1 key in debug builds
- [ ] Shows: all collider shapes, ball velocity vector, peg hit_count labels
- [ ] Console prints peg_hit signal data (peg_type, position, ball velocity)
- [ ] F1 toggles overlay, hitting pegs prints to console

---

## Functional Requirements

### FR-1: Project Configuration
- FR-1.1: Project uses Godot 4.3+ with GL Compatibility renderer
- FR-1.2: Physics tick rate set to 120 Hz
- FR-1.3: All 6 AutoLoad singletons configured and functional

### FR-2: Board Geometry
- FR-2.1: Board bounds: 600×900px logical space
- FR-2.2: 4 walls (StaticBody2D) form complete enclosure
- FR-2.3: 8 pockets (Area2D) at bottom with distinct types
- FR-2.4: Pocket types: 2 Damage, 2 Heal, 2 Gold, 1 Void, 1 Chaos

### FR-3: Ball Physics
- FR-3.1: Ball uses RigidBody2D with CircleShape2D (radius 12px)
- FR-3.2: Gravity scale: 1.4, Mass: 1.0, Linear damp: 0.05
- FR-3.3: Continuous collision detection: Cast Ray mode
- FR-3.4: Ball belongs to "ball" group
- FR-3.5: Emits `ball_lost` when exiting bounds
- FR-3.6: Emits `ball_entered_pocket` on pocket entry

### FR-4: Peg System
- FR-4.1: BasePeg.gd defines peg_type, peg_state, hit_count
- FR-4.2: Pegs load physics from `data/pegs/peg_definitions.json`
- FR-4.3: 8 peg types extend BasePeg with unique PhysicsMaterial
- FR-4.4: All pegs emit `peg_hit` signal on ball collision
- FR-4.5: Physics values per type:
  | Type | Restitution | Friction |
  |------|-------------|----------|
  | Stone | 0.6 | 0.1 |
  | Bone | 0.5 | 0.05 |
  | Fungal | 0.4 | 0.45 |
  | Ember | 0.9 | 0.05 |
  | Eye | 0.6 | 0.1 |
  | Heart | 0.7 | 0.15 |
  | Oracle | 0.6 | 0.1 |
  | Void Rift | 0.0 | 0.0 |

### FR-5: Ball Spawner
- FR-5.1: BallSpawner positioned at top of board
- FR-5.2: Line2D aim line updates with mouse/touch position
- FR-5.3: Click launches ball toward aimed angle
- FR-5.4: Respects RunState.ball_count limit

### FR-6: Debug Overlay
- FR-6.1: F1 toggles debug overlay visibility
- FR-6.2: Overlay shows collision shapes for all bodies
- FR-6.3: Overlay shows ball velocity vector (Line2D)
- FR-6.4: Overlay shows peg hit_count as labels
- FR-6.5: Console logs peg_hit with peg_type, position, velocity

---

## Non-Goals

- No game loop (drop/result/board phases) — that is Milestone 3
- No enemy system
- No mutation or synergy systems
- No UI (stability bar, gold display)
- No save/load functionality

---

## Technical Considerations

### EventBus Integration
This milestone establishes the signal architecture:
- `EventBus.peg_hit.emit(peg, ball)` — emitted by BasePeg on collision
- `EventBus.ball_lost.emit(ball)` — emitted when ball exits bounds
- `EventBus.ball_entered_pocket.emit(ball, pocket_type)` — emitted on pocket entry

### Data Dependencies
- `data/pegs/peg_definitions.json` — must exist with all 8 peg types and physics values
- AutoLoad singletons must be configured in project.godot

### Physics Tuning Notes
- Fungal pegs are intentionally "sticky" (high friction) to create variety
- Ember pegs are hyper-elastic for unpredictable bounces
- Void Rift has 0 restitution so balls don't bounce off — they teleport (future feature)

---

## Open Questions

- Should the aim line show a trajectory prediction (parabola)? For M1, no — simple straight line is sufficient
- Pocket arrangement — the spec says "vary layout" but doesn't specify exact positions. Use alternating pattern for visual interest
