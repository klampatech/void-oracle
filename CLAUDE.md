# CLAUDE.md — Void Oracle
# Hand this file to Claude Code at the start of every session.
# It lives in the project root. Claude Code reads it automatically.

## Project Overview

**Void Oracle** is a physics-driven roguelike pachinko game built in Godot 4.3+ with GDScript.
The central concept: *the pachinko board is the player's character*. There is no avatar. The board
mutates, grows, and degrades across a run of encounters resolved through real physics simulation.

Full design: see `docs/gdd.md`
Full tech spec: see `docs/tech_stack.md`

---

## Architecture Rules (Never Break These)

### 1. All cross-system communication goes through EventBus
- NEVER call methods directly between systems (e.g. enemy calling `board.damage_peg()`)
- ALWAYS emit a signal on EventBus and let systems subscribe
- Example: `EventBus.peg_hit.emit(self, ball)` — NOT `SynergyChecker.on_peg_hit(self, ball)`

### 2. AutoLoad singletons own their domain exclusively
| Singleton | Owns | Never Does |
|---|---|---|
| `EventBus` | Signal definitions only | No game logic |
| `RunState` | Current run data | No physics, no rendering |
| `GhostBoardManager` | File I/O for ghosts | No game logic |
| `SynergyChecker` | Tag counting + synergy state | No board modification |
| `AudioManager` | Audio playback | No game logic |
| `MutationEngine` | Peg state transitions | No rendering |

### 3. Pegs are data-driven
- All peg stats live in `data/pegs/peg_definitions.json`
- Load via `preload("res://data/pegs/peg_definitions.json")`
- Never hardcode peg values in GDScript — always read from the JSON
- Same rule applies to synergies (`data/synergies/`) and enemies (`data/enemies/`)

### 4. Physics is sacred — don't fight it
- Ball behavior must emerge from real physics (RigidBody2D), not scripted paths
- If a special effect requires overriding physics (e.g. Void Rift teleport), do it in
  `_integrate_forces()` using `PhysicsDirectBodyState2D`, not by setting `position` directly
- CCD mode must stay on (Cast Ray) — never disable it

### 5. Renderer is GL Compatibility — always
- No Forward+ features (no SDFGI, no volumetrics, no screen-space reflections)
- All shaders must work in WebGL2 — test web export early and often
- Use `GPUParticles2D` for performance-critical effects; `CPUParticles2D` only for
  low-frequency effects (e.g. slow ambient auras on idle pegs)

---

## Scene Structure

```
Board.tscn                    ← Main game scene
├── PhysicsWorld (Node2D)     ← Contains all RigidBody2D and StaticBody2D nodes
│   ├── BallSpawner           ← Instantiates Ball.tscn on drop
│   ├── PegContainer          ← All peg instances live here
│   ├── PocketRow             ← StaticBody2D pockets at bottom
│   └── BoardFrame            ← Walls (StaticBody2D)
├── EffectsLayer (CanvasLayer)← Shaders, particles, trails — never physics objects
├── BoardUI (CanvasLayer)     ← HUD — stability bar, gold, drop button
└── EncounterManager (Node)   ← Enemy logic, turn sequencing
```

## Key Patterns

### Peg hit handling (use this pattern for ALL peg types)
```gdscript
# BasePeg.gd
func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("ball"):
        return
    _hit_count += 1
    EventBus.peg_hit.emit(self, body)
    _apply_hit_bonus(body)        # override in subclass
    _update_shader()              # update corruption_level uniform
```

### Saving board state (always use RunState.snapshot_board())
```gdscript
# On run end / death:
var state = RunState.snapshot_board()
GhostBoardManager.save_ghost(state)
```

### Reading peg data
```gdscript
var PEG_DATA = preload("res://data/pegs/peg_definitions.json")
var stone_friction = PEG_DATA["stone"]["friction"]  # → 0.1
```

---

## Current Milestone

**M1 — Physics Sandbox** (start here)

Goal: A board with pegs, a working ball drop, and all peg friction/restitution values
producing satisfying physics. No game logic, no UI, no enemies.

Acceptance criteria:
- [ ] Ball spawns at top, falls with realistic physics
- [ ] All 8 peg types instantiable with correct PhysicsMaterial values
- [ ] Ball reaches pockets at bottom consistently (no tunneling)
- [ ] Peg hit signal fires and prints to console
- [ ] 120 physics ticks/sec confirmed in debug overlay

Files to create first:
1. `scenes/game/Board.tscn` + `scripts/Board.gd`
2. `scenes/game/Ball.tscn` + `scripts/Ball.gd`
3. `scenes/game/pegs/BasePeg.tscn` + `scripts/pegs/BasePeg.gd`
4. One concrete peg: `StonePeg.tscn` extending BasePeg

---

## Placeholder Asset Policy

Until real assets arrive, use Godot primitives:
- **Pegs**: `ColorRect` circles, color-coded by type (see color map below)
- **Ball**: White `ColorRect` circle, radius 12px
- **Board background**: Dark `ColorRect` (#0A0A1A)
- **Pockets**: Colored `ColorRect` rectangles at bottom

### Placeholder color map
| Peg Type | Placeholder Color |
|---|---|
| Stone | #888888 |
| Bone | #E8E0D0 |
| Fungal | #4A7A3A |
| Ember | #E85A20 |
| Eye | #9060E8 |
| Heart | #E83060 |
| Oracle | #C9A84C |
| Void Rift | #0A0A2A (near-black) |

---

## File Naming Conventions

- Scenes: `PascalCase.tscn` (e.g. `FungalPeg.tscn`)
- Scripts: `PascalCase.gd` matching scene name
- Assets: `snake_case` (e.g. `fungal_peg_idle.png`)
- Data files: `snake_case.json`
- Signals: `snake_case` (e.g. `peg_state_changed`)
- Constants: `ALL_CAPS` (e.g. `MUTATION_THRESHOLD`)
- Variables: `_private_with_underscore` or `public_without`

---

## Do Not

- Do not use `@export` for physics values — they must come from `peg_definitions.json`
- Do not use `get_node()` with hardcoded paths — use signals or dependency injection
- Do not store scene-specific state in AutoLoad singletons (use the scene's own script)
- Do not use `await` inside `_physics_process()` — use state machines instead
- Do not disable CCD on balls
- Do not use Forward+ renderer features

---

## Reference Docs

- `docs/gdd.md` — Full game design document
- `docs/tech_stack.md` — Full technology specification
- `data/pegs/peg_definitions.json` — All peg stats
- `data/synergies/synergy_definitions.json` — All synergy definitions
